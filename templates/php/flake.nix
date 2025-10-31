{
  description = "My PHP Project";

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
      # Uncomment to build your PHP project
      # packages.default = let
      #   pkgs = nixpkgs.legacyPackages.${system};
      # in pkgs.stdenv.mkDerivation {
      #   pname = "my-php-project";
      #   version = "0.1.0";
      #
      #   src = ./.;
      #
      #   buildInputs = with pkgs; [
      #     php83
      #     php83Packages.composer
      #   ];
      #
      #   buildPhase = ''
      #     # Install composer dependencies
      #     composer install --no-dev --optimize-autoloader
      #   '';
      #
      #   installPhase = ''
      #     mkdir -p $out/share/php/my-php-project
      #     cp -r * $out/share/php/my-php-project/
      #
      #     # Optional: Create a wrapper script
      #     # mkdir -p $out/bin
      #     # cat > $out/bin/my-php-project << EOF
      #     # #!/bin/sh
      #     # ${pkgs.php83}/bin/php $out/share/php/my-php-project/index.php "\$@"
      #     # EOF
      #     # chmod +x $out/bin/my-php-project
      #   '';
      #
      #   meta = with pkgs.lib; {
      #     description = "My PHP project";
      #     homepage = "https://github.com/yourusername/my-php-project";
      #     license = licenses.mit;
      #     maintainers = [];
      #   };
      # };

      # Development environment from nix-devshells
      # This provides: PHP, Composer, development tools, etc.
      devShells.default = devshells.devShells.${system}.php;

      # Optional: Extend the devshell with project-specific tools
      # devShells.default = let
      #   pkgs = nixpkgs.legacyPackages.${system};
      # in pkgs.mkShell {
      #   inputsFrom = [ devshells.devShells.${system}.php ];
      #   packages = with pkgs; [
      #     # Add project-specific development tools here
      #     # nodejs  # For frontend asset compilation
      #     # mysql80  # For local database
      #   ];
      # };

      # Optional: Define apps for easy running
      # apps.default = {
      #   type = "app";
      #   program = "${self.packages.${system}.default}/bin/my-php-project";
      # };
    });
}
