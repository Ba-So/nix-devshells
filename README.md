# nix-devshells

Composable Nix development shells with MCP server and agent integration for AI-assisted workflows.

The flake exposes a module system (`languages`, `mcps`, `tools`, `agents`, `presets`) and a `composeShell` function that combines selected modules into a `pkgs.mkShell` derivation. On shell entry, the active harness adapter (Claude Code by default; Opencode also supported) renders MCP config and agent files into the project directory.

## Quick Start

Use a pre-built shell directly:

```bash
nix develop github:Ba-So/nix-devshells           # default (nix)
nix develop github:Ba-So/nix-devshells#rust
nix develop github:Ba-So/nix-devshells#python
nix develop github:Ba-So/nix-devshells#rust-python
nix develop github:Ba-So/nix-devshells#web-dev
```

Or compose your own from another flake:

```nix
{
  inputs.devshells.url = "github:Ba-So/nix-devshells";

  outputs = { devshells, ... }: {
    devShells.x86_64-linux.default = devshells.lib.x86_64-linux.composeShell {
      languages = [ "rust" ];
      mcps      = [ "cargo-mcp" "serena" ];
      tools     = "standard";
    };
  };
}
```

direnv:

```bash
echo "use flake github:Ba-So/nix-devshells#rust" > .envrc
direnv allow
```

## Public API

`devshells.lib.${system}` exposes:

| Attribute                 | Purpose                                                            |
| ------------------------- | ------------------------------------------------------------------ |
| `composeShell`            | Build a shell from named languages/mcps/tools (high-level).        |
| `composeShellFromModules` | Build a shell from a list of resolved module attrsets (low-level). |
| `modules`                 | The module tree: `languages`, `mcp`, `tools`, `agents`, `presets`. |
| `harnesses`               | The harness adapters (`claude`, `opencode`).                       |

### composeShell

```nix
composeShell {
  languages      = [ "rust" "python" ];   # see Languages
  mcps           = [ "cargo-mcp" ];       # see MCP Servers
  tools          = "standard";            # "minimal" | "standard" | { preset, include }
  type           = "standard";            # "standard" | "worktree" | "subtree"
  harness        = "claude";              # "claude" | "opencode"
  extraPackages  = [];
  extraShellHook = "";
  devshellsUrl   = "github:Ba-So/nix-devshells";  # used by worktree mode
  enableRtk      = false;                 # eval "$(rtk init)" if rtk is on PATH
}
```

Behavior on shell entry:

- Resolves the named modules, validates them, and deduplicates by `meta.name`.
- For `type = "subtree"`, drops `claude-task-master` from `mcps` automatically.
- Generates the harness MCP config (`.mcp.json` for Claude, `opencode.json` for Opencode) and merges with any existing file via `jq`.
- Renders all agent modules whose `mcpDeps` are satisfied by the active MCPs into the harness agent directory (`.claude/agents/` or `.opencode/agents/`), tracking managed files in `.devshell-managed` so removed agents are cleaned up.
- For `type = "worktree"`, also creates `.shared/`, `.orchestrator/`, an orchestrator `CLAUDE.md`, the `.shared/CLAUDE.md` worker doc, the `.shared/flake.nix` subtree shell, `.claude/commands/{orchestrate,prd}.md` skills, and adds the `worktree-new`, `worktree-status`, `worktree-remove` scripts to the shell.
- For `type = "subtree"`, scans sibling directories for a `.shared/.codanna` index and exports `CODANNA_INDEX_DIR`.

`composeShellFromModules { allModules; agents?; enableRtk?; harness?; }` skips name resolution and operates on already-resolved module attrsets.

### Module shape

A minimal module:

```nix
{
  meta = {
    name        = "mymod";
    description = "...";
    category    = "language";   # "language" | "mcp" | "tool" | "preset"
  };
  packages  = [ pkgs.foo ];
  shellHook = "echo mymod ready";
  env       = { FOO_HOME = "/path"; };
}
```

`validateModule` checks for `meta.name` and a list `packages`; everything else is optional. MCP modules add `mcpConfig`; agent modules use a separate factory and aren't subject to `validateCategory`.

For MCP modules, prefer the factory:

```nix
mkMcpModule {
  name        = "my-mcp";
  description = "...";
  package     = devPkgs.my-mcp;
  command     = "my-mcp-server";   # default: name
  args        = [];
  env         = {};
  emoji       = "🔧";
  configName  = "my-mcp";          # default: name; key in mcpConfig
  languages   = null;              # optional: meta.languages
  shellHook   = "";                # appended after the emoji line
}
```

For agents:

