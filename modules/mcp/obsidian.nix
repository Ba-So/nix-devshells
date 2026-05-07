# Obsidian MCP server - Read/write/search Obsidian vaults via Local REST API plugin
{
  pkgs,
  lib,
  devPkgs,
  mkMcpModule,
}:
mkMcpModule {
  name = "obsidian-mcp";
  description = "Obsidian vault access via the Local REST API plugin";
  package = devPkgs.obsidian-mcp;
  command = "obsidian-mcp-server";
  configName = "obsidian";
  env = {
    OBSIDIAN_API_KEY = "";
    OBSIDIAN_BASE_URL = "http://127.0.0.1:27123";
    OBSIDIAN_VERIFY_SSL = "false";
    MCP_TRANSPORT_TYPE = "stdio";
  };
  emoji = "📓";
}
