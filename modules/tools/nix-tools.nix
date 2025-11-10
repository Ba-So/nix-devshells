# Nix development and formatting tools
{
  pkgs,
  lib,
}: {
  meta = {
    name = "nix-tools";
    description = "Nix development and formatting tools";
    category = "tool";
  };

  packages = [
    pkgs.nixfmt-rfc-style
    pkgs.nil # Nix LSP
    pkgs.alejandra # Additional Nix formatter
    pkgs.deadnix # Dead code detection
    pkgs.statix # Nix linter
  ];

  shellHook = ''
    echo "  📦 Nix development tools"
  '';
}
