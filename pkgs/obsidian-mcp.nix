{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  bun,
  nodejs_22,
  makeWrapper,
  cacert,
}: let
  pname = "obsidian-mcp-server";
  version = "3.1.4";

  src = fetchFromGitHub {
    owner = "cyanheads";
    repo = "obsidian-mcp-server";
    rev = "v${version}";
    hash = "sha256-515lTLMFxl0eLFJUxphHQ9ZRTEAXIZsiBJTlPukBYHM=";
  };

  # Fixed-output derivation for bun-installed node_modules.
  # Bun is the only supported package manager (no package-lock.json upstream),
  # so we vendor production deps as an FOD to keep the rest of the build pure.
  nodeModules = stdenvNoCC.mkDerivation {
    pname = "${pname}-node-modules";
    inherit version src;

    nativeBuildInputs = [bun cacert];

    dontConfigure = true;
    dontFixup = true;

    buildPhase = ''
      runHook preBuild
      export HOME=$TMPDIR
      export BUN_INSTALL_CACHE_DIR=$TMPDIR/bun-cache
      bun install --frozen-lockfile --ignore-scripts
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r node_modules $out/
      runHook postInstall
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-q9uwrTdXZANhSUtKOS50/QipBb56o9eFYrItNJuPljM=";
  };
in
  stdenvNoCC.mkDerivation {
    inherit pname version src;

    nativeBuildInputs = [bun nodejs_22 makeWrapper];

    buildPhase = ''
      runHook preBuild
      export HOME=$TMPDIR
      cp -a ${nodeModules}/node_modules ./node_modules
      chmod -R u+w node_modules
      node ./node_modules/typescript/bin/tsc -p tsconfig.build.json
      node ./node_modules/tsc-alias/dist/bin/index.js -p tsconfig.build.json
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin $out/share/${pname}
      cp -r dist node_modules package.json $out/share/${pname}/
      makeWrapper ${nodejs_22}/bin/node $out/bin/${pname} \
        --add-flags "$out/share/${pname}/dist/index.js"
      runHook postInstall
    '';

    meta = with lib; {
      description = "MCP server for Obsidian vaults via the Local REST API plugin";
      homepage = "https://github.com/cyanheads/obsidian-mcp-server";
      license = licenses.asl20;
      maintainers = [];
      mainProgram = pname;
      platforms = platforms.unix;
    };
  }
