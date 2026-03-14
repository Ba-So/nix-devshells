# nix-devshells

Composable Nix development shells with MCP server integration for AI-assisted development.

- **Modular composition**: Mix languages, tools, and MCP servers as building blocks
- **Pre-configured AI tooling**: MCP servers for code intelligence, task management, and more
- **Multi-agent workflows**: Parallel development with orchestrator/worker architecture
- **Zero-config defaults**: Sensible presets that just work

## Quick Start

### With flake input

```nix
{
  inputs.devshells.url = "github:Ba-So/nix-devshells";

  outputs = {devshells, ...}: {
    devShells.x86_64-linux.default = devshells.lib.x86_64-linux.composeShell {
      languages = ["rust"];
      mcps = ["cargo-mcp" "serena"];
      tools = "standard";
    };
  };
}
```

### With direnv

```bash
echo "use flake github:Ba-So/nix-devshells#rust" > .envrc
direnv allow
```

### Direct activation

```bash
nix develop github:Ba-So/nix-devshells#python
```

## Available Modules

### Languages

| Module    | Description             | Key Packages                                        |
| --------- | ----------------------- | --------------------------------------------------- |
| `rust`    | Rust 1.90.0 development | rustc, cargo, sccache, rust-analyzer, cargo-nextest |
| `python`  | Python 3.12 with UV     | Python, uv, ruff, mypy, pytest                      |
| `cpp`     | C++ development         | GCC 14, Clang 18, CMake, Ninja, conan               |
| `nix`     | Nix development         | nixos-rebuild, alejandra, nil, statix               |
| `php`     | PHP development         | PHP with Xdebug, composer, Symfony CLI              |
| `latex`   | LaTeX documents         | TeXLive full, tectonic, texlab LSP                  |
| `ansible` | Ansible automation      | ansible, molecule, ansible-lint                     |
| `julia`   | Julia development       | Julia, LanguageServer                               |
| `js`      | JavaScript/Node.js      | Node.js, npm, typescript                            |

### MCP Servers

MCP (Model Context Protocol) servers extend AI assistants with specialized capabilities.

| Module                 | Description                                            |
| ---------------------- | ------------------------------------------------------ |
| `codanna`              | Code intelligence with symbol-level semantic search    |
| `serena`               | Project-wide code analysis and navigation              |
| `claude-task-master`   | AI-powered task management for coordinated development |
| `cargo-mcp`            | Rust/Cargo operations (build, test, check)             |
| `cratedocs`            | Rust crate documentation lookup                        |
| `gitlab`               | GitLab integration (issues, MRs, pipelines)            |
| `puppeteer`            | Browser automation for web testing                     |
| `computer-use`         | System interaction via screenshots                     |
| `universal-screenshot` | Cross-platform screenshot capture                      |
| `qdrant-mcp`           | Semantic documentation search (requires Qdrant)        |
| `paper-search`         | Academic paper search (arXiv, PubMed, bioRxiv)         |
| `shrimp`               | Alternative task management system                     |

### Tool Presets

| Preset     | Includes                                       |
| ---------- | ---------------------------------------------- |
| `minimal`  | git, git-lfs, jq, curl, fd, ripgrep, Nix tools |
| `standard` | minimal + codanna, serena, shrimp MCPs         |

Custom tool selection:

```nix
composeShell {
  tools = {
    preset = "minimal";
    include = ["helix"];  # Add specific tools
  };
}
```

## Shell Composition API

### `composeShell` (High-level API)

```nix
devshells.lib.${system}.composeShell {
  languages = ["rust" "python"];  # Language modules to include
  mcps = ["cargo-mcp" "serena"];  # MCP servers to configure
  tools = "standard";              # "minimal" | "standard" or custom config
  type = "standard";               # "standard" | "worktree" | "subtree"
  extraPackages = [];              # Additional Nix packages
  extraShellHook = "";             # Additional shell initialization
}
```

### `composeShellFromModules` (Low-level API)

Direct module composition for advanced use cases:

```nix
devshells.lib.${system}.composeShellFromModules [
  devshells.lib.${system}.modules.languages.rust
  devshells.lib.${system}.modules.mcp.serena
  devshells.lib.${system}.modules.presets.minimal
]
```

## Git Worktree Workflow

This flake adds some quality of life commands for git-worktree management.

The worktree workflow enables parallel AI agent development with shared resources. An orchestrator agent coordinates work across multiple worker agents, each in their own git worktree.

### Architecture

```text
project/
├── flake.nix          # Orchestrator shell (type = "worktree")
├── main/              # Main git checkout (source code)
├── .shared/           # Shared config for workers
│   ├── flake.nix      # Subtree shell (auto-generated)
│   ├── .mcp.json      # MCP config without task-master
│   ├── CLAUDE.md      # Worker instructions
│   └── .codanna/      # Shared code intelligence index
├── .orchestrator/
│   └── .mcp.json      # Full MCP config with task-master
├── feature-x/         # Worker worktree (git worktree)
└── bugfix-y/          # Another worker worktree
```

### Shell Types

