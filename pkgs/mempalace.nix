{
  lib,
  pkgs,
  fetchFromGitHub,
  pyproject-nix,
  uv2nix,
  pyproject-build-systems,
}: let
  src = fetchFromGitHub {
    owner = "MemPalace";
    repo = "mempalace";
    rev = "v3.3.3";
    hash = "sha256-XiZs46qrQnP/nL2XvxbV6z8JFOFi/MVkgvQfnOdFVI8=";
  };

  workspace = uv2nix.lib.workspace.loadWorkspace {workspaceRoot = src;};

  python = pkgs.python3;

  pythonBase = pkgs.callPackage pyproject-nix.build.packages {
    inherit python;
  };

  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  pythonSet = pythonBase.overrideScope (
    lib.composeManyExtensions [
      pyproject-build-systems.overlays.wheel
      overlay
    ]
  );

  venv = pythonSet.mkVirtualEnv "mempalace-env" workspace.deps.default;
in
  pkgs.runCommand "mempalace" {
    nativeBuildInputs = [pkgs.makeWrapper];
    meta = {
      description = "Local-first AI memory system with verbatim storage and semantic search (CLI + MCP server)";
      homepage = "https://github.com/MemPalace/mempalace";
      license = lib.licenses.mit;
      mainProgram = "mempalace";
    };
  } ''
    mkdir -p $out/bin
    for bin in mempalace mempalace-mcp; do
      makeWrapper ${venv}/bin/$bin $out/bin/$bin \
        --unset PYTHONPATH \
        --unset PYTHONHOME
    done
  ''
