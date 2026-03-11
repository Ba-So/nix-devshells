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

  packages = [pkgs.uv];

  mcpConfig = {
    paper-search = {
      type = "stdio";
      command = "uvx";
      args = ["paper-search-mcp"];
      env = {
        SEMANTIC_SCHOLAR_API_KEY = "";
      };
    };
  };

  shellHook = ''
    echo "  📚 paper-search: Academic paper search (arXiv, PubMed, etc.)"
  '';
}
