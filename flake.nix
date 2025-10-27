{
  description = "Development shells for various programming languages";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    serena = {
      # pin to last-working commit, there is no release with a flake.nix yet
      url = "github:oraios/serena?ref=dc31e4e";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    nixpkgs-unstable,
    flake-utils,
    rust-overlay,
    serena,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        # Import our shell definitions
        shells = import ./default.nix {
          inherit pkgs;
          _system = system;
          inputs = {inherit nixpkgs nixpkgs-unstable rust-overlay serena;};
        };
      in {
        # Standard flake structure: devShells.<name>
        devShells = {
          inherit (shells) rust php nix cpp python py-cpp latex ansible;
          default = shells.nix; # Default to rust shell
        };
      }
    )
    // {
      templates = {
        rust = {
          path = ./templates/rust;
          description = "Rust development environment using central devshells";
        };
        php = {
          path = ./templates/php;
          description = "php development environment using central devshells";
        };
        latex = {
          path = ./templates/latex;
          description = "LaTeX development environment using central devshells";
        };
      };
    };
}
