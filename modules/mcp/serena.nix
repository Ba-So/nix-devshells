# Serena MCP server - Project analysis and code intelligence
{
  pkgs,
  lib,
  serena,
}: {
  meta = {
    name = "serena";
    description = "Project analysis MCP server";
    category = "mcp";
    languages = ["python" "cpp" "rust"];
  };

  packages = [serena];

  mcpConfig = {
    serena = {
      type = "stdio";
      command = "serena";
      args = ["start-mcp-server" "--transport" "stdio" "--project" "."];
      env = {};
    };
  };

  shellHook = ''
    echo "  🔍 serena: Project analysis and code intelligence"
  '';
}
