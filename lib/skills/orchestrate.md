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

## Constraints

- Review BEFORE merge — never skip
- Max 3 fix iterations per task — then block and report
- On merge conflict: block, do NOT auto-resolve
- On timeout/crash: block, keep worktree for inspection