```nix
mkAgentModule {
  name        = "rust-developer";
  description = "Rust specialist";
  model       = "sonnet";          # bare alias or "provider/id"
  tools       = [ "Read" "Edit" "Bash" "Grep" "Glob" "Write" ];
  mcpDeps     = [ "cargo-mcp" ];   # agent appears only when all deps are active
  body        = "...";
}
```

The `tools` list uses Claude-style names. The Opencode adapter translates `Write/Edit/Read/Bash/Grep/Glob/WebFetch` to its permission map and drops anything else.

## Languages

| Name      | Toolchain                                                                                                                                                                                                            |
| --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `rust`    | rustc 1.92.0, cargo, sccache (RUSTC_WRAPPER), rust-analyzer, clippy, rustfmt, cargo-{watch,edit,outdated,audit,nextest,criterion,cross,flamegraph,machete,bloat,llvm-lines,modules,depgraph,tarpaulin}, lld, openssl |
| `python`  | Python 3.12, uv, ruff, mypy, pytest                                                                                                                                                                                  |
| `cpp`     | GCC 14, Clang 18, CMake, Ninja, conan                                                                                                                                                                                |
| `nix`     | nixos-rebuild, alejandra, nil, statix                                                                                                                                                                                |
| `php`     | PHP with Xdebug, composer, Symfony CLI                                                                                                                                                                               |
| `latex`   | TeX Live full, tectonic, texlab                                                                                                                                                                                      |
| `ansible` | ansible, molecule, ansible-lint                                                                                                                                                                                      |
| `julia`   | Julia, LanguageServer                                                                                                                                                                                                |
| `js`      | Node.js, npm, typescript                                                                                                                                                                                             |

## MCP Servers

| Name                   | Purpose                                              |
| ---------------------- | ---------------------------------------------------- |
| `codanna`              | Symbol-level code intelligence (semantic search)     |
| `serena`               | Project-wide code analysis                           |
| `claude-task-master`   | AI task management; auto-removed in `subtree` shells |
| `cargo-mcp`            | Rust/Cargo build, test, check                        |
| `cratedocs`            | Rust crate documentation lookup                      |
| `github`               | GitHub API (needs `GITHUB_PERSONAL_ACCESS_TOKEN`)    |
| `gitlab`               | GitLab issues, MRs, pipelines                        |
| `onedev`               | OneDev integration (via `tod mcp`)                   |
| `puppeteer`            | Browser automation                                   |
| `universal-screenshot` | Cross-platform screenshot capture                    |
| `computer-use`         | System interaction via screenshots                   |
| `qdrant`               | Semantic doc search (requires Qdrant)                |
| `paper-search`         | arXiv, PubMed, bioRxiv search                        |
| `mempalace`            | Local-first AI memory                                |
| `mcp-grafana`          | Grafana / Prometheus / Loki / Pyroscope              |
| `mcp-libre`            | LibreOffice document operations                      |
| `shrimp`               | Legacy task management                               |

## Agents

Agent markdown files are deployed when their `mcpDeps` are all present in the active shell. Available:

| Name                  | mcpDeps   |
| --------------------- | --------- |
| `code-reviewer`       | `codanna` |
| `coder`               | (none)    |
| `codebase-researcher` | `codanna` |
| `complexity-analyzer` | `codanna` |
| `software-designer`   | (none)    |
| `test-specialist`     | (none)    |
| `design-assistant`    | (none)    |
| `sql-assistant`       | (none)    |

(Confirm `mcpDeps` per agent in `modules/agents/<name>.nix`.)

## Tool Presets

| Preset     | Contents                                                                                                                                                                                               |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `minimal`  | git, git-lfs, jq, curl, wget, tree, fd, ripgrep, gnumake, tokei, pre-commit, nodejs, prettier, markdownlint-cli, direnv, just, rtk, plus nix-tools (nixfmt-rfc-style, nil, alejandra, deadnix, statix) |
| `standard` | `minimal` + `codanna`, `serena`, `shrimp` MCPs                                                                                                                                                         |

Custom selection:

```nix
tools = { preset = "minimal"; include = [ "editors" ]; };  # adds helix
```

Available tool modules: `version-control`, `nix-tools`, `editors`, `utilities`.

## Pre-built devShells

| Name           | Composition                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `default`      | `nix` language + standard tools                                           |
| `rust`         | `rust` + standard                                                         |
| `python`       | `python` + standard                                                       |
| `cpp`          | `cpp` + standard                                                          |
| `php`          | `php` + standard                                                          |
| `nix`          | `nix` + standard                                                          |
| `latex`        | `latex` + standard                                                        |
| `ansible`      | `ansible` + standard                                                      |
| `julia`        | `julia` + standard                                                        |
| `py-cpp`       | `python` + `cpp` + standard                                               |
| `rust-minimal` | `rust` + minimal + `cargo-mcp`                                            |
| `rust-python`  | `rust` + `python` + standard + `cargo-mcp`, `serena`                      |
| `web-dev`      | `rust` + `python` + `php` + standard + `cargo-mcp`, `serena`, `puppeteer` |

