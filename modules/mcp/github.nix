# GitHub MCP server - GitHub API integration
{
  pkgs,
  lib,
  devPkgs,
}: {
  meta = {
    name = "github";
    description = "GitHub API integration";
    category = "mcp";
  };

  packages = [pkgs.github-mcp-server];

  mcpConfig = {
    github = {
      type = "stdio";
      command = "github-mcp-server";
      args = ["stdio"];
      env = {
        GITHUB_PERSONAL_ACCESS_TOKEN = "";
      };
    };
  };

  shellHook = ''
    echo "  GitHub: GitHub API integration"
  '';
}
