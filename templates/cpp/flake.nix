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

  outputs = { self, nixpkgs, flake-utils, devshells, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
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
            maintainers = [ ];
            platforms = platforms.linux ++ platforms.darwin;
          };
        };

        # Development environment from nix-devshells
        # This provides: CMake, C++ compiler, debugger, etc.
        devShells.default = devshells.devShells.${system}.cpp;

        # Optional: Extend the devshell with project-specific tools
        # devShells.default = pkgs.mkShell {
        #   inputsFrom = [ devshells.devShells.${system}.cpp ];
        #   packages = with pkgs; [
        #     # Add project-specific development tools here
        #     # valgrind  # Memory debugging
        #     # boost  # Boost libraries
        #     # doxygen  # Documentation generation
        #   ];
        # };

        # Optional: Define apps for easy running
        # apps.default = {
        #   type = "app";
        #   program = "${self.packages.${system}.default}/bin/my-cpp-project";
        # };
      }
    );
}
