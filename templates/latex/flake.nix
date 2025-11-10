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
    flake-utils.lib.eachDefaultSystem (system: {
      # Uncomment to build your LaTeX document
      # packages.default = let
      #   pkgs = nixpkgs.legacyPackages.${system};
      #   mainDocument = "main.tex";
      #   documentName = "my-document";
      # in pkgs.stdenvNoCC.mkDerivation {
      #   pname = documentName;
      #   version = "0.1.0";
      #
      #   src = ./.;
      #
      #   buildInputs = with pkgs; [
      #     (texlive.combine {
      #       inherit
      #         (texlive)
      #         scheme-basic
      #         latexmk
      #         # Add your required LaTeX packages here
      #         amsmath
      #         amsfonts
      #         graphics
      #         hyperref
      #         # bibtex  # For bibliography
      #         # biblatex  # Modern bibliography system
      #         ;
      #     })
      #   ];
      #
      #   buildPhase = ''
      #     # Compile the LaTeX document
      #     latexmk -pdf -interaction=nonstopmode ${mainDocument}
      #   '';
      #
      #   installPhase = ''
      #     mkdir -p $out
      #     cp *.pdf $out/
      #   '';
      #
      #   meta = with pkgs.lib; {
      #     description = "My LaTeX document";
      #     license = licenses.cc-by-40;
      #     maintainers = [];
      #   };
      # };

      # Development environment using NEW composition API
      # This provides: texlive, latexmk, editor support, git, helix, etc.
      devShells.default = devshells.lib.${system}.composeShell {
        languages = ["latex"];
        mcps = ["serena"]; # MCP servers for AI assistance
        tools = "standard"; # or "minimal" for lightweight setup
      };

      # Alternative configurations (uncomment to use):

      # Minimal shell (fast startup, no MCP overhead):
      # devShells.default = devshells.lib.${system}.composeShell {
      #   languages = ["latex"];
      #   tools = "minimal";
      #   mcps = [];
      # };

      # Extended shell with document-specific tools:
      # devShells.default = let
      #   pkgs = nixpkgs.legacyPackages.${system};
      # in devshells.lib.${system}.composeShell {
      #   languages = ["latex"];
      #   mcps = ["serena"];
      #   tools = "standard";
      #   extraPackages = with pkgs; [
      #     # Add document-specific tools
      #     inkscape # For SVG to PDF conversion
      #     imagemagick # For image processing
      #     python3 # For build scripts
      #     zathura # PDF viewer
      #   ];
      #   extraShellHook = ''
      #     echo "LaTeX project development environment ready!"
      #   '';
      # };

      # Advanced: Direct module composition for full control
      # devShells.default = let
      #   inherit (devshells.lib.${system}) modules composeShellFromModules;
      # in
      #   composeShellFromModules [
      #     modules.languages.latex
      #     modules.mcp.serena
      #     modules.tools.version-control
      #     modules.tools.editors
      #   ];

      # OLD API (still works, for migration reference):
      # devShells.default = devshells.devShells.${system}.latex;
      #
      # OLD API with extension:
      # devShells.default = pkgs.mkShell {
      #   inputsFrom = [ devshells.devShells.${system}.latex ];
      #   packages = with pkgs; [ inkscape imagemagick ];
      # };

      # Optional: Define an app to open the PDF
      # apps.default = let
      #   documentName = "my-document";
      # in {
      #   type = "app";
      #   program = "${pkgs.zathura}/bin/zathura";
      #   args = [ "${self.packages.${system}.default}/${documentName}.pdf" ];
      # };
    });
}
