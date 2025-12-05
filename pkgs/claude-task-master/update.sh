#!/usr/bin/env bash
# Update script for task-master-ai package

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Function to print colored messages
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if version is provided
if [ $# -eq 0 ]; then
    error "Usage: $0 <version>"
fi

VERSION="$1"
info "Updating task-master-ai to version $VERSION"

# Step 1: Fetch package-lock.json from GitHub tag
info "Fetching package-lock.json from GitHub tag task-master-ai@${VERSION}..."
if ! curl -fsSL "https://raw.githubusercontent.com/eyaltoledano/claude-task-master/task-master-ai@${VERSION}/package-lock.json" -o "$SCRIPT_DIR/package-lock.json"; then
    error "Failed to fetch package-lock.json from GitHub tag task-master-ai@${VERSION}"
fi

# Verify version matches
LOCK_VERSION=$(grep -m1 '"version":' "$SCRIPT_DIR/package-lock.json" | sed 's/.*"\([0-9.]*\)".*/\1/')
if [ "$LOCK_VERSION" != "$VERSION" ]; then
    warn "package-lock.json version ($LOCK_VERSION) differs from requested version ($VERSION)"
fi

# Step 2: Update version in default.nix
info "Updating version in default.nix..."
sed -i "s/version = \".*\";/version = \"${VERSION}\";/" "$SCRIPT_DIR/default.nix"

# Step 3: Set hashes to lib.fakeHash temporarily
info "Setting hashes to lib.fakeHash for hash calculation..."
sed -i 's/npmDepsHash = ".*";/npmDepsHash = lib.fakeHash;/' "$SCRIPT_DIR/default.nix"
sed -i 's/hash = "sha256-.*";/hash = lib.fakeHash;/' "$SCRIPT_DIR/default.nix"

# Step 4: Get the source hash
info "Calculating source hash..."
cd "$SCRIPT_DIR"
SOURCE_HASH=$(nix-prefetch-url --type sha256 --unpack "https://registry.npmjs.org/task-master-ai/-/task-master-ai-${VERSION}.tgz" 2>&1 | tail -1)
if [ -z "$SOURCE_HASH" ]; then
    error "Failed to calculate source hash"
fi
SOURCE_HASH_SRI=$(nix hash convert --hash-algo sha256 --to sri "$SOURCE_HASH")
info "Source hash: $SOURCE_HASH_SRI"

# Update source hash
sed -i "s|hash = lib.fakeHash;|hash = \"${SOURCE_HASH_SRI}\";|" "$SCRIPT_DIR/default.nix"

# Step 5: Build to get the real npmDepsHash
info "Building package to determine npmDepsHash..."
cd "$REPO_ROOT"
BUILD_OUTPUT=$(NIXPKGS_ALLOW_UNFREE=1 nix build .#claude-task-master --impure 2>&1 || true)

# Extract the hash from build output
NPM_DEPS_HASH=$(echo "$BUILD_OUTPUT" | grep -oP 'got:\s+\K(sha256-[A-Za-z0-9+/=]+)' | head -1)

if [ -z "$NPM_DEPS_HASH" ]; then
    error "Failed to extract npmDepsHash from build output"
fi

info "npmDepsHash: $NPM_DEPS_HASH"

# Step 6: Update default.nix with the real npmDepsHash
info "Updating default.nix with real npmDepsHash..."
sed -i "s/npmDepsHash = lib.fakeHash;/npmDepsHash = \"${NPM_DEPS_HASH}\";/" "$SCRIPT_DIR/default.nix"

# Step 7: Verify the build
info "Verifying the build..."
if NIXPKGS_ALLOW_UNFREE=1 nix build .#claude-task-master --impure > /dev/null 2>&1; then
    info "Build successful!"
else
    error "Build verification failed"
fi

# Clean up result symlink
rm -f result

info "Successfully updated task-master-ai to version $VERSION"
info "Updated files:"
info "  - default.nix (version: $VERSION, source hash: $SOURCE_HASH_SRI, npmDepsHash: $NPM_DEPS_HASH)"
info "  - package-lock.json"
echo ""
warn "Don't forget to test the package and commit the changes!"
