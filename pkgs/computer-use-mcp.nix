{
  pkgs,
  lib ? pkgs.lib,
  fetchFromGitHub ? pkgs.fetchFromGitHub,
  python3 ? pkgs.python3,
  xdotool ? pkgs.xdotool,
  scrot ? pkgs.scrot,
  imagemagick ? pkgs.imagemagick,
  xorg ? pkgs.xorg,
}: let
  pname = "computer-use-mcp";
  version = "1.0.0";

  pythonEnv = python3.withPackages (ps: [
    ps.pillow
    ps.mcp
  ]);
in
  pkgs.stdenv.mkDerivation {
    inherit pname version;

    src = fetchFromGitHub {
      owner = "SebastianBaltes";
      repo = "claude_code_computer_use_mcp";
      rev = "e1345d32e4df578bd8f617f96504fd9c1c1d9ae3";
      hash = "sha256-SswPTh3TFZWlo6agfaPCYbAH20dC5TX7ovbrFoi5fYk=";
    };

    dontBuild = true;

    installPhase = ''
          mkdir -p $out/lib/${pname}
          cp -r computer_use_mcp $out/lib/${pname}/

          mkdir -p $out/bin
          cat > $out/bin/computer-use-mcp << EOF
      #!/usr/bin/env bash
      # Ensure required tools are in PATH
      export PATH="${xdotool}/bin:${scrot}/bin:${imagemagick}/bin:${xorg.xdpyinfo}/bin:\$PATH"

      exec ${pythonEnv}/bin/python -m computer_use_mcp.server "\$@"
      EOF
          chmod +x $out/bin/computer-use-mcp

          # Add PYTHONPATH for the module
          wrapProgram $out/bin/computer-use-mcp \
            --prefix PYTHONPATH : "$out/lib/${pname}"
    '';

    nativeBuildInputs = [pkgs.makeWrapper];

    meta = with lib; {
      description = "MCP server for Computer Use capabilities on Linux (screenshots, mouse, keyboard)";
      homepage = "https://github.com/SebastianBaltes/claude_code_computer_use_mcp";
      license = licenses.mit;
      maintainers = [];
      mainProgram = "computer-use-mcp";
      platforms = platforms.linux;
    };
  }
