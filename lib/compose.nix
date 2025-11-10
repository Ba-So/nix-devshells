# Shell composition functions
# High-level and low-level APIs for composing development shells
{
  pkgs,
  lib,
  system,
  inputs,
  modules,
  resolveModule,
  flattenPackages,
  mergeShellHooks,
  mergeEnv,
  validateModule,
  validateModules,
}: let
  # Import MCP config generation
  mcpLib = import ./mcp.nix {
    inherit pkgs lib;
    filterByCategory = moduleList:
      builtins.filter (m: (m.meta.category or "") == "mcp") moduleList;
  };

  # Resolve tools parameter (string or attrset)
  resolveTools = tools:
    if builtins.isString tools
    then
      # Simple preset name like "minimal", "standard", "full"
      [
        (resolveModule tools "presets")
      ]
    else if builtins.isAttrs tools && tools ? preset
    then let
      # Advanced config: { preset = "minimal"; include = ["helix"]; }
      preset = resolveModule tools.preset "presets";
      included =
        if tools ? include
        then map (name: resolveModule name "tools") tools.include
        else [];
    in
      [preset] ++ included
    else throw "tools parameter must be a string (preset name) or attrset with 'preset' field";
in rec {
  # High-level composition API
  # Usage: composeShell { languages = ["rust" "python"]; mcps = ["cargo"]; tools = "standard"; }
  composeShell = {
    languages ? [],
    mcps ? [],
    tools ? "standard",
    extraPackages ? [],
    extraShellHook ? "",
    ...
  }: let
    # Resolve language modules
    langModules =
      if languages != []
      then map (name: resolveModule name "languages") languages
      else [];

    # Resolve MCP modules
    mcpModules =
      if mcps != []
      then map (name: resolveModule name "mcp") mcps
      else [];

    # Resolve tool modules/presets
    toolModules = resolveTools tools;

    # Combine all modules
    allModules = langModules ++ mcpModules ++ toolModules;

    # Compose base shell from modules
    baseShell = composeShellFromModules allModules;
  in
    # Extend with extra packages and hooks
    baseShell.overrideAttrs (old: {
      buildInputs = old.buildInputs ++ extraPackages;
      shellHook = old.shellHook + "\n" + extraShellHook;
    });

  # Low-level composition API
  # Usage: composeShellFromModules [ module1 module2 module3 ]
  composeShellFromModules = moduleList: let
    # Validate all modules
    validatedModules = validateModules moduleList;

    # Collect packages from all modules
    allPackages = flattenPackages validatedModules;

    # Merge shellHooks from all modules
    combinedShellHooks = mergeShellHooks validatedModules;

    # Merge environment variables
    envVars = mergeEnv validatedModules;

    # Generate MCP configuration if any MCP modules present
    mcpModules = builtins.filter (m: (m.meta.category or "") == "mcp") validatedModules;
    hasMcpModules = mcpModules != [];

    mcpConfigFile =
      if hasMcpModules
      then mcpLib.generateMcpConfig validatedModules
      else null;

    mcpSetupHook =
      if hasMcpModules
      then mcpLib.mcpConfigShellHook mcpConfigFile
      else "";

    # Combine all shellHooks with MCP setup
    finalShellHook = ''
      ${combinedShellHooks}

      ${mcpSetupHook}
    '';
  in
    # Create the devShell using pkgs.mkShell
    pkgs.mkShell ({
        buildInputs = allPackages;
        shellHook = finalShellHook;
      }
      // envVars);

  # Helper function to extend an existing shell
  # Usage: extendShell baseShell { extraPackages = [ pkgs.postgresql ]; }
  extendShell = baseShell: {
    extraPackages ? [],
    extraShellHook ? "",
    ...
  }:
    baseShell.overrideAttrs (old: {
      buildInputs = (old.buildInputs or []) ++ extraPackages;
      shellHook = (old.shellHook or "") + "\n" + extraShellHook;
    });
}
