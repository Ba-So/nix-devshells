# Agent configuration deployment
# Syncs agent markdown definitions from lib/agents/ into .claude/agents/
{
  pkgs,
  lib,
}: rec {
  # Collect all agent markdown files from a directory
  # Returns a list of { name, path } attrsets
  collectAgents = agentDir: let
    contents = builtins.readDir agentDir;
    mdFiles =
      lib.filterAttrs
      (name: type: type == "regular" && lib.hasSuffix ".md" name)
      contents;
  in
    lib.mapAttrsToList
    (name: _: {
      name = lib.removeSuffix ".md" name;
      path = agentDir + "/${name}";
    })
    mdFiles;

  # Generate a derivation containing agent files ready for deployment
  # agents: list of { name, path } attrsets
  generateAgentConfig = agents:
    pkgs.runCommand "claude-agents" {} (
      ''
        mkdir -p $out
      ''
      + lib.concatMapStringsSep "\n" (agent: ''
        cp ${agent.path} $out/${agent.name}.md
      '')
      agents
    );

  # Generate shellHook snippet for agent deployment
  # Syncs agent files into .claude/agents/, tracking managed agents
  # to avoid clobbering user-added agents
  agentConfigShellHook = agentConfigDir: ''
    # Agent configuration setup
    _claude_agents_dir=".claude/agents"
    _managed_marker="$_claude_agents_dir/.devshell-managed"
    mkdir -p "$_claude_agents_dir"

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
      cp "$agent_file" "$_claude_agents_dir/$_agent_name"
      _current_managed="$_current_managed$_agent_name"$'\n'
    done

    # Remove agents that were previously managed but are no longer in the devshell
    if [ -n "$_prev_managed" ]; then
      while IFS= read -r _old_agent; do
        [ -z "$_old_agent" ] && continue
        if ! echo "$_current_managed" | ${pkgs.gnugrep}/bin/grep -qF "$_old_agent"; then
          rm -f "$_claude_agents_dir/$_old_agent"
        fi
      done <<< "$_prev_managed"
    fi

    # Write current managed list
    echo "$_current_managed" > "$_managed_marker"

    # Summary
    _agent_count=$(echo -n "$_current_managed" | ${pkgs.gnugrep}/bin/grep -c '.' 2>/dev/null || echo 0)
    if [ "$_agent_count" -gt 0 ]; then
      echo "  🤖 Synced $_agent_count agent(s) to .claude/agents/"
    fi
  '';
}
