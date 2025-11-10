# Tool modules - Common development utilities and tools
{
  pkgs,
  lib,
}: {
  version-control = import ./version-control.nix {inherit pkgs lib;};
  nix-tools = import ./nix-tools.nix {inherit pkgs lib;};
  editors = import ./editors.nix {inherit pkgs lib;};
  utilities = import ./utilities.nix {inherit pkgs lib;};
}
