# MemPalace MCP server - Local-first AI memory with verbatim storage and semantic search
{
  pkgs,
  lib,
  devPkgs,
  mkMcpModule,
}:
mkMcpModule {
  name = "mempalace";
  description = "Local-first AI memory: verbatim storage, semantic search, knowledge graph";
  package = devPkgs.mempalace;
  command = "mempalace-mcp";
  emoji = "🏛️";
}
