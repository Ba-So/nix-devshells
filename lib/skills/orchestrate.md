# Orchestrator

Orchestrate tasks using worktree isolation with parallel agents.

Tasks: $ARGUMENTS

## Per-Task Lifecycle

Each task runs INDEPENDENTLY. A task is NEVER merged until its review passes.

```
CODE ──► SYNC ──► REVIEW ──► APPROVED ──► MERGE ──► DONE
                    │
                    │ CHANGES_REQUESTED
                    ▼
                   FIX ──► SYNC ──► REVIEW  (max 3 iterations)
                                      │
                                      ▼
                             iteration > 3 ──► BLOCK + REPORT
```

## Workflow

1. **Plan**: For each task, run `task-master set-status --id=<id> --status=in-progress`

2. **Spawn**: Invoke `/spawn-workers <task-ids>` to create worktrees and launch coding agents

3. **Collect**: Invoke `/collect-results <agent-ids>` to poll and track progress

4. **Review & Merge**: Invoke `/review-and-merge <task-ids>` for each completed task.
   This handles: sync with main, code review, fix iterations, and final merge.

5. **Report**: Final status with `task-master list`

## Constraints

- Review BEFORE merge — never skip
- Sync with main BEFORE review — never skip
- Max 3 fix iterations per task — then block and report
- On unresolvable merge conflict: block, do NOT auto-resolve
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
- **Task**: Task number + brief description (include "Fix", "Sync", or "Review" for iterations)
- **Status**: Emoji + state + current activity

**Status icons:**

- ✅ Completed
- 🔄 Running
- ⏳ Pending
- ❌ Failed/Blocked
- 🔍 In Review
- 🔀 Syncing with main
