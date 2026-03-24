# Puppeteer MCP server - Browser automation
{
  pkgs,
  lib,
  devPkgs,
  mkMcpModule,
}:
mkMcpModule {
  name = "puppeteer";
  description = "Browser automation MCP server";
  package = devPkgs.puppeteer-mcp-server;
  command = "mcp-server-puppeteer";
  emoji = "🎭";
}
