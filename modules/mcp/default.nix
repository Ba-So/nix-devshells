# MCP modules - Model Context Protocol servers for AI development
{
  pkgs,
  lib,
  devPkgs,
  serena,
}: let
  mkMcpModule = import ../../lib/mkMcpModule.nix {};
in {
  cargo-mcp = import ./cargo.nix {inherit pkgs lib devPkgs mkMcpModule;};
  serena = import ./serena.nix {inherit pkgs lib serena mkMcpModule;};
  codanna = import ./codanna.nix {inherit pkgs lib devPkgs mkMcpModule;};
  claude-task-master = import ./claude-task-master.nix {inherit pkgs lib devPkgs mkMcpModule;};
  github = import ./github.nix {inherit pkgs lib devPkgs mkMcpModule;};
  gitlab = import ./gitlab.nix {inherit pkgs lib devPkgs mkMcpModule;};
  puppeteer = import ./puppeteer.nix {inherit pkgs lib devPkgs mkMcpModule;};
  universal-screenshot = import ./universal-screenshot.nix {inherit pkgs lib devPkgs mkMcpModule;};
  computer-use = import ./computer-use.nix {inherit pkgs lib devPkgs mkMcpModule;};
  cratedocs = import ./cratedocs.nix {inherit pkgs lib devPkgs mkMcpModule;};
  qdrant = import ./qdrant.nix {inherit pkgs lib devPkgs mkMcpModule;};
  paper-search = import ./paper-search.nix {inherit pkgs lib devPkgs mkMcpModule;};
  mcp-libre = import ./libre.nix {inherit pkgs lib devPkgs mkMcpModule;};
  mempalace = import ./mempalace.nix {inherit pkgs lib devPkgs mkMcpModule;};
  mcp-grafana = import ./grafana.nix {inherit pkgs lib devPkgs mkMcpModule;};
  onedev = import ./onedev.nix {inherit pkgs lib devPkgs mkMcpModule;};

  # Deprecated/legacy MCPs
  shrimp = import ./shrimp.nix {inherit pkgs lib devPkgs mkMcpModule;};
}
