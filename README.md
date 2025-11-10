# nix-devshells

Development shells and project templates for Nix flake-based workflows.

## 🆕 What's New: Modular Composition System

The new modular architecture lets you compose development environments from individual modules:

- **🎯 Selective tool inclusion**: Choose minimal, standard, or full preset
- **🤖 Optional MCP servers**: AI assistance only when you need it
- **🔧 Language combinations**: Mix and match languages (rust + python, etc.)
- **⚡ Faster builds**: Minimal preset for CI/CD and quick testing
- **📦 Better composability**: Build exactly what you need

**Migration note**: Old API (pre-built shells, packageSets) still works! No breaking changes.

📚 **[Full Composition Guide](./COMPOSITION_GUIDE.md)** | 🛠️ **[Module Creation Guide](./MODULE_GUIDE.md)**

## Quick Start with Composition API

### Simple Rust Environment

```nix
{
  inputs.devshells.url = "github:Ba-So/nix-devshells";

  outputs = {devshells, ...}: {
    devShells.x86_64-linux.default = devshells.lib.x86_64-linux.composeShell {
      languages = ["rust"];
      tools = "standard";  # or "minimal" / "full"
      mcps = ["cargo-mcp" "serena"];  # AI assistance
    };
  };
}
```

### Multi-Language Project

```nix
devShells.default = devshells.lib.${system}.composeShell {
  languages = ["rust" "python"];
  tools = "standard";
  mcps = ["cargo-mcp" "serena"];
};
```

### Minimal Shell (Fast, for CI)

```nix
devShells.ci = devshells.lib.${system}.composeShell {
  languages = ["rust"];
  tools = "minimal";  # Just essentials
  mcps = [];  # No MCP overhead
};
```

### Extended with Custom Packages

```nix
devShells.default = devshells.lib.${system}.composeShell {
  languages = ["rust"];
  tools = "standard";
  mcps = ["cargo-mcp"];
  extraPackages = with pkgs; [
    postgresql  # Add project-specific tools
    diesel-cli
  ];
  extraShellHook = ''
    export DATABASE_URL="postgres://localhost/myapp"
  '';
};
```

## Outputs

### DevShells

**Pre-Built Shells** (ready to use):

- `rust` - Rust 1.90.0, cargo tools, sccache, analysis tools
- `php` - PHP with Xdebug, composer, Symfony CLI, database clients
- `nix` - nixos-rebuild, formatters, linters, cachix (default)
- `cpp` - GCC 14, Clang 18, CMake, Ninja, static analysis, profiling tools
- `python` - Python 3.12, uv, ruff, mypy, pytest
- `py-cpp` - Combined Python and C++ toolchain
- `latex` - TeXLive full, tectonic, texlab LSP, PDF viewers
- `ansible` - Ansible, molecule, lint tools, vault

**New Composed Shells** (demonstrating modular API):

- `rust-minimal` - Rust with minimal tools (fast build)
- `rust-python` - Rust + Python for mixed projects
- `web-dev` - Rust + Python + PHP for full-stack development

Common tools in standard preset: git, pre-commit, direnv, helix, just, jq, ripgrep, fd, nixfmt, nil LSP.

### Library API

**Composition Functions**:

- `lib.${system}.composeShell { ... }` - High-level composition API
- `lib.${system}.composeShellFromModules [...]` - Direct module composition
- `lib.${system}.modules` - Access to all available modules

**Module Categories**:

- `modules.languages.*` - Programming language toolchains (rust, python, cpp, nix, php, latex, ansible)
- `modules.tools.*` - Development utilities (version-control, editors, nix-tools, utilities)
- `modules.mcp.*` - MCP servers for AI assistance
- `modules.presets.*` - Pre-configured bundles (minimal, standard, full)

### Package Sets

Reusable package lists for composing custom devshells (backward compatible):

- `packageSets.${system}.common` - Common tools (standard preset)
- `packageSets.${system}.rust` - Rust toolchain and cargo tools
- `packageSets.${system}.python` - Python development tools
- `packageSets.${system}.cpp` - C++ compilers and build tools
- `packageSets.${system}.nix` - Nix development tools
- `packageSets.${system}.php` - PHP development tools
- `packageSets.${system}.latex` - LaTeX tools
- `packageSets.${system}.ansible` - Ansible automation tools

### Packages

**MCP Servers**:

- `cargo-mcp` - Cargo documentation and project operations (default)
- `cratedocs-mcp` - Rust crate documentation search
- `codanna` - Code intelligence and semantic search
- `mcp-shrimp-task-manager` - AI task management
- `mcp-gitlab` - GitLab API integration
- `puppeteer-mcp-server` - Browser automation with Puppeteer
- `serena` - Project analysis MCP server

