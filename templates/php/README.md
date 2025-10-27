# PHP Development Environment

A PHP development environment using Nix flakes with comprehensive tooling for modern PHP development.

## Quick Start

```bash
# Enter the development environment
nix develop

# Or use direnv (if you have it installed)
direnv allow
```

## Included Tools

### Core PHP Environment

- **PHP 8.1+** with essential extensions
- **Composer** for dependency management
- **Symfony CLI** for framework development

### Extensions Included

- **xdebug** - Debugging and profiling
- **opcache** - Performance optimization
- **redis, memcached** - Caching backends
- **imagick, gd** - Image processing
- **pdo_mysql, pdo_pgsql, pdo_sqlite** - Database drivers

### Development Tools

- **php-codesniffer** - Code style checking
- **php-cs-fixer** - Automatic code formatting
- **php-parallel-lint** - Fast syntax checking

### Database Clients

- **MySQL 8.0** client
- **PostgreSQL** client
- **SQLite** client

### Web Development

- **Caddy** web server with automatic HTTPS
- **Node.js & npm** for frontend asset compilation

## Getting Started

### Create a new PHP project

```bash
composer create-project symfony/skeleton my-project
cd my-project
```

### Install dependencies

```bash
composer install
```

### Run development server

```bash
# Using PHP built-in server
php -S localhost:8000

# Or using Caddy for static files
caddy file-server --browse
```

### Code Quality Tools

```bash
# Check code style
composer run cs-check

# Fix code style automatically
composer run cs-fix

# Run static analysis
composer run stan

# Run tests
composer run test
```

## Development Features

### Xdebug Configuration

Xdebug is pre-configured for development:

- **Port**: 9003 (default for modern IDEs)
- **Mode**: debug, develop, coverage
- **Auto-start**: Enabled

### Database Development

Quick database setup examples:

```bash
# MySQL development database
mysql -h localhost -u root

# PostgreSQL development database
psql -h localhost -U postgres

# SQLite for lightweight development
sqlite3 database.db
```

## Project Structure

This template provides a basic structure following PHP standards:

```
├── src/           # Application source code (PSR-4: App\\)
├── tests/         # Test files (PSR-4: App\\Tests\\)
├── composer.json  # Dependencies and scripts
├── flake.nix      # Nix development environment
└── README.md      # This file
```

## Customization

### Adding PHP Extensions

Edit `flake.nix` to reference a custom PHP configuration, or modify the devshells configuration to add more extensions.

### Adding Development Tools

The environment can be extended with additional tools by modifying the `devshells/languages/php.nix` configuration.

## IDE Integration

### PhpStorm

1. Configure PHP interpreter to use the Nix-provided PHP
2. Set Xdebug port to 9003
3. Enable "Start listening for PHP Debug Connections"

### VS Code

1. Install PHP Debug extension
2. Configure launch.json with port 9003
3. Set PHP executable path to Nix-provided PHP

## Common Commands

```bash
# Package management
composer install                    # Install dependencies
composer require vendor/package     # Add new dependency
composer require --dev vendor/package # Add dev dependency
composer update                     # Update dependencies

# Symfony projects
symfony new project --webapp        # Create new Symfony webapp
symfony server:start               # Start Symfony dev server
symfony console make:controller     # Generate controller

# Testing and quality
phpunit                            # Run tests
phpcs src                          # Check coding standards
php-cs-fixer fix src               # Fix coding standards
phpstan analyse src                # Static analysis
```
