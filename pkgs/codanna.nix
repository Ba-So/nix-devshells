{
  lib,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  openssl,
  onnxruntime,
  perl,
}:
rustPlatform.buildRustPackage rec {
  pname = "codanna";
  version = "0.8.3-nix";

  src = fetchFromGitHub {
    owner = "Ba-So";
    repo = "codanna";
    rev = "main";
    hash = "sha256-BfIexYM73PuDha6G1prVBrQ1Xp8wWOvCoim53ufAs14=";
  };

  cargoHash = "sha256-qx+8mjjvPNzJPW7tBH7Pao1jqz5+HGOlC4SelC41VJA=";

  # Optimize build for faster compilation
  doCheck = false; # Skip tests to speed up build
  auditable = false; # Disable auditable builds for faster compilation

  # Build with minimal features for MCP server usage
  buildFeatures = ["http-server"]; # Only enable HTTP server, skip HTTPS for speed

  nativeBuildInputs = [pkg-config perl];
  buildInputs = [openssl onnxruntime];

  # Configure ort-sys to use system ONNX Runtime instead of downloading
  env = {
    ORT_LIB_LOCATION = "${onnxruntime}";
    ORT_SKIP_DOWNLOAD = "1";
  };

  # Explicitly set cargo install arguments to ensure binary is installed
  cargoInstallFlags = ["--path" "."];

  postInstall = ''
        # List what was actually installed
        echo "Contents of $out/bin/:"
        ls -la $out/bin/ || echo "No bin directory found"

        # Only create wrapper if binary exists
        if [ -f "$out/bin/codanna" ]; then
          # Rename original binary
          mv "$out/bin/codanna" "$out/bin/codanna-unwrapped"

          # Create wrapper script
          cat > "$out/bin/codanna" << 'EOF'
    #!/usr/bin/env bash

    # Set up runtime environment for MCP server
    export CODANNA_DATA_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/codanna"
    export CODANNA_CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/codanna"

    # Create necessary directories for model storage (~150MB) and configuration
    mkdir -p "$CODANNA_DATA_DIR" "$CODANNA_CONFIG_DIR"

    # Execute the actual codanna binary as MCP server
    exec "$(dirname "$0")/codanna-unwrapped" "$@"
    EOF
          chmod +x "$out/bin/codanna"
          echo "Created wrapper for codanna binary"
        else
          echo "ERROR: codanna binary not found after installation!"
          exit 1
        fi
  '';

  meta = with lib; {
    description = "Code intelligence for Large Language Models - semantic search and navigation";
    homepage = "https://github.com/bartolli/codanna";
    license = licenses.asl20;
    maintainers = [];
    mainProgram = "codanna";
    platforms = platforms.all;
    # Note: This package has a long build time due to ML dependencies and Rust compilation
    # Consider using binary cache or pre-built releases for faster development workflows
  };
}
