{
  pkgs,
  fetchFromGitHub ? pkgs.fetchFromGitHub,
  buildNpmPackage ? pkgs.buildNpmPackage,
  nodejs_20 ? pkgs.nodejs_20,
}:
buildNpmPackage rec {
  pname = "mcp-shrimp-task-manager";
  version = "1.0.21";

  src = fetchFromGitHub {
    owner = "cjo4m06";
    repo = "mcp-shrimp-task-manager";
    rev = "v${version}";
    hash = "sha256-1IRLOgxLVVu1QrFZ99jsEfIABzIfr+9qo2LL76mwD8Q=";
  };

  npmDepsHash = "sha256-VK3XXv6IQ7+o+nkB1kFNcOwhlfC6iY4CKlsHm9qoyeA=";

  # Try using the standard npm build first
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

    # Copy source files and templates that might be needed at runtime
    cp -r src/ $out/lib/node_modules/${pname}/ 2>/dev/null || true

    runHook postInstall
  '';

  postInstall = ''
    # Ensure the binary is executable
    chmod +x $out/lib/node_modules/${pname}/dist/index.js

    # Create a wrapper script that sets up the environment properly
    mkdir -p $out/bin
    cat > $out/bin/${pname} << EOF
    #!/usr/bin/env bash
    export NODE_PATH="$out/lib/node_modules/${pname}/node_modules:$out/lib/node_modules"

    # Set up runtime environment for MCP server
    export MCP_DATA_DIR="\''${XDG_DATA_HOME:-\$HOME/.local/share}/mcp-shrimp-task-manager"
    export MCP_CONFIG_DIR="\''${XDG_CONFIG_HOME:-\$HOME/.config}/mcp-shrimp-task-manager"
    export TEMPLATES_USE="\''${TEMPLATES_USE:-en}"
    export ENABLE_GUI="\''${ENABLE_GUI:-false}"

    # Create necessary directories
    mkdir -p "\$MCP_DATA_DIR" "\$MCP_CONFIG_DIR"

    # Execute the actual MCP server
    exec ${nodejs_20}/bin/node "$out/lib/node_modules/${pname}/dist/index.js" "\$@"
    EOF
    chmod +x $out/bin/${pname}
  '';

  meta = with pkgs.lib; {
    description = "AI-powered task management system for development workflows using Model Context Protocol";
    homepage = "https://github.com/cjo4m06/mcp-shrimp-task-manager";
    license = licenses.mit;
    maintainers = [];
    mainProgram = pname;
    platforms = platforms.all;
  };
}
