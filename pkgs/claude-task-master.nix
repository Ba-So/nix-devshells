{
  pkgs,
  writeShellScriptBin ? pkgs.writeShellScriptBin,
  nodejs_20 ? pkgs.nodejs_20,
}:
# Simple wrapper around the npm package task-master-ai
# Uses npx to run the MCP server without needing to build from source
writeShellScriptBin "task-master-mcp" ''
  export PATH="${nodejs_20}/bin:$PATH"

  # Set up default directories for task master
  export TASKMASTER_DIR="''${TASKMASTER_DIR:-.taskmaster}"

  # Run the MCP server via npx
  # This will automatically download and cache the package on first run
  exec ${nodejs_20}/bin/npx --yes task-master-ai@0.36.0 "$@"
''
