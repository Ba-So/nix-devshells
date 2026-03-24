# GitHub MCP server - GitHub API integration
{
  pkgs,
  lib,
  devPkgs,
  mkMcpModule,
}:
mkMcpModule {
  name = "github";
  description = "GitHub API integration";
  package = pkgs.github-mcp-server;
  command = "github-mcp-server";
  args = ["stdio"];
  env = {
    GITHUB_PERSONAL_ACCESS_TOKEN = "";
  };
}
