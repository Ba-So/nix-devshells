# GitLab MCP server - GitLab API integration
{
  pkgs,
  lib,
  devPkgs,
  mkMcpModule,
}:
mkMcpModule {
  name = "gitlab";
  description = "GitLab API integration";
  package = devPkgs.mcp-gitlab;
  command = "mcp-gitlab";
  env = {
    GITLAB_PERSONAL_ACCESS_TOKEN = "";
    GITLAB_API_URL = "https://gitlab.com/api/v4";
  };
  emoji = "🦊";
}
