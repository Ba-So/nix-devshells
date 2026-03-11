# Paper Search MCP server - Academic paper search across multiple sources
{
  pkgs,
  lib,
  devPkgs,
}: {
  meta = {
    name = "paper-search";
    description = "Academic paper search (arXiv, PubMed, bioRxiv, etc.)";
    category = "mcp";
  };

  packages = [devPkgs.paper-search-mcp];

  mcpConfig = {
    paper-search = {
      type = "stdio";
      command = "paper-search-mcp";
      args = [];
      env = {
        SEMANTIC_SCHOLAR_API_KEY = "";
      };
    };
  };

  shellHook = ''
    echo "  📚 paper-search: Academic paper search (arXiv, PubMed, etc.)"
  '';
}
