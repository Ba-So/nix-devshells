{
  description = "Multi-agent worktree project with orchestrator and worker support";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Import devshells for development environment
    devshells.url = "github:Ba-So/nix-devshells";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    devshells,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: {
      # Main development environment - ORCHESTRATOR shell
      # This shell sets up:
      # - .shared/ directory with subtree flake for workers
      # - .orchestrator/.mcp.json with full MCP config (including task-master)
      # - .shared/.mcp.json without task-master for workers
      # - Shared codanna index at .shared/.codanna/
      # - Helper commands: worktree-new, worktree-status, worktree-remove
      #
      # Worktrees are created as SIBLINGS: ../<project>-<branch>/
      devShells.default = devshells.lib.${system}.composeShell {
        type = "worktree"; # Enable multi-agent worktree mode

        # Languages available in all worktrees
        languages = ["rust"];

        # MCPs for the orchestrator (workers get these minus task-master)
        mcps = [
          "codanna" # Code intelligence (shared index)
          "serena" # Project analysis
          "claude-task-master" # Task management (orchestrator only)
        ];

        tools = "standard";

        # Optional: Custom devshells URL for generated subtree flake
        # devshellsUrl = "github:Ba-So/nix-devshells?ref=v1.0.0";
      };

      # Alternative: Minimal orchestrator with fewer MCPs
      # devShells.minimal = devshells.lib.${system}.composeShell {
      #   type = "worktree";
      #   languages = ["rust"];
      #   mcps = ["codanna" "claude-task-master"];
      #   tools = "minimal";
      # };
    });
}
