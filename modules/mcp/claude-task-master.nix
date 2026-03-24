# Claude Task Master MCP server - AI-powered task management system
{
  pkgs,
  lib,
  devPkgs,
  mkMcpModule,
}: let
  module = mkMcpModule {
    name = "claude-task-master";
    description = "AI-powered task management system for AI-driven development";
    package = devPkgs.claude-task-master;
    command = "task-master-mcp";
    env = {
      TASKMASTER_DIR = ".taskmaster";
    };
    emoji = "🎯";
  };
in
  module
  // {
    shellHook =
      module.shellHook
      + ''

        # Setup Task Master config with Nix-compatible claude-code defaults
        _setup_taskmaster_config() {
          local config_dir=".taskmaster"
          local config_file="$config_dir/config.json"
          local claude_path

          # Find claude executable
          claude_path="$(command -v claude 2>/dev/null || echo "")"
          if [ -z "$claude_path" ]; then
            echo "  ⚠️  claude-task-master: claude CLI not found, skipping config setup"
            return
          fi

          if [ -f "$config_file" ]; then
            # Config exists - check if it needs patching
            local needs_patch=false

            # Check for claudeCode.pathToClaudeCodeExecutable matching current path
            local current_path
            current_path=$(${pkgs.jq}/bin/jq -r '.claudeCode.pathToClaudeCodeExecutable // ""' "$config_file" 2>/dev/null)
            if [ "$current_path" != "$claude_path" ]; then
              needs_patch=true
            fi

            # Check if models are using claude-code provider
            if ! ${pkgs.jq}/bin/jq -e '.models.main.provider == "claude-code"' "$config_file" &>/dev/null; then
              needs_patch=true
            fi

            if [ "$needs_patch" = true ]; then
              local tmp
              tmp=$(mktemp)
              ${pkgs.jq}/bin/jq --arg path "$claude_path" '
                .models = {
                  "main": {"provider": "claude-code", "modelId": "sonnet", "maxTokens": 64000, "temperature": 0.2},
                  "research": {"provider": "claude-code", "modelId": "opus", "maxTokens": 32000, "temperature": 0.1},
                  "fallback": {"provider": "claude-code", "modelId": "sonnet", "maxTokens": 64000, "temperature": 0.2}
                } |
                .global = (.global // {}) * {
                  "logLevel": "info",
                  "debug": false,
                  "defaultNumTasks": 10,
                  "defaultSubtasks": 5,
                  "defaultPriority": "medium",
                  "projectName": (.global.projectName // "Task Master"),
                  "ollamaBaseURL": "http://localhost:11434/api",
                  "bedrockBaseURL": "https://bedrock.us-east-1.amazonaws.com",
                  "responseLanguage": "English",
                  "enableCodebaseAnalysis": true,
                  "enableProxy": false,
                  "anonymousTelemetry": true,
                  "userId": (.global.userId // "")
                } |
                .claudeCode.pathToClaudeCodeExecutable = $path
              ' "$config_file" > "$tmp" && \
                mv "$tmp" "$config_file" && \
                echo "  ✓ Patched $config_file with claude-code defaults"
            fi
          fi
        }
        _setup_taskmaster_config

        # Wrapper for task-master init that applies Nix-specific defaults
        task-master-init() {
          command task-master init "$@"
          local config_file=".taskmaster/config.json"
          if [ -f "$config_file" ]; then
            local claude_path
            claude_path="$(command -v claude 2>/dev/null || echo "")"
            if [ -n "$claude_path" ]; then
              local tmp
              tmp=$(mktemp)
              ${pkgs.jq}/bin/jq --arg path "$claude_path" '
                .models = {
                  "main": {"provider": "claude-code", "modelId": "sonnet", "maxTokens": 64000, "temperature": 0.2},
                  "research": {"provider": "claude-code", "modelId": "opus", "maxTokens": 32000, "temperature": 0.1},
                  "fallback": {"provider": "claude-code", "modelId": "sonnet", "maxTokens": 64000, "temperature": 0.2}
                } |
                .global = (.global // {}) * {
                  "logLevel": "info",
                  "debug": false,
                  "defaultNumTasks": 10,
                  "defaultSubtasks": 5,
                  "defaultPriority": "medium",
                  "projectName": (.global.projectName // "Task Master"),
                  "ollamaBaseURL": "http://localhost:11434/api",
                  "bedrockBaseURL": "https://bedrock.us-east-1.amazonaws.com",
                  "responseLanguage": "English",
                  "enableCodebaseAnalysis": true,
                  "enableProxy": false,
                  "anonymousTelemetry": true,
                  "userId": (.global.userId // "")
                } |
                .claudeCode.pathToClaudeCodeExecutable = $path
              ' "$config_file" > "$tmp" && mv "$tmp" "$config_file"
              echo "✓ Applied Nix claude-code defaults to $config_file"
            fi
          fi
        }
      '';
  }
