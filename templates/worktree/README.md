# Multi-Agent Worktree Project

This template sets up a multi-agent development workflow using git worktrees with the **sibling pattern**.

## Directory Structure

The main repository is the orchestrator, and worktrees are created as sibling directories:

```
myproject/                          # Main repo + orchestrator (git repo)
├── .envrc                          # use flake . --impure
├── flake.nix                       # type = "worktree"
├── flake.lock
├── .mcp.json → .orchestrator/.mcp.json
├── .orchestrator/
│   └── .mcp.json                   # Full MCP (WITH task-master)
├── .shared/
│   ├── flake.nix                   # GENERATED - subtree shell for workers
│   ├── .mcp.json                   # Worker MCP (NO task-master)
│   ├── .codanna/                   # Shared code index
│   └── CLAUDE.md                   # Shared worker instructions
├── CLAUDE.md                       # Orchestrator instructions
└── <source code>                   # Your actual code

../myproject-feature-x/             # Sibling worktree (worker)
├── .envrc                          # use flake ../myproject/.shared --impure
├── .mcp.json → ../myproject/.shared/.mcp.json
├── CLAUDE.md → ../myproject/.shared/CLAUDE.md
└── <working copy>                  # Working copy of the code

../myproject-feature-y/             # Another sibling worktree
└── ...
```

## Why Sibling Worktrees?

The sibling pattern has several advantages over nested worktrees:

1. **Orchestrator has code access** - The orchestrator runs in the actual repo, with full access to code intelligence tools like codanna
2. **Natural git workflow** - Git worktrees are designed to be peers, not nested children
3. **Simpler paths** - No need for a separate `mainDir` configuration
4. **Standard tooling** - Works naturally with all git commands

## Initial Setup

```bash
# 1. Clone or create your project
git clone <your-repo-url> myproject
cd myproject

# 2. Create flake.nix (copy from template or use nix flake init)
nix flake init -t github:Ba-So/nix-devshells#worktree

# 3. Create .envrc
echo "use flake . --impure" > .envrc

# 4. Activate orchestrator shell
direnv allow

# This creates:
#   .shared/          (with flake.nix, .mcp.json, CLAUDE.md, .codanna/)
#   .orchestrator/    (with .mcp.json including task-master)
#   .mcp.json         (symlink to .orchestrator/.mcp.json)
#   CLAUDE.md         (orchestrator instructions)
```

## Workflow

### Create Worker Worktrees

From the project root (where flake.nix is):

```bash
# Create a new worktree for a feature branch
worktree-new feature-auth

# This creates:
#   ../myproject-feature-auth/
#   ../myproject-feature-auth/.envrc (use flake ../myproject/.shared --impure)
#   ../myproject-feature-auth/.mcp.json → ../myproject/.shared/.mcp.json
#   ../myproject-feature-auth/CLAUDE.md → ../myproject/.shared/CLAUDE.md
```

### Activate Worker Environment

```bash
cd ../myproject-feature-auth
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
# - Project name and location
# - Git worktrees (including siblings)
# - Shared resource status
# - Codanna index size
```

### Remove Worktree

```bash
worktree-remove feature-auth
# Optionally also deletes the branch
```

## Agent Roles

### Orchestrator (main project)

- Has access to `claude-task-master` MCP
- Manages task coordination
- Creates/removes worktrees
- Full project oversight
- **Runs in the actual codebase** with full code intelligence

### Workers (sibling worktrees)

- Work in isolated worktrees
- Share codanna index for code navigation
- No access to task-master (prevents conflicts)
- Report completion via git commits

## Configuration

Edit `flake.nix` to customize:

| Parameter      | Default      | Description                                       |
| -------------- | ------------ | ------------------------------------------------- |
| `languages`    | `[]`         | Programming languages to include                  |
| `mcps`         | `[]`         | MCP servers (workers get these minus task-master) |
| `tools`        | `"standard"` | Tool preset ("minimal", "standard", "full")       |
| `devshellsUrl` | GitHub       | Pin to specific devshells version                 |

## Example Configuration

```nix
devShells.default = devshells.lib.${system}.composeShell {
  type = "worktree";
  languages = ["rust" "python"];
  mcps = ["codanna" "serena" "claude-task-master"];
  tools = "standard";
};
```

## Git Workflow

With sibling worktrees, standard git commands work naturally:

```bash
# In main project
git log                           # See commit history
git merge feature-auth            # Merge completed work

# Check all worktrees
git worktree list

# In worker worktree
git add . && git commit -m "..."  # Commit work
git push origin feature-auth      # Push branch
```

## Source Filtering

If you need to create derivations from your source without copying large directories:

```nix
packages.default = pkgs.stdenv.mkDerivation {
  src = devshells.lib.${system}.mkWorktreeSource {
    src = ./.;
    extraExcludes = [ "data" "models" ];
  };
  # ...
};
```

This automatically excludes:

- `.shared/` and `.orchestrator/` (generated)
- `.direnv/` (cache)
- `target/`, `node_modules/`, `__pycache__/` (build artifacts)
