# Universal Screenshot MCP server - Web and system screenshots
{
  pkgs,
  lib,
  devPkgs,
  mkMcpModule,
}:
mkMcpModule {
  name = "universal-screenshot";
  description = "Cross-platform screenshot MCP server (web + system)";
  package = devPkgs.universal-screenshot-mcp;
  configName = "screenshot-server";
  emoji = "📸";
}
