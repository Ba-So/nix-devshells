# Orchestrator

Orchestrate tasks using worktree isolation with parallel agents.

Tasks: $ARGUMENTS

## Per-Task Lifecycle

Each task runs INDEPENDENTLY. A task is NEVER merged until its review passes.

```
CODE ──► REVIEW ──► APPROVED ──► MERGE ──► DONE
           │
           │ CHANGES_REQUESTED
           ▼
          FIX ──► REVIEW  (max 3 iterations)
                    │
                    ▼
           iteration > 3 ──► BLOCK + REPORT
```

## Workflow

1. **Setup**: For each task, run `task-master set-status --id=<id> --status=in-progress`,
   then `worktree-new task-<id>` to create `../<project>-task-<id>/`

2. **Spawn coding agents** in parallel using Task tool with `run_in_background=true`.
   Each agent: cd to worktree, implement, commit, push. Returns JSON with task_id, status, files_changed, summary.

3. **Process each task as it completes**:
   - Verify committed and pushed
   - Spawn review agent for THIS task (not batch - per task!)
   - Review agent returns: `{task_id, verdict: APPROVE|CHANGES_REQUESTED, issues[], summary}`

4. **On verdict**:
   - **APPROVE**: Merge immediately (`git fetch .. && git merge`), set status=done, remove worktree
   - **CHANGES_REQUESTED**: Increment iteration counter for this task
     - If iteration ≤ 3: Spawn fix agent, then back to review
     - If iteration > 3: Set status=blocked, report failure, keep worktree

5. **Report** final status with `task-master list`

## Agent Output Format (CRITICAL)

All spawned agents MUST return minimal output to prevent context bloat.
Include this instruction in EVERY agent prompt:

```
OUTPUT CONSTRAINT: Your ENTIRE final response must be a single JSON object.
No explanations, no reasoning, no file contents, no markdown formatting.
Just the raw JSON on one line.
```

**Coding agent returns:**

```json
{
  "task_id": "X",
  "status": "done|failed",
  "files_changed": ["path"],
  "summary": "<20 words max>"
}
```

**Review agent returns:**

```json
{
  "task_id": "X",
  "verdict": "APPROVE|CHANGES_REQUESTED",
  "issues": ["short issue"],
  "summary": "<20 words max>"
}
```

**Fix agent returns:**

```json
{
  "task_id": "X",
  "status": "done|failed",
  "fixes_applied": ["short desc"],
  "summary": "<20 words max>"
}
```

## Constraints

- Review BEFORE merge — never skip
- Max 3 fix iterations per task — then block and report
- On merge conflict: block, do NOT auto-resolve
- On timeout/crash: block, keep worktree for inspection

## User Experience

Display a progress table after each state change:

```
┌─────────┬────────────────────────────┬─────────────────────────────────┐
│  Agent  │            Task            │             Status              │
├─────────┼────────────────────────────┼─────────────────────────────────┤
│ aec6d88 │ Task 1 Fix (short desc)    │ ✅ Completed - summary          │
├─────────┼────────────────────────────┼─────────────────────────────────┤
│ a2f1c72 │ Task 2 (short desc)        │ 🔄 Running - current step       │
├─────────┼────────────────────────────┼─────────────────────────────────┤
│ a1c091f │ Task 4 (short desc)        │ ⏳ Pending                      │
└─────────┴────────────────────────────┴─────────────────────────────────┘
```

**Columns:**

- **Agent**: Short task ID from Task tool (first 7 chars)
- **Task**: Task number + brief description (include "Fix" or "Review" for iterations)
- **Status**: Emoji + state + current activity

**Status icons:**

- ✅ Completed
- 🔄 Running
- ⏳ Pending
- ❌ Failed/Blocked
- 🔍 In Review
