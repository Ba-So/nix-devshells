# Qdrant MCP server - Semantic documentation search with local embeddings
{
  pkgs,
  lib,
  devPkgs,
  mkMcpModule,
}:
mkMcpModule {
  name = "qdrant-mcp";
  description = "Semantic documentation search using Qdrant with local CPU embeddings";
  package = devPkgs.qdrant-mcp;
  command = "mcp-server-qdrant";
  configName = "qdrant-docs";
  env = {
    QDRANT_URL = "http://localhost:6333";
    EMBEDDING_MODEL = "sentence-transformers/all-MiniLM-L6-v2";
  };
  emoji = "🔍";
}
