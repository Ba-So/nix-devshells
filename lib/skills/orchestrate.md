# Orchestrator

Orchestrate tasks by tag using worktree isolation with parallel agents.

Tag: $ARGUMENTS

## Available Agents

| Agent                   | Role in Workflow                                                    | Model  |
| ----------------------- | ------------------------------------------------------------------- | ------ |
| **coder**               | Implements tasks in worktrees, applies fixes after review           | sonnet |
| **code-reviewer**       | Reviews diffs for design red flags, anti-patterns, correctness      | sonnet |
| **codebase-researcher** | Deep codebase exploration when coder/reviewer need context          | sonnet |
| **software-designer**   | Consulted for non-trivial design decisions before implementation    | opus   |
| **test-specialist**     | Writes and improves tests as part of implementation or review fixes | sonnet |

**Primary workflow agents**: `coder` (CODE, FIX phases) and `code-reviewer` (REVIEW phase).
**Supporting agents**: spawn `codebase-researcher`, `software-designer`, or `test-specialist`
as sub-agents within a coder/reviewer prompt when the task requires it.

## Per-Task Lifecycle

Each task progresses through this chain **independently and asynchronously**.
Within a wave, do NOT wait for all tasks to finish a step before advancing others.
As soon as one task's coder finishes, start its sync/review immediately — even while
other tasks in the same wave are still coding.

```
CODE --> SYNC --> REVIEW --> APPROVED --> MERGE --> DONE
                    |
                    | CHANGES_REQUESTED
                    v
                   FIX --> SYNC --> REVIEW  (max 3 iterations)
                                      |
                                      v
                             iteration > 3 --> BLOCK + REPORT
```

## Workflow

### Phase 1: Plan Waves

1. Run `task-master list --tag=<tag>` to get all tasks for the given tag.
2. Analyze task dependencies to group them into **waves**:
   - **Wave 1**: tasks with no pending dependencies (or dependencies already done)
   - **Wave 2**: tasks whose dependencies are all in wave 1
   - **Wave N**: tasks whose dependencies are all in earlier waves
3. Execute waves sequentially. Within each wave, all tasks run **asynchronously**.
4. A wave is complete when every task in it is either `done` or `blocked`.
   Only then does the next wave begin.

### Phase 2: Execute Wave

For each wave:

1. **Spawn all coders** for the wave (see Spawn Workers below).
2. **Poll continuously.** Each time a coder completes, immediately advance that task
   to sync → review → merge (or fix → sync → review loop). Do not wait for other
   coders in the wave.
3. Multiple tasks may be in different lifecycle stages simultaneously (one coding,
   another in review, another merging). This is expected and desired.
4. The wave is complete when every task is `done` or `blocked`.

### Spawn Workers

1. **Setup worktrees**: For each task in the current wave:
   - `task-master show <id> --tag=<tag>` to get task details
   - `task-master set-status --id=<id> --status=in-progress --tag=<tag>`
   - `worktree-new task-<id>` to create `../<project>-task-<id>/`
   - If worktree creation fails, report and skip this task

2. **Spawn ALL coder agents** in ONE message using the Agent tool with `run_in_background=true`.
   For test-focused tasks, use the **test-specialist** agent instead.
   For tasks requiring non-trivial design decisions, instruct the coder to spawn a
   **software-designer** sub-agent before implementing.

   Each agent prompt MUST include:
   - The task description and details from task-master
   - The worktree path to `cd` into
   - Instructions to implement, commit, and push
   - The OUTPUT CONSTRAINT below

   **Coder prompt template:**

   ```
   You are the coder agent working in a worktree. Your task:
   - cd to <worktree-path>
   - Implement: <task description>
   - Use serena for all code modifications (replace_symbol_body, insert_after_symbol, etc.)
   - Stage and commit your changes (do NOT push — worktrees share the local repo)
   - Use clear commit messages (feat:, fix:, refactor:, etc.)

   OUTPUT CONSTRAINT: Your ENTIRE final response must be a single JSON object.
   No explanations, no reasoning, no file contents, no markdown formatting.
   Just the raw JSON on one line.
   ```

   **Coder output format:**

   ```json
   {
     "task_id": "X",
     "status": "done|failed",
     "files_changed": ["path"],
     "summary": "<20 words max>"
   }
   ```

### Per-Task: Sync, Review, Merge

As soon as a coder (or fix agent) completes for a task, advance it through the
following steps. Each task progresses independently — don't batch or serialize
across tasks.

#### Sync main into feature branch

Before any review, the feature branch MUST incorporate the latest main.
Spawn a sync agent in the worktree with `run_in_background=true`:

```
You are a sync agent. Your task:
- cd to <worktree-path>
- Run: git merge main
- If merge succeeds cleanly: commit if needed, report success
- If merge conflicts occur: attempt to resolve them sensibly, then commit
- If conflicts cannot be resolved: report blocked with conflict details

OUTPUT CONSTRAINT: Your ENTIRE final response must be a single JSON object.
Just the raw JSON on one line.
```

**Sync output:**

