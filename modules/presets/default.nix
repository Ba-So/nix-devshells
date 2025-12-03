# Preset modules - Pre-configured module bundles
# These presets combine tool and MCP modules into common configurations
{
  pkgs,
  lib,
  modules,
}: {
  minimal = import ./minimal.nix {inherit pkgs lib modules;};
  standard = import ./standard.nix {inherit pkgs lib modules;};
}
