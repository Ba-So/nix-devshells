# Module Creation Guide

This guide explains how to create new modules for the nix-devshells modular architecture. Modules are the building blocks of development environments, allowing fine-grained composition of tools, languages, and services.

## Table of Contents

- [Module Interface Specification](#module-interface-specification)
- [Module Categories](#module-categories)
- [Creating Language Modules](#creating-language-modules)
- [Creating Tool Modules](#creating-tool-modules)
- [Creating MCP Modules](#creating-mcp-modules)
- [Creating Preset Modules](#creating-preset-modules)
- [Module Validation](#module-validation)
- [Contribution Guidelines](#contribution-guidelines)

## Module Interface Specification

All modules must follow a standardized interface to ensure compatibility with the composition system.

### Required Fields

```nix
{
  meta = {
    name = "module-name";         # Unique identifier (string)
    description = "Short desc";    # One-line description (string)
    category = "languages";        # Category: languages|tools|mcp|presets (string)
  };

  packages = [ /* list of packages */ ];  # Nix packages to include (list)
}
```

### Optional Fields

```nix
{
  # Shell initialization code
  shellHook = ''
    echo "Module loaded"
  '';

  # Environment variables
  env = {
    MY_VAR = "value";
    PATH_ADDITIONS = "/custom/path";
  };

  # Suggested MCP servers for this module
  suggestedMcps = ["serena" "codanna"];

  # MCP server configuration (only for MCP modules)
  mcpConfig = {
    server-name = {
      type = "stdio";
      command = "server-command";
      args = ["--arg1" "value"];
    };
  };

  # Module dependencies (list of module names)
  requires = ["other-module"];

  # Conditional application predicate
  appliesWhen = system: true;
}
```

### Field Type Reference

| Field              | Type              | Required | Description                                 |
| ------------------ | ----------------- | -------- | ------------------------------------------- |
| `meta`             | `attrset`         | Yes      | Module metadata                             |
| `meta.name`        | `string`          | Yes      | Unique module identifier                    |
| `meta.description` | `string`          | Yes      | One-line description                        |
| `meta.category`    | `string`          | Yes      | Module category (see below)                 |
| `packages`         | `list`            | Yes      | Nix packages to include                     |
| `shellHook`        | `string`          | No       | Shell initialization code                   |
| `env`              | `attrset`         | No       | Environment variables                       |
| `suggestedMcps`    | `list of strings` | No       | Recommended MCP servers                     |
| `mcpConfig`        | `attrset`         | No       | MCP server configuration (MCP modules only) |
| `requires`         | `list of strings` | No       | Module dependencies                         |
| `appliesWhen`      | `function`        | No       | Conditional application predicate           |

## Module Categories

Modules are organized into four categories:

1. **languages**: Programming language toolchains (rust, python, cpp, etc.)
2. **tools**: Development utilities (editors, version control, etc.)
3. **mcp**: MCP (Model Context Protocol) servers for AI assistance
4. **presets**: Pre-configured bundles of modules

## Creating Language Modules

Language modules provide complete toolchains for specific programming languages.

### Step-by-Step Guide

1. Create a new file in `modules/languages/` (e.g., `go.nix`)
2. Define the module following the interface specification
3. Add the module to `modules/languages/default.nix`

### Example: Go Language Module

```nix
# modules/languages/go.nix
{
  pkgs,
  lib,
  inputs,
}: {
  meta = {
    name = "go";
    description = "Go 1.21 development environment";
    category = "languages";
    languages = ["go"];  # Additional metadata for filtering
  };

  packages = with pkgs; [
    go_1_21
    gopls        # Language server
    delve        # Debugger
    gotools      # Additional Go tools
    go-tools     # Static analysis tools
  ];

  shellHook = ''
    echo "🚀 Go ${pkgs.go_1_21.version} development environment"
    echo "  → go: $(command -v go)"
    echo "  → gopls: $(command -v gopls)"

    # Set up Go workspace
    export GOPATH="$HOME/go"
    export PATH="$GOPATH/bin:$PATH"
  '';

  env = {
    GO111MODULE = "on";
    CGO_ENABLED = "1";
  };

  suggestedMcps = ["serena" "codanna"];
}
```

### Adding to default.nix

```nix
# modules/languages/default.nix
{
  pkgs,
  inputs,
  lib,
}: {
  rust = import ./rust.nix {inherit pkgs inputs lib;};
  python = import ./python.nix {inherit pkgs inputs lib;};
  go = import ./go.nix {inherit pkgs inputs lib;};  # Add your module
  # ... other languages
}
```

## Creating Tool Modules

Tool modules provide focused development utilities like editors, version control, or build systems.

### Example: Database Tools Module

```nix
# modules/tools/database.nix
{
  pkgs,
  lib,
}: {
  meta = {
    name = "database-tools";
    description = "Database clients and utilities";
    category = "tools";
  };

  packages = with pkgs; [
    postgresql_15    # PostgreSQL client
    sqlite          # SQLite client
    redis           # Redis client
    mycli           # MySQL client with autocomplete
  ];

  shellHook = ''
    echo "  📊 Database tools available: psql, sqlite3, redis-cli, mycli"
  '';

  env = {
    PGHOST = "localhost";
    PGPORT = "5432";
  };
}
```

### Tool Module Best Practices

- Keep tools focused on a specific domain (e.g., "database", "containers", "monitoring")
- Avoid overlap with language modules
- Use descriptive names that clearly indicate purpose
- Provide sensible default environment variables

## Creating MCP Modules

MCP modules integrate AI-powered development assistants through the Model Context Protocol.

### MCP Module Structure

```nix
# modules/mcp/example.nix
{
  pkgs,
  lib,
  devPkgs,  # Custom packages built by the system
}: {
  meta = {
    name = "example-mcp";
    description = "Example MCP server for demonstration";
    category = "mcp";
    languages = ["rust" "python"];  # Languages this MCP supports
  };

  packages = [devPkgs.example-mcp];  # Use devPkgs for custom packages

  mcpConfig = {
    example = {
      type = "stdio";
      command = "example-mcp";
      args = ["--verbose"];
      env = {
        # Pass environment variables to the MCP server
        MY_CONFIG = "\${MY_CONFIG}";
      };
    };
  };

  shellHook = ''
    echo "  🤖 example-mcp: AI assistance for Rust and Python"
    if [ -z "$MY_CONFIG" ]; then
      echo "  ⚠️  Set MY_CONFIG environment variable"
    fi
  '';
}
```

### MCP Config Format

The `mcpConfig` field follows the MCP specification:

```nix
mcpConfig = {
  server-name = {
    type = "stdio";              # Connection type: stdio, sse, http
    command = "server-binary";    # Command to execute
    args = ["--flag" "value"];    # Optional arguments
    env = {                       # Optional environment variables
      MY_SETTING = "\${MY_SETTING}";
    };
  };
};
```

### MCP Module Best Practices

- Include the package in `devPkgs` parameter (built by lib system)
- Provide helpful shellHook messages about setup requirements
- Document any required environment variables
- Use descriptive server names in mcpConfig
- Test the MCP server works correctly with the configuration

## Creating Preset Modules

Preset modules bundle multiple modules together for common use cases.

### Preset with Inheritance

```nix
# modules/presets/backend.nix
{
  pkgs,
  lib,
  modules,  # Access to all other modules
}: let
  # Extend the standard preset
  standardPreset = modules.presets.standard;
in {
  meta = {
    name = "backend";
    description = "Backend development preset with database tools";
    category = "presets";
  };

  # Combine packages from standard preset + additional tools
  packages = standardPreset.packages ++ (with pkgs; [
    postgresql_15
    redis
    docker-compose
  ]);

  shellHook = standardPreset.shellHook + ''
    echo "  🔧 Backend preset: Added database and container tools"
  '';

  env = standardPreset.env // {
    BACKEND_ENV = "development";
  };
}
```

### Preset Best Practices

- Build on existing presets when appropriate (minimal → standard → full)
- Clearly document what's included
- Use descriptive names that indicate the use case
- Consider performance: larger presets take longer to build

## Module Validation

The module system automatically validates modules at build time.

### Validation Rules

1. **Required fields**: `meta.name`, `meta.description`, `meta.category`, `packages`
2. **Category values**: Must be one of: `languages`, `tools`, `mcp`, `presets`
3. **Package types**: All items in `packages` must be derivations
4. **MCP configs**: Only MCP modules can have `mcpConfig`

### Error Messages

```
error: Module validation failed for 'my-module'
  Missing required field: meta.name

error: Module validation failed for 'my-module'
  Invalid category: 'utilities' (must be: languages, tools, mcp, presets)

error: Module validation failed for 'my-module'
  Field 'packages' must be a list, got: attribute set
```

## Contribution Guidelines

### Before Creating a Module

1. Check if a similar module already exists
2. Consider whether it should be a separate module or part of an existing one
3. Review existing modules for inspiration and consistency

### Contribution Checklist

- [ ] Module follows the interface specification
- [ ] Module is in the correct category directory
- [ ] Module is added to the category's `default.nix`
- [ ] Documentation includes examples of usage
- [ ] shellHook messages are helpful and concise
- [ ] Environment variables have sensible defaults
- [ ] Tested with `nix build .#devShells.x86_64-linux.<test-shell>`
- [ ] Pre-commit hooks pass (run `pre-commit run --all-files`)

### Testing Your Module

```bash
# Test a language module
nix develop -c bash <<EOF
  composeShell {
    languages = ["your-new-language"];
    tools = "standard";
  }
EOF

# Test module composition
nix eval .#lib.x86_64-linux.modules.languages.your-module --json

# Test in a shell
nix develop github:Ba-So/nix-devshells#your-shell
```

### Submitting Your Module

1. Fork the repository
2. Create a feature branch: `git checkout -b add-<module-name>-module`
3. Add your module following this guide
4. Test thoroughly
5. Commit with descriptive message: `feat(modules): add <module-name> module`
6. Create a pull request with:
   - Description of the module
   - Example usage
   - Any special setup requirements

## Advanced Topics

### Module Composition Patterns

```nix
# Conditional packages based on system
packages = with pkgs;
  [
    common-package
  ]
  ++ lib.optionals stdenv.isLinux [
    linux-only-package
  ]
  ++ lib.optionals stdenv.isDarwin [
    macos-only-package
  ];

# Parameterized modules
{version ? "1.21"}: {
  # Module uses 'version' parameter
  packages = with pkgs; [
    (pkgs."go_${lib.replaceStrings ["."] ["_"] version}")
  ];
}
```

### Module Dependencies

```nix
{
  meta = {
    # ...
  };

  requires = ["git" "helix"];  # This module needs these tool modules

  packages = [/* ... */];
}
```

The composition system will automatically include required modules.

## Getting Help

- Check existing modules in `modules/` for examples
- Read the [COMPOSITION_GUIDE.md](./COMPOSITION_GUIDE.md) for usage examples
- Open an issue on GitHub for questions
- Join discussions about module design

Happy module creating! 🚀
