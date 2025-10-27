{
  pkgs,
  inputs ? {},
}:
# Serena AI Assistant development tools using the official flake
let
  # Get Serena package from the flake input
  serenaPackage = inputs.serena.packages.${pkgs.system}.default or null;

  # Info script about Serena setup
  serenaMessage = pkgs.writeShellScriptBin "serena-info" ''
    echo "🤖 Serena AI Assistant setup:"
    echo ""
    echo "Nix environment is ready with:"
    echo "   • nixd language server for Nix files"
    echo "   • serena package from flake"
    echo ""
    echo "Available commands:"
    echo "   serena-stdio <path>     # Start MCP server with stdio transport"
    echo "   serena --help           # Show all serena commands"
    echo ""
    ${
      if serenaPackage != null
      then ''
        echo "✅ Serena package available from flake input"
      ''
      else ''
        echo "⚠️  Serena flake input not available, falling back to nix run"
      ''
    }
  '';

  # MCP stdio server command using the flake package
  serena-stdio = pkgs.writeShellScriptBin "serena-stdio" ''
    if [ -z "$1" ]; then
      echo "Usage: serena-stdio <project-path>"
      echo "Example: serena-stdio $HOME/dev/my-project"
      exit 1
    fi

    PROJECT_PATH="$(realpath "$1")"

    if [ ! -d "$PROJECT_PATH" ]; then
      echo "❌ Error: Directory does not exist: $PROJECT_PATH"
      exit 1
    fi

    echo "🚀 Starting Serena MCP server for: $PROJECT_PATH"
    cd "$PROJECT_PATH"

    ${
      if serenaPackage != null
      then ''
        exec ${serenaPackage}/bin/serena start-mcp-server --transport stdio --project "$PROJECT_PATH"
      ''
      else ''
        exec ${pkgs.nix}/bin/nix run github:oraios/serena -- start-mcp-server --transport stdio --project "$PROJECT_PATH"
      ''
    }
  '';
in {
  packages =
    [
      # Nix tools with nixd language server
      pkgs.nixd

      # Development utilities
      pkgs.jq
      pkgs.curl

      # Serena helper commands
      serenaMessage
      serena-stdio
    ]
    ++ pkgs.lib.optionals (serenaPackage != null) [serenaPackage];

  shellHook = ''
    echo "🤖 Serena AI Assistant (with Nix support):"
    echo "   serena-info             # Show setup information"
    echo "   serena-stdio <path>     # Start MCP server"
    ${
      if serenaPackage != null
      then ''
        echo "   serena --help           # Native serena commands"
      ''
      else ''
        echo "   (using fallback to nix run)"
      ''
    }
    echo ""
    echo "🔧 Nix environment includes:"
    echo "   • nixd language server for Nix development"
    echo "   • Serena AI Assistant ${
      if serenaPackage != null
      then "package"
      else "via nix run"
    }"
    echo "   • Full Nix flake support"
    echo ""
    mkdir -p "$HOME/dev"
  '';
}
