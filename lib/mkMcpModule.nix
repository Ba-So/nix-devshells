# Factory function for creating MCP modules with minimal boilerplate
#
# Usage:
#   mkMcpModule {
#     name = "my-mcp";
#     description = "My MCP server";
#     package = devPkgs.my-mcp;
#     command = "my-mcp-server";  # defaults to name
#     args = ["--flag"];          # defaults to []
#     env = { API_KEY = ""; };   # defaults to {}
#     emoji = "🔧";              # defaults to "🔧"
#
#     # Optional overrides
#     configName = "my-mcp";     # key in mcpConfig, defaults to name
#     languages = ["rust"];       # defaults to omitted from meta
#     shellHook = "extra logic";  # appended after the echo line
#   }
_: {
  name,
  description,
  package,
  command ? name,
  args ? [],
  env ? {},
  emoji ? "🔧",
  configName ? name,
  languages ? null,
  shellHook ? "",
}: {
  meta =
    {
      inherit name description;
      category = "mcp";
    }
    // (
      if languages != null
      then {inherit languages;}
      else {}
    );

  packages = [package];

  mcpConfig = {
    ${configName} =
      {
        type = "stdio";
        inherit command args;
      }
      // (
        if env != {}
        then {inherit env;}
        else {}
      );
  };

  shellHook =
    ''
      echo "  ${emoji} ${name}: ${description}"
    ''
    + shellHook;
}
