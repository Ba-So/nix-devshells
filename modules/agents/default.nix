# Agent modules - Claude Code agent definitions with MCP dependency tracking
{
  pkgs,
  lib,
}: let
  mkAgentModule = import ../../lib/mkAgentModule.nix {inherit pkgs;};
in {
  # Agent modules will be added here, e.g.:
  # rust-developer = import ./rust-developer.nix { inherit mkAgentModule; };
}
