# Shrimp MCP server - AI-powered task management system
{
  pkgs,
  lib,
  devPkgs,
  mkMcpModule,
}:
mkMcpModule {
  name = "shrimp";
  description = "AI-powered task management system";
  package = devPkgs.mcp-shrimp-task-manager;
  command = "mcp-shrimp-task-manager";
  env = {
    DATA_DIR = ".shrimp";
    TEMPLATES_USE = "en";
    ENABLE_GUI = "true";
    MCP_PROMPT_EXECUTE_TASK_APPEND = "Validation: Add that pre-commit hooks must pass and progress must be committed.";
  };
  emoji = "🦐";
}
