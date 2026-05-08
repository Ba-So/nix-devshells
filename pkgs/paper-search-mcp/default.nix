{
  lib,
  pkgs,
  fetchFromGitHub,
  pyproject-nix,
  uv2nix,
  pyproject-build-systems,
}: let
  src = fetchFromGitHub {
    owner = "openags";
    repo = "paper-search-mcp";
    rev = "cf2697fd04a7b7c1ced0e382ab84f0c214614f83";
    hash = "sha256-xnNvIcGHNe7L9OSRwCExQMnBJGbpSA5iUZZ/CVd1XGA=";
  };

  workspace = uv2nix.lib.workspace.loadWorkspace {workspaceRoot = ./.;};

  python = pkgs.python3;

  pythonBase = pkgs.callPackage pyproject-nix.build.packages {
    inherit python;
  };

  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  buildSystemOverlay = final: prev: {
    sgmllib3k = prev.sgmllib3k.overrideAttrs (old: {
      nativeBuildInputs =
        (old.nativeBuildInputs or [])
        ++ [
          final.setuptools
        ];
    });
  };

  srcOverlay = _final: prev: {
    paper-search-mcp = prev.paper-search-mcp.overrideAttrs (_old: {
      inherit src;
    });
  };

  pythonSet = pythonBase.overrideScope (
    lib.composeManyExtensions [
      pyproject-build-systems.overlays.wheel
      overlay
      buildSystemOverlay
      srcOverlay
    ]
  );

  venv = pythonSet.mkVirtualEnv "paper-search-mcp-env" workspace.deps.default;
in
  pkgs.runCommand "paper-search-mcp" {
    nativeBuildInputs = [pkgs.makeWrapper];
    meta = {
      description = "MCP server for searching academic papers (arXiv, PubMed, bioRxiv, etc.)";
      homepage = "https://github.com/openags/paper-search-mcp";
      license = lib.licenses.mit;
      mainProgram = "paper-search-mcp";
    };
  } ''
    mkdir -p $out/bin
    makeWrapper ${venv}/bin/python $out/bin/paper-search-mcp \
      --add-flags "-m" \
      --add-flags "paper_search_mcp.server" \
      --unset PYTHONPATH \
      --unset PYTHONHOME
  ''
