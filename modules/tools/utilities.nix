# Common development utilities
{
  pkgs,
  lib,
  devPkgs,
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
    pkgs.nodejs
    pkgs.nodePackages.prettier
    pkgs.nodePackages.markdownlint-cli
    pkgs.direnv
    pkgs.just
    devPkgs.rtk # Token compression for LLM CLI tools
  ];

  shellHook = ''
    echo "  🔧 Development utilities ready"
  '';
}
