# Devshell Modularity Proposal

## Executive Summary

This proposal restructures the nix-devshells repository to enable:
- **Composable shells**: Easily combine rust + python + specific tools
- **Selective MCP servers**: Opt-in to only the servers you need
- **Modular common packages**: Choose which common tools to include
- **Simple extension API**: Clear patterns for creating custom combinations

## Current Architecture Analysis

### Strengths ✓
- Language configs are self-contained (`languages/*.nix`)
- PackageSets exposed for external composition
- MCP servers packaged independently
- Template system demonstrates usage

### Limitations ✗
1. **All-or-nothing MCP integration**: Every shell gets all 7 MCP servers via `common.nix`
2. **Monolithic common packages**: 30+ tools always included, no opt-out
3. **Manual shell combination**: `py-cpp` shell manually combines packages
4. **No standard composition API**: External users must understand internal structure
5. **Configuration duplication**: `.mcp.json` lists all servers even if unused

## Proposed Architecture

### 1. Module System Structure

```
nix-devshells/
├── flake.nix                    # Entry point
├── lib/
│   ├── default.nix              # Module system API
│   ├── compose.nix              # Shell composition functions
│   └── mcp.nix                  # MCP configuration generators
├── modules/
│   ├── languages/
│   │   ├── rust.nix             # Rust language module
│   │   ├── python.nix           # Python language module
│   │   ├── cpp.nix              # C++ language module
│   │   └── ...
│   ├── mcp/
│   │   ├── cargo.nix            # Cargo MCP module
│   │   ├── serena.nix           # Serena MCP module
│   │   ├── codanna.nix          # Codanna MCP module
│   │   ├── shrimp.nix           # Shrimp MCP module
│   │   └── ...
│   ├── tools/
│   │   ├── version-control.nix  # Git, git-lfs
│   │   ├── nix-tools.nix        # Nix formatters, LSP
│   │   ├── editors.nix          # Helix, etc.
│   │   └── utilities.nix        # jq, curl, ripgrep, etc.
│   └── presets/
│       ├── minimal.nix          # Essential tools only
│       ├── standard.nix         # Current "common" set
│       └── full.nix             # Everything including all MCPs
├── pkgs/                        # Package definitions (unchanged)
└── templates/                   # Updated templates using new API
```

### 2. Module Definition Standard

Each module exports a standardized interface:

```nix
# modules/languages/rust.nix
{ pkgs, inputs, lib, ... }:
{
  # Metadata
  meta = {
    name = "rust";
    description = "Rust development environment";
    category = "language";
  };

  # Packages to include
  packages = [ /* ... */ ];

  # Shell initialization
  shellHook = ''
    echo "🦀 Rust ${rustVersion}"
    # ...
  '';

  # Optional: Environment variables
  env = {
    RUST_BACKTRACE = "1";
    # ...
  };

  # Optional: Suggested MCP servers
  suggestedMcps = [ "cargo" "cratedocs" ];

  # Optional: Dependencies on other modules
  # (automatically included)
  requires = [ ];
}
```

```nix
# modules/mcp/cargo.nix
{ pkgs, devPkgs, ... }:
{
  meta = {
    name = "cargo-mcp";
    description = "Safe Cargo operations for Rust projects";
    category = "mcp";
    languages = [ "rust" ]; # Hint for which language this supports
  };

  packages = [ devPkgs.cargo-mcp ];

  # MCP configuration for .mcp.json
  mcpConfig = {
    cargo = {
      type = "stdio";
      command = "cargo-mcp";
    };
  };

  # Optional: Only relevant if rust is present
  appliesWhen = modules: builtins.elem "rust" (map (m: m.meta.name) modules);
}
```

### 3. Composition API

**Simple combination:**
```nix
# lib/compose.nix provides:
composeShell {
  languages = [ "rust" "python" ];
  mcps = [ "cargo" "serena" ];
  tools = "standard"; # preset
}
```

**Advanced configuration:**
```nix
composeShell {
  languages = [ "rust" "python" ];
  mcps = [ "cargo" "serena" "codanna" ];
  tools = {
    preset = "minimal";
    include = [ "helix" "ripgrep" ];
    exclude = [ ];
  };
  extraPackages = [ pkgs.postgresql ];
  extraShellHook = ''
    export DATABASE_URL="postgres://localhost/mydb"
  '';
}
```

**Using modules directly:**
```nix
composeShellFromModules [
  modules.languages.rust
  modules.languages.python
  modules.mcp.cargo
  modules.mcp.serena
  modules.tools.minimal
]
```

### 4. Preset System

**Presets provide curated common tool sets:**

