# Module system public API
# Main entry point for the devshell module system
{
  pkgs,
  system,
  inputs,
  ...
}: let
  inherit (pkgs) lib;

  # Create pkgs with rust overlay for cargo-mcp
  pkgs-with-rust = import inputs.nixpkgs {
    inherit system;
    overlays = [
      inputs.rust-overlay.overlays.default
      # Fix conan build failure (test_create_pip_manager fails with Python 3.13)
      (_: prev: {
        conan = prev.conan.overridePythonAttrs (old: {
          disabledTestPaths =
            (old.disabledTestPaths or [])
            ++ [
              "test/functional/tools/system/pip_manager_test.py"
            ];
        });
      })
    ];
  };

  # Create pkgs from unstable for packages requiring newer toolchains
  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit system;
  };

  # Create pkgs with unfree packages allowed for claude-task-master
  pkgs-unfree = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

  # Build custom packages for MCP modules
  devPkgs = {
    cargo-mcp = pkgs-with-rust.callPackage ../pkgs/cargo-mcp.nix {
      inherit (pkgs-with-rust) rust-bin;
    };
    serena = inputs.serena.packages.${system}.default or inputs.serena.defaultPackage.${system};
    codanna = inputs.codanna.packages.${system}.default;
    claude-task-master = pkgs-unfree.callPackage ../pkgs/claude-task-master {};
    mcp-gitlab = pkgs.callPackage ../pkgs/gitlab.nix {};
    puppeteer-mcp-server = pkgs.callPackage ../pkgs/puppeteer-mcp.nix {};
    universal-screenshot-mcp = pkgs.callPackage ../pkgs/universal-screenshot-mcp.nix {};
    computer-use-mcp = pkgs.callPackage ../pkgs/computer-use-mcp.nix {};
    cratedocs-mcp = pkgs.callPackage ../pkgs/cratedocs-mcp.nix {};
    qdrant-mcp = pkgs.callPackage ../pkgs/qdrant-mcp.nix {
      inherit (inputs) pyproject-nix uv2nix pyproject-build-systems;
    };
    paper-search-mcp = pkgs.callPackage ../pkgs/paper-search-mcp.nix {
      inherit (inputs) pyproject-nix uv2nix pyproject-build-systems;
    };
    mempalace = pkgs.callPackage ../pkgs/mempalace.nix {
      inherit (inputs) pyproject-nix uv2nix pyproject-build-systems;
    };
    mcp-libre = pkgs.callPackage ../pkgs/mcp-libre.nix {};
    mcp-grafana = pkgs-unstable.callPackage ../pkgs/mcp-grafana.nix {};
    tod = pkgs.callPackage ../pkgs/tod.nix {};
    rtk = pkgs-with-rust.callPackage ../pkgs/rtk.nix {
      inherit (pkgs-with-rust) rust-bin;
    };

    # Deprecated/legacy packages
    mcp-shrimp-task-manager = pkgs.callPackage ../pkgs/shrimp.nix {};
  };

  # Import validation and utility functions
  validate = import ./validate.nix {inherit lib;};

  # Import modules from various categories
  # These will be populated as modules are created
  # Pass pkgs-with-rust so that language modules have access to rust-bin
  languageModules =
    if builtins.pathExists ../modules/languages
    then
      import ../modules/languages
      {
        pkgs = pkgs-with-rust;
        inherit inputs lib;
      }
    else {};

  toolModules =
    if builtins.pathExists ../modules/tools
    then
      import ../modules/tools
      {
        pkgs = pkgs-with-rust;
        inherit lib devPkgs;
      }
    else {};

  mcpModules =
    if builtins.pathExists ../modules/mcp
    then
      import ../modules/mcp
      {
        pkgs = pkgs-with-rust;
        inherit lib devPkgs;
        inherit (devPkgs) serena;
      }
    else {};

  agentModules =
    if builtins.pathExists ../modules/agents
    then
      import ../modules/agents
      {
        pkgs = pkgs-with-rust;
        inherit lib;
      }
    else {};

  # Consolidated modules attrset (without presets first to avoid circular dependency)
  modulesWithoutPresets = {
    languages = languageModules;
    tools = toolModules;
    mcp = mcpModules;
    agents = agentModules;
    presets = {};
  };

  # Load presets incrementally to handle inheritance (minimal -> standard -> full)
  # Each preset can reference previously loaded presets
  presetModules =
    if builtins.pathExists ../modules/presets
    then let
      # Load minimal preset first (no dependencies)
      minimal = import ../modules/presets/minimal.nix {
        pkgs = pkgs-with-rust;
        inherit lib;
        modules = modulesWithoutPresets;
      };

      # Load standard with access to minimal
      modulesWithMinimal = modulesWithoutPresets // {presets = {inherit minimal;};};
      standard = import ../modules/presets/standard.nix {
        pkgs = pkgs-with-rust;
        inherit lib;
        modules = modulesWithMinimal;
      };

      # Load full with access to minimal and standard
      modulesWithStandard = modulesWithMinimal // {presets = {inherit minimal standard;};};
      full = import ../modules/presets/full.nix {
        pkgs = pkgs-with-rust;
        inherit lib;
        modules = modulesWithStandard;
      };
    in {
      inherit minimal standard full;
    }
    else {};

  # Final consolidated modules attrset
  modules = modulesWithoutPresets // {presets = presetModules;};

  # Import utility functions (with modules passed for resolution)
  utils = import ./utils.nix {
    inherit lib modules;
  };

  # Import composition functions (will be created in Task 2)
  compose =
    if builtins.pathExists ./compose.nix
    then
      import ./compose.nix
      {
        inherit pkgs lib system inputs modules;
        inherit (utils) resolveModule flattenPackages mergeShellHooks mergeEnv filterByCategory deduplicateModules;
        inherit (validate) validateModule validateModules;
      }
    else {
      # Placeholder until compose.nix is created
      composeShell = _: throw "compose.nix not yet implemented (Task 2)";
      composeShellFromModules = _: throw "compose.nix not yet implemented (Task 2)";
    };

  # Import harness adapters and pick claude as the default for top-level exports.
  # composeShell can override per-call via the `harness` parameter.
  harnesses = import ./harness {inherit pkgs lib;};
  defaultHarness = harnesses.claude;

  # Import MCP config generation (will be created in Task 2)
  mcp =
    if builtins.pathExists ./mcp.nix
    then
      import ./mcp.nix
      {
        inherit pkgs lib;
        inherit (utils) filterByCategory;
        harness = defaultHarness;
      }
    else {
      # Placeholder until mcp.nix is created
      generateMcpConfig = _: throw "mcp.nix not yet implemented (Task 2)";
    };

  # Import agent deployment functions
  agents =
    if builtins.pathExists ./agents.nix
    then
      import ./agents.nix
      {
        inherit pkgs lib;
        harness = defaultHarness;
      }
    else {
      filterAgentsByMcps = _: _: [];
      generateAgentConfig = _: null;
      agentConfigShellHook = _: "";
    };

  # Import worktree support
  worktree =
    if builtins.pathExists ./worktree/default.nix
    then
      import ./worktree
      {
        inherit pkgs lib system;
      }
    else {
      # Placeholder
      generateSubtreeFlakeContent = _: throw "worktree.nix not yet implemented";
    };
in {
  # Public API exports
  inherit modules;
  inherit harnesses;

  # Composition functions
  inherit (compose) composeShell composeShellFromModules;

  # MCP configuration
  inherit (mcp) generateMcpConfig generateMcpConfigFiltered generateWorktreeMcpConfigs;

  # Agent deployment
  inherit (agents) filterAgentsByMcps generateAgentConfig agentConfigShellHook mkAgentShellHook;

  # Worktree support
  inherit (worktree) generateSubtreeFlakeContent worktreeShellHook subtreeShellHook worktreeScripts mkWorktreeScripts mkWorktreeSource;

  # Utility functions (exposed for advanced usage)
  inherit utils validate;
}
