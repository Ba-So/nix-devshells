# Serena MCP server - Project analysis and code intelligence
{
  pkgs,
  lib,
  serena,
  mkMcpModule,
}:
mkMcpModule {
  name = "serena";
  description = "Project analysis MCP server";
  package = serena;
  args = ["start-mcp-server" "--transport" "stdio" "--project" "."];
  env = {};
  languages = ["python" "cpp" "rust"];
  emoji = "🔍";
}
