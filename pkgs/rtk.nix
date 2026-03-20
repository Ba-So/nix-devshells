# RTK - Rust Token Killer
# Reduces LLM token consumption by 60-90% on common development commands
{
  lib,
  fetchFromGitHub,
  makeRustPlatform,
  rust-bin,
}: let
  rustPlatform = makeRustPlatform {
    cargo = rust-bin.stable.latest.minimal;
    rustc = rust-bin.stable.latest.minimal;
  };
in
  rustPlatform.buildRustPackage rec {
    pname = "rtk";
    version = "0.31.0";

    src = fetchFromGitHub {
      owner = "rtk-ai";
      repo = "rtk";
      rev = "v${version}";
      hash = "sha256-p4OX3SSDGKlHVLIWhgKpcme449wOHbfWbc3mxlCkaMI=";
    };

    cargoHash = "sha256-37YHhccgPNUrlFh35CoQv2H+Y4e41ax0ZoIvrIC0o6I=";

    # Tests require filesystem access and git which aren't available in sandbox
    doCheck = false;

    meta = with lib; {
      description = "Rust Token Killer - Reduce LLM token usage by 60-90%";
      homepage = "https://github.com/rtk-ai/rtk";
      license = licenses.mit;
      mainProgram = "rtk";
    };
  }
