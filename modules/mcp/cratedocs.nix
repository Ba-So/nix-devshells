# CrateDocs MCP server - Rust documentation search
{
  pkgs,
  lib,
  devPkgs,
  mkMcpModule,
}:
mkMcpModule {
  name = "cratedocs";
  description = "Rust documentation MCP server";
  package = devPkgs.cratedocs-mcp;
  languages = ["rust"];
  emoji = "📚";
}
