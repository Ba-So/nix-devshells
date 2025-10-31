# CI/CD Pipeline Documentation

This repository uses GitHub Actions for continuous integration and automated maintenance.

## Workflows

### 🔍 CI (Continuous Integration)

**File:** `.github/workflows/ci.yaml`
**Triggers:** Push to main, Pull Requests, Manual dispatch

#### Tier 1: Fast Validation (~2-5 minutes)

- **Nix Flake Check**: Validates all flake outputs without building
- **Pre-commit Hooks**: Runs all pre-commit checks (format, lint, security)
- **Nix Formatting**: Verifies Alejandra formatting, deadnix, and statix linting

#### Tier 2: Build Validation (~5-15 minutes)

- **Build Packages**: Builds and tests all custom packages
  - cargo-mcp
  - cratedocs-mcp
- **Test DevShells**: Instantiates all development shells
  - rust, php, nix, cpp, python, py-cpp, latex, ansible
- **Test Templates**: Validates template initialization
  - rust, php, latex, cpp

#### Summary Job

- **CI Success**: Aggregates all job results for branch protection

### 🏷️ PR Labeler

**File:** `.github/workflows/pr-labels.yaml`
**Triggers:** PR opened, synchronized, reopened

Automatically labels PRs based on changed files:

- `nix` - Nix file changes
- `flake` - Flake changes
- `ci` - CI configuration changes
- `pre-commit` - Pre-commit hook changes
- `templates` - Template changes
- `packages` - Package changes
- `documentation` - Documentation changes
- `devshells` - DevShell changes
- Language-specific labels (rust, php, cpp, latex, python, ansible)

### 🔄 Update Flake Inputs

**File:** `.github/workflows/update-flake.yaml`
**Triggers:** Weekly schedule (Monday 9:00 UTC), Manual dispatch

Automatically creates PRs to update flake inputs:

1. Runs `nix flake update`
2. Creates a PR with changes
3. Labels PR as `dependencies`, `flake`, `automated`
4. Includes update summary in PR description

### 📦 Dependabot

**File:** `.github/dependabot.yaml`

- Updates GitHub Actions weekly
- Labels updates as `dependencies`, `github-actions`

**Note:** Nix flake inputs are updated via the Update Flake Inputs workflow, not Dependabot.

## Caching

### Cachix

The workflows use Cachix for caching Nix store paths:

- **Cache:** nix-community
- **Auth Token:** Set via `CACHIX_AUTH_TOKEN` secret
- **Mode:** Read-only (skipPush: true)

To enable pushing to your own cache:

1. Create a Cachix cache
2. Add `CACHIX_AUTH_TOKEN` to repository secrets
3. Change cache name in workflows
4. Remove `skipPush: true`

## Branch Protection

Recommended branch protection rules for `main`:

```yaml
Required status checks:
  - CI Success
Require branches to be up to date: true
Require linear history: true
```

## Running Locally

### Run all CI checks

```bash
# Flake check
nix flake check --no-build

# Pre-commit hooks
pre-commit run --all-files

# Build packages
nix build .#cargo-mcp
nix build .#cratedocs-mcp

# Test devshell
nix develop .#rust --command echo "Success"

# Test template
mkdir test-rust && cd test-rust
nix flake init -t ..#rust
nix flake check --no-build
```

### Update flake inputs manually

```bash
# Update all inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs

# Test after update
nix flake check
```

## Performance

### Typical Run Times

- **Fast validation jobs**: 2-5 minutes
- **Build validation jobs**: 5-15 minutes per package/shell/template
- **Full CI run**: ~15-20 minutes (parallel execution)

### Optimization Tips

1. **Use Cachix**: Significantly speeds up builds
2. **Concurrency**: Workflows cancel in-progress runs on new pushes
3. **Matrix strategy**: Packages, devshells, and templates tested in parallel
4. **fail-fast: false**: All tests run even if one fails

## Troubleshooting

### Workflow fails but passes locally

1. Check GitHub Actions runner environment
2. Verify secrets are configured
3. Check if cache is accessible

### Build timeouts

1. Increase timeout in workflow
2. Check for missing cache hits
3. Consider splitting large builds

### Flake lock out of sync

Run locally:

```bash
nix flake update
git add flake.lock
git commit -m "chore: update flake.lock"
```

## Contributing

When adding new components:

1. Add build/test jobs to CI workflow
2. Update PR labeler configuration
3. Document any new secrets or configuration
4. Test locally before pushing

## Monitoring

GitHub provides workflow run history:

- **Actions tab**: View all workflow runs
- **Status badges**: Add to README
- **Email notifications**: Configure in GitHub settings
