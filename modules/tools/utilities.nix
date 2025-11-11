# Common development utilities
{
  pkgs,
  lib,
}: {
  meta = {
    name = "utilities";
    description = "Common development utilities";
    category = "tool";
  };

  packages = [
    pkgs.jq
    pkgs.curl
    pkgs.wget
    pkgs.tree
    pkgs.fd
    pkgs.ripgrep
    pkgs.gnumake
    pkgs.tokei # Lines of code counter
    pkgs.pre-commit
    pkgs.nodePackages.prettier
    pkgs.nodePackages.markdownlint-cli
    pkgs.direnv
    pkgs.just
  ];

  shellHook = ''
    echo "  🔧 Development utilities ready"
  '';
}
