# nix-devshells

Development shells and project templates for Nix flake-based workflows.

## Outputs

### Packages
- `cargo-mcp` - MCP server for cargo documentation (default package)
- `cratedocs-mcp` - MCP server for Rust crate documentation
- `codanna` - Code intelligence and semantic search for LLMs
- `mcp-shrimp-task-manager` - AI-powered task management for development workflows
- `mcp-gitlab` - MCP server for GitLab API integration

### DevShells
- `rust` - Rust toolchain with cargo, clippy, rust-analyzer
- `php` - PHP with composer and development tools
- `nix` - Nix development tools (default shell)
- `cpp` - C++ toolchain with CMake and build tools
- `python` - Python with uv package manager
- `py-cpp` - Combined Python and C++ environment
- `latex` - LaTeX distribution with document preparation tools
- `ansible` - Ansible with configuration management tools

Each devshell includes common development tools (git, pre-commit, direnv integration).

### Templates
- `rust` - Rust project with package definition and build configuration
- `php` - PHP project with package definition
- `latex` - LaTeX document with build setup
- `cpp` - C++ project with CMake configuration

Templates include `.envrc`, `.mcp.json`, `.pre-commit-config.yaml`, and `flake.nix`.

### Overlays
- `overlays.default` - Provides `cargo-mcp`, `cratedocs-mcp`, `codanna`, `mcp-shrimp-task-manager`, and `mcp-gitlab` packages

## Usage

### With direnv

Create `.envrc` in your project:

```bash
use flake github:Ba-So/nix-devshells#rust
```

Allow direnv to load:

```bash
direnv allow
```

The shell activates on directory entry and deactivates on exit.

### Initialize from template

```bash
mkdir project-name
cd project-name
nix flake init -t github:Ba-So/nix-devshells#rust
direnv allow
```

Local repository:

```bash
nix flake init -t /path/to/nix-devshells#rust
```

### Direct shell activation

```bash
nix develop github:Ba-So/nix-devshells#python
```

## Structure

- `languages/` - Language-specific package sets
- `templates/` - Project templates
- `pkgs/` - Custom package definitions and common tool configurations
- `default.nix` - Shell composition
- `flake.nix` - Flake outputs
