# MCP configuration generation.
# Selects MCP modules and delegates rendering/deployment to the harness adapter.
{
  pkgs,
  lib,
  filterByCategory,
  harness,
}: rec {
  # Generate MCP configuration from modules
  generateMcpConfig = modules: generateMcpConfigFiltered modules [];

  # Generate MCP configuration excluding specific servers by name
  # excludeNames is a list of module names to exclude (e.g., ["claude-task-master"])
  generateMcpConfigFiltered = modules: excludeNames: let
    mcpModules = filterByCategory "mcp" modules;
    filteredModules =
      builtins.filter
      (m: !(builtins.elem (m.meta.name or "") excludeNames))
      mcpModules;
  in
    harness.renderMcpConfig filteredModules;

  # Generate MCP configs for worktree setup (claude-only feature, see compose.nix).
  # Returns attrset with orchestrator (all MCPs) and shared (without task-master).
  generateWorktreeMcpConfigs = modules: {
    orchestrator = generateMcpConfig modules;
    shared = generateMcpConfigFiltered modules ["claude-task-master"];
  };

  # Generate shellHook snippet for MCP config setup.
  mcpConfigShellHook = mcpConfigFile: harness.mcpDeployHook mcpConfigFile;
}
