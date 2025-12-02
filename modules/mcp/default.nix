# MCP modules - Model Context Protocol servers for AI development
{
  pkgs,
  lib,
  devPkgs,
  serena,
}: {
  cargo-mcp = import ./cargo.nix {inherit pkgs lib devPkgs;};
  serena = import ./serena.nix {inherit pkgs lib serena;};
  codanna = import ./codanna.nix {inherit pkgs lib devPkgs;};
  claude-task-master = import ./claude-task-master {inherit pkgs lib devPkgs;};
  gitlab = import ./gitlab.nix {inherit pkgs lib devPkgs;};
  puppeteer = import ./puppeteer.nix {inherit pkgs lib devPkgs;};
  cratedocs = import ./cratedocs.nix {inherit pkgs lib devPkgs;};

  # Deprecated/legacy MCPs
  shrimp = import ./shrimp.nix {inherit pkgs lib devPkgs;};
}