```json
{
  "task_id": "X",
  "main_synced": true,
  "conflicts_resolved": false,
  "status": "synced|blocked",
  "summary": "<20 words max>"
}
```

- If `status: "blocked"`: run `task-master set-status --id=<id> --status=blocked --tag=<tag>`, keep worktree, report conflict details
- If `status: "synced"`: proceed to review

#### Code review

Spawn the **code-reviewer** agent with `run_in_background=true`.
The code-reviewer has codanna for semantic analysis — it can trace callers, assess
impact, and verify that changes don't leak across boundaries.

```
You are the code-reviewer agent reviewing a feature branch. Your task:
- cd to <worktree-path>
- Review ALL changes on this branch vs main: git diff main...HEAD
- Use codanna to understand the impact of changes:
  - find_callers on modified functions to check what depends on them
  - analyze_impact on key symbols to assess blast radius
  - semantic_search_with_context for broader context
- Check: correctness, test coverage, code quality, no regressions
- Apply the design red flags and anti-pattern checks from your agent definition
- Verdict: APPROVE if ready to merge, CHANGES_REQUESTED if issues found

OUTPUT CONSTRAINT: Your ENTIRE final response must be a single JSON object.
Just the raw JSON on one line.
```

**Review output:**

```json
{
  "task_id": "X",
  "verdict": "APPROVE|CHANGES_REQUESTED",
  "issues": ["short issue"],
  "summary": "<20 words max>"
}
```

#### On verdict

- **APPROVE**: Merge the feature branch into main, run `task-master set-status --id=<id> --status=done --tag=<tag>`, remove worktree with `worktree-remove task-<id>`
- **CHANGES_REQUESTED**: Increment iteration counter for this task
  - If iteration <= 3: spawn fix agent (below), then loop back to Sync (sync + review again)
  - If iteration > 3: run `task-master set-status --id=<id> --status=blocked --tag=<tag>`, report failure, keep worktree

#### Fix agent

Spawn the **coder** agent to apply fixes. The coder has serena for precise,
symbol-aware edits.

```
You are the coder agent fixing review issues. Your task:
- cd to <worktree-path>
- Fix these issues: <issues from review>
- Use serena for all code modifications (replace_symbol_body, insert_after_symbol, etc.)
- Stage and commit your fixes (do NOT push — worktrees share the local repo)

OUTPUT CONSTRAINT: Your ENTIRE final response must be a single JSON object.
Just the raw JSON on one line.
```

**Fix output:**

```json
{
  "task_id": "X",
  "status": "done|failed",
  "fixes_applied": ["short desc"],
  "summary": "<20 words max>"
}
```

### Wave Complete

When all tasks in the wave are `done` or `blocked`, the wave is complete.
Proceed to the next wave. Tasks in later waves whose dependencies are `blocked`
should also be set to `blocked` via `task-master set-status --id=<id> --status=blocked --tag=<tag>`.

### Phase 3: Report

Display final status with `task-master list --tag=<tag>`.

## Constraints

- Tasks are selected by **tag**, not by individual IDs
- Tasks execute in **dependency waves** — never start a task before its dependencies are done
- **Within a wave, tasks progress asynchronously** — never wait for all tasks to finish coding before starting reviews
- **Sync main into branch** before every review — never skip, never reverse the direction
- Review BEFORE merge — never skip
- Max 3 fix iterations per task — then block and report
- On unresolvable merge conflict: block, do NOT auto-resolve
- On timeout/crash: block, keep worktree for inspection

## Progress Table

Maintain a single progress table and **reprint it every time any task changes state**.
This includes: agent spawned, agent completed, sync started/finished, review verdict
received, fix spawned, task merged, task blocked, wave advanced.

The table is the user's primary view into the orchestration — keep it current.

```
+---------+----------------------------+------------------------------------------+
|  Wave   |            Task            |             Status                       |
+---------+----------------------------+------------------------------------------+
|    1    | Task 3 (auth middleware)    | ✅ Done - added JWT validation            |
+---------+----------------------------+------------------------------------------+
|    1    | Task 5 (db migrations)     | 🔍 Review - awaiting verdict              |
+---------+----------------------------+------------------------------------------+
|    1    | Task 7 (config parsing)    | 🔄 Running - Fix #2, applying fixes      |
+---------+----------------------------+------------------------------------------+
|    2    | Task 9 (API endpoints)     | ⏳ Pending - waiting on 3, 5              |
+---------+----------------------------+------------------------------------------+
|    2    | Task 11 (error handling)   | ❌ Blocked - dependency 7 blocked         |
+---------+----------------------------+------------------------------------------+
```

**Status icons:**

- ✅ Done
- 🔄 Running (coding, fixing, syncing)
- 🔍 Review (awaiting or processing verdict)
- ⏳ Pending (waiting on dependencies)
- ❌ Blocked (failed after 3 iterations or unresolvable conflict)

**Columns:**

- **Wave**: Wave number the task belongs to
- **Task**: Task number + brief description (include "Fix #N", "Sync", or "Review" for iterations)
- **Status**: Emoji + state + context. For pending tasks, show which dependencies they await.
