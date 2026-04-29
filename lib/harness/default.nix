# Harness adapters: per-AI-CLI conventions for MCP config and agent files.
#
# Each adapter exposes:
#   - name             : identifier ("claude", "opencode")
#   - mcpFile          : project-relative path to write MCP config to
#   - agentDir         : project-relative directory for agent markdown files
#   - renderMcpConfig  : list-of-mcp-modules -> derivation containing the config
#   - renderAgent      : canonical agent attrset -> derivation containing the .md file
#   - mcpDeployHook    : config-derivation -> shell snippet that installs it
{
  pkgs,
  lib,
}: {
  claude = import ./claude.nix {inherit pkgs lib;};
  opencode = import ./opencode.nix {inherit pkgs lib;};
}
