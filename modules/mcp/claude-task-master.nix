# Claude Task Master MCP server - AI-powered task management system
{
  pkgs,
  lib,
  devPkgs,
}: {
  meta = {
    name = "claude-task-master";
    description = "AI-powered task management system for AI-driven development";
    category = "mcp";
  };

  packages = [devPkgs.claude-task-master];

  mcpConfig = {
    "claude-task-master" = {
      type = "stdio";
      command = "task-master-mcp";
      args = [];
      env = {
        # Use .taskmaster directory for project data
        TASKMASTER_DIR = ".taskmaster";

        # Claude Code integration - uses claude-cli approach automatically
        # The package is configured to work with Claude Code without API keys
        # See: https://github.com/eyaltoledano/claude-task-master/blob/main/docs/examples/claude-code-usage.md
      };
    };
  };

  shellHook = ''
    echo "  🎯 claude-task-master: AI-powered task management (npm-based)"
  '';
}