```nix
# modules/presets/minimal.nix
{
  meta.name = "minimal";
  includes = [
    modules.tools.version-control  # git
    modules.tools.nix-tools         # nil, nixfmt
  ];
}

# modules/presets/standard.nix (current common.nix)
{
  meta.name = "standard";
  includes = [
    modules.tools.version-control
    modules.tools.nix-tools
    modules.tools.editors
    modules.tools.utilities
    modules.mcp.shrimp
    modules.mcp.codanna
    modules.mcp.serena
    modules.mcp.gitlab
  ];
}

# modules/presets/full.nix
{
  meta.name = "full";
  includes = [ /* everything */ ];
}
```

### 5. Flake API

**Backward compatible outputs:**
```nix
{
  # Legacy shells (unchanged for compatibility)
  devShells.x86_64-linux = {
    rust = /* existing rust shell */;
    python = /* existing python shell */;
    # ...
  };

  # NEW: Compose function for users
  lib.x86_64-linux = {
    composeShell = { languages, mcps ? [], tools ? "standard", ... }: /* ... */;
    composeShellFromModules = modules: /* ... */;

    # Access to all modules
    modules = {
      languages = { rust, python, cpp, ... };
      mcp = { cargo, serena, codanna, ... };
      tools = { version-control, nix-tools, ... };
      presets = { minimal, standard, full };
    };
  };

  # NEW: Pre-composed popular combinations
  devShells.x86_64-linux = {
    # Legacy shells
    rust = /* ... */;
    python = /* ... */;

    # NEW: Combinations with different tool presets
    rust-minimal = composeShell {
      languages = ["rust"];
      tools = "minimal";
      mcps = ["cargo"];
    };

    rust-python = composeShell {
      languages = ["rust" "python"];
      mcps = ["cargo" "serena"];
    };

    web-dev = composeShell {
      languages = ["rust" "python" "php"];
      mcps = ["cargo" "serena" "puppeteer"];
    };
  };
}
```

### 6. User Experience Examples

#### Example 1: Quick Language Combination

**Before:**
```nix
# User's flake.nix - manual composition
devShells.default = pkgs.mkShell {
  buildInputs = devshells.packageSets.${system}.rust
             ++ devshells.packageSets.${system}.python
             ++ devshells.packageSets.${system}.common;
  shellHook = ''
    # Manually combine shell hooks...
  '';
};
```

**After:**
```nix
# User's flake.nix - simple composition
{
  inputs.devshells.url = "github:Ba-So/nix-devshells";

  outputs = { devshells, ... }: {
    devShells.default = devshells.lib.${system}.composeShell {
      languages = [ "rust" "python" ];
      mcps = [ "cargo" "serena" ];
    };
  };
}
```

#### Example 2: Minimal Shell (No MCP Overhead)

```nix
# Just Rust + essential tools, no MCP servers
devShells.default = devshells.lib.${system}.composeShell {
  languages = [ "rust" ];
  tools = "minimal";
  mcps = [ ]; # No MCP servers
};
```

#### Example 3: Custom Tool Selection

```nix
devShells.default = devshells.lib.${system}.composeShell {
  languages = [ "cpp" ];
  tools = {
    preset = "minimal";
    include = [
      "helix"        # Editor
      "ripgrep"      # Search
      "valgrind"     # Already in cpp module, but explicit
    ];
  };
  mcps = [ "serena" ]; # Only project analysis
};
```

#### Example 4: Direct Module Composition

```nix
let
  inherit (devshells.lib.${system}) modules composeShellFromModules;
in {
  devShells.default = composeShellFromModules [
    modules.languages.rust
    modules.languages.python
    modules.mcp.cargo
    modules.mcp.serena
    modules.tools.version-control
    modules.tools.nix-tools
  ];
}
```

### 7. MCP Configuration Generation

Automatically generate `.mcp.json` based on included modules:

```nix
# lib/mcp.nix
generateMcpConfig = modules:
  let
    mcpModules = builtins.filter (m: m.meta.category == "mcp") modules;
    configs = map (m: m.mcpConfig) mcpModules;
  in
    pkgs.writeTextFile {
      name = "mcp.json";
      text = builtins.toJSON {
        mcpServers = lib.fold (a: b: a // b) {} configs;
      };
    };
```

**Usage in shell:**
```nix
shellHook = ''
  # Auto-generate .mcp.json if not present
  if [ ! -f .mcp.json ]; then
    cp ${generatedMcpConfig} .mcp.json
  fi
'';
```

### 8. Migration Path

**Phase 1: Add new structure alongside existing**
- Create `lib/` and `modules/` directories
- Implement composition functions
- Keep existing `languages/` and structure unchanged
- Add new composed shells to flake outputs

**Phase 2: Update templates**
- Templates use new composition API
- Show both old and new patterns in examples
- Update README with new patterns

