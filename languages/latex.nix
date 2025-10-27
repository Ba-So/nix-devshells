{
  pkgs,
  inputs,
}:
# LaTeX development tools and environment
# Provides everything needed for LaTeX document development
let
  serena = import ../base/serena.nix {inherit pkgs inputs;};
in {
  packages =
    [
      # Full TeXLive distribution with most packages (includes latexindent)
      pkgs.texliveFull

      # LaTeX development tools
      pkgs.texlab # LSP server for LaTeX

      # Modern LaTeX compilation and automation
      pkgs.tectonic # Modern, self-contained TeX/LaTeX engine
      # Note: latexmk is included in texliveFull

      # PDF viewing and manipulation
      pkgs.zathura # Lightweight PDF viewer
      pkgs.evince # GNOME PDF viewer
      pkgs.poppler_utils # PDF manipulation utilities (pdfinfo, pdftoppm, etc.)

      # Image conversion and manipulation (often needed for LaTeX)
      pkgs.imagemagick
      pkgs.ghostscript # PostScript and PDF interpreter

      # Bibliography management
      pkgs.biber # Backend for biblatex

      # Spell checking
      pkgs.aspell
      pkgs.aspellDicts.en
      pkgs.aspellDicts.de

      # Live preview and watch tools
      pkgs.watchexec # Generic file watcher for auto-recompilation
    ]
    ++ serena.packages;

  # Combined shell hook for LaTeX and Serena
  shellHook = ''
    echo "📄 LaTeX toolchain ready!"
    echo "   pdflatex: $(pdflatex --version | head -n1)"
    echo "   tectonic: $(tectonic --version)"
    echo "   texlab: $(texlab --version)"
    echo ""

    echo "🚀 Modern workflow (recommended):"
    echo "   tectonic document.tex              # Fast, modern compilation (auto-downloads packages)"
    echo "   tectonic -X compile document.tex   # Compile with live reloading"
    echo "   watchexec -e tex tectonic doc.tex  # Watch for changes and auto-compile"
    echo ""

    echo "💡 Traditional workflow:"
    echo "   pdflatex document.tex              # Traditional LaTeX compilation"
    echo "   latexmk -pdf document.tex          # Automatic compilation with proper reruns"
    echo "   latexmk -pdf -pvc document.tex     # Continuous preview mode (auto-recompile)"
    echo "   biber document                     # Process bibliography"
    echo ""

    echo "📚 Tools available:"
    echo "   texlab                             # LSP server (background)"
    echo "   zathura / evince                   # PDF viewers"
    echo "   aspell -c document.tex             # Spell checking"
    echo ""

    echo "🔧 Code quality:"
    echo "   pre-commit install                 # Set up git hooks"
    echo "   pre-commit run --all-files         # Run all hooks manually"
    echo ""

    echo "✨ Pro tips:"
    echo "   - Use tectonic for speed and automatic package management"
    echo "   - Use latexmk -pdf -pvc for live preview while editing"
    echo "   - zathura auto-reloads PDFs when they change"
    echo "   - Run 'pre-commit install' to enable automatic formatting and spell check"
    echo ""

    ${serena.shellHook}
  '';
}
