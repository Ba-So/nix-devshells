{
  inputs, # Required by flake interface, now used for rust-overlay
  pkgs,
  _system, # Required by flake interface, unused currently
}: let
  inherit (pkgs.lib) concatStringsSep;

  # Create development-specific package set with rust-overlay and dev packages
  devPkgs = import pkgs.path {
    inherit (pkgs) system;
    overlays = [
      inputs.rust-overlay.overlays.default
      (final: _prev: {
        devPkgs = import ./pkgs {pkgs = final;};
      })
    ];
  };

  # Extract serena from inputs
  serenaPackage = inputs.serena.packages.${pkgs.system}.default or inputs.serena.defaultPackage.${pkgs.system};

  # Import common packages and language-specific configurations
  commonPackages = import ./pkgs/common.nix {
    inherit pkgs;
    inherit (devPkgs) devPkgs;
    serena = serenaPackage;
  };
  rustConfig = import ./languages/rust.nix {
    pkgs = devPkgs;
    inherit inputs;
  };
  nixConfig = import ./languages/nix.nix {inherit pkgs inputs;};
  phpConfig = import ./languages/php.nix {inherit pkgs inputs;};
  cppConfig = import ./languages/cpp.nix {inherit pkgs inputs;};
  pythonConfig = import ./languages/python.nix {inherit pkgs inputs;};
  latexConfig = import ./languages/latex.nix {inherit pkgs inputs;};
  ansibleConfig = import ./languages/ansible.nix {inherit pkgs inputs;};
  # Helper function to create development shells with common patterns
in {
  # Expose package sets for composition in other projects
  packageSets = {
    common = commonPackages;
    rust = rustConfig.packages;
    nix = nixConfig.packages;
    php = phpConfig.packages;
    cpp = cppConfig.packages;
    python = pythonConfig.packages;
    latex = latexConfig.packages;
    ansible = ansibleConfig.packages;
  };

  # Rust development environment
  rust = pkgs.mkShell {
    buildInputs = commonPackages ++ rustConfig.packages;
    shellHook = ''
      echo "🚀 Entering Rust development environment"
      echo "📦 Available tools: ${concatStringsSep ", " (map (pkg: pkg.pname or pkg.name or "unknown") (commonPackages ++ rustConfig.packages))}"
      echo ""
      ${rustConfig.shellHook}
    '';
  };

  # Nix development environment
  nix = pkgs.mkShell {
    buildInputs = commonPackages ++ nixConfig.packages;
    shellHook = ''
      echo "🚀 Entering Nix development environment"
      echo "📦 Available tools: ${concatStringsSep ", " (map (pkg: pkg.pname or pkg.name or "unknown") (commonPackages ++ nixConfig.packages))}"
      echo ""
      ${nixConfig.shellHook}
    '';
  };

  # PHP development environment
  php = pkgs.mkShell {
    buildInputs = commonPackages ++ phpConfig.packages;
    shellHook = ''
      echo "🚀 Entering PHP development environment"
      echo "📦 Available tools: ${concatStringsSep ", " (map (pkg: pkg.pname or pkg.name or "unknown") (commonPackages ++ phpConfig.packages))}"
      echo ""
      ${phpConfig.shellHook}
    '';
  };

  # C++ development environment
  cpp = pkgs.mkShell {
    buildInputs = commonPackages ++ cppConfig.packages;
    shellHook = ''
      echo "🚀 Entering C++ development environment"
      echo "📦 Available tools: ${concatStringsSep ", " (map (pkg: pkg.pname or pkg.name or "unknown") (commonPackages ++ cppConfig.packages))}"
      echo ""
      ${cppConfig.shellHook}
    '';
  };

  # Python development environment with UV
  python = pkgs.mkShell {
    buildInputs = commonPackages ++ pythonConfig.packages;
    shellHook = ''
      echo "🚀 Entering Python development environment"
      echo "📦 Available tools: ${concatStringsSep ", " (map (pkg: pkg.pname or pkg.name or "unknown") (commonPackages ++ pythonConfig.packages))}"
      echo ""
      ${pythonConfig.shellHook}
    '';
  };

  # Combined Python and C++ development environment
  py-cpp = pkgs.mkShell {
    buildInputs = commonPackages ++ pythonConfig.packages ++ cppConfig.packages;
    shellHook = ''
      echo "🚀 Entering Python + C++ development environment"
      echo "📦 Combined toolchain for Python extensions and mixed projects"
      echo ""
      echo "=== 🐍 Python Environment ==="
      ${pythonConfig.shellHook}
      echo ""
      echo "=== 🚀 C++ Environment ==="
      ${cppConfig.shellHook}
    '';
  };

  # LaTeX development environment
  latex = pkgs.mkShell {
    buildInputs = commonPackages ++ latexConfig.packages;
    shellHook = ''
      echo "🚀 Entering LaTeX development environment"
      echo "📦 Available tools: ${concatStringsSep ", " (map (pkg: pkg.pname or pkg.name or "unknown") (commonPackages ++ latexConfig.packages))}"
      echo ""
      ${latexConfig.shellHook}
    '';
  };

  # Ansible development environment
  ansible = pkgs.mkShell {
    buildInputs = commonPackages ++ ansibleConfig.packages;
    shellHook = ''
      echo "🚀 Entering Ansible development environment"
      echo "📦 Available tools: ${concatStringsSep ", " (map (pkg: pkg.pname or pkg.name or "unknown") (commonPackages ++ ansibleConfig.packages))}"
      echo ""
      ${ansibleConfig.shellHook}
    '';
  };

  # You can easily add more environments here following the same pattern:
  # javascript = mkDevShell { name = "JavaScript"; packages = jsPackages; };
}
