# Codanna MCP server - Code intelligence and semantic search for LLMs
{
  pkgs,
  lib,
  devPkgs,
  mkMcpModule,
}:
mkMcpModule {
  name = "codanna";
  description = "Code intelligence and semantic search for LLMs";
  package = devPkgs.codanna;
  args = ["serve" "--watch" "--watch-interval" "5"];
  emoji = "🧠";
}
