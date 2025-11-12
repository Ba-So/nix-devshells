{
  pkgs,
  inputs,
  lib,
}:
# Julia development tools and environment
# Provides a comprehensive Julia development setup with testing, profiling, and quality tools
{
  meta = {
    name = "julia";
    description = "Julia development environment with comprehensive tooling";
    category = "language";
  };

  packages = [
    # Core Julia runtime
    pkgs.julia-bin

    # Development and analysis tools
    # Note: Most Julia development tools are packages installed via Pkg
    # rather than standalone executables in nixpkgs
  ];

  shellHook = ''
    echo "🔬 Julia development environment ready!"
    echo "   julia --version: $(julia --version)"
    echo ""

    # Set up Julia depot path for packages
    export JULIA_DEPOT_PATH="$HOME/.julia:${pkgs.julia-bin}/share/julia/site"

    # Enable Julia's package precompilation cache
    export JULIA_PKG_PRECOMPILE_AUTO=1

    # Set number of threads (defaults to auto-detection)
    # Users can override with: export JULIA_NUM_THREADS=X
    if [ -z "$JULIA_NUM_THREADS" ]; then
      export JULIA_NUM_THREADS=auto
    fi

    echo "📦 Julia package environment:"
    echo "   Depot: $JULIA_DEPOT_PATH"
    echo "   Threads: $JULIA_NUM_THREADS"
    echo ""

    # Check for Project.toml
    if [ -f "Project.toml" ]; then
      echo "📦 Julia project detected (Project.toml found)"
      echo "   Activate with: julia --project=."
      echo ""
    fi

    echo "💡 Quick commands:"
    echo "   julia                      # Start Julia REPL"
    echo "   julia --project=.          # Start with current project activated"
    echo "   julia script.jl            # Run Julia script"
    echo "   julia -e 'code'            # Execute Julia code"
    echo "   julia --threads=auto       # Use all available threads"
    echo ""

    echo "📦 Package management (in Julia REPL or Pkg mode with ]):"
    echo "   ]add Package               # Add a package"
    echo "   ]rm Package                # Remove a package"
    echo "   ]update                    # Update all packages"
    echo "   ]status                    # Show installed packages"
    echo "   ]activate .                # Activate current project"
    echo "   ]instantiate               # Install packages from Project.toml"
    echo "   ]precompile                # Precompile packages"
    echo ""

    echo "🧪 Testing (via Pkg in Julia REPL):"
    echo "   ]test                      # Run package tests"
    echo "   ]test --coverage           # Run tests with coverage"
    echo ""

    echo "🔧 Common development packages (install via Julia REPL):"
    echo "   ]add Revise                # Auto-reload code changes"
    echo "   ]add OhMyREPL              # Enhanced REPL with syntax highlighting"
    echo "   ]add BenchmarkTools        # Performance benchmarking"
    echo "   ]add ProfileView           # Profiling visualization"
    echo "   ]add JET                   # Static analysis tool"
    echo "   ]add Infiltrator           # Debugging breakpoints"
    echo "   ]add TestEnv               # Temporary test environments"
    echo ""

    echo "📊 Profiling and benchmarking:"
    echo "   using Profile; @profile func()  # Profile function execution"
    echo "   using BenchmarkTools; @benchmark func()  # Benchmark performance"
    echo "   using ProfileView; @profview func()  # Visual profiling"
    echo ""

    echo "📚 Documentation:"
    echo "   ?symbol                    # Get help on symbol (in REPL)"
    echo "   ]add Documenter            # Generate package documentation"
    echo "   ]add LiveServer            # Live preview documentation"
    echo ""

    echo "🎨 Code quality:"
    echo "   ]add JuliaFormatter        # Code formatting"
    echo "   ]add JET                   # Static analysis and type checking"
    echo "   ]add Aqua                  # Automated quality assurance"
    echo ""

    echo "🚀 Julia tips:"
    echo "   - Use Revise.jl for interactive development"
    echo "   - Precompile packages to reduce startup time"
    echo "   - Use @time, @benchmark for performance analysis"
    echo "   - Add startup.jl to ~/.julia/config/ for REPL customization"
    echo "   - Type ] in REPL to enter Pkg mode"
    echo "   - Type ? in REPL to enter help mode"
    echo ""
  '';

  suggestedMcps = ["serena"];
}
