{
  lib,
  buildNpmPackage,
  fetchzip,
  nodejs_20,
}:
buildNpmPackage rec {
  pname = "task-master-ai";
  version = "0.37.0";

  nodejs = nodejs_20;

  src = fetchzip {
    url = "https://registry.npmjs.org/task-master-ai/-/task-master-ai-${version}.tgz";
    hash = "sha256-kGnxv9hpbTEFapn2L+DUzZfu7eiNS4GsGHfX0djuzpA=";
  };

  npmDepsHash = "sha256-udJWH9LfSMcb0zW7uuUyhy3LQsrObYTaObPcSCMUESw=";

  # Handle peer dependency conflicts (zod v3 vs v4)
  npmFlags = ["--legacy-peer-deps"];

  postPatch = ''
    # Use our pre-generated clean lockfile (generated from npm tarball without workspaces)
    cp ${./package-lock.json} package-lock.json

    # Remove workspaces and devDependencies from package.json to match our lockfile
    ${nodejs_20}/bin/node <<'PATCH_SCRIPT'
      const fs = require('fs');
      const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
      delete pkg.workspaces;
      delete pkg.devDependencies;
      fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
    PATCH_SCRIPT
  '';

  # The npm package is already pre-built (dist/ contains compiled JS)
  dontNpmBuild = true;

  AUTHORIZED = "1";

  # Disable auto-updates and create wrapper scripts
  postInstall = ''
    wrapProgram $out/bin/task-master \
      --set TASKMASTER_SKIP_AUTO_UPDATE 1 \
      --unset NODE_ENV

    wrapProgram $out/bin/task-master-mcp \
      --set TASKMASTER_SKIP_AUTO_UPDATE 1 \
      --unset NODE_ENV

    wrapProgram $out/bin/task-master-ai \
      --set TASKMASTER_SKIP_AUTO_UPDATE 1 \
      --unset NODE_ENV
  '';

  meta = {
    description = "AI-driven task management system for development workflows";
    homepage = "https://github.com/eyaltoledano/claude-task-master";
    license = lib.licenses.unfree; # MIT WITH Commons-Clause
    maintainers = [];
    platforms = lib.platforms.all;
    mainProgram = "task-master";
  };
}
