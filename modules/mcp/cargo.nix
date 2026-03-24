# Cargo MCP server - Safe Cargo operations for Rust projects
{
  pkgs,
  lib,
  devPkgs,
  mkMcpModule,
}:
mkMcpModule {
  name = "cargo-mcp";
  description = "Safe Cargo operations for Rust projects";
  package = devPkgs.cargo-mcp;
  configName = "cargo";
  languages = ["rust"];
  emoji = "📦";
}
