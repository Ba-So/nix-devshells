# PHP Development Environment

## Quick Start

```bash
# Activate environment
direnv allow  # or: nix develop

# Create project
composer create-project symfony/skeleton my-project

# Install dependencies
composer install

# Run server
php -S localhost:8000
```

## Included

- PHP 8.1+ with Xdebug, opcache
- Tools: composer, Symfony CLI
- Database: MySQL, PostgreSQL, SQLite clients
- Web: Caddy, Node.js

See `flake.nix` and `composer.json` for details.
