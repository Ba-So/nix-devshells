# MCP configuration generation
# Generates .mcp.json files from MCP modules
{
  pkgs,
  lib,
  filterByCategory,
}: rec {
  # Generate MCP configuration from modules
  # Returns a derivation containing the mcp.json file
  generateMcpConfig = modules: generateMcpConfigFiltered modules [];

  # Generate MCP configuration excluding specific servers by name
  # excludeNames is a list of module names to exclude (e.g., ["claude-task-master"])
  generateMcpConfigFiltered = modules: excludeNames: let
    # Filter to only MCP modules
    mcpModules = filterByCategory "mcp" modules;

    # Filter out excluded modules by name
    filteredModules =
      builtins.filter
      (m: !(builtins.elem (m.meta.name or "") excludeNames))
      mcpModules;

    # Extract mcpConfig from each module
    configs = map (m: m.mcpConfig or {}) filteredModules;

    # Merge all configs (later configs override earlier ones)
    mergedConfig = lib.foldl (a: b: a // b) {} configs;

    # Generate JSON content
    jsonContent = builtins.toJSON {mcpServers = mergedConfig;};
  in
    # Write to a file in the Nix store
    pkgs.writeText "mcp.json" jsonContent;

  # Generate MCP configs for worktree setup
  # Returns attrset with orchestrator (all MCPs) and shared (without task-master)
  generateWorktreeMcpConfigs = modules: {
    orchestrator = generateMcpConfig modules;
    shared = generateMcpConfigFiltered modules ["claude-task-master"];
  };

  # Generate shellHook snippet for MCP config setup
  # Includes smart merging to preserve user customizations
  mcpConfigShellHook = mcpConfigFile: ''
    # MCP configuration setup
    if [ -f .mcp.json ]; then
      # Merge with existing config (user customizations preserved)
      if command -v ${pkgs.jq}/bin/jq &> /dev/null; then
        ${pkgs.jq}/bin/jq -s '.[0] * .[1]' .mcp.json ${mcpConfigFile} > .mcp.json.new 2>/dev/null || {
          echo "Warning: Failed to merge .mcp.json, keeping existing file"
          rm -f .mcp.json.new
        }
        [ -f .mcp.json.new ] && mv .mcp.json.new .mcp.json && echo "✓ Updated .mcp.json with devshell MCP servers"
      else
        echo "Note: jq not available, keeping existing .mcp.json"
      fi
    else
      # Create new config file
      cp ${mcpConfigFile} .mcp.json
      chmod u+w .mcp.json
      echo "✓ Generated .mcp.json with MCP servers: $(${pkgs.jq}/bin/jq -r '.mcpServers | keys | join(", ")' ${mcpConfigFile})"
    fi

    # Normalize formatting to match prettier (pre-commit hook) so the
    # generated file doesn't dirty the working tree on every shell entry.
    if [ -f .mcp.json ]; then
      ${pkgs.nodePackages.prettier}/bin/prettier --write --log-level=warn .mcp.json >/dev/null 2>&1 || true
    fi
  '';
}
