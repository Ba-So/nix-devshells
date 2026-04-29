{
  description = "Development shells for various programming languages";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    serena = {
      # pin to last-working commit, there is no release with a flake.nix yet
      url = "github:oraios/serena?ref=0c915bd18d51e2225508b6dccc8ae3bd9c20be1e";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    codanna = {
      url = "github:ba-so/codanna";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs = {
        pyproject-nix.follows = "pyproject-nix";
        uv2nix.follows = "uv2nix";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = {
    nixpkgs,
    nixpkgs-unstable,
    flake-utils,
    rust-overlay,
    serena,
    codanna,
    pyproject-nix,
    uv2nix,
    pyproject-build-systems,
    ...
  }:
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        # Create pkgs with rust overlay for cargo-mcp
        pkgs-with-rust = import nixpkgs {
          inherit system;
          overlays = [rust-overlay.overlays.default];
        };

        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            # Fix conan build failure (test_create_pip_manager fails with Python 3.13)
            (_: prev: {
              conan = prev.conan.overridePythonAttrs (old: {
                disabledTestPaths =
                  (old.disabledTestPaths or [])
                  ++ [
                    "test/functional/tools/system/pip_manager_test.py"
                  ];
              });
            })
          ];
        };

        # Create pkgs from unstable for packages requiring newer toolchains
        pkgs-unstable = import nixpkgs-unstable {
          inherit system;
        };

        # Create pkgs with unfree packages allowed for specific packages
        pkgs-unfree = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Import our shell definitions
        shells = import ./default.nix {
          inherit pkgs;
          _system = system;
          inputs = {inherit nixpkgs nixpkgs-unstable rust-overlay serena codanna;};
        };

        # Import lib system for module composition
        libSystem = import ./lib/default.nix {
          inherit pkgs system;
          inputs = {
            inherit nixpkgs nixpkgs-unstable rust-overlay serena codanna;
            inherit pyproject-nix uv2nix pyproject-build-systems;
          };
        };
      in {
        # Standard flake structure: devShells.<name>
        devShells = {
          inherit (shells) rust php nix cpp python py-cpp latex ansible julia;
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
          codanna = codanna.packages.${system}.default;
          claude-task-master = pkgs-unfree.callPackage ./pkgs/claude-task-master {};
          mcp-gitlab = pkgs.callPackage ./pkgs/gitlab.nix {};
          puppeteer-mcp-server = pkgs.callPackage ./pkgs/puppeteer-mcp.nix {};
          universal-screenshot-mcp = pkgs.callPackage ./pkgs/universal-screenshot-mcp.nix {};
          computer-use-mcp = pkgs.callPackage ./pkgs/computer-use-mcp.nix {};

          # Qdrant MCP - MCP server for semantic documentation search
          qdrant-mcp = pkgs.callPackage ./pkgs/qdrant-mcp.nix {
            inherit pyproject-nix uv2nix pyproject-build-systems;
          };

          # Paper Search MCP - Academic paper search across multiple sources
          paper-search-mcp = pkgs.callPackage ./pkgs/paper-search-mcp.nix {
            inherit pyproject-nix uv2nix pyproject-build-systems;
          };

          # MemPalace - Local-first AI memory (CLI + MCP server)
          mempalace = pkgs.callPackage ./pkgs/mempalace.nix {
            inherit pyproject-nix uv2nix pyproject-build-systems;
          };

          # MCP-Libre - LibreOffice document MCP server
          mcp-libre = pkgs.callPackage ./pkgs/mcp-libre.nix {};

          # MCP-Grafana - MCP server for Grafana observability platform
          mcp-grafana = pkgs-unstable.callPackage ./pkgs/mcp-grafana.nix {};

          # Tod - CLI tool and MCP server for OneDev
          tod = pkgs.callPackage ./pkgs/tod.nix {};

          # Serena - MCP server for project analysis
          serena = serena.packages.${system}.default or serena.defaultPackage.${system};

          # Deprecated/legacy packages
          mcp-shrimp-task-manager = pkgs.callPackage ./pkgs/shrimp.nix {};

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
        worktree = {
          path = ./templates/worktree;
          description = "Multi-agent worktree project with orchestrator and worker support";
        };
      };

      # Overlay for easy integration into other configurations
      overlays.default = final: _prev: {
        cargo-mcp = final.callPackage ./pkgs/cargo-mcp.nix {
          inherit (final) rust-bin;
        };
        cratedocs-mcp = final.callPackage ./pkgs/cratedocs-mcp.nix {};
        codanna = codanna.packages.${final.system}.default;
        claude-task-master = final.callPackage ./pkgs/claude-task-master {};
        mcp-gitlab = final.callPackage ./pkgs/gitlab.nix {};
        puppeteer-mcp-server = final.callPackage ./pkgs/puppeteer-mcp.nix {};
        universal-screenshot-mcp = final.callPackage ./pkgs/universal-screenshot-mcp.nix {};
        computer-use-mcp = final.callPackage ./pkgs/computer-use-mcp.nix {};
        qdrant-mcp = final.callPackage ./pkgs/qdrant-mcp.nix {
          inherit pyproject-nix uv2nix pyproject-build-systems;
        };
        paper-search-mcp = final.callPackage ./pkgs/paper-search-mcp.nix {
          inherit pyproject-nix uv2nix pyproject-build-systems;
        };
        mempalace = final.callPackage ./pkgs/mempalace.nix {
          inherit pyproject-nix uv2nix pyproject-build-systems;
        };
        mcp-libre = final.callPackage ./pkgs/mcp-libre.nix {};
        mcp-grafana = (import nixpkgs-unstable {inherit (final) system;}).callPackage ./pkgs/mcp-grafana.nix {};
        tod = final.callPackage ./pkgs/tod.nix {};

        # Deprecated/legacy packages
        mcp-shrimp-task-manager = final.callPackage ./pkgs/shrimp.nix {};

        # Expose devshells lib for external users
        devshells-lib = final.callPackage ./lib/default.nix {
          pkgs = final;
          inherit (final) system;
          inputs = {
            inherit nixpkgs nixpkgs-unstable rust-overlay serena codanna;
          };
        };
      };
    };
}
