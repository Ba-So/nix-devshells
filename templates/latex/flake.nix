{
  description = "My LaTeX Document";

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

        # Define your main LaTeX document
        mainDocument = "main.tex";
        documentName = "my-document";
      in {
        # Build the PDF document
        packages.default = pkgs.stdenvNoCC.mkDerivation {
          pname = documentName;
          version = "0.1.0";

          src = ./.;

          buildInputs = with pkgs; [
            (texlive.combine {
              inherit
                (texlive)
                scheme-basic
                latexmk
                # Add your required LaTeX packages here
                amsmath
                amsfonts
                graphics
                hyperref
                # bibtex  # For bibliography
                # biblatex  # Modern bibliography system
                ;
            })
          ];

          buildPhase = ''
            # Compile the LaTeX document
            latexmk -pdf -interaction=nonstopmode ${mainDocument}
          '';

          installPhase = ''
            mkdir -p $out
            cp *.pdf $out/
          '';

          meta = with pkgs.lib; {
            description = "My LaTeX document";
            license = licenses.cc-by-40;
            maintainers = [];
          };
        };

        # Development environment from nix-devshells
        # This provides: texlive, latexmk, and editor support
        devShells.default = devshells.devShells.${system}.latex;

        # Optional: Extend the devshell with additional packages
        # devShells.default = pkgs.mkShell {
        #   inputsFrom = [ devshells.devShells.${system}.latex ];
        #   packages = with pkgs; [
        #     # Add document-specific tools here
        #     # inkscape  # For SVG to PDF conversion
        #     # imagemagick  # For image processing
        #     # python3  # For build scripts
        #   ];
        # };

        # Optional: Define an app to open the PDF
        # apps.default = {
        #   type = "app";
        #   program = "${pkgs.zathura}/bin/zathura";
        #   args = [ "${self.packages.${system}.default}/${documentName}.pdf" ];
        # };
      }
    );
}