**Phase 3: Deprecate old structure (optional)**
- Move language files into modules/
- Mark old packageSets as legacy
- Provide migration guide

## Implementation Benefits

### For Users

1. **Simpler combinations**: `languages = ["rust" "python"]` instead of manual package list management
2. **Selective MCP servers**: Only include what you need, faster startup
3. **Reduced bloat**: Minimal preset for lightweight shells
4. **Clear documentation**: Each module is self-documenting
5. **Discoverable**: `nix flake show` reveals all available modules

### For Maintainers

1. **Easier testing**: Each module can be tested independently
2. **Clear dependencies**: Modules explicitly declare what they need
3. **Consistent structure**: Standard module interface
4. **Better organization**: Clear separation of concerns
5. **Extensible**: New languages/tools follow same pattern

### For Contributors

1. **Clear contribution guide**: "Add new language? Create a module!"
2. **Isolated changes**: New module = single file
3. **Review simplicity**: Module interface is standardized
4. **No breakage risk**: New modules don't affect existing shells

## Implementation Checklist

### Core Infrastructure
- [ ] Create `lib/default.nix` with module system
- [ ] Implement `lib/compose.nix` with `composeShell` function
- [ ] Implement `lib/mcp.nix` with config generation
- [ ] Add module validation and error messages

### Module Migration
- [ ] Convert language files to module format
  - [ ] rust.nix → modules/languages/rust.nix
  - [ ] python.nix → modules/languages/python.nix
  - [ ] cpp.nix → modules/languages/cpp.nix
  - [ ] nix.nix, php.nix, latex.nix, ansible.nix
- [ ] Split common.nix into tool modules
  - [ ] modules/tools/version-control.nix
  - [ ] modules/tools/nix-tools.nix
  - [ ] modules/tools/editors.nix
  - [ ] modules/tools/utilities.nix
- [ ] Create MCP modules
  - [ ] modules/mcp/cargo.nix
  - [ ] modules/mcp/serena.nix
  - [ ] modules/mcp/codanna.nix
  - [ ] modules/mcp/shrimp.nix
  - [ ] modules/mcp/gitlab.nix
  - [ ] modules/mcp/puppeteer.nix
  - [ ] modules/mcp/cratedocs.nix

### Presets
- [ ] Create modules/presets/minimal.nix
- [ ] Create modules/presets/standard.nix
- [ ] Create modules/presets/full.nix

### Flake Updates
- [ ] Update flake.nix to expose lib with composeShell
- [ ] Add pre-composed shell combinations
- [ ] Maintain backward compatibility with existing shells
- [ ] Update flake outputs documentation

### Templates
- [ ] Update rust template to use composition API
- [ ] Update python template
- [ ] Update cpp template
- [ ] Update php template
- [ ] Add examples of different composition patterns

### Documentation
- [ ] Update README with new composition patterns
- [ ] Add MODULE_GUIDE.md explaining module creation
- [ ] Add COMPOSITION_GUIDE.md with examples
- [ ] Document migration from old to new pattern
- [ ] Update per-shell documentation

### Testing
- [ ] Test all pre-defined shells still work
- [ ] Test composition with various combinations
- [ ] Test MCP config generation
- [ ] Test minimal preset (no unnecessary packages)
- [ ] Validate all templates

## Example Implementation Snippets

### lib/compose.nix (Core)

```nix
{ pkgs, lib, modules, ... }:

rec {
  # Resolve a module by name from the modules set
  resolveModule = name: category:
    if modules.${category} ? ${name}
    then modules.${category}.${name}
    else throw "Module '${name}' not found in category '${category}'";

  # Compose a shell from high-level specification
  composeShell = {
    languages ? [],
    mcps ? [],
    tools ? "standard",
    extraPackages ? [],
    extraShellHook ? "",
    ...
  }:
    let
      # Resolve language modules
      langModules = map (name: resolveModule name "languages") languages;

      # Resolve MCP modules
      mcpModules = map (name: resolveModule name "mcp") mcps;

      # Resolve tool preset or custom config
      toolModules =
        if builtins.isString tools
        then [ (resolveModule tools "presets") ]
        else
          let
            preset = resolveModule tools.preset "presets";
            included = map (name: resolveModule name "tools") (tools.include or []);
          in [ preset ] ++ included;

      # Combine all modules
      allModules = langModules ++ mcpModules ++ toolModules;

    in composeShellFromModules allModules // {
      buildInputs = (composeShellFromModules allModules).buildInputs ++ extraPackages;
      shellHook = (composeShellFromModules allModules).shellHook + extraShellHook;
    };

  # Compose a shell from explicit module list
  composeShellFromModules = modules:
    let
      # Collect all packages from modules
      allPackages = lib.flatten (map (m: m.packages or []) modules);

      # Combine shell hooks
      allShellHooks = lib.concatStringsSep "\n" (map (m: m.shellHook or "") modules);

      # Merge environment variables
      allEnv = lib.fold (m: acc: acc // (m.env or {})) {} modules;

      # Generate MCP config
      mcpConfig = generateMcpConfig modules;

    in pkgs.mkShell ({
      buildInputs = allPackages;
      shellHook = allShellHooks + ''
        # Auto-generate .mcp.json from included MCP modules
        if [ ! -f .mcp.json ]; then
          echo "Generating .mcp.json with enabled MCP servers..."
          cat > .mcp.json << 'EOF'
        ${builtins.readFile mcpConfig}
        EOF
        fi
      '';
    } // allEnv);

  # Generate MCP configuration file
  generateMcpConfig = modules:
    let
      mcpModules = builtins.filter (m: (m.meta.category or "") == "mcp") modules;
      configs = map (m: m.mcpConfig or {}) mcpModules;
      merged = lib.fold (a: b: a // b) {} configs;
    in pkgs.writeText "mcp.json" (builtins.toJSON {
      mcpServers = merged;
    });
}
```

