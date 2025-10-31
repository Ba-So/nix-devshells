{
  pkgs,
  fetchFromGitHub ? pkgs.fetchFromGitHub,
  buildNpmPackage ? pkgs.buildNpmPackage,
  nodejs_20 ? pkgs.nodejs_20,
}:
buildNpmPackage rec {
  pname = "mcp-gitlab";
  version = "2.0.8";

  src = fetchFromGitHub {
    owner = "zereight";
    repo = "gitlab-mcp";
    rev = "v${version}";
    hash = "sha256-EqAVxX4/bCMgtVwvPtHAz3z8D9L+sU3WgORhUlduy2Q=";
  };

  npmDepsHash = "sha256-OgJKbPub5fDEMlVgXv6rOGPeNtYxkuXZamZcpcIMl3I=";

  # Build the TypeScript project
  npmBuildScript = "build";

  # Custom install phase to ensure proper setup
  installPhase = ''
    runHook preInstall

    # Create the lib directory structure that npmInstallHook expects
    mkdir -p $out/lib/node_modules/${pname}

    # Copy all built files to the package directory
    cp -r build/ $out/lib/node_modules/${pname}/
    cp -r node_modules/ $out/lib/node_modules/${pname}/
    cp package.json $out/lib/node_modules/${pname}/

    # Copy source files that might be needed at runtime
    cp -r src/ $out/lib/node_modules/${pname}/ 2>/dev/null || true

    runHook postInstall
  '';

  postInstall = ''
        # Ensure the binary is executable
        chmod +x $out/lib/node_modules/${pname}/build/index.js

        # Create a wrapper script that sets up the environment properly
        mkdir -p $out/bin
        cat > $out/bin/${pname} << EOF
    #!/usr/bin/env bash
    export NODE_PATH="$out/lib/node_modules/${pname}/node_modules:$out/lib/node_modules"

    # Execute the actual MCP server
    exec ${nodejs_20}/bin/node "$out/lib/node_modules/${pname}/build/index.js" "\$@"
    EOF
        chmod +x $out/bin/${pname}
  '';

  meta = with pkgs.lib; {
    description = "MCP server for using the GitLab API";
    homepage = "https://github.com/zereight/gitlab-mcp";
    license = licenses.mit;
    maintainers = [];
    mainProgram = pname;
    platforms = platforms.all;
  };
}
