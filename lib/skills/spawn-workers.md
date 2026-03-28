# Spawn Workers

Tasks: $ARGUMENTS

## Workflow

1. **Setup worktrees**: For each task:
   - `task-master show <id>` to get task details
   - `task-master set-status --id=<id> --status=in-progress`
   - `worktree-new task-<id>` to create `../<project>-task-<id>/`
   - If worktree creation fails, report and skip this task

2. **Spawn ALL coding agents** in ONE message using Task tool with `run_in_background=true`.
   Each agent prompt must include:
   - The task description and details from task-master
   - The worktree path to `cd` into
   - Instructions to implement, commit, and push
   - The OUTPUT CONSTRAINT below

3. **Return** agent IDs and task mapping for tracking with `/collect-results`

## Agent Prompt Template

Include in EVERY coding agent prompt:

```
You are a worker agent. Your task:
- cd to <worktree-path>
- Implement: <task description>
- Stage, commit, and push your changes
- Use clear commit messages (feat:, fix:, refactor:, etc.)

OUTPUT CONSTRAINT: Your ENTIRE final response must be a single JSON object.
No explanations, no reasoning, no file contents, no markdown formatting.
Just the raw JSON on one line.
```

## Coding Agent Output Format

```json
{
  "task_id": "X",
  "status": "done|failed",
  "files_changed": ["path"],
  "summary": "<20 words max>"
}
```