### Templates

- `rust` - Cargo project with flake.nix
- `php` - PHP project with composer
- `latex` - LaTeX document
- `cpp` - CMake project

Each includes `.envrc`, flake.nix with composition examples, `.pre-commit-config.yaml`.

Templates now demonstrate the new composition API with multiple configuration examples.

### Overlays

`overlays.default` exports all packages for use in other Nix configurations.

## Usage

### With direnv

```bash
echo "use flake github:Ba-So/nix-devshells#rust" > .envrc
direnv allow
```

Shell activates on directory entry, deactivates on exit.

### From template

```bash
nix flake init -t github:Ba-So/nix-devshells#rust
direnv allow
```

Templates now include examples of the composition API. Edit `flake.nix` to customize.

Local: `nix flake init -t /path/to/nix-devshells#rust`

### Direct activation

```bash
nix develop github:Ba-So/nix-devshells#python
```

### Install packages

```bash
nix profile install github:Ba-So/nix-devshells#cargo-mcp
```

### Use overlay

```nix
{
  inputs.nix-devshells.url = "github:Ba-So/nix-devshells";

  outputs = { nixpkgs, nix-devshells, ... }: {
    nixpkgs.overlays = [ nix-devshells.overlays.default ];
  };
}
```

### Compose custom devshells

**New API** (recommended):

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    devshells.url = "github:Ba-So/nix-devshells";
  };

  outputs = { nixpkgs, devshells, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = devshells.lib.${system}.composeShell {
        languages = ["rust"];
        tools = "standard";
        mcps = ["cargo-mcp" "serena"];
        extraPackages = [ pkgs.postgresql pkgs.redis ];
      };
    };
}
```

**Old API** (still supported):

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    devshells.url = "github:Ba-So/nix-devshells";
  };

  outputs = { nixpkgs, devshells, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        # Combine package sets as needed
        buildInputs = devshells.packageSets.${system}.rust
                   ++ [ pkgs.postgresql pkgs.redis ];
      };
    };
}
```

## Preset Comparison

Choose the right preset for your needs:

| Preset     | Build Speed | Features  | Use Case                      |
| ---------- | ----------- | --------- | ----------------------------- |
| `minimal`  | ⚡ Fastest  | Essential | CI/CD, quick edits            |
| `standard` | 🚀 Normal   | Balanced  | Day-to-day development        |
| `full`     | 🐌 Slower   | Complete  | Power users, complex projects |

See the [Composition Guide](./COMPOSITION_GUIDE.md) for detailed comparison.

## Documentation

- **[Composition Guide](./COMPOSITION_GUIDE.md)** - How to use the composition API
- **[Module Guide](./MODULE_GUIDE.md)** - How to create custom modules
- **[Modularity Proposal](./MODULARITY_PROPOSAL.md)** - Architecture details

## Structure

- `modules/` - Modular building blocks
  - `languages/` - Language toolchains (rust, python, cpp, etc.)
  - `tools/` - Development utilities (git, editors, etc.)
  - `mcp/` - MCP server configurations
  - `presets/` - Pre-configured module bundles
- `lib/` - Composition API and utilities
- `templates/` - Project scaffolding
- `pkgs/` - Custom package definitions
- `default.nix` - Shell composition (now uses module system)
- `flake.nix` - Flake outputs and overlay

## Contributing

We welcome contributions! See:

- [Module Creation Guide](./MODULE_GUIDE.md) for adding new modules
- [Composition Guide](./COMPOSITION_GUIDE.md) for usage examples
- Open an issue for questions or suggestions

## Examples

### Rust Web Service

```nix
devShells.default = devshells.lib.${system}.composeShell {
  languages = ["rust"];
  tools = "standard";
  mcps = ["cargo-mcp" "serena"];
  extraPackages = with pkgs; [
    postgresql
    redis
    diesel-cli
  ];
};
```

### Python Data Science

```nix
devShells.default = devshells.lib.${system}.composeShell {
  languages = ["python"];
  tools = "standard";
  mcps = ["serena"];
  extraPackages = with pkgs; [
    python312Packages.jupyter
    python312Packages.numpy
    python312Packages.pandas
  ];
};
```

### Multi-Language (Rust + Python)

```nix
devShells.default = devshells.lib.${system}.composeShell {
  languages = ["rust" "python"];
  tools = "standard";
  mcps = ["cargo-mcp" "serena"];
};
```

### CI/CD (Minimal)

```nix
devShells.ci = devshells.lib.${system}.composeShell {
  languages = ["rust"];
  tools = "minimal";  # Fast build
  mcps = [];          # No AI overhead
};
```

## License

MIT
