# Puppeteer MCP server - Browser automation
{
  pkgs,
  lib,
  devPkgs,
}: {
  meta = {
    name = "puppeteer";
    description = "Browser automation MCP server";
    category = "mcp";
  };

  packages = [devPkgs.puppeteer-mcp-server];

  mcpConfig = {
    puppeteer = {
      type = "stdio";
      command = "mcp-server-puppeteer";
      args = [];
    };
  };

  shellHook = ''
    echo "  🎭 puppeteer: Browser automation"
  '';
}
