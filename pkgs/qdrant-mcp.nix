{
  lib,
  pkgs,
  fetchFromGitHub,
  pyproject-nix,
  uv2nix,
  pyproject-build-systems,
}: let
  # Load the mcp-server-qdrant workspace
  src = fetchFromGitHub {
    owner = "qdrant";
    repo = "mcp-server-qdrant";
    rev = "8d6f388543e1b3043a687a3270b6cdebd54a6fe1";
    hash = "sha256-xbHCnOJLvCyTl/ZwhBtMmSd3TZ9o59SGI7/tgql5jg8=";
  };

  workspace = uv2nix.lib.workspace.loadWorkspace {workspaceRoot = src;};

  # Select Python interpreter
  python = pkgs.python3;

  # Create base Python package set
  pythonBase = pkgs.callPackage pyproject-nix.build.packages {
    inherit python;
  };

  # Create overlay from uv.lock
  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel"; # Prefer binary wheels
  };

  # Compose into final Python set with build systems
  pythonSet = pythonBase.overrideScope (
    lib.composeManyExtensions [
      pyproject-build-systems.overlays.wheel
      overlay
    ]
  );
in
  # Build virtual environment with all dependencies
  pythonSet.mkVirtualEnv "mcp-server-qdrant-env" workspace.deps.default
