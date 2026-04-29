# opencode harness adapter
# Renders MCP config to opencode.json (under top-level "mcp" key) and agents to .opencode/agents/
#
# Schema differences from Claude:
#   - top-level key "mcp" (not "mcpServers")
#   - per-server: type "local"|"remote", command is a single array (cmd + args), env -> environment
#   - agent frontmatter: mode (subagent|primary|all), model is provider/id, tools is a permission map
{
  pkgs,
  lib,
}: let
  # Translate Claude tool names to opencode permission keys.
  # Tools not in this map are dropped (opencode only knows its own tool set).
  toolMap = {
    Write = "write";
    Edit = "edit";
    Read = "read";
    Bash = "bash";
    Grep = "grep";
    Glob = "glob";
    WebFetch = "webfetch";
  };

  mapTools = tools:
    lib.foldl (
      acc: t:
        if toolMap ? ${t}
        then acc // {${toolMap.${t}} = true;}
        else acc
    ) {}
    tools;

  # Translate a Claude-shape MCP entry to an opencode-shape entry.
  toOpencodeMcp = entry: let
    cmd = entry.command or "";
    args = entry.args or [];
    base = {
      type = "local";
      command = [cmd] ++ args;
      enabled = true;
    };
  in
    base
    // (
      if entry ? env
      then {environment = entry.env;}
      else {}
    );
in rec {
  name = "opencode";
  mcpFile = "opencode.json";
  agentDir = ".opencode/agents";

  renderMcpConfig = mcpModules: let
    configs = map (m: m.mcpConfig or {}) mcpModules;
    mergedClaude = lib.foldl (a: b: a // b) {} configs;
    mappedMcp = lib.mapAttrs (_: toOpencodeMcp) mergedClaude;
    jsonContent = builtins.toJSON {
      "$schema" = "https://opencode.ai/config.json";
      mcp = mappedMcp;
    };
  in
    pkgs.writeText "opencode.json" jsonContent;

  renderAgent = {
    name,
    description,
    model,
    tools,
    body,
    ...
  }: let
    mappedTools = mapTools tools;
    # opencode wants fully qualified models (provider/id). If the canonical
    # model is a bare alias like "sonnet"/"opus"/"haiku", omit it and let
    # opencode fall back to its configured default.
    isFullyQualified = builtins.match ".+/.+" model != null;

    # Naive YAML serialization — matches the Claude renderer's level of escaping
    # (callers are expected to keep description on a single line).
    yamlScalar = v:
      if builtins.isBool v
      then
        (
          if v
          then "true"
          else "false"
        )
      else if builtins.isString v
      then v
      else builtins.toJSON v;

    renderField = key: val:
      if builtins.isAttrs val
      then
        "${key}:\n"
        + lib.concatStringsSep "\n"
        (lib.mapAttrsToList (k: v: "  ${k}: ${yamlScalar v}") val)
      else "${key}: ${yamlScalar val}";

    fields =
      {
        inherit description;
        mode = "subagent";
      }
      // (
        if isFullyQualified
        then {inherit model;}
        else {}
      )
      // (
        if mappedTools != {}
        then {tools = mappedTools;}
        else {}
      );

    frontmatter = lib.concatStringsSep "\n" (lib.mapAttrsToList renderField fields);

    agentMarkdown = ''
      ---
      ${frontmatter}
      ---

      ${body}
    '';
  in
    pkgs.writeText "${name}.md" agentMarkdown;

  mcpDeployHook = mcpConfigFile: ''
    # MCP configuration setup (opencode harness)
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
      echo "✓ Generated ${mcpFile} with MCP servers: $(${pkgs.jq}/bin/jq -r '.mcp | keys | join(", ")' ${mcpConfigFile})"
    fi

    if [ -f ${mcpFile} ]; then
      ${pkgs.nodePackages.prettier}/bin/prettier --write --log-level=warn ${mcpFile} >/dev/null 2>&1 || true
    fi
  '';
}
