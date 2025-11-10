# Codanna MCP server - Code intelligence and semantic search for LLMs
{
  pkgs,
  lib,
  devPkgs,
}: {
  meta = {
    name = "codanna";
    description = "Code intelligence and semantic search for LLMs";
    category = "mcp";
  };

  packages = [devPkgs.codanna];

  mcpConfig = {
    codanna = {
      type = "stdio";
      command = "codanna";
      args = ["serve" "--watch" "--watch-interval" "5"];
    };
  };

  shellHook = ''
    echo "  🧠 codanna: Code intelligence and semantic search"
  '';
}
