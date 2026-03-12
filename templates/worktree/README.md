# Multi-Agent Worktree Project

This template sets up a multi-agent development workflow using git worktrees.

## Directory Structure

The project root is a container directory (NOT a git repo itself):

```
project/                            # Orchestrator container
├── .envrc                          # use flake . --impure
├── flake.nix                       # type = "worktree", mainDir = "main"
├── flake.lock
├── .mcp.json → .orchestrator/.mcp.json
├── .orchestrator/
│   └── .mcp.json                   # Full MCP (WITH task-master)
├── .shared/
│   ├── flake.nix                   # GENERATED - subtree shell for workers
│   ├── .mcp.json                   # Agent MCP (NO task-master)
│   ├── .codanna/                   # Shared code index
│   └── CLAUDE.md                   # Shared agent instructions
├── main/                           # Main git checkout (configured via mainDir)
│   └── ...                         # Your actual code
└── feature-x/                      # Worktree (sibling to main)
    ├── .envrc                      # use flake ../.shared --impure
    ├── .mcp.json → ../.shared/.mcp.json
    ├── CLAUDE.md → ../.shared/CLAUDE.md
    └── ...                         # Working copy
```

## Initial Setup

```bash
# 1. Create project container
mkdir my-project
cd my-project

# 2. Create flake.nix (copy from template or nix flake init -t github:Ba-So/nix-devshells#worktree)
# Edit flake.nix to set mainDir if not using "main"

# 3. Create .envrc
echo "use flake . --impure" > .envrc

# 4. Clone your repo into the mainDir subdirectory
git clone <your-repo-url> main
# Or for an existing repo:
# mv /path/to/existing/repo main

# 5. Activate orchestrator shell
direnv allow

# This creates:
#   .shared/          (with flake.nix, .mcp.json, CLAUDE.md, .codanna/)
#   .orchestrator/    (with .mcp.json including task-master)
#   .mcp.json         (symlink to .orchestrator/.mcp.json)
```

## Workflow

### Create Worker Worktrees

From the project root (where flake.nix is):

```bash
# Create a new worktree for a feature branch
worktree-new feature-auth

# This creates:
#   ./feature-auth/
#   ./feature-auth/.envrc (use flake ../.shared --impure)
#   ./feature-auth/.mcp.json → ../.shared/.mcp.json
#   ./feature-auth/CLAUDE.md → ../.shared/CLAUDE.md
```

### Activate Worker Environment

```bash
cd feature-auth
direnv allow

# Worker shell activates with:
# - All MCPs except task-master
# - Shared codanna index
```

### Check Status

```bash
# From project root
worktree-status

# Shows:
# - Main git checkout location
# - Git worktrees
# - Shared resource status
# - Codanna index size
```

### Remove Worktree

```bash
worktree-remove feature-auth
```

## Agent Roles

### Orchestrator (project root)
- Has access to `claude-task-master` MCP
- Manages task coordination
- Creates/removes worktrees
- Full project oversight

### Workers (worktree directories)
- Work in isolated worktrees
- Share codanna index for code navigation
- No access to task-master (prevents conflicts)
- Report completion via git commits

## Configuration

Edit `flake.nix` to customize:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `mainDir` | `"main"` | Subdirectory containing the main git checkout |
| `languages` | `[]` | Programming languages to include |
| `mcps` | `[]` | MCP servers (workers get these minus task-master) |
| `tools` | `"standard"` | Tool preset ("minimal", "standard", "full") |
| `devshellsUrl` | GitHub | Pin to specific devshells version |

## Example Configuration

```nix
devShells.default = devshells.lib.${system}.composeShell {
  type = "worktree";
  mainDir = "repo";  # Git checkout is in ./repo/
  languages = ["rust" "python"];
  mcps = ["codanna" "serena" "claude-task-master"];
  tools = "standard";
};
```
