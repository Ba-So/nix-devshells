# Worktree helper scripts (worktree-new, worktree-status, worktree-remove)
# Uses sibling worktree pattern: worktrees are created as siblings of the main repo
{pkgs}: rec {
  # Create worktree helper scripts as actual executables
  mkWorktreeScripts = _:
    pkgs.stdenvNoCC.mkDerivation {
      name = "worktree-scripts";
      dontUnpack = true;
      buildInputs = [pkgs.git];

      installPhase = ''
              mkdir -p $out/bin

              # worktree-new script
              cat > $out/bin/worktree-new << 'SCRIPT_EOF'
        #!/usr/bin/env bash
        set -euo pipefail

        branch="''${1:-}"
        if [ -z "$branch" ]; then
          echo "Usage: worktree-new <branch-name>"
          echo "Creates a new git worktree as a sibling directory"
          echo ""
          echo "Example: worktree-new feature-auth"
          echo "  Creates: ../<project>-feature-auth/"
          exit 1
        fi

        # Check we're in the project root (where .shared/ lives)
        if [ ! -d ".shared" ]; then
          echo "Error: .shared/ directory not found."
          echo "Run this command from the project root (orchestrator directory)."
          exit 1
        fi

        # Check this is a git repository
        if [ ! -d ".git" ]; then
          echo "Error: Current directory is not a git repository."
          exit 1
        fi

        # Get project name from current directory
        project_name=$(basename "$(pwd)")
        worktree_path="../''${project_name}-''${branch}"

        # Check if worktree already exists
        if [ -d "$worktree_path" ]; then
          echo "Error: Directory $worktree_path already exists"
          exit 1
        fi

        # Create the git worktree as a sibling
        echo "Creating git worktree for branch '$branch'..."
        if git worktree add "$worktree_path" -b "$branch" 2>/dev/null || git worktree add "$worktree_path" "$branch"; then
          echo "  Created worktree at $worktree_path"
        else
          echo "Error: Failed to create worktree"
          exit 1
        fi

        # Create .envrc in worktree pointing back to .shared
        cat > "$worktree_path/.envrc" << ENVRC_EOF
        # Use the shared subtree flake for worker agents
        use flake ../$project_name/.shared --impure
        ENVRC_EOF
        echo "  Created $worktree_path/.envrc"

        # Create symlinks to shared config
        ln -sf "../$project_name/.shared/.mcp.json" "$worktree_path/.mcp.json"
        echo "  Linked .mcp.json -> ../$project_name/.shared/.mcp.json"

        ln -sf "../$project_name/.shared/CLAUDE.md" "$worktree_path/CLAUDE.md"
        echo "  Linked CLAUDE.md -> ../$project_name/.shared/CLAUDE.md"

        echo ""
        echo "Worktree '$branch' created successfully!"
        echo "  Path: $worktree_path"
        echo "  Shell: use flake ../$project_name/.shared --impure"

        # Auto-allow direnv if available
        if command -v direnv &> /dev/null; then
          echo ""
          echo "Allowing direnv in worktree..."
          direnv allow "$worktree_path"
          echo "  direnv allowed for $worktree_path"
        else
          echo ""
          echo "To activate: cd $worktree_path && direnv allow"
        fi
        SCRIPT_EOF
              chmod +x $out/bin/worktree-new

              # worktree-status script
              cat > $out/bin/worktree-status << 'SCRIPT_EOF'
        #!/usr/bin/env bash
        set -euo pipefail

        project_name=$(basename "$(pwd)")

        echo "=== Project: $project_name ==="
        echo "  Location: $(pwd)"
        echo ""

        echo "=== Git Worktrees ==="
        if [ -d ".git" ]; then
          git worktree list
        else
          echo "  Error: Current directory is not a git repository"
        fi
        echo ""

        echo "=== Shared Resources ==="
        if [ -d ".shared" ]; then
          echo "  .shared/flake.nix: $([ -f .shared/flake.nix ] && echo 'present' || echo 'MISSING')"
          echo "  .shared/.mcp.json: $([ -f .shared/.mcp.json ] && echo 'present' || echo 'MISSING')"
          echo "  .shared/CLAUDE.md: $([ -f .shared/CLAUDE.md ] && echo 'present' || echo 'MISSING')"
          echo "  .shared/.codanna/: $([ -d .shared/.codanna ] && echo 'present' || echo 'MISSING')"
          if [ -d .shared/.codanna ]; then
            index_size=$(du -sh .shared/.codanna 2>/dev/null | cut -f1)
            echo "    Index size: $index_size"
          fi
        else
          echo "  .shared/ directory: MISSING"
        fi
        echo ""

        echo "=== Orchestrator ==="
        echo "  .orchestrator/.mcp.json: $([ -f .orchestrator/.mcp.json ] && echo 'present' || echo 'MISSING')"
        if [ -L ".mcp.json" ]; then
          echo "  .mcp.json: symlink -> $(readlink .mcp.json)"
        elif [ -f ".mcp.json" ]; then
          echo "  .mcp.json: regular file"
        else
          echo "  .mcp.json: MISSING"
        fi
        echo ""

        echo "=== Environment ==="
        echo "  CODANNA_INDEX_DIR: ''${CODANNA_INDEX_DIR:-not set}"
        SCRIPT_EOF
              chmod +x $out/bin/worktree-status

              # worktree-remove script
              cat > $out/bin/worktree-remove << 'SCRIPT_EOF'
        #!/usr/bin/env bash
        set -euo pipefail

        branch="''${1:-}"
        if [ -z "$branch" ]; then
          echo "Usage: worktree-remove <branch-name>"
          echo "Removes a sibling git worktree"
          exit 1
        fi

        project_name=$(basename "$(pwd)")
        worktree_path="../''${project_name}-''${branch}"

        if [ ! -d "$worktree_path" ]; then
          echo "Error: Worktree directory $worktree_path does not exist"
          exit 1
        fi

        # Run git worktree remove
        echo "Removing git worktree '$branch'..."
        git worktree remove "$worktree_path" --force
        echo "  Removed worktree at $worktree_path"

        # Optionally remove the branch
        read -p "Also delete branch '$branch'? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          git branch -D "$branch" 2>/dev/null && echo "  Deleted branch '$branch'" || echo "  Could not delete branch (may not exist or be checked out elsewhere)"
        fi
        SCRIPT_EOF
              chmod +x $out/bin/worktree-remove
      '';
    };

  # Default worktree scripts
  worktreeScripts = mkWorktreeScripts {};
}
