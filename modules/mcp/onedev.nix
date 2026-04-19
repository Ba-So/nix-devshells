# OneDev MCP server - OneDev API integration via tod
{
  pkgs,
  lib,
  devPkgs,
  mkMcpModule,
}:
mkMcpModule {
  name = "onedev";
  description = "OneDev API integration via tod";
  package = devPkgs.tod;
  command = "tod";
  args = ["mcp"];
  emoji = "🔧";
}
