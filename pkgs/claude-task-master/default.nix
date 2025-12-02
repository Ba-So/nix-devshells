{
  lib,
  stdenv,
  makeWrapper,
  nodejs_20,
}:
stdenv.mkDerivation rec {
  pname = "task-master-ai";
  version = "0.36.0";

  # No source needed - we're creating wrappers
  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [makeWrapper];

  installPhase = ''
        mkdir -p $out/bin

        # The npm package provides these binaries:
        # - task-master: CLI tool (dist/task-master.js)
        # - task-master-mcp: MCP server (dist/mcp-server.js)
        # - task-master-ai: Also MCP server (dist/mcp-server.js)

        # Main CLI wrapper - calls the task-master binary from npm
        cat > $out/bin/task-master <<'EOF'
    #!/usr/bin/env bash
    export TASKMASTER_DISABLE_AUTO_UPDATE=true
    unset NODE_ENV
    exec ${nodejs_20}/bin/npx -y -p "task-master-ai@${version}" task-master "$@"
    EOF
        chmod +x $out/bin/task-master

        # task-master-ai wrapper - calls task-master-ai binary (which is the MCP server)
        cat > $out/bin/task-master-ai <<'EOF'
    #!/usr/bin/env bash
    export TASKMASTER_DISABLE_AUTO_UPDATE=true
    unset NODE_ENV
    exec ${nodejs_20}/bin/npx -y -p "task-master-ai@${version}" task-master-ai "$@"
    EOF
        chmod +x $out/bin/task-master-ai

        # MCP server wrapper - calls the task-master-mcp binary
        cat > $out/bin/task-master-mcp <<'EOF'
    #!/usr/bin/env bash
    export TASKMASTER_DISABLE_AUTO_UPDATE=true
    unset NODE_ENV
    exec ${nodejs_20}/bin/npx -y -p "task-master-ai@${version}" task-master-mcp "$@"
    EOF
        chmod +x $out/bin/task-master-mcp
  '';

  meta = {
    description = "AI-driven task management system for development workflows (npx wrapper)";
    homepage = "https://github.com/eyaltoledano/claude-task-master";
    license = lib.licenses.mit; # Actually MIT WITH Commons-Clause
    maintainers = with lib.maintainers; [];
    platforms = lib.platforms.all;
    mainProgram = "task-master-ai";
  };
}
