# Rust Development Environment

## Quick Start

```bash
# Activate environment
direnv allow  # or: nix develop

# Initialize project
cargo init

# Development workflow
just          # Show available commands
just dev-check # Check, lint, test
just run      # Build and run
```

## Included

- Rust toolchain: cargo, rustc, rust-analyzer, clippy, rustfmt
- Development: cargo-watch, cargo-edit, cargo-nextest, sccache
- Tools: git, pre-commit, direnv, helix

See `flake.nix` and `justfile` for details.
