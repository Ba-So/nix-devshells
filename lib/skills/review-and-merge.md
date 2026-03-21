# Review and Merge

Tasks: $ARGUMENTS

For each task:

1. Spawn review agent for the worktree
2. On APPROVE: merge, set status=done, remove worktree
3. On CHANGES_REQUESTED: spawn fix agent, re-review (max 3 iterations)
4. On iteration > 3: block and report

Never merge without review approval.
