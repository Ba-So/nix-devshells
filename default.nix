{
  inputs, # Required by flake interface, now used for module system
  pkgs,
  _system, # Required by flake interface, used for module system
}: let
  # Import lib system for module-based composition
  libSystem = import ./lib/default.nix {
    inherit pkgs inputs;
    system = _system;
  };
in {
  # Expose package sets for composition in other projects
  # Maintained for backward compatibility
  packageSets = {
    common = libSystem.modules.presets.standard.packages;
    rust = libSystem.modules.languages.rust.packages;
    nix = libSystem.modules.languages.nix.packages;
    php = libSystem.modules.languages.php.packages;
    cpp = libSystem.modules.languages.cpp.packages;
    python = libSystem.modules.languages.python.packages;
    latex = libSystem.modules.languages.latex.packages;
    ansible = libSystem.modules.languages.ansible.packages;
  };

  # Rust development environment
  rust = libSystem.composeShell {
    languages = ["rust"];
    tools = "standard";
  };

  # Nix development environment
  nix = libSystem.composeShell {
    languages = ["nix"];
    tools = "standard";
  };

  # PHP development environment
  php = libSystem.composeShell {
    languages = ["php"];
    tools = "standard";
  };

  # C++ development environment
  cpp = libSystem.composeShell {
    languages = ["cpp"];
    tools = "standard";
  };

  # Python development environment with UV
  python = libSystem.composeShell {
    languages = ["python"];
    tools = "standard";
  };

  # Combined Python and C++ development environment
  py-cpp = libSystem.composeShell {
    languages = ["python" "cpp"];
    tools = "standard";
  };

  # LaTeX development environment
  latex = libSystem.composeShell {
    languages = ["latex"];
    tools = "standard";
  };

  # Ansible development environment
  ansible = libSystem.composeShell {
    languages = ["ansible"];
    tools = "standard";
  };
}
