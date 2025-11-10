# Full preset - All available tools and MCP servers
# Includes standard preset + remaining language-specific MCP servers
{
  pkgs,
  lib,
  modules,
}: let
  # Inherit from standard preset
  standardPreset = modules.presets.standard;

  # Additional MCP servers not in standard
  additionalModules = [
    modules.mcp.cargo-mcp # Rust Cargo operations
    modules.mcp.puppeteer # Browser automation
    modules.mcp.cratedocs # Rust documentation
  ];

  # Combine standard packages with additional packages
  allPackages =
    standardPreset.packages
    ++ (lib.flatten (map (m: m.packages or []) additionalModules));

  # Merge shellHooks from standard and additional modules
  allShellHooks =
    standardPreset.shellHook
    + "\n"
    + (lib.concatStringsSep "\n" (map (m: m.shellHook or "") additionalModules));
in {
  meta = {
    name = "full";
    description = "All available tools and MCP servers";
    category = "preset";
  };

  # Combined packages from standard + additional
  packages = allPackages;

  # Combined shellHooks
  shellHook = allShellHooks;

  # Track all included modules (standard + additional)
  includes = standardPreset.includes ++ additionalModules;
}
