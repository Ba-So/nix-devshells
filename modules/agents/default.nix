# Agent modules - Claude Code agent definitions with MCP dependency tracking
{
  pkgs,
  lib,
}: let
  mkAgentModule = import ../../lib/mkAgentModule.nix {inherit pkgs;};
in {
  code-reviewer = import ./code-reviewer.nix {inherit mkAgentModule;};
  coder = import ./coder.nix {inherit mkAgentModule;};
  codebase-researcher = import ./codebase-researcher.nix {inherit mkAgentModule;};
  software-designer = import ./software-designer.nix {inherit mkAgentModule;};
  test-specialist = import ./test-specialist.nix {inherit mkAgentModule;};
}