## Harness Adapters

| Adapter    | MCP file        | MCP shape                                                                             | Agent dir           |
| ---------- | --------------- | ------------------------------------------------------------------------------------- | ------------------- |
| `claude`   | `.mcp.json`     | `{ mcpServers: { <name>: { type, command, args, env } } }`                            | `.claude/agents/`   |
| `opencode` | `opencode.json` | `{ mcp: { <name>: { type="local", command=[cmd, ...args], environment, enabled } } }` | `.opencode/agents/` |

Both adapters merge into existing config files via `jq -s '.[0] * .[1]'`.

## Worktree Workflow

Multi-agent setup with one orchestrator and N workers in sibling git worktrees, sharing a code-intelligence index. The orchestrator runs in the actual repo so it has full code access.

```text
myproject/                           # orchestrator (type = "worktree")
├── flake.nix
├── .mcp.json -> .orchestrator/.mcp.json
├── .orchestrator/.mcp.json          # full MCP set incl. task-master
├── .shared/
│   ├── flake.nix                    # generated subtree shell (type = "subtree")
│   ├── .mcp.json                    # MCP set without task-master
│   ├── .codanna/                    # shared code index
│   └── CLAUDE.md                    # worker instructions
├── .claude/commands/{orchestrate,prd}.md
├── CLAUDE.md                        # orchestrator instructions
└── ...

../myproject-feature-x/              # worker (sibling worktree)
├── .envrc                           # use flake ../myproject/.shared --impure
├── .mcp.json -> ../myproject/.shared/.mcp.json
├── CLAUDE.md  -> ../myproject/.shared/CLAUDE.md
└── ...
```

| `type`     | Role               | MCP scope                   |
| ---------- | ------------------ | --------------------------- |
| `standard` | Normal development | All configured MCPs         |
| `worktree` | Orchestrator       | All MCPs                    |
| `subtree`  | Worker             | All MCPs except task-master |

Setup:

```bash
nix flake init -t github:Ba-So/nix-devshells#worktree
git init                       # if not already a repo
direnv allow                   # generates .shared/, .orchestrator/, etc.
```

Commands available in the orchestrator shell:

| Command                    | Action                                                                                                                                                |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `worktree-new <branch>`    | Create sibling worktree at `../<project>-<branch>/`, link `.mcp.json` and `CLAUDE.md` to `.shared/`, write `.envrc`, run `direnv allow` if available. |
| `worktree-status`          | List worktrees, shared resources, codanna index size, env.                                                                                            |
| `worktree-remove <branch>` | `git worktree remove --force` and optionally delete branch.                                                                                           |

The worker shell (`type = "subtree"`) finds the shared index by scanning sibling directories for `.shared/.codanna` and exports `CODANNA_INDEX_DIR`.

## Templates

| Template   | Init                                                    | Default shell                                                       |
| ---------- | ------------------------------------------------------- | ------------------------------------------------------------------- |
| `rust`     | `nix flake init -t github:Ba-So/nix-devshells#rust`     | `rust` + standard + `cargo-mcp`, `serena`                           |
| `cpp`      | `nix flake init -t github:Ba-So/nix-devshells#cpp`      | `cpp` + standard + `serena`                                         |
| `php`      | `nix flake init -t github:Ba-So/nix-devshells#php`      | `php` + standard + `serena`, `puppeteer`                            |
| `latex`    | `nix flake init -t github:Ba-So/nix-devshells#latex`    | `latex` + standard + `serena`                                       |
| `worktree` | `nix flake init -t github:Ba-So/nix-devshells#worktree` | `type = "worktree"`, `rust` + standard + codanna/serena/task-master |

## Packages and Overlay

`packages.<system>` and `overlays.default` expose: `cargo-mcp`, `cratedocs-mcp`, `codanna`, `claude-task-master`, `mcp-gitlab`, `puppeteer-mcp-server`, `universal-screenshot-mcp`, `computer-use-mcp`, `qdrant-mcp`, `paper-search-mcp`, `mempalace`, `mcp-libre`, `mcp-grafana`, `tod`, `serena`, `mcp-shrimp-task-manager`. `packages.<system>.default` is `cargo-mcp`.

```nix
nixpkgs.overlays = [ inputs.devshells.overlays.default ];
# environment.systemPackages = [ pkgs.codanna pkgs.cargo-mcp ];
```

## License

MIT
