# Factory function for creating agent modules with minimal boilerplate.
#
# Produces a canonical agent attrset; the active harness adapter is responsible
# for rendering it into the harness-specific markdown/frontmatter format.
#
# Usage:
#   mkAgentModule {
#     name = "rust-developer";
#     description = "Rust development specialist";
#     model = "sonnet";                        # bare alias or "provider/id"
#     tools = ["Write" "Read" "Bash" "Grep"];  # canonical (Claude-style) names
#     mcpDeps = ["cargo-mcp"];                 # required MCP module names
#     body = ''
#       You are a Rust specialist...
#     '';
#   }
_: {
  name,
  description,
  model ? "sonnet",
  tools ? ["Write" "Read" "Edit" "Bash" "Grep" "Glob"],
  mcpDeps ? [],
  body ? "",
}: {
  meta = {
    inherit name description;
    category = "agent";
  };

  # Canonical fields — consumed by lib/harness/<harness>.nix renderAgent.
  inherit name description model tools body mcpDeps;
}
