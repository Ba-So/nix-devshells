# Cargo MCP server - Safe Cargo operations for Rust projects
{
  pkgs,
  lib,
  devPkgs,
}: {
  meta = {
    name = "cargo-mcp";
    description = "Safe Cargo operations for Rust projects";
    category = "mcp";
    languages = ["rust"];
  };

  packages = [devPkgs.cargo-mcp];

  mcpConfig = {
    cargo = {
      type = "stdio";
      command = "cargo-mcp";
      args = [];
    };
  };

  shellHook = ''
    echo "  📦 cargo-mcp: Safe Cargo operations"
  '';
}
