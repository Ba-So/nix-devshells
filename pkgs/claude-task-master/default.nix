{
  lib,
  buildNpmPackage,
  fetchzip,
  nodejs_20,
  makeWrapper,
}:
buildNpmPackage rec {
  pname = "task-master-ai";
  version = "0.36.0";

  nodejs = nodejs_20;

  src = fetchzip {
    url = "https://registry.npmjs.org/task-master-ai/-/task-master-ai-${version}.tgz";
    hash = "sha256-SyczLmdvUroERsQvEfPrIpF2NMHr1kNTkswMmnrM5WQ=";
  };

  npmDepsHash = "sha256-1klKS4+Z0Tf0qlCTHk2/9+9nCQE1fQGW8h8goM1r6Sw=";

  nativeBuildInputs = [makeWrapper];

  npmFlags = ["--legacy-peer-deps"];
  makeCacheWritable = true;

  postPatch = ''
    # Replace with our clean package.json and package-lock.json
    # These have optional dependencies, workspaces, and devDependencies removed
    cp ${./claude-task-master-package.json} package.json
    cp ${./claude-task-master-package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;

  # Disable auto-updates and set up environment
  postInstall = ''
    # Ensure binaries are executable
    chmod +x $out/lib/node_modules/${pname}/dist/task-master.js
    chmod +x $out/lib/node_modules/${pname}/dist/mcp-server.js

    # Wrap binaries to set environment variables
    for bin in task-master task-master-ai task-master-mcp; do
      wrapProgram $out/bin/$bin \
        --set TASKMASTER_DISABLE_AUTO_UPDATE true \
        --unset NODE_ENV
    done
  '';

  meta = {
    description = "AI-driven task management system for development workflows";
    homepage = "https://github.com/eyaltoledano/claude-task-master";
    license = lib.licenses.unfree; # MIT WITH Commons-Clause
    maintainers = with lib.maintainers; [];
    platforms = lib.platforms.all;
    mainProgram = "task-master-ai";
  };
}
