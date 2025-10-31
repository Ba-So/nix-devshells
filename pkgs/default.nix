# Development-only packages for devshells
# These packages are specific to development environments and not meant for system-wide use
{pkgs}: {
  cargo-mcp = pkgs.callPackage ./cargo-mcp.nix {
    inherit (pkgs) rust-bin;
  };

  mcp-shrimp-task-manager = pkgs.callPackage ./shrimp.nix {};

  mcp-gitlab = pkgs.callPackage ./gitlab.nix {};

  codanna = pkgs.callPackage ./codanna.nix {};

  cratedocs-mcp = pkgs.callPackage ./cratedocs-mcp.nix {};
}
