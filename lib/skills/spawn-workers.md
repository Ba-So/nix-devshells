# Spawn Workers

Tasks: $ARGUMENTS

1. For each task: `task-master show <id>`, then `worktree-new task-<id>`
2. Spawn ALL coding agents in ONE message with `run_in_background=true`
3. Each agent: cd to worktree, implement, commit, push
4. Return agent IDs for tracking