| Type       | Purpose            | MCP Access                     |
| ---------- | ------------------ | ------------------------------ |
| `standard` | Normal development | All configured MCPs            |
| `worktree` | Orchestrator agent | All MCPs including task-master |
| `subtree`  | Worker agents      | All MCPs except task-master    |

### Setup

1. Initialize with the worktree template:

```bash
nix flake init -t github:Ba-So/nix-devshells#worktree
```

2. Clone your project into the `main/` directory:

```bash
git clone <your-repo> main
```

3. Activate the orchestrator shell:

```bash
direnv allow
```

### Worktree Commands

| Command                    | Description                             |
| -------------------------- | --------------------------------------- |
| `worktree-new <branch>`    | Create a new worktree for a feature/fix |
| `worktree-status`          | Show all worktrees and shared resources |
| `worktree-remove <branch>` | Remove a completed worktree             |

### Workflow

1. **Orchestrator** creates tasks via task-master MCP
2. **Orchestrator** creates worktrees: `worktree-new feature-x`
3. **Workers** operate in worktrees using shared code intelligence
4. **Workers** commit changes when complete
5. **Orchestrator** reviews, merges, and removes worktrees

## MCP Configuration

### Automatic Generation

MCP servers are automatically configured in `.mcp.json` based on selected modules. The shell hook:

1. Generates MCP config from module definitions
2. Merges with existing `.mcp.json` if present
3. Configures environment variables (API keys from `.env`)

### Manual Configuration

For custom MCP setup, modules expose their config:

```nix
# Access module MCP configuration
devshells.lib.${system}.modules.mcp.codanna.mcpConfig
# => { codanna = { type = "stdio"; command = "codanna"; args = [...]; }; }
```

## Templates

| Template   | Description                         | Init Command                                            |
| ---------- | ----------------------------------- | ------------------------------------------------------- |
| `rust`     | Rust project with cargo, pre-commit | `nix flake init -t github:Ba-So/nix-devshells#rust`     |
| `cpp`      | C++ project with CMake, testing     | `nix flake init -t github:Ba-So/nix-devshells#cpp`      |
| `php`      | PHP project with composer           | `nix flake init -t github:Ba-So/nix-devshells#php`      |
| `latex`    | LaTeX document with build config    | `nix flake init -t github:Ba-So/nix-devshells#latex`    |
| `worktree` | Multi-agent project structure       | `nix flake init -t github:Ba-So/nix-devshells#worktree` |

## Pre-built DevShells

Ready-to-use shells without composition:

```bash
nix develop github:Ba-So/nix-devshells#rust
nix develop github:Ba-So/nix-devshells#python
nix develop github:Ba-So/nix-devshells#cpp
nix develop github:Ba-So/nix-devshells#php
nix develop github:Ba-So/nix-devshells#nix      # default
nix develop github:Ba-So/nix-devshells#latex
nix develop github:Ba-So/nix-devshells#ansible
nix develop github:Ba-So/nix-devshells#julia
```

Composed examples:

```bash
nix develop github:Ba-So/nix-devshells#rust-minimal   # Rust + minimal tools
nix develop github:Ba-So/nix-devshells#rust-python    # Rust + Python
nix develop github:Ba-So/nix-devshells#web-dev        # Rust + Python + PHP
```

## AI-Assisted Development

### Recommended MCP Combinations

| Workflow             | MCPs                                      | Purpose                              |
| -------------------- | ----------------------------------------- | ------------------------------------ |
| General development  | `codanna`, `serena`                       | Code intelligence + project analysis |
| Rust development     | `cargo-mcp`, `cratedocs`, `codanna`       | Cargo ops + docs + search            |
| Multi-agent projects | `codanna`, `serena`, `claude-task-master` | Coordination + shared intelligence   |
| Research projects    | `paper-search`, `qdrant-mcp`              | Academic search + semantic docs      |

### Claude Code Integration

1. Compose a shell with desired MCPs
2. Enter the shell: `nix develop` or `direnv allow`
3. Start Claude Code in the project directory
4. MCP servers are auto-configured in `.mcp.json`

### Task Master Workflow

With `claude-task-master` MCP:

```bash
task-master init                    # Initialize task management
task-master parse-prd docs/prd.md   # Generate tasks from PRD
task-master next                    # Get next task
task-master set-status --id=1 --status=done
```

## Creating Custom Modules

Modules follow a standard structure:

```nix
# modules/languages/mylang.nix
{pkgs, lib, ...}: {
  meta = {
    name = "mylang";
    description = "MyLang development environment";
    category = "language";  # "language" | "mcp" | "tool" | "preset"
  };

  packages = [
    pkgs.mylang
    pkgs.mylang-lsp
  ];

  shellHook = ''
    echo "MyLang ready: $(mylang --version)"
  '';

  # For MCP modules
  mcpConfig = {
    mylang-mcp = {
      type = "stdio";
      command = "mylang-mcp-server";
      args = [];
    };
  };

  env = {
    MYLANG_HOME = "/some/path";
  };

  suggestedMcps = ["serena"];  # Optional: suggest compatible MCPs
}
```

## License

MIT
