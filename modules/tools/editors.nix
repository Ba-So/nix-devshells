# Text editors
{
  pkgs,
  lib,
}: {
  meta = {
    name = "editors";
    description = "Text editors";
    category = "tool";
  };

  packages = [
    pkgs.helix
  ];

  shellHook = ''
    echo "  📝 Helix editor available"
  '';
}
