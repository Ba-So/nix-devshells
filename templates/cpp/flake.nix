{
  description = "My C++ Project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Import devshells for development environment
    devshells.url = "github:Ba-So/nix-devshells";
    # Optionally pin to a specific version:
    # devshells.url = "github:Ba-So/nix-devshells?ref=v1.0.0";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    devshells,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        # The actual project package
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "my-cpp-project";
          version = "0.1.0";

          src = ./.;

          nativeBuildInputs = with pkgs; [
            cmake
            pkg-config
          ];

          buildInputs = with pkgs; [
            # Add your project dependencies here
            # boost
            # openssl
            # sqlite
          ];

          # CMake build configuration
          cmakeFlags = [
            "-DCMAKE_BUILD_TYPE=Release"
          ];

          # Optional: Run tests during build
          # doCheck = true;
          # checkPhase = ''
          #   ctest --output-on-failure
          # '';

          meta = with pkgs.lib; {
            description = "My C++ project";
            homepage = "https://github.com/yourusername/my-cpp-project";
            license = licenses.mit;
            maintainers = [];
            platforms = platforms.linux ++ platforms.darwin;
          };
        };

        # Development environment using NEW composition API
        # This provides: CMake, C++ compiler, debugger, git, helix, etc.
        devShells.default = devshells.lib.${system}.composeShell {
          languages = ["cpp"];
          mcps = ["serena"]; # MCP servers for AI assistance
          tools = "standard"; # or "minimal" for lightweight setup
        };

        # Alternative configurations (uncomment to use):

        # Minimal shell (fast startup, no MCP overhead):
        # devShells.default = devshells.lib.${system}.composeShell {
        #   languages = ["cpp"];
        #   tools = "minimal";
        #   mcps = [];
        # };

        # Extended shell with project-specific tools:
        # devShells.default = devshells.lib.${system}.composeShell {
        #   languages = ["cpp"];
        #   mcps = ["serena" "codanna"];
        #   tools = "standard";
        #   extraPackages = with pkgs; [
        #     # Add project-specific development tools
        #     valgrind # Memory debugging
        #     boost # Boost libraries
        #     doxygen # Documentation generation
        #   ];
        #   extraShellHook = ''
        #     export CMAKE_EXPORT_COMPILE_COMMANDS=ON
        #   '';
        # };

        # Advanced: Direct module composition for full control
        # devShells.default = let
        #   inherit (devshells.lib.${system}) modules composeShellFromModules;
        # in
        #   composeShellFromModules [
        #     modules.languages.cpp
        #     modules.mcp.serena
        #     modules.tools.version-control
        #     modules.tools.editors
        #   ];

        # OLD API (still works, for migration reference):
        # devShells.default = devshells.devShells.${system}.cpp;
        #
        # OLD API with extension:
        # devShells.default = pkgs.mkShell {
        #   inputsFrom = [ devshells.devShells.${system}.cpp ];
        #   packages = with pkgs; [ valgrind boost ];
        # };

        # Optional: Define apps for easy running
        # apps.default = {
        #   type = "app";
        #   program = "${self.packages.${system}.default}/bin/my-cpp-project";
        # };
      }
    );
}
