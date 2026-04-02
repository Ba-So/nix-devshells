# Factory function for creating agent modules with minimal boilerplate
#
# Usage:
#   mkAgentModule {
#     name = "rust-developer";
#     description = "Rust development specialist";
#     model = "sonnet";                        # haiku | sonnet | opus
#     tools = ["Write" "Read" "Bash" "Grep"];  # Claude Code tools
#     mcpDeps = ["cargo-mcp"];                 # required MCP module names
#     body = ''
#       You are a Rust specialist...
#     '';
#   }
{pkgs}: {
  name,
  description,
  model ? "sonnet",
  tools ? ["Write" "Read" "Edit" "Bash" "Grep" "Glob"],
  mcpDeps ? [],
  body ? "",
}: let
  toolsString = builtins.concatStringsSep ", " tools;

  # Generate markdown with YAML frontmatter
  agentMarkdown = ''
    ---
    name: ${name}
    description: ${description}
    model: ${model}
    tools: ${toolsString}
    ---

    ${body}
  '';

  agentFile = pkgs.writeText "${name}.md" agentMarkdown;
in {
  meta = {
    inherit name description;
    category = "agent";
  };

  inherit mcpDeps agentFile;
}