### modules/languages/rust.nix (Example Module)

```nix
{ pkgs, inputs, ... }:

let
  rustVersion = "1.90.0";
  rustToolchain = inputs.rust-overlay.lib.mkRustBin {} pkgs.buildPackages rustVersion;
in
{
  meta = {
    name = "rust";
    description = "Rust ${rustVersion} development environment";
    category = "language";
  };

  packages = with pkgs; [
    # Toolchain
    (rustToolchain.override {
      extensions = [ "rust-src" "rust-analyzer" "clippy" ];
    })

    # Cargo extensions
    cargo-watch
    cargo-edit
    cargo-audit
    cargo-nextest
    cargo-bloat
    cargo-llvm-lines

    # Build optimization
    sccache
  ];

  shellHook = ''
    echo "🦀 Rust ${rustVersion}"

    # sccache configuration
    export RUSTC_WRAPPER=${pkgs.sccache}/bin/sccache
    export SCCACHE_DIR="$HOME/.cache/sccache"

    # Rust backtrace
    export RUST_BACKTRACE=1

    # Version check
    cargo --version
    rustc --version
  '';

  env = {
    RUST_BACKTRACE = "1";
  };

  suggestedMcps = [ "cargo" "cratedocs" ];
}
```

### modules/mcp/cargo.nix (Example MCP Module)

```nix
{ pkgs, devPkgs, ... }:

{
  meta = {
    name = "cargo-mcp";
    description = "Safe Cargo operations and project queries";
    category = "mcp";
    languages = [ "rust" ];
  };

  packages = [ devPkgs.cargo-mcp ];

  mcpConfig = {
    cargo = {
      type = "stdio";
      command = "cargo-mcp";
    };
  };

  shellHook = ''
    echo "  📦 cargo-mcp: Safe Cargo operations"
  '';

  # Optional: Only include if rust module is present
  appliesWhen = modules:
    builtins.any (m: (m.meta.name or "") == "rust") modules;
}
```

### modules/presets/minimal.nix (Example Preset)

```nix
{ modules, ... }:

{
  meta = {
    name = "minimal";
    description = "Essential development tools only";
    category = "preset";
  };

  # This preset includes other modules
  includes = with modules; [
    tools.version-control  # git, git-lfs
    tools.nix-tools        # nil, nixfmt, alejandra
  ];

  # Flatten the packages from included modules
  packages = /* derived from includes */;
  shellHook = /* combined from includes */;
}
```

## Timeline Estimate

- **Phase 1 (Core infrastructure)**: 1-2 days
  - Implement lib/compose.nix
  - Create module system foundation
  - Basic validation and tests

- **Phase 2 (Module migration)**: 2-3 days
  - Convert all language files to modules
  - Split common.nix into tool modules
  - Create MCP modules

- **Phase 3 (Integration)**: 1-2 days
  - Update flake.nix
  - Create preset modules
  - Generate composed shells

- **Phase 4 (Templates & docs)**: 1-2 days
  - Update templates
  - Write documentation
  - Create examples

**Total: 5-9 days** for complete implementation

## Conclusion

This modular architecture provides:
- **Flexibility**: Compose any combination of languages, tools, and MCP servers
- **Simplicity**: High-level API for common use cases
- **Efficiency**: Include only what you need (no bloat)
- **Maintainability**: Clear structure for adding new modules
- **Backward compatibility**: Existing shells continue to work

The investment in this structure will pay dividends as the repository grows, making it easier for users to create exactly the development environment they need without unnecessary overhead.
