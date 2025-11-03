# nix-devshells

Development shells and project templates for Nix flake-based workflows.

## Outputs

### Packages

**MCP Servers**

- `cargo-mcp` - Cargo documentation and project operations (default)
- `cratedocs-mcp` - Rust crate documentation search
- `codanna` - Code intelligence and semantic search
- `mcp-shrimp-task-manager` - AI task management
- `mcp-gitlab` - GitLab API integration
- `puppeteer-mcp-server` - Browser automation with Puppeteer
- `serena` - Project analysis MCP server

### DevShells

- `rust` - Rust 1.90.0, cargo tools, sccache, analysis tools
- `php` - PHP with Xdebug, composer, Symfony CLI, database clients
- `nix` - nixos-rebuild, formatters, linters, cachix (default)
- `cpp` - GCC 14, Clang 18, CMake, Ninja, static analysis, profiling tools
- `python` - Python 3.12, uv, ruff, mypy, pytest
- `py-cpp` - Combined Python and C++ toolchain
- `latex` - TeXLive full, tectonic, texlab LSP, PDF viewers
- `ansible` - Ansible, molecule, lint tools, vault

Common tools: git, pre-commit, direnv, helix, just, jq, ripgrep, fd, nixfmt, nil LSP.

### Package Sets

Reusable package lists for composing custom devshells:

- `packageSets.${system}.common` - Common tools (git, direnv, helix, etc.)
- `packageSets.${system}.rust` - Rust toolchain and cargo tools
- `packageSets.${system}.python` - Python development tools
- `packageSets.${system}.cpp` - C++ compilers and build tools
- `packageSets.${system}.nix` - Nix development tools
- `packageSets.${system}.php` - PHP development tools
- `packageSets.${system}.latex` - LaTeX tools
- `packageSets.${system}.ansible` - Ansible automation tools

### Templates

- `rust` - Cargo project with flake.nix
- `php` - PHP project with composer
- `latex` - LaTeX document
- `cpp` - CMake project

Each includes `.envrc`, `.mcp.json`, `.pre-commit-config.yaml`, flake.nix.

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

## Structure

- `languages/` - Language-specific package sets and shell hooks
- `templates/` - Project scaffolding
- `pkgs/` - Package definitions and common tools list
- `default.nix` - Shell composition logic
- `flake.nix` - Flake outputs and overlay
