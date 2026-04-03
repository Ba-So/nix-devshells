# Orchestrator

Orchestrate tasks using worktree isolation with parallel agents.

Tasks: $ARGUMENTS

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

Each task runs INDEPENDENTLY. A task is NEVER merged until its review passes.

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

### Phase 1: Plan

For each task, run `task-master set-status --id=<id> --status=in-progress`

### Phase 2: Spawn Workers

1. **Setup worktrees**: For each task:
   - `task-master show <id>` to get task details
   - `worktree-new task-<id>` to create `../<project>-task-<id>/`
   - If worktree creation fails, report and skip this task

2. **Spawn ALL coder agents** in ONE message using the Agent tool with `run_in_background=true`.
   For tasks that are primarily about tests, use the **test-specialist** agent instead.
   For tasks that require non-trivial design decisions, instruct the coder to spawn a
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
   - Stage, commit, and push your changes
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

3. **Record** agent IDs and their task mapping for tracking.

### Phase 3: Collect Results

1. **Poll each agent** with `TaskOutput(block=false)`

2. **Categorize** results:
   - **Completed**: Agent returned JSON with `status: "done"`
   - **Running**: Agent still in progress (no output yet)
   - **Failed**: Agent returned JSON with `status: "failed"`, or errored out

3. **Verify git state** for completed agents:
   - Check the worktree has committed changes: `git -C <worktree> log --oneline -1`
   - Check changes are pushed: `git -C <worktree> status` (no unpushed commits)
   - If not committed/pushed, flag as incomplete

4. If agents are still running, wait and re-poll. Display the progress table at each check.

### Phase 4: Review and Merge

For each completed task, process sequentially:

#### 4a. Sync with main

Before any review, the feature branch MUST be up-to-date with main.
Spawn a sync agent with `run_in_background=true`:

```
You are a sync agent. Your task:
- cd to <worktree-path>
- Run: git fetch origin main && git merge origin/main
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

- If `status: "blocked"`: skip review, set task status=blocked, keep worktree, report conflict details
- If `status: "synced"`: proceed to review

#### 4b. Code review

Spawn the **code-reviewer** agent with `run_in_background=true`.
The code-reviewer has codanna for semantic analysis -- it can trace callers, assess
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

#### 4c. On verdict

- **APPROVE**: Merge into main, run `task-master set-status --id=<id> --status=done`, remove worktree with `worktree-remove task-<id>`
- **CHANGES_REQUESTED**: Increment iteration counter for this task
  - If iteration <= 3: spawn fix agent (below), then loop back to 4a (sync + review)
  - If iteration > 3: set status=blocked, report failure, keep worktree

#### 4d. Fix agent

Spawn the **coder** agent to apply fixes. The coder has serena for precise,
symbol-aware edits.

```
You are the coder agent fixing review issues. Your task:
- cd to <worktree-path>
- Fix these issues: <issues from review>
- Use serena for all code modifications (replace_symbol_body, insert_after_symbol, etc.)
- Stage, commit, and push your fixes

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

### Phase 5: Report

Display final status with `task-master list`.

## Constraints

- Review BEFORE merge -- never skip
- Sync with main BEFORE review -- never skip
- Max 3 fix iterations per task -- then block and report
- On unresolvable merge conflict: block, do NOT auto-resolve
- On timeout/crash: block, keep worktree for inspection

## User Experience

Display a progress table after each state change:

```
+---------+----------------------------+---------------------------------+
|  Agent  |            Task            |             Status              |
+---------+----------------------------+---------------------------------+
| aec6d88 | Task 1 Fix (short desc)    | Done - summary                  |
+---------+----------------------------+---------------------------------+
| a2f1c72 | Task 2 (short desc)        | Running - current step           |
+---------+----------------------------+---------------------------------+
| a1c091f | Task 4 (short desc)        | Pending                          |
+---------+----------------------------+---------------------------------+
```

**Columns:**

- **Agent**: Short task ID from Task tool (first 7 chars)
- **Task**: Task number + brief description (include "Fix", "Sync", or "Review" for iterations)
- **Status**: State + current activity
