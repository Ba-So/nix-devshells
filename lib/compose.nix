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
  filterByCategory,
  validateModule,
  validateModules,
  deduplicateModules,
}: let
  # Import MCP config generation
  mcpLib = import ./mcp.nix {
    inherit pkgs lib filterByCategory;
  };

  # Import agent deployment
  agentLib = import ./agents.nix {
    inherit pkgs lib;
  };

  # Import worktree support
  worktreeLib = import ./worktree {
    inherit pkgs lib system;
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

  # Get tools string for worktree flake generation
  toolsToString = tools:
    if builtins.isString tools
    then tools
    else if builtins.isAttrs tools && tools ? preset
    then tools.preset
    else "standard";
  # RTK initialization hook (transparent token compression for LLM CLI tools)
  rtkInitHook = ''
    # Initialize RTK for transparent token compression
    if command -v rtk &> /dev/null; then
      eval "$(rtk init 2>/dev/null)" || true
    fi
  '';
in rec {
  # High-level composition API
  # Usage: composeShell { languages = ["rust" "python"]; mcps = ["cargo"]; tools = "standard"; }
  # type: "standard" (default), "worktree" (orchestrator), or "subtree" (worker)
  # enableRtk: when true, automatically initializes RTK hooks for token compression
  composeShell = {
    languages ? [],
    mcps ? [],
    tools ? "standard",
    type ? "standard",
    extraPackages ? [],
    extraShellHook ? "",
    devshellsUrl ? "github:Ba-So/nix-devshells",
    enableRtk ? false,
    ...
  }: let
    # Resolve language modules
    langModules =
      if languages != []
      then map (name: resolveModule name "languages") languages
      else [];

    # Resolve MCP modules (for subtree, filter out task-master)
    effectiveMcps =
      if type == "subtree"
      then builtins.filter (m: m != "claude-task-master") mcps
      else mcps;

    mcpModules =
      if effectiveMcps != []
      then map (name: resolveModule name "mcp") effectiveMcps
      else [];

    # Resolve tool modules/presets
    toolModules = resolveTools tools;

    # Combine all modules and deduplicate by name
    # This prevents loading the same module multiple times
    # (e.g., when an MCP is in both the explicit list and a preset)
    allModules = deduplicateModules (langModules ++ mcpModules ++ toolModules);

    # Include all agent modules by default, filtered by active MCP dependencies
    activeMcpNames = map (m: m.meta.name or "") mcpModules;
    allAgentModules = builtins.attrValues (modules.agents or {});
    filteredAgents = agentLib.filterAgentsByMcps allAgentModules activeMcpNames;

    # Compose base shell from modules with type-specific behavior
    baseShell =
      if type == "worktree"
      then
        composeWorktreeShell {
          inherit allModules languages mcps tools devshellsUrl enableRtk;
          agents = filteredAgents;
        }
      else if type == "subtree"
      then composeSubtreeShell {inherit allModules enableRtk; agents = filteredAgents;}
      else composeShellFromModules {inherit allModules enableRtk; agents = filteredAgents;};
  in
    # Extend with extra packages and hooks
    baseShell.overrideAttrs (old: {
      buildInputs = old.buildInputs ++ extraPackages;
      shellHook = old.shellHook + "\n" + extraShellHook;
    });

  # Compose shell for worktree mode (orchestrator)
  # Sets up .shared/ and .orchestrator/ directories, generates subtree flake
  # Uses sibling worktree pattern - main repo is orchestrator, worktrees are siblings
  composeWorktreeShell = {
    allModules,
    languages,
    mcps,
    agents ? [],
    tools,
    devshellsUrl,
    enableRtk ? false,
  }: let
    # Validate all modules
    validatedModules = validateModules allModules;

    # Create worktree scripts
    worktreeScriptsConfigured = worktreeLib.mkWorktreeScripts {};

    # Collect packages from all modules (plus worktree scripts)
    allPackages = flattenPackages validatedModules ++ [worktreeScriptsConfigured];

    # Merge shellHooks from all modules
    combinedShellHooks = mergeShellHooks validatedModules;

    # Merge environment variables
    envVars = mergeEnv validatedModules;

    # Generate both MCP configs (orchestrator with task-master, shared without)
    mcpConfigs = mcpLib.generateWorktreeMcpConfigs validatedModules;

    # Generate worktree setup hook
    worktreeHook = worktreeLib.worktreeShellHook {
      mcpConfigOrchestrator = mcpConfigs.orchestrator;
      mcpConfigShared = mcpConfigs.shared;
      inherit languages mcps devshellsUrl;
      tools = toolsToString tools;
    };

    # Agent deployment hook (agents are pre-filtered module attrsets)
    agentHook = agentLib.mkAgentShellHook agents;

    # RTK hook if enabled
    rtkHook =
      if enableRtk
      then rtkInitHook
      else "";

    # Combine all shellHooks with worktree setup
    finalShellHook = ''
      ${combinedShellHooks}

      # Worktree mode setup
      echo "Setting up worktree mode..."
      ${worktreeHook}
      ${agentHook}
      ${rtkHook}
    '';
  in
    # Create the devShell using pkgs.mkShell
    pkgs.mkShell ({
        buildInputs = allPackages;
        shellHook = finalShellHook;
      }
      // envVars);

  # Compose shell for subtree mode (worker agents)
  # Minimal setup - just sets CODANNA_INDEX_DIR
  composeSubtreeShell = {
    allModules,
    agents ? [],
    enableRtk ? false,
  }: let
    # Validate all modules
    validatedModules = validateModules allModules;

    # Collect packages from all modules
    allPackages = flattenPackages validatedModules;

    # Merge shellHooks from all modules
    combinedShellHooks = mergeShellHooks validatedModules;

    # Merge environment variables
    envVars = mergeEnv validatedModules;

    # Generate MCP configuration (without task-master, already filtered in composeShell)
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

    # Agent deployment hook (agents are pre-filtered module attrsets)
    agentHook = agentLib.mkAgentShellHook agents;

    # RTK hook if enabled
    rtkHook =
      if enableRtk
      then rtkInitHook
      else "";

    # Combine all shellHooks with subtree setup
    finalShellHook = ''
      ${combinedShellHooks}

      # Subtree mode setup (worker agent)
      ${worktreeLib.subtreeShellHook}

      ${mcpSetupHook}
      ${agentHook}
      ${rtkHook}
    '';
  in
    # Create the devShell using pkgs.mkShell
    pkgs.mkShell ({
        buildInputs = allPackages;
        shellHook = finalShellHook;
      }
      // envVars);

  # Low-level composition API
  # Usage: composeShellFromModules { allModules = [ module1 module2 module3 ]; }
  composeShellFromModules = {
    allModules,
    agents ? [],
    enableRtk ? false,
  }: let
    # Validate all modules
    validatedModules = validateModules allModules;

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

    # Agent deployment hook (agents are pre-filtered module attrsets)
    agentHook = agentLib.mkAgentShellHook agents;

    # RTK hook if enabled
    rtkHook =
      if enableRtk
      then rtkInitHook
      else "";

    # Combine all shellHooks with MCP setup
    finalShellHook = ''
      ${combinedShellHooks}

      ${mcpSetupHook}
      ${agentHook}
      ${rtkHook}
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
