# Rust Development Environment

This project uses a centralized development shell configuration for Rust development.

## Quick Start

1. **Direnv (Recommended)**: If you have direnv installed, the development environment will activate automatically when you enter this directory.

2. **Manual activation**:

   ```bash
   nix develop
   ```

3. **Specific shell**:
   ```bash
   nix develop .#rust
   ```

## Available Tools

This environment includes:

- **Rust toolchain**: cargo, rustc
- **Development tools**: rust-analyzer, clippy, rustfmt
- **Common utilities**: cargo-watch, cargo-edit, cargo-outdated, cargo-audit
- **Testing**: cargo-nextest, cargo-criterion
- **Cross-compilation**: cargo-cross
- **Base tools**: git, pre-commit, direnv, helix, and more

## Getting Started with Your Project

```bash
# Initialize a new Rust project
cargo new my-rust-project
cd my-rust-project

# Or initialize in current directory
cargo init

# Set up pre-commit hooks (recommended)
just setup-hooks

# See all available commands
just

# Quick development workflow
just dev-check    # Run check, lint, and test
just run          # Build and run the project
```

## Code Quality Tools

This template includes:

- **`.pre-commit-config.yaml`**: Automated code quality checks

  - `cargo fmt` - Code formatting
  - `cargo clippy` - Linting with sensible allow rules
  - `cargo check` - Compilation check
  - `cargo test` - Run tests (pre-push only)
  - `cargo audit` - Security audit (pre-push only)

- **`rustfmt.toml`**: Rust formatting configuration
  - 100 character line width
  - Rust 2021 edition
  - Tall function parameter layout

Run pre-commit manually: `pre-commit run --all-files`

## Just Commands

This template includes a comprehensive `justfile` with common Rust development tasks:

**Development:**

- `just run` - Run the project
- `just check` - Check code for errors
- `just test` - Run tests
- `just dev-check` - Run check, lint, and test together
- `just dev-watch` - Auto-run checks on file changes

**Code Quality:**

- `just fmt` - Format code
- `just lint` - Run clippy linter
- `just quality` - Run format, lint, and test
- `just setup-hooks` - Install pre-commit hooks

**Analysis & Optimization:**

- `just bloat` - Analyze binary size
- `just machete` - Find unused dependencies
- `just llvm-lines` - Count LLVM IR lines
- `just loc` - Count lines of code
- `just cache-stats` - Show sccache statistics

**Build & Maintenance:**

- `just build` - Build release version
- `just clean` - Clean build artifacts
- `just update` - Update dependencies
- `just audit` - Security audit

Run `just` to see all available commands.

## Environment Updates

This development environment is automatically updated from the central configuration. No manual maintenance required for tool versions or configurations.
