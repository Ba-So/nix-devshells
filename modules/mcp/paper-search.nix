# Paper Search MCP server - Academic paper search across multiple sources
{
  pkgs,
  lib,
  devPkgs,
  mkMcpModule,
}:
mkMcpModule {
  name = "paper-search";
  description = "Academic paper search (arXiv, PubMed, bioRxiv, etc.)";
  package = devPkgs.paper-search-mcp;
  command = "paper-search-mcp";
  env = {
    SEMANTIC_SCHOLAR_API_KEY = "";
  };
  emoji = "📚";
}
