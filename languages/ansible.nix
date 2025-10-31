{
  pkgs,
  inputs,
}:
# Ansible automation and configuration management environment
# Provides a complete Ansible development setup with Python and essential tools
{
  packages =
    [
      # Core Python runtime
      pkgs.python312

      # Ansible and related tools
      pkgs.ansible
      pkgs.ansible-lint # Best practices checker for Ansible
      pkgs.ansible-language-server # LSP for Ansible YAML files

      # Python development tools (minimal set for Ansible work)
      pkgs.python312Packages.pytest # Testing framework
      pkgs.python312Packages.pytest-ansible # Ansible-specific pytest plugin
      pkgs.python312Packages.molecule # Ansible role testing framework
      pkgs.python312Packages.molecule-plugins # Additional providers for molecule

      # YAML tools
      pkgs.yamllint # YAML linter
      pkgs.yq-go # YAML/JSON processor

      # Jinja2 tools (Ansible's templating engine)
      pkgs.python312Packages.jinja2 # Template engine

      # SSH and connection tools
      pkgs.openssh
      pkgs.sshpass # For password-based SSH (non-key authentication)

      # Common Ansible dependencies
      pkgs.python312Packages.netaddr # IP address manipulation
      pkgs.python312Packages.dnspython # DNS toolkit
      pkgs.python312Packages.pywinrm # Windows Remote Management
      pkgs.python312Packages.requests # HTTP library
      pkgs.python312Packages.pyyaml # YAML parser

      # Vault and secrets management
      pkgs.python312Packages.hvac # HashiCorp Vault client

      # System dependencies
      pkgs.git
      pkgs.gnumake
    ];

  shellHook = ''
    echo "🔧 Ansible development environment ready!"
    echo "   ansible --version: $(ansible --version | head -n1)"
    echo "   python --version: $(python --version 2>&1)"
    echo ""

    # Set up Ansible environment variables
    export ANSIBLE_HOME="$HOME/.ansible"
    export ANSIBLE_CONFIG="$PWD/ansible.cfg"
    export ANSIBLE_INVENTORY="$PWD/inventory"
    export ANSIBLE_ROLES_PATH="$PWD/roles:$HOME/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles"
    export ANSIBLE_COLLECTIONS_PATH="$PWD/collections:$HOME/.ansible/collections"

    mkdir -p "$ANSIBLE_HOME"
    mkdir -p "$HOME/.ansible/roles"
    mkdir -p "$HOME/.ansible/collections"

    echo "⚙️  Ansible environment configured:"
    echo "   ANSIBLE_HOME: $ANSIBLE_HOME"
    echo "   Config: $ANSIBLE_CONFIG"
    echo "   Inventory: $ANSIBLE_INVENTORY"
    echo ""

    echo "🔧 Development tools:"
    echo "   ✅ ansible: Core automation engine"
    echo "   ✅ ansible-lint: Playbook best practices checker"
    echo "   ✅ ansible-language-server: LSP support for editors"
    echo "   ✅ molecule: Role testing framework"
    echo "   ✅ yamllint: YAML linter"
    echo ""

    echo "💡 Quick commands:"
    echo "   ansible --version              # Show Ansible version"
    echo "   ansible-playbook playbook.yml  # Run a playbook"
    echo "   ansible-galaxy init role_name  # Create new role"
    echo "   ansible-galaxy install -r requirements.yml  # Install roles"
    echo "   ansible-inventory --list       # Show inventory"
    echo "   ansible-vault create secret.yml # Create encrypted file"
    echo ""

    echo "🧪 Testing and validation:"
    echo "   ansible-lint playbook.yml      # Lint playbook"
    echo "   yamllint .                     # Lint YAML files"
    echo "   ansible-playbook --syntax-check playbook.yml  # Syntax check"
    echo "   ansible-playbook --check playbook.yml  # Dry run (check mode)"
    echo "   molecule init role my-role     # Initialize role with tests"
    echo "   molecule test                  # Run role tests"
    echo ""

    echo "🎨 Playbook development:"
    echo "   ansible-playbook -i inventory playbook.yml  # Run with inventory"
    echo "   ansible-playbook -i inventory playbook.yml -v  # Verbose output"
    echo "   ansible-playbook -i inventory playbook.yml --limit host  # Target specific host"
    echo "   ansible-playbook -i inventory playbook.yml --tags tag1,tag2  # Run specific tags"
    echo "   ansible-playbook -i inventory playbook.yml --start-at-task 'task name'  # Start at task"
    echo ""

    echo "🔐 Ansible Vault:"
    echo "   ansible-vault create secret.yml       # Create encrypted file"
    echo "   ansible-vault edit secret.yml         # Edit encrypted file"
    echo "   ansible-vault encrypt file.yml        # Encrypt existing file"
    echo "   ansible-vault decrypt file.yml        # Decrypt file"
    echo "   ansible-vault view secret.yml         # View encrypted file"
    echo ""

    echo "📦 Galaxy (roles and collections):"
    echo "   ansible-galaxy role init my-role      # Create new role"
    echo "   ansible-galaxy role install username.rolename  # Install role"
    echo "   ansible-galaxy collection install community.general  # Install collection"
    echo "   ansible-galaxy collection install -r requirements.yml  # Install from file"
    echo ""

    echo "🔍 Ad-hoc commands:"
    echo "   ansible all -m ping            # Ping all hosts"
    echo "   ansible all -m setup           # Gather facts from all hosts"
    echo "   ansible all -a 'uptime'        # Run command on all hosts"
    echo "   ansible web -m service -a 'name=nginx state=restarted'  # Restart service"
    echo ""

    echo "📚 Documentation:"
    echo "   ansible-doc -l                 # List all modules"
    echo "   ansible-doc module_name        # Show module documentation"
    echo "   ansible-doc -t connection -l   # List connection plugins"
    echo ""
  '';
}
