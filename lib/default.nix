# Module system public API
# Main entry point for the devshell module system
{
  pkgs,
  system,
  inputs,
  ...
}: let
  inherit (pkgs) lib;

  # Import validation and utility functions
  validate = import ./validate.nix {inherit lib;};

  # Import modules from various categories
  # These will be populated as modules are created
  languageModules =
    if builtins.pathExists ../modules/languages
    then import ../modules/languages {inherit pkgs inputs lib;}
    else {};

  toolModules =
    if builtins.pathExists ../modules/tools
    then import ../modules/tools {inherit pkgs lib;}
    else {};

  mcpModules =
    if builtins.pathExists ../modules/mcp
    then import ../modules/mcp {inherit pkgs lib;}
    else {};

  presetModules =
    if builtins.pathExists ../modules/presets
    then import ../modules/presets {inherit pkgs lib;}
    else {};

  # Consolidated modules attrset
  modules = {
    languages = languageModules;
    tools = toolModules;
    mcp = mcpModules;
    presets = presetModules;
  };

  # Import utility functions (with modules passed for resolution)
  utils = import ./utils.nix {
    inherit lib modules;
  };

  # Import composition functions (will be created in Task 2)
  compose =
    if builtins.pathExists ./compose.nix
    then
      import ./compose.nix {
        inherit pkgs lib system inputs modules;
        inherit (utils) resolveModule flattenPackages mergeShellHooks mergeEnv;
        inherit (validate) validateModule validateModules;
      }
    else {
      # Placeholder until compose.nix is created
      composeShell = _: throw "compose.nix not yet implemented (Task 2)";
      composeShellFromModules = _: throw "compose.nix not yet implemented (Task 2)";
    };

  # Import MCP config generation (will be created in Task 2)
  mcp =
    if builtins.pathExists ./mcp.nix
    then
      import ./mcp.nix {
        inherit pkgs lib;
        inherit (utils) filterByCategory;
      }
    else {
      # Placeholder until mcp.nix is created
      generateMcpConfig = _: throw "mcp.nix not yet implemented (Task 2)";
    };
in {
  # Public API exports
  inherit modules;

  # Composition functions
  inherit (compose) composeShell composeShellFromModules;

  # MCP configuration
  inherit (mcp) generateMcpConfig;

  # Utility functions (exposed for advanced usage)
  inherit utils validate;
}
