# Agent configuration deployment
# Filters agents by MCP dependencies and syncs to the active harness's agent dir.
{
  pkgs,
  lib,
  harness,
}: rec {
  # Filter agent modules to only those whose mcpDeps are satisfied
  # agentModules: list of agent module attrsets
  # activeMcpNames: list of MCP module name strings currently active
  filterAgentsByMcps = agentModules: activeMcpNames:
    builtins.filter
    (agent:
      builtins.all
      (dep: builtins.elem dep activeMcpNames)
      (agent.mcpDeps or []))
    agentModules;

  # Generate a derivation containing agent markdown files ready for deployment.
  # Each agent is rendered via the active harness adapter.
  generateAgentConfig = agents:
    pkgs.runCommand "${harness.name}-agents" {} (
      ''
        mkdir -p $out
      ''
      + lib.concatMapStringsSep "\n" (agent: ''
        cp ${harness.renderAgent agent} $out/${agent.meta.name}.md
      '')
      agents
    );

  # Convenience: generate shell hook from a list of agent modules (handles empty case)
  mkAgentShellHook = agents:
    if agents != []
    then agentConfigShellHook (generateAgentConfig agents)
    else "";

  # Generate shellHook snippet for agent deployment.
  # Syncs agent files into the harness's agent directory, tracking managed
  # agents to avoid clobbering user-added agents.
  agentConfigShellHook = agentConfigDir: ''
    # Agent configuration setup (${harness.name} harness)
    _agents_dir="${harness.agentDir}"
    _managed_marker="$_agents_dir/.devshell-managed"
    mkdir -p "$_agents_dir"

    # Read previously managed agents (if any)
    if [ -f "$_managed_marker" ]; then
      _prev_managed=$(cat "$_managed_marker")
    else
      _prev_managed=""
    fi

    # Sync agent files from devshell
    _current_managed=""
    for agent_file in ${agentConfigDir}/*.md; do
      [ -f "$agent_file" ] || continue
      _agent_name=$(basename "$agent_file")
      cp "$agent_file" "$_agents_dir/$_agent_name"
      _current_managed="$_current_managed$_agent_name"$'\n'
    done

    # Remove agents that were previously managed but are no longer in the devshell
    if [ -n "$_prev_managed" ]; then
      while IFS= read -r _old_agent; do
        [ -z "$_old_agent" ] && continue
        if ! echo "$_current_managed" | ${pkgs.gnugrep}/bin/grep -qF "$_old_agent"; then
          rm -f "$_agents_dir/$_old_agent"
        fi
      done <<< "$_prev_managed"
    fi

    # Write current managed list
    echo "$_current_managed" > "$_managed_marker"

    # Summary
    _agent_count=$(echo -n "$_current_managed" | ${pkgs.gnugrep}/bin/grep -c '.' 2>/dev/null || echo 0)
    if [ "$_agent_count" -gt 0 ]; then
      echo "  🤖 Synced $_agent_count agent(s) to $_agents_dir/"
    fi
  '';
}
