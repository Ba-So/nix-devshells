# Collect Results

Agent IDs: $ARGUMENTS

## Workflow

1. **Poll each agent** with `TaskOutput(block=false)`

2. **Categorize** results:
   - **Completed**: Agent returned JSON with `status: "done"`
   - **Running**: Agent still in progress (no output yet)
   - **Failed**: Agent returned JSON with `status: "failed"`, or errored out

3. **Verify git state** for completed agents:
   - Check the worktree has committed changes: `git -C <worktree> log --oneline -1`
   - Check changes are pushed: `git -C <worktree> status` (no unpushed commits)
   - If not committed/pushed, flag as incomplete

4. **Display progress table**:

```
┌─────────┬────────────────────────────┬─────────────────────────────────┐
│  Agent  │            Task            │             Status              │
├─────────┼────────────────────────────┼─────────────────────────────────┤
│ aec6d88 │ Task 1 (short desc)        │ ✅ Completed - summary          │
├─────────┼────────────────────────────┼─────────────────────────────────┤
│ a2f1c72 │ Task 2 (short desc)        │ 🔄 Running                      │
├─────────┼────────────────────────────┼─────────────────────────────────┤
│ a1c091f │ Task 4 (short desc)        │ ❌ Failed - error reason         │
└─────────┴────────────────────────────┴─────────────────────────────────┘
```

5. **Return** list of completed task IDs ready for `/review-and-merge`

If agents are still running, wait and re-poll. Report progress at each check.
