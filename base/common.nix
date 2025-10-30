{
  pkgs,
  devPkgs,
}:
# Common development tools used across all development environments
# This provides the base set of tools every developer needs
[
  # Version control
  pkgs.git
  pkgs.git-lfs

  # Development workflow tools
  pkgs.pre-commit
  pkgs.direnv
  pkgs.just

  # Nix tooling
  pkgs.nixfmt-rfc-style
  pkgs.nil # Nix LSP

  # Basic utilities
  pkgs.jq
  pkgs.curl
  pkgs.wget
  pkgs.tree
  pkgs.fd
  pkgs.ripgrep

  # Build and project management
  pkgs.gnumake

  # Editor support (minimal)
  pkgs.helix # Your preferred editor from the config

  # Project analysis tools
  pkgs.tokei # Lines of code counter (useful across all languages)

  # AI Development Tools
  devPkgs.mcp-shrimp-task-manager # AI-powered task management system
  devPkgs.codanna # Code intelligence and semantic search for LLMs
  devPkgs.mcp-gitlab
]
