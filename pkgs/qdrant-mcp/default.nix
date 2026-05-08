{
  lib,
  pkgs,
  fetchFromGitHub,
  pyproject-nix,
  uv2nix,
  pyproject-build-systems,
}: let
  src = fetchFromGitHub {
    owner = "qdrant";
    repo = "mcp-server-qdrant";
    rev = "8d6f388543e1b3043a687a3270b6cdebd54a6fe1";
    hash = "sha256-xbHCnOJLvCyTl/ZwhBtMmSd3TZ9o59SGI7/tgql5jg8=";
  };

  workspace = uv2nix.lib.workspace.loadWorkspace {workspaceRoot = ./.;};

  python = pkgs.python3;

  pythonBase = pkgs.callPackage pyproject-nix.build.packages {
    inherit python;
  };

  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  srcOverlay = _final: prev: {
    mcp-server-qdrant = prev.mcp-server-qdrant.overrideAttrs (_old: {
      inherit src;
    });
  };

  pythonSet = pythonBase.overrideScope (
    lib.composeManyExtensions [
      pyproject-build-systems.overlays.wheel
      overlay
      srcOverlay
    ]
  );

  venv = pythonSet.mkVirtualEnv "mcp-server-qdrant-env" workspace.deps.default;
in
  pkgs.runCommand "mcp-server-qdrant" {
    nativeBuildInputs = [pkgs.makeWrapper];
    meta = {
      description = "MCP server for Qdrant semantic search";
      mainProgram = "mcp-server-qdrant";
    };
  } ''
    mkdir -p $out/bin
    makeWrapper ${venv}/bin/mcp-server-qdrant $out/bin/mcp-server-qdrant \
      --unset PYTHONPATH \
      --unset PYTHONHOME
  ''
