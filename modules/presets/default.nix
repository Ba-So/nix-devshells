# Preset modules - Pre-configured module bundles
# These presets combine tool and MCP modules into common configurations
{
  pkgs,
  lib,
  modules,
}: rec {
  minimal = import ./minimal.nix {inherit pkgs lib modules;};
  standard = import ./standard.nix {inherit pkgs lib modules;};
  full = import ./full.nix {inherit pkgs lib modules;};
}
