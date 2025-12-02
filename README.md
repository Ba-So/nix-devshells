# nix-devshells

Development shells and project templates for Nix flake-based workflows.

## Quick Start

```nix
{
  inputs.devshells.url = "github:Ba-So/nix-devshells";

  outputs = {devshells, ...}: {
    devShells.x86_64-linux.default = devshells.lib.x86_64-linux.composeShell {
      languages = ["rust"];
      tools = "standard";  # or "minimal" / "full"
      mcps = ["cargo-mcp" "serena"];
    };
  };
}
```

## Outputs

### DevShells

**Pre-Built:**

- `rust` - Rust 1.90.0, cargo tools, sccache
- `php` - PHP with Xdebug, composer, Symfony CLI
- `nix` - nixos-rebuild, formatters, linters (default)
- `cpp` - GCC 14, Clang 18, CMake, Ninja
- `python` - Python 3.12, uv, ruff, mypy
- `py-cpp` - Combined Python and C++
- `latex` - TeXLive full, tectonic, texlab LSP
- `ansible` - Ansible, molecule, lint tools

**Composed Examples:**

- `rust-minimal` - Rust with minimal tools
- `rust-python` - Rust + Python
- `web-dev` - Rust + Python + PHP

### Library API

- `lib.${system}.composeShell { languages, tools, mcps, ... }` - Compose shells
- `lib.${system}.composeShellFromModules [...]` - Direct module composition
- `lib.${system}.modules` - All available modules

### Packages (MCP Servers)

- `cargo-mcp` - Cargo operations
- `cratedocs-mcp` - Rust crate docs
- `codanna` - Code intelligence
- `claude-task-master` - AI-powered task management
- `mcp-gitlab` - GitLab integration
- `puppeteer-mcp-server` - Browser automation
- `serena` - Project analysis

### Templates

- `rust` - Cargo project
- `php` - PHP project
- `latex` - LaTeX document
- `cpp` - CMake project

## Usage

### With direnv

```bash
echo "use flake github:Ba-So/nix-devshells#rust" > .envrc
direnv allow
```

### From template

```bash
nix flake init -t github:Ba-So/nix-devshells#rust
direnv allow
```

### Direct activation

```bash
nix develop github:Ba-So/nix-devshells#python
```

### Custom composition

```nix
devShells.default = devshells.lib.${system}.composeShell {
  languages = ["rust" "python"];
  tools = "standard";
  mcps = ["cargo-mcp" "serena"];
  extraPackages = with pkgs; [ postgresql redis ];
  extraShellHook = ''
    export DATABASE_URL="postgres://localhost/myapp"
  '';
};
```

## License

MIT
