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

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    devshells,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: {
      # Uncomment to build your Rust package
      # packages.default = let
      #   pkgs = nixpkgs.legacyPackages.${system};
      # in pkgs.rustPlatform.buildRustPackage {
      #   pname = "my-rust-project";
      #   version = "0.1.0";
      #
      #   src = ./.;
      #
      #   # Run `nix run nixpkgs#nix-prefetch-git -- --url . --rev HEAD` to get the hash
      #   # Or let Nix tell you the correct hash in the error message
      #   cargoLock.lockFile = ./Cargo.lock;
      #
      #   # Optional: Add runtime dependencies
      #   # buildInputs = with pkgs; [ openssl ];
      #   # nativeBuildInputs = with pkgs; [ pkg-config ];
      #
      #   meta = with pkgs.lib; {
      #     description = "My Rust project";
      #     homepage = "https://github.com/yourusername/my-rust-project";
      #     license = licenses.mit;
      #     maintainers = [];
      #   };
      # };

      # Development environment using NEW composition API
      # This provides: cargo, rustc, clippy, rust-analyzer, git, helix, etc.
      devShells.default = devshells.lib.${system}.composeShell {
        languages = ["rust"];
        mcps = ["cargo-mcp" "serena"]; # MCP servers for AI assistance
        tools = "standard"; # or "minimal" for lightweight setup
      };

      # Alternative configurations (uncomment to use):

      # Minimal shell (fast startup, no MCP overhead):
      # devShells.default = devshells.lib.${system}.composeShell {
      #   languages = ["rust"];
      #   tools = "minimal";
      #   mcps = [];
      # };

      # Extended shell with project-specific tools:
      # devShells.default = let
      #   pkgs = nixpkgs.legacyPackages.${system};
      # in devshells.lib.${system}.composeShell {
      #   languages = ["rust"];
      #   mcps = ["cargo-mcp" "cratedocs"];
      #   tools = "standard";
      #   extraPackages = with pkgs; [
      #     # Add project-specific development tools
      #     diesel-cli
      #     sea-orm-cli
      #     postgresql
      #   ];
      #   extraShellHook = ''
      #     export DATABASE_URL="postgres://localhost/mydb"
      #   '';
      # };

      # Advanced: Direct module composition for full control
      # devShells.default = let
      #   inherit (devshells.lib.${system}) modules composeShellFromModules;
      # in
      #   composeShellFromModules [
      #     modules.languages.rust
      #     modules.mcp.cargo-mcp
      #     modules.tools.version-control
      #     modules.tools.editors
      #   ];

      # OLD API (still works, for migration reference):
      # devShells.default = devshells.devShells.${system}.rust;
      #
      # OLD API with extension:
      # devShells.default = pkgs.mkShell {
      #   inputsFrom = [ devshells.devShells.${system}.rust ];
      #   packages = with pkgs; [ diesel-cli sea-orm-cli ];
      # };

      # Optional: Define apps for easy running
      # apps.default = {
      #   type = "app";
      #   program = "${self.packages.${system}.default}/bin/my-rust-project";
      # };
    });
}
