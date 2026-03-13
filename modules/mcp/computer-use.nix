# Computer Use MCP server - Desktop automation (screenshots, mouse, keyboard)
{
  pkgs,
  lib,
  devPkgs,
}: {
  meta = {
    name = "computer-use";
    description = "Desktop automation MCP server (screenshots, mouse, keyboard)";
    category = "mcp";
  };

  packages = [devPkgs.computer-use-mcp];

  mcpConfig = {
    computer-use = {
      type = "stdio";
      command = "computer-use-mcp";
      args = [];
    };
  };

  shellHook = ''
    echo "  🖥️  computer-use: Desktop automation (X11)"
  '';
}
