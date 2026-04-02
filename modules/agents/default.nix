# Agent modules - Claude Code agent definitions with MCP dependency tracking
{
  pkgs,
  lib,
}: let
  mkAgentModule = import ../../lib/mkAgentModule.nix {inherit pkgs;};
in {
  code-reviewer = import ./code-reviewer.nix {inherit mkAgentModule;};
}
