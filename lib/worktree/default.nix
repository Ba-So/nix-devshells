# Worktree mode support
# Generates subtree flakes and helper commands for multi-agent workflows
#
# Design: Sibling worktree pattern
# ================================
# The main repo contains the orchestrator, and worktrees are created as siblings:
#
#   myproject/                  # Main git repo + orchestrator
#   ├── .shared/                # Shared config for sibling worktrees
#   ├── .orchestrator/          # Orchestrator MCP config
#   └── <source code>
#
#   ../myproject-feature-x/     # Sibling worktree (not nested)
#   ../myproject-feature-y/     # Another sibling worktree
#
{
  pkgs,
  lib,
  system,
}: let
  flakeGen = import ./flake.nix {inherit lib;};
  claudeMd = import ./claude-md.nix {};
  scripts = import ./scripts.nix {inherit pkgs;};
  hooks = import ./hooks.nix {inherit pkgs claudeMd flakeGen;};
  source = import ./source.nix {};
in {
  inherit (flakeGen) generateSubtreeFlakeContent;
  inherit (claudeMd) generateSharedClaudeMd generateOrchestratorClaudeMd generateOrchestratorSkills;
  inherit (scripts) mkWorktreeScripts worktreeScripts;
  inherit (hooks) worktreeShellHook subtreeShellHook;
  inherit (source) mkWorktreeSource;
}
