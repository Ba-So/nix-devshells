# Claude Code harness adapter
# Renders MCP config to .mcp.json ({mcpServers: {...}}) and agents to .claude/agents/
{
  pkgs,
  lib,
}: rec {
  name = "claude";
  mcpFile = ".mcp.json";
  agentDir = ".claude/agents";

  # Render MCP config from a list of mcp module attrsets.
  # Returns a derivation containing the mcp.json file.
  renderMcpConfig = mcpModules: let
    configs = map (m: m.mcpConfig or {}) mcpModules;
    merged = lib.foldl (a: b: a // b) {} configs;
    jsonContent = builtins.toJSON {mcpServers = merged;};
  in
    pkgs.writeText "mcp.json" jsonContent;

  # Render canonical agent attrset to a markdown file with Claude-format frontmatter.
  renderAgent = {
    name,
    description,
    model,
    tools,
    body,
    ...
  }: let
    toolsString = builtins.concatStringsSep ", " tools;
    agentMarkdown = ''
      ---
      name: ${name}
      description: ${description}
      model: ${model}
      tools: ${toolsString}
      ---

      ${body}
    '';
  in
    pkgs.writeText "${name}.md" agentMarkdown;

  # Hook to deploy the rendered MCP config (preserves user customizations via jq merge).
  mcpDeployHook = mcpConfigFile: ''
    # MCP configuration setup (claude harness)
    if [ -f ${mcpFile} ]; then
      if command -v ${pkgs.jq}/bin/jq &> /dev/null; then
        ${pkgs.jq}/bin/jq -s '.[0] * .[1]' ${mcpFile} ${mcpConfigFile} > ${mcpFile}.new 2>/dev/null || {
          echo "Warning: Failed to merge ${mcpFile}, keeping existing file"
          rm -f ${mcpFile}.new
        }
        [ -f ${mcpFile}.new ] && mv ${mcpFile}.new ${mcpFile} && echo "✓ Updated ${mcpFile} with devshell MCP servers"
      else
        echo "Note: jq not available, keeping existing ${mcpFile}"
      fi
    else
      cp ${mcpConfigFile} ${mcpFile}
      chmod u+w ${mcpFile}
      echo "✓ Generated ${mcpFile} with MCP servers: $(${pkgs.jq}/bin/jq -r '.mcpServers | keys | join(", ")' ${mcpConfigFile})"
    fi

    if [ -f ${mcpFile} ]; then
      ${pkgs.nodePackages.prettier}/bin/prettier --write --log-level=warn ${mcpFile} >/dev/null 2>&1 || true
    fi
  '';
}
