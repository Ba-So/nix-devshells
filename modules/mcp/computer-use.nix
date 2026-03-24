# Computer Use MCP server - Desktop automation (screenshots, mouse, keyboard)
{
  pkgs,
  lib,
  devPkgs,
  mkMcpModule,
}:
mkMcpModule {
  name = "computer-use";
  description = "Desktop automation MCP server (screenshots, mouse, keyboard)";
  package = devPkgs.computer-use-mcp;
  emoji = "🖥️ ";
}
