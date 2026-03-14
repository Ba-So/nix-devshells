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
└── worktrees/                      # All worker worktrees
    └── feature-x/                  # Worktree directory
        ├── .envrc                  # use flake ../../.shared --impure
        ├── .mcp.json → ../../.shared/.mcp.json
        ├── CLAUDE.md → ../../.shared/CLAUDE.md
        └── ...                     # Working copy
```

## Source Filtering

When the project container is not a git repository, Nix would normally copy the entire directory to the store during flake evaluation. This includes potentially large build artifacts in `main/target/` or similar.

The template uses `mkWorktreeSource` to filter out:

- `main/` (or your configured `mainDir`) - the main git checkout
- `worktrees/` - all worker worktrees
- `.shared/` and `.orchestrator/` - generated directories
- `.direnv/` - direnv cache

This ensures fast flake evaluation even with large build artifacts present.

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
#   ./worktrees/feature-auth/
#   ./worktrees/feature-auth/.envrc (use flake ../../.shared --impure)
#   ./worktrees/feature-auth/.mcp.json → ../../.shared/.mcp.json
#   ./worktrees/feature-auth/CLAUDE.md → ../../.shared/CLAUDE.md
```

### Activate Worker Environment

```bash
cd worktrees/feature-auth
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

| Parameter       | Default      | Description                                       |
| --------------- | ------------ | ------------------------------------------------- |
| `mainDir`       | `"main"`     | Subdirectory containing the main git checkout     |
| `languages`     | `[]`         | Programming languages to include                  |
| `mcps`          | `[]`         | MCP servers (workers get these minus task-master) |
| `tools`         | `"standard"` | Tool preset ("minimal", "standard", "full")       |
| `devshellsUrl`  | GitHub       | Pin to specific devshells version                 |
| `extraExcludes` | `[]`         | Additional directories to filter from source      |

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

## Custom Source Filtering

If you have additional large directories to exclude:

```nix
filteredSource = system:
  devshells.lib.${system}.mkWorktreeSource {
    src = ./.;
    inherit mainDir;
    extraExcludes = [ "data" "models" "node_modules" ];
  };
```
