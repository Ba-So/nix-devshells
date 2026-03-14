{
  lib,
  buildNpmPackage,
  fetchzip,
  fetchurl,
  nodejs_20,
}: let
  version = "0.43.0";

  # Fetch package-lock.json from upstream (not stored in repo to save 1.2MB)
  packageLock = fetchurl {
    url = "https://raw.githubusercontent.com/eyaltoledano/claude-task-master/task-master-ai%40${version}/package-lock.json";
    hash = "sha256-bKoGo3qqiQaP3+RKI/L1Q/Ws0ozsLIaFFqxMIois048=";
  };
in
  buildNpmPackage rec {
    pname = "task-master-ai";
    inherit version;

    nodejs = nodejs_20;

    src = fetchzip {
      url = "https://registry.npmjs.org/task-master-ai/-/task-master-ai-${version}.tgz";
      hash = "sha256-Vzp2oHN+WoNWyruhG9fxh5dAALyb6LMfOhwgeySowoI=";
    };

    npmDepsHash = "sha256-srTSz0e2J8UxD61oBMj8R0jhA1gTrnmgxC6i7OOudbQ=";

    # Handle peer dependency conflicts (zod v3 vs v4)
    npmFlags = ["--legacy-peer-deps"];

    postPatch = ''
      # Use upstream lockfile (fetched at build time)
      cp ${packageLock} package-lock.json

      # Remove workspaces and devDependencies from package.json to match lockfile
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
