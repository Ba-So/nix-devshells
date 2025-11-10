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
        # Create pkgs with rust overlay for cargo-mcp
        pkgs-with-rust = import nixpkgs {
          inherit system;
          overlays = [rust-overlay.overlays.default];
        };

        pkgs = nixpkgs.legacyPackages.${system};

        # Import our shell definitions
        shells = import ./default.nix {
          inherit pkgs;
          _system = system;
          inputs = {inherit nixpkgs nixpkgs-unstable rust-overlay serena;};
        };

        # Import lib system for module composition
        libSystem = import ./lib/default.nix {
          inherit pkgs system;
          inputs = {inherit nixpkgs nixpkgs-unstable rust-overlay serena;};
        };
      in {
        # Standard flake structure: devShells.<name>
        devShells = {
          inherit (shells) rust php nix cpp python py-cpp latex ansible;
          default = shells.nix; # Default to nix shell

          # NEW: Composed shells using module system
          rust-minimal = libSystem.composeShell {
            languages = ["rust"];
            tools = "minimal";
            mcps = ["cargo-mcp"];
          };

          rust-python = libSystem.composeShell {
            languages = ["rust" "python"];
            mcps = ["cargo-mcp" "serena"];
            tools = "standard";
          };

          web-dev = libSystem.composeShell {
            languages = ["rust" "python" "php"];
            mcps = ["cargo-mcp" "serena" "puppeteer"];
            tools = "standard";
          };
        };

        # Expose package sets for easy composition in other projects
        # Usage: buildInputs = devshells.packageSets.${system}.rust;
        inherit (shells) packageSets;

        # Expose lib for module composition
        # Usage: devshells.lib.${system}.composeShell { languages = ["rust"]; tools = "minimal"; }
        lib = {
          inherit (libSystem) composeShell composeShellFromModules modules;
        };

        # Expose custom packages
        packages = {
          cargo-mcp = pkgs-with-rust.callPackage ./pkgs/cargo-mcp.nix {
            inherit (pkgs-with-rust) rust-bin;
          };
          cratedocs-mcp = pkgs.callPackage ./pkgs/cratedocs-mcp.nix {};
          codanna = pkgs.callPackage ./pkgs/codanna.nix {};
          mcp-shrimp-task-manager = pkgs.callPackage ./pkgs/shrimp.nix {};
          mcp-gitlab = pkgs.callPackage ./pkgs/gitlab.nix {};
          puppeteer-mcp-server = pkgs.callPackage ./pkgs/puppeteer-mcp.nix {};

          # Serena - MCP server for project analysis
          serena = serena.packages.${system}.default or serena.defaultPackage.${system};

          # Default to cargo-mcp as it's most generally useful
          default = pkgs-with-rust.callPackage ./pkgs/cargo-mcp.nix {
            inherit (pkgs-with-rust) rust-bin;
          };
        };
      }
    )
    // {
      # Non-system-specific outputs
      templates = {
        rust = {
          path = ./templates/rust;
          description = "Rust project template with complete package definition";
        };
        php = {
          path = ./templates/php;
          description = "PHP project template with complete package definition";
        };
        latex = {
          path = ./templates/latex;
          description = "LaTeX document template with build configuration";
        };
        cpp = {
          path = ./templates/cpp;
          description = "C++ project template with CMake and complete package definition";
        };
      };

      # Overlay for easy integration into other configurations
      overlays.default = final: _prev: {
        cargo-mcp = final.callPackage ./pkgs/cargo-mcp.nix {
          inherit (final) rust-bin;
        };
        cratedocs-mcp = final.callPackage ./pkgs/cratedocs-mcp.nix {};
        codanna = final.callPackage ./pkgs/codanna.nix {};
        mcp-shrimp-task-manager = final.callPackage ./pkgs/shrimp.nix {};
        mcp-gitlab = final.callPackage ./pkgs/gitlab.nix {};
        puppeteer-mcp-server = final.callPackage ./pkgs/puppeteer-mcp.nix {};

        # Expose devshells lib for external users
        devshells-lib = final.callPackage ./lib/default.nix {
          pkgs = final;
          inherit (final) system;
          inputs = {
            inherit nixpkgs nixpkgs-unstable rust-overlay serena;
          };
        };
      };
    };
}
