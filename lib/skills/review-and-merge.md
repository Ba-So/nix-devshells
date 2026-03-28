# Review and Merge

Tasks: $ARGUMENTS

## Per-Task Workflow

For each task, process sequentially:

### 1. Sync with main

Before any review, the feature branch MUST be up-to-date with main.
Spawn a sync agent for the worktree with `run_in_background=true`:

```
You are a sync agent. Your task:
- cd to <worktree-path>
- Run: git fetch origin main && git merge origin/main
- If merge succeeds cleanly: commit if needed, report success
- If merge conflicts occur: attempt to resolve them sensibly, then commit
- If conflicts cannot be resolved: report blocked with conflict details

OUTPUT CONSTRAINT: Your ENTIRE final response must be a single JSON object.
No explanations, no reasoning, no file contents, no markdown formatting.
Just the raw JSON on one line.
```

**Sync agent output:**

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

### 2. Code review

Spawn a review agent for the worktree with `run_in_background=true`:

```
You are a review agent. Your task:
- cd to <worktree-path>
- Review ALL changes on this branch vs main: git diff main...HEAD
- Check: correctness, test coverage, code quality, no regressions
- Verdict: APPROVE if ready to merge, CHANGES_REQUESTED if issues found

OUTPUT CONSTRAINT: Your ENTIRE final response must be a single JSON object.
No explanations, no reasoning, no file contents, no markdown formatting.
Just the raw JSON on one line.
```

**Review agent output:**

```json
{
  "task_id": "X",
  "verdict": "APPROVE|CHANGES_REQUESTED",
  "issues": ["short issue"],
  "summary": "<20 words max>"
}
```

### 3. On verdict

- **APPROVE**: Merge into main, set `task-master set-status --id=<id> --status=done`, remove worktree with `worktree-remove task-<id>`
- **CHANGES_REQUESTED**: Increment iteration counter for this task
  - If iteration <= 3: Spawn fix agent (see below), then loop back to step 1 (sync + review)
  - If iteration > 3: Set status=blocked, report failure, keep worktree

### Fix Agent

```
You are a fix agent. Your task:
- cd to <worktree-path>
- Fix these issues: <issues from review>
- Stage, commit, and push your fixes

OUTPUT CONSTRAINT: Your ENTIRE final response must be a single JSON object.
No explanations, no reasoning, no file contents, no markdown formatting.
Just the raw JSON on one line.
```

**Fix agent output:**

```json
{
  "task_id": "X",
  "status": "done|failed",
  "fixes_applied": ["short desc"],
  "summary": "<20 words max>"
}
```

## Constraints

- NEVER merge without review approval
- ALWAYS sync with main before review (including after fixes)
- Max 3 fix iterations per task — then block and report
- On unresolvable merge conflict: block, do NOT force-resolve
- On timeout/crash: block, keep worktree for inspection
