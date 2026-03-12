# Universal Screenshot MCP server - Web and system screenshots
{
  pkgs,
  lib,
  devPkgs,
}: {
  meta = {
    name = "universal-screenshot";
    description = "Cross-platform screenshot MCP server (web + system)";
    category = "mcp";
  };

  packages = [devPkgs.universal-screenshot-mcp];

  mcpConfig = {
    screenshot-server = {
      type = "stdio";
      command = "universal-screenshot-mcp";
      args = [];
    };
  };

  shellHook = ''
    echo "  📸 universal-screenshot: Web and system screenshots"
  '';
}
