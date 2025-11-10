# GitLab MCP server - GitLab API integration
{
  pkgs,
  lib,
  devPkgs,
}: {
  meta = {
    name = "gitlab";
    description = "GitLab API integration";
    category = "mcp";
  };

  packages = [devPkgs.mcp-gitlab];

  mcpConfig = {
    gitlab = {
      type = "stdio";
      command = "mcp-gitlab";
      args = [];
      env = {
        GITLAB_PERSONAL_ACCESS_TOKEN = "";
        GITLAB_API_URL = "https://gitlab.com/api/v4";
      };
    };
  };

  shellHook = ''
    echo "  🦊 gitlab: GitLab API integration"
  '';
}
