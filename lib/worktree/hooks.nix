# Shell hooks for worktree mode (orchestrator) and subtree mode (worker)
{
  pkgs,
  claudeMd,
  flakeGen,
}: {
  # Shell hook for worktree mode (orchestrator)
  # Sets up directories and generates config files
  # Uses sibling worktree pattern - main repo is the orchestrator, worktrees are siblings
  worktreeShellHook = {
    mcpConfigOrchestrator,
    mcpConfigShared,
    languages,
    mcps,
    tools,
    devshellsUrl ? "github:Ba-So/nix-devshells",
  }: let
    subtreeFlakeContent = flakeGen.generateSubtreeFlakeContent {
      inherit languages mcps tools devshellsUrl;
    };
    sharedClaudeMd = claudeMd.generateSharedClaudeMd;
    orchestratorClaudeMd = claudeMd.generateOrchestratorClaudeMd;
    orchestratorSkills = claudeMd.generateOrchestratorSkills;
  in ''
    # Worktree mode setup (sibling pattern)
    _setup_worktree_mode() {
      local project_root
      project_root="$(pwd)"

      # Verify this is a git repository
      if [ ! -d ".git" ]; then
        echo "  Warning: Not a git repository. Worktree commands won't work."
        echo "  Initialize git first: git init"
      fi

      # Ensure .shared and .orchestrator are in .gitignore
      for entry in .shared .orchestrator; do
        if ! grep -qxF "$entry" .gitignore 2>/dev/null; then
          echo "$entry" >> .gitignore
        fi
      done

      # Create .shared directory
      if [ ! -d ".shared" ]; then
        mkdir -p .shared/.codanna
        echo "  Created .shared/ directory"
      fi

      # Generate .shared/flake.nix
      cat > .shared/flake.nix << 'SUBTREE_FLAKE_EOF'
    ${subtreeFlakeContent}
    SUBTREE_FLAKE_EOF

      # Initialize .shared as its own git repo so nix flake can see the files
      (cd .shared && git init -q && git add flake.nix) 2>/dev/null
      echo "  Generated .shared/flake.nix"

      # Copy shared MCP config (without task-master)
      cp ${mcpConfigShared} .shared/.mcp.json
      echo "  Generated .shared/.mcp.json (without task-master)"

      # Generate shared CLAUDE.md
      cat > .shared/CLAUDE.md << 'SHARED_CLAUDE_EOF'
    ${sharedClaudeMd}
    SHARED_CLAUDE_EOF
      echo "  Generated .shared/CLAUDE.md"

      # Create .orchestrator directory
      if [ ! -d ".orchestrator" ]; then
        mkdir -p .orchestrator
        echo "  Created .orchestrator/ directory"
      fi

      # Copy orchestrator MCP config (with task-master)
      cp ${mcpConfigOrchestrator} .orchestrator/.mcp.json

      # Update codanna in orchestrator config to index current directory (.)
      if ${pkgs.jq}/bin/jq -e '.mcpServers.codanna' .orchestrator/.mcp.json &>/dev/null; then
        ${pkgs.jq}/bin/jq '
          .mcpServers.codanna.args = ["serve", ".", "--watch", "--watch-interval", "5"]
        ' .orchestrator/.mcp.json > .orchestrator/.mcp.json.tmp && \
        mv .orchestrator/.mcp.json.tmp .orchestrator/.mcp.json
        echo "  Configured codanna to index current directory"
      fi
      echo "  Generated .orchestrator/.mcp.json (with task-master)"

      # Generate orchestrator CLAUDE.md at root (only if not exists or is a generated file)
      if [ ! -f "CLAUDE.md" ] || grep -q "Orchestrator Agent Instructions" CLAUDE.md 2>/dev/null; then
        cat > CLAUDE.md << 'ORCHESTRATOR_CLAUDE_EOF'
    ${orchestratorClaudeMd}
    ORCHESTRATOR_CLAUDE_EOF
        echo "  Generated CLAUDE.md (orchestrator instructions)"
      else
        echo "  Keeping existing CLAUDE.md (not overwriting user content)"
      fi

      # Generate orchestrator skills in .claude/commands/
      mkdir -p .claude/commands

      cat > .claude/commands/orchestrate.md << 'SKILL_EOF'
    ${orchestratorSkills."orchestrate"}
    SKILL_EOF

      cat > .claude/commands/spawn-workers.md << 'SKILL_EOF'
    ${orchestratorSkills."spawn-workers"}
    SKILL_EOF

      cat > .claude/commands/collect-results.md << 'SKILL_EOF'
    ${orchestratorSkills."collect-results"}
    SKILL_EOF

      cat > .claude/commands/review-and-merge.md << 'SKILL_EOF'
    ${orchestratorSkills."review-and-merge"}
    SKILL_EOF

      cat > .claude/commands/iteration-loop.md << 'SKILL_EOF'
    ${orchestratorSkills."iteration-loop"}
    SKILL_EOF

      echo "  Generated .claude/commands/ (orchestrator skills)"

      # Create symlink from root to orchestrator config
      if [ ! -L ".mcp.json" ] && [ ! -f ".mcp.json" ]; then
        ln -sf .orchestrator/.mcp.json .mcp.json
        echo "  Linked .mcp.json -> .orchestrator/.mcp.json"
      elif [ -L ".mcp.json" ]; then
        # Update existing symlink
        rm .mcp.json
        ln -sf .orchestrator/.mcp.json .mcp.json
        echo "  Updated .mcp.json symlink"
      else
        # .mcp.json exists as regular file - merge configs
        if command -v ${pkgs.jq}/bin/jq &> /dev/null; then
          ${pkgs.jq}/bin/jq -s '.[0] * .[1]' .mcp.json ${mcpConfigOrchestrator} > .mcp.json.new 2>/dev/null || {
            echo "Warning: Failed to merge .mcp.json, keeping existing file"
            rm -f .mcp.json.new
          }
          [ -f .mcp.json.new ] && mv .mcp.json.new .mcp.json && echo "  Merged orchestrator MCP config into .mcp.json"
        fi
      fi

      # Set CODANNA_INDEX_DIR for shared index
      export CODANNA_INDEX_DIR="$project_root/.shared/.codanna"

      echo "  Worktree mode configured (sibling pattern)"
      echo "  CODANNA_INDEX_DIR=$CODANNA_INDEX_DIR"
    }

    _setup_worktree_mode

    echo "  Worktree commands: worktree-new, worktree-status, worktree-remove"
    echo "  Orchestrator skills: /orchestrate, /spawn-workers, /collect-results, /review-and-merge"
  '';

  # Shell hook for subtree mode (worker agents)
  # Minimal setup - just sets CODANNA_INDEX_DIR
  # Sibling pattern: worktree is at ../<project>-<branch>/, main project is at ../<project>/
  subtreeShellHook = ''
    # Subtree mode setup (worker agent in sibling worktree)
    _setup_subtree_mode() {
      local project_root
      project_root="$(pwd)"

      # Find the main project's .shared directory
      # In sibling pattern, we're at ../<project>-<branch>/, main is at ../<project>/
      # The .envrc points to ../<project>/.shared, so we can find it from the flake path

      # Try to find .shared in sibling directories
      local found_shared=""
      for sibling in ../*; do
        if [ -d "$sibling/.shared/.codanna" ]; then
          found_shared="$(cd "$sibling/.shared/.codanna" && pwd)"
          break
        fi
      done

      if [ -n "$found_shared" ]; then
        export CODANNA_INDEX_DIR="$found_shared"
        echo "  Using shared codanna index: $CODANNA_INDEX_DIR"
      else
        echo "  Warning: Shared codanna index not found in sibling directories"
        echo "  Run 'direnv allow' in the main project directory first"
      fi
    }

    _setup_subtree_mode
  '';
}
