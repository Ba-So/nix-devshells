# LibreOffice MCP server - Interact with LibreOffice documents
{
  pkgs,
  lib,
  devPkgs,
  mkMcpModule,
}:
mkMcpModule {
  name = "mcp-libre";
  description = "LibreOffice document tools (Writer, Calc, etc.)";
  package = devPkgs.mcp-libre;
  command = "mcp-libre";
  emoji = "📄";
}
