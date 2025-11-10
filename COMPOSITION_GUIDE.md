# Shell Composition Guide

This guide shows you how to use the nix-devshells modular composition system to create customized development environments tailored to your needs.

## Table of Contents

- [Quick Start](#quick-start)
- [Understanding Presets](#understanding-presets)
- [Common Use Cases](#common-use-cases)
- [MCP Server Selection](#mcp-server-selection)
- [Advanced Composition](#advanced-composition)
- [Migration Guide](#migration-guide)
- [Troubleshooting](#troubleshooting)

## Quick Start

The simplest way to use nix-devshells with the new composition API:

```nix
{
  inputs.devshells.url = "github:Ba-So/nix-devshells";

  outputs = {devshells, ...}: {
    devShells.x86_64-linux.default = devshells.lib.x86_64-linux.composeShell {
      languages = ["rust"];
      tools = "standard";
      mcps = ["cargo-mcp" "serena"];
    };
  };
}
```

That's it! You now have a complete Rust development environment with cargo, rustc, clippy, rust-analyzer, git, helix, and AI assistance.

## Understanding Presets

Presets are pre-configured tool bundles. Choose based on your needs:

### Preset Comparison

| Feature             | Minimal         | Standard        | Full            |
| ------------------- | --------------- | --------------- | --------------- |
| **Version Control** | git             | git             | git             |
| **Editors**         | ❌              | helix           | helix, neovim   |
| **Shell Utilities** | ❌              | starship, atuin | starship, atuin |
| **Nix Tools**       | nil             | nil, alejandra  | nil, alejandra  |
| **Build Time**      | ⚡ Fast         | 🚀 Normal       | 🐌 Slower       |
| **Disk Space**      | 💾 Small        | 💾 Medium       | 💾 Large        |
| **Recommended For** | CI, quick edits | Daily dev       | Power users     |

### When to Use Each Preset

**Minimal** (`tools = "minimal"`):

- CI/CD pipelines where speed matters
- Quick edits and testing
- Resource-constrained environments
- Learning/experimenting without commit

**Standard** (`tools = "standard"`) - **Recommended**:

- Day-to-day development
- Balanced feature set
- Most projects

**Full** (`tools = "full"`):

- Power users who want everything
- Complex multi-language projects
- When you need specialized tools

## Common Use Cases

### Single Language Development

```nix
# Rust project
devShells.default = devshells.lib.${system}.composeShell {
  languages = ["rust"];
  tools = "standard";
  mcps = ["cargo-mcp" "serena"];
};

# Python project with minimal overhead
devShells.default = devshells.lib.${system}.composeShell {
  languages = ["python"];
  tools = "minimal";
  mcps = [];  # No AI assistance
};

# PHP web project
devShells.default = devshells.lib.${system}.composeShell {
  languages = ["php"];
  tools = "standard";
  mcps = ["serena" "puppeteer"];  # AI + browser automation
};
```

### Multi-Language Projects

```nix
# Python extensions in C++
devShells.default = devshells.lib.${system}.composeShell {
  languages = ["python" "cpp"];
  tools = "standard";
  mcps = ["serena"];
};

# Rust + Python data processing
devShells.default = devshells.lib.${system}.composeShell {
  languages = ["rust" "python"];
  tools = "standard";
  mcps = ["cargo-mcp" "serena"];
};

# Full-stack web development
devShells.default = devshells.lib.${system}.composeShell {
  languages = ["rust" "python" "php"];
  tools = "standard";
  mcps = ["cargo-mcp" "serena" "puppeteer"];
};
```

### Minimal Shells for Speed

```nix
# Fastest possible Rust environment
devShells.default = devshells.lib.${system}.composeShell {
  languages = ["rust"];
  tools = "minimal";
  mcps = [];
};

# CI/CD environment
devShells.ci = devshells.lib.${system}.composeShell {
  languages = ["nix"];
  tools = "minimal";
  mcps = [];
};
```

### Custom Tool Selection

```nix
# Minimal tools + specific additions
devShells.default = devshells.lib.${system}.composeShell {
  languages = ["rust"];
  tools = {
    preset = "minimal";
    include = ["helix" "editors"];  # Add specific tools
  };
  mcps = ["cargo-mcp"];
};
```

### Extending with Extra Packages

```nix
# Add project-specific tools
devShells.default = devshells.lib.${system}.composeShell {
  languages = ["rust"];
  tools = "standard";
  mcps = ["cargo-mcp"];

  extraPackages = with pkgs; [
    # Database tools
    postgresql_15
    diesel-cli

    # Additional Rust tools
    sea-orm-cli
    cargo-watch
  ];

  extraShellHook = ''
    export DATABASE_URL="postgres://localhost/myapp"
    echo "Custom project setup complete!"
  '';
};
```

### Direct Module Composition

For maximum control, compose modules directly:

```nix
devShells.default = let
  inherit (devshells.lib.${system}) modules composeShellFromModules;
in composeShellFromModules [
  # Languages
  modules.languages.rust
  modules.languages.python

  # Specific tools (no preset)
  modules.tools.version-control
  modules.tools.editors

  # MCP servers
  modules.mcp.cargo-mcp
  modules.mcp.serena
];
```

## MCP Server Selection

MCP (Model Context Protocol) servers provide AI assistance. Choose based on your language and needs:

### Available MCP Servers

| MCP Server  | Languages | Purpose                    | Recommended For      |
| ----------- | --------- | -------------------------- | -------------------- |
| `cargo-mcp` | Rust      | Safe Cargo operations      | All Rust projects    |
| `serena`    | All       | Code analysis & assistance | Any language         |
| `codanna`   | All       | Code search & navigation   | Large codebases      |
| `shrimp`    | All       | Task management            | Complex projects     |
| `gitlab`    | All       | GitLab integration         | GitLab users         |
| `puppeteer` | Web       | Browser automation         | Web development      |
| `cratedocs` | Rust      | Crate documentation        | Rust library authors |

### Recommended Combinations

```nix
# Rust development
mcps = ["cargo-mcp" "serena"];

# Python development
mcps = ["serena"];

# Web development (PHP/JavaScript)
mcps = ["serena" "puppeteer"];

# Large codebase exploration
mcps = ["serena" "codanna"];

# No AI assistance (fastest)
mcps = [];
```

### MCP Configuration

MCP servers are configured automatically. The system generates `.mcp.json` in your project:

```json
{
  "mcpServers": {
    "cargo-mcp": {
      "type": "stdio",
      "command": "cargo-mcp",
      "args": []
    },
    "serena": {
      "type": "stdio",
      "command": "serena",
      "args": []
    }
  }
}
```

User customizations in `.mcp.json` are preserved when updating the shell.

## Advanced Composition

### Conditional Composition

```nix
devShells.default = devshells.lib.${system}.composeShell {
  languages = ["rust"] ++ lib.optionals needsPython ["python"];
  tools = "standard";
  mcps = if enableAI then ["cargo-mcp" "serena"] else [];
};
```

### Multiple Shells

```nix
let
  lib = devshells.lib.${system};
in {
  # Production-like environment
  devShells.default = lib.composeShell {
    languages = ["rust"];
    tools = "standard";
    mcps = ["cargo-mcp" "serena"];
  };

  # Minimal testing environment
  devShells.ci = lib.composeShell {
    languages = ["rust"];
    tools = "minimal";
    mcps = [];
  };

  # Full-featured development
  devShells.full = lib.composeShell {
    languages = ["rust" "python"];
    tools = "full";
    mcps = ["cargo-mcp" "serena" "codanna"];
  };
}
```

### Accessing Individual Modules

```nix
let
  modules = devshells.lib.${system}.modules;
in {
  # Just the Rust language module packages
  packages.rust-tools = modules.languages.rust.packages;

  # Custom shell with specific modules
  devShells.custom = composeShellFromModules [
    modules.languages.nix
    modules.tools.editors
  ];
}
```

## Migration Guide

### From Old API to New API

#### Pattern 1: Using Pre-Built Shells

**Old (still works):**

```nix
devShells.default = devshells.devShells.${system}.rust;
```

**New:**

```nix
devShells.default = devshells.lib.${system}.composeShell {
  languages = ["rust"];
  tools = "standard";
  mcps = ["cargo-mcp" "serena"];
};
```

#### Pattern 2: Using packageSets

**Old (still works):**

```nix
devShells.default = pkgs.mkShell {
  buildInputs = devshells.packageSets.${system}.rust;
};
```

**New:**

```nix
devShells.default = devshells.lib.${system}.composeShell {
  languages = ["rust"];
  tools = "standard";
};
```

#### Pattern 3: Extending Shells

**Old:**

```nix
devShells.default = pkgs.mkShell {
  inputsFrom = [ devshells.devShells.${system}.rust ];
  packages = with pkgs; [ diesel-cli postgresql ];
};
```

**New:**

```nix
devShells.default = devshells.lib.${system}.composeShell {
  languages = ["rust"];
  tools = "standard";
  extraPackages = with pkgs; [ diesel-cli postgresql ];
};
```

#### Pattern 4: Combining Languages

**Old:**

```nix
devShells.default = pkgs.mkShell {
  buildInputs =
    devshells.packageSets.${system}.rust ++
    devshells.packageSets.${system}.python;
};
```

**New:**

```nix
devShells.default = devshells.lib.${system}.composeShell {
  languages = ["rust" "python"];
  tools = "standard";
};
```

### Migration Benefits

- ✨ Simpler, more declarative syntax
- 🎯 Selective tool and MCP inclusion
- 🚀 Faster builds with minimal preset
- 🔧 Better composability
- 📦 Automatic MCP configuration

## Troubleshooting

### Common Issues

#### "Module not found" error

```
error: Module 'cargo' not found in category 'mcp'.
Available modules: cargo-mcp, serena, ...
```

**Solution:** Use the full module name: `cargo-mcp` instead of `cargo`.

#### Shell build takes too long

**Solution:** Use the `minimal` preset instead of `standard`:

```nix
tools = "minimal";  # Much faster
```

#### MCP servers not working

**Solution:** Check that `.mcp.json` is generated in your project root:

```bash
ls -la .mcp.json
cat .mcp.json
```

If missing, the shell may not have MCP modules. Verify your configuration:

```nix
mcps = ["cargo-mcp" "serena"];  # Must be non-empty
```

#### Wrong Rust version

The rust module uses a pinned version (1.90.0). To use a different version:

```nix
devShells.default = let
  lib = devshells.lib.${system};
in lib.composeShell {
  languages = [];  # Don't use the rust module
  tools = "standard";
  extraPackages = with pkgs; [
    (rust-bin.stable."1.85.0".default.override {
      extensions = ["rust-src" "rust-analyzer"];
    })
  ];
};
```

#### Conflicting packages

If two modules provide the same package, the later one wins. Use direct module composition to control order:

```nix
composeShellFromModules [
  modules.languages.rust  # This rust version
  # NOT: modules.languages.other-with-rust
]
```

### Getting Help

- Check the [MODULE_GUIDE.md](./MODULE_GUIDE.md) for module details
- Review existing templates in `templates/`
- Open an issue on GitHub
- Check the module source code in `modules/`

### Debugging Tips

```bash
# Check what modules are available
nix eval .#lib.x86_64-linux.modules --apply 'builtins.attrNames'

# Inspect a specific module
nix eval .#lib.x86_64-linux.modules.languages.rust --json

# Test a shell without entering it
nix build .#devShells.x86_64-linux.default --dry-run

# See what packages will be included
nix eval .#devShells.x86_64-linux.default.buildInputs --apply 'map (p: p.name)'
```

## Best Practices

1. **Start with standard preset**: It's the best balance of features vs. build time
2. **Add MCPs selectively**: Only include MCPs you actually use
3. **Use minimal for CI**: Faster builds in automated environments
4. **Document your choice**: Comment why you chose specific modules
5. **Test changes**: Use `nix develop` to test before committing

## Next Steps

- Explore [pre-built shells](./README.md#available-shells)
- Learn to [create custom modules](./MODULE_GUIDE.md)
- Check out [templates](./templates/) for project examples
- Read the [architecture proposal](./MODULARITY_PROPOSAL.md)

Happy composing! 🚀
