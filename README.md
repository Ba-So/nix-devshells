# nix-devshells

Collection of Nix development shells and project templates for various programming languages and tools.

## Available Development Shells

- **rust** - Rust development with cargo, clippy, and rust-analyzer
- **php** - PHP development environment
- **nix** - Nix development tools
- **cpp** - C++ development with CMake and tooling
- **python** - Python development environment
- **py-cpp** - Combined Python and C++ environment
- **latex** - LaTeX document preparation
- **ansible** - Ansible automation and configuration management

## Using Development Shells with direnv

The development shells can be automatically loaded when entering a project directory using direnv.

1. Install direnv for your system if not already installed
2. Create a `.envrc` file in your project root:

```bash
use flake github:Ba-So/nix-devshells#<shell-name>
```

Replace `<shell-name>` with one of the available shells (e.g., `rust`, `python`, `cpp`).

3. Allow direnv to load the configuration:

```bash
direnv allow
```

The development environment will now be automatically loaded when you enter the directory and unloaded when you leave.

## Using Templates

Templates provide a complete project structure with development environment configuration.

### Available Templates

- **rust** - Rust project template
- **php** - PHP project template
- **latex** - LaTeX document template

### Initializing a New Project

Create a new project from a template:

```bash
nix flake init -t github:Ba-So/nix-devshells#<template-name>
```

For example, to create a new Rust project:

```bash
mkdir my-rust-project
cd my-rust-project
nix flake init -t github:Ba-So/nix-devshells#rust
direnv allow
```

The template includes:

- Pre-configured `.envrc` for automatic environment loading
- `.mcp.json` for MCP server configuration
- `.pre-commit-config.yaml` for code quality checks
- Language-specific configuration files

### Using Templates Locally

If you have this repository cloned locally:

```bash
nix flake init -t /path/to/nix-devshells#<template-name>
```

## Development

The repository structure:

- `base/` - Base configurations for common tools (codanna, serena, shrimp)
- `languages/` - Language-specific shell definitions
- `templates/` - Project templates
- `pkgs/` - Custom package definitions
- `default.nix` - Shell composition
- `flake.nix` - Flake configuration
