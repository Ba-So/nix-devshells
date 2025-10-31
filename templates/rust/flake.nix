{
  description = "My Rust Project";

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
        packages.default = pkgs.rustPlatform.buildRustPackage {
          pname = "my-rust-project";
          version = "0.1.0";

          src = ./.;

          # Run `nix run nixpkgs#nix-prefetch-git -- --url . --rev HEAD` to get the hash
          # Or let Nix tell you the correct hash in the error message
          cargoLock.lockFile = ./Cargo.lock;

          # Optional: Add runtime dependencies
          # buildInputs = with pkgs; [ openssl ];
          # nativeBuildInputs = with pkgs; [ pkg-config ];

          meta = with pkgs.lib; {
            description = "My Rust project";
            homepage = "https://github.com/yourusername/my-rust-project";
            license = licenses.mit;
            maintainers = [ ];
          };
        };

        # Development environment from nix-devshells
        # This provides: cargo, rustc, clippy, rust-analyzer, etc.
        devShells.default = devshells.devShells.${system}.rust;

        # Optional: Extend the devshell with project-specific tools
        # devShells.default = pkgs.mkShell {
        #   inputsFrom = [ devshells.devShells.${system}.rust ];
        #   packages = with pkgs; [
        #     # Add project-specific development tools here
        #     # diesel-cli
        #     # sea-orm-cli
        #   ];
        # };

        # Optional: Define apps for easy running
        # apps.default = {
        #   type = "app";
        #   program = "${self.packages.${system}.default}/bin/my-rust-project";
        # };
      }
    );
}
