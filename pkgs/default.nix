# Development-only packages for devshells
# These packages are specific to development environments and not meant for system-wide use
{pkgs}: {
  cargo-mcp = pkgs.callPackage ./cargo-mcp.nix {
    inherit (pkgs) rust-bin;
  };

  mcp-shrimp-task-manager = pkgs.callPackage ../base/shrimp.nix {};

  codanna = pkgs.callPackage ../base/codanna.nix {};

  cratedocs-mcp = pkgs.callPackage ./cratedocs-mcp.nix {};
}
