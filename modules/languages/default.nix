# Language modules - Development environments for various programming languages
{
  pkgs,
  inputs,
  lib,
}: {
  rust = import ./rust.nix {inherit pkgs inputs lib;};
  python = import ./python.nix {inherit pkgs inputs lib;};
  cpp = import ./cpp.nix {inherit pkgs inputs lib;};
  nix = import ./nix.nix {inherit pkgs inputs lib;};
  php = import ./php.nix {inherit pkgs inputs lib;};
  latex = import ./latex.nix {inherit pkgs inputs lib;};
  ansible = import ./ansible.nix {inherit pkgs inputs lib;};
  julia = import ./julia.nix {inherit pkgs inputs lib;};
}
