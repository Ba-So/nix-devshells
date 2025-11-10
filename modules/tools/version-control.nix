# Version control tools
{
  pkgs,
  lib,
}: {
  meta = {
    name = "version-control";
    description = "Git and version control tools";
    category = "tool";
  };

  packages = [
    pkgs.git
    pkgs.git-lfs
  ];

  shellHook = ''
    echo "  📦 Git version control tools"
  '';
}
