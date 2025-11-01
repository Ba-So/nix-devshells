{
  pkgs,
  fetchFromGitHub ? pkgs.fetchFromGitHub,
  buildNpmPackage ? pkgs.buildNpmPackage,
  nodejs_20 ? pkgs.nodejs_20,
  chromium ? pkgs.chromium,
}:
buildNpmPackage rec {
  pname = "puppeteer-mcp-server";
  version = "0.7.2";

  src = fetchFromGitHub {
    owner = "merajmehrabi";
    repo = "puppeteer-mcp-server";
    rev = "${version}";
    hash = "sha256-bo+yRymb4sQmpjxGu2xzHdLp1B6e2i2lABNyR9/IiSU=";
  };

  npmDepsHash = "sha256-2t5yRqrD3qe5gLHxSuGahder8W5Rezx9Hvs3Iar+IzI=";

  # Prevent Puppeteer from downloading Chrome during install
  env = {
    PUPPETEER_SKIP_DOWNLOAD = "1";
  };

  # Build the TypeScript project
  npmBuildScript = "build";

  # Custom install phase to ensure proper setup
  installPhase = ''
    runHook preInstall

    # Create the lib directory structure that npmInstallHook expects
    mkdir -p $out/lib/node_modules/${pname}

    # Copy all built files to the package directory
    cp -r dist/ $out/lib/node_modules/${pname}/
    cp -r node_modules/ $out/lib/node_modules/${pname}/
    cp package.json $out/lib/node_modules/${pname}/

    # Copy source files that might be needed at runtime
    cp -r src/ $out/lib/node_modules/${pname}/ 2>/dev/null || true

    runHook postInstall
  '';

  postInstall = ''
        # Ensure the binary is executable
        chmod +x $out/lib/node_modules/${pname}/dist/index.js

        # Create a wrapper script that sets up the environment properly
        mkdir -p $out/bin
        cat > $out/bin/mcp-server-puppeteer << EOF
    #!/usr/bin/env bash
    export NODE_PATH="$out/lib/node_modules/${pname}/node_modules:$out/lib/node_modules"

    # Set up runtime environment for MCP server
    export PUPPETEER_CACHE_DIR="\''${XDG_CACHE_HOME:-\$HOME/.cache}/puppeteer"
    export PUPPETEER_SKIP_DOWNLOAD=1
    export PUPPETEER_EXECUTABLE_PATH="${chromium}/bin/chromium"

    # Create necessary directories
    mkdir -p "\$PUPPETEER_CACHE_DIR"

    # Execute the actual MCP server
    exec ${nodejs_20}/bin/node "$out/lib/node_modules/${pname}/dist/index.js" "\$@"
    EOF
        chmod +x $out/bin/mcp-server-puppeteer
  '';

  meta = with pkgs.lib; {
    description = "Model Context Protocol (MCP) server for browser automation with Puppeteer";
    homepage = "https://github.com/merajmehrabi/puppeteer-mcp-server";
    license = licenses.mit;
    maintainers = [];
    mainProgram = "mcp-server-puppeteer";
    platforms = platforms.all;
  };
}
