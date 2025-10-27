{
  lib,
  fetchFromGitHub,
  makeRustPlatform,
  rust-bin,
}: let
  # Create a Rust platform with nightly toolchain for unstable features
  rustPlatform = makeRustPlatform {
    cargo = rust-bin.selectLatestNightlyWith (toolchain: toolchain.default);
    rustc = rust-bin.selectLatestNightlyWith (toolchain: toolchain.default);
  };
in
  rustPlatform.buildRustPackage rec {
    pname = "cargo-mcp";
    version = "0.2.0";

    src = fetchFromGitHub {
      owner = "jbr";
      repo = "cargo-mcp";
      rev = "v${version}";
      sha256 = "sha256-8JupxBtZSHPlOgIXIRHbUVqC3p+1abm0xJ47Mi5OWCM=";
    };

    cargoHash = "sha256-6yTD7HEc35jL/kvDs3JKTQHiat18v9jIcup9pRK20fQ=";

    meta = with lib; {
      description = "A Model Context Protocol (MCP) server that provides safe access to Cargo operations for Rust projects";
      homepage = "https://github.com/jbr/cargo-mcp";
      license = with licenses; [mit asl20];
      maintainers = [];
      mainProgram = "cargo-mcp";
    };
  }
