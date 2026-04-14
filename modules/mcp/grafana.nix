# Grafana MCP server - Model Context Protocol server for Grafana
{
  pkgs,
  lib,
  devPkgs,
  mkMcpModule,
}:
mkMcpModule {
  name = "mcp-grafana";
  description = "MCP server for Grafana observability platform";
  package = devPkgs.mcp-grafana;
  configName = "grafana";
  emoji = "📊";
}
