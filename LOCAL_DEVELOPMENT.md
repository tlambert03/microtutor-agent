# Local Moodle Development Environment

This guide will help you clone your AWS Lightsail Moodle instance to your local machine for development and testing.

## Prerequisites

Before you begin, ensure you have:

1. **Docker Desktop** installed and running
   - Download from: https://www.docker.com/products/docker-desktop
   - Verify installation: `docker --version` and `docker compose version`

2. **SSH access** to your Lightsail instance
   - Private key file (.pem)
   - IP address of your instance
   - SSH user (usually `ubuntu`)

3. **Disk space**: At least 5-10 GB free for Moodle files and database

## Quick Start

### 1. Configure Environment Variables

Copy the example environment file and fill in your Lightsail details:

```bash
cp .env.example .env
```

Edit `.env` and configure at minimum:

```bash
# REQUIRED - Your Lightsail instance details
MOODLE_LIGHTSAIL_IP="YOUR_IP_HERE"
MOODLE_SSH_KEY="$HOME/.ssh/your-key.pem"

# REQUIRED - Remote Moodle paths (check your Lightsail instance)
MOODLE_REMOTE_DIR="/opt/bitnami/moodle"
MOODLE_REMOTE_DATA_DIR="/opt/bitnami/moodledata"

# REQUIRED - Remote database credentials
MOODLE_DB_NAME="bitnami_moodle"
MOODLE_DB_USER="bn_moodle"
# MOODLE_DB_PASSWORD will be auto-detected from config.php
```

#### Finding Your Remote Paths

If you're not sure about the paths, SSH into your Lightsail instance:

```bash
ssh -i ~/.ssh/your-key.pem ubuntu@YOUR_IP

# Find Moodle installation directory
sudo find / -name "config.php" -path "*/moodle/config.php" 2>/dev/null

# Check config.php for paths
sudo grep -E "wwwroot|dataroot|dbname|dbuser" /path/to/moodle/config.php
```

Common configurations:
- **Bitnami Stack**: `/opt/bitnami/moodle` and `/opt/bitnami/moodledata`
- **Standard LAMP**: `/var/www/html/moodle` and `/var/moodledata`

### 2. Run the Setup Script

Once your `.env` file is configured, run:

```bash
./scripts/setup_local_dev.sh
```

This script will:
1. ✅ Validate prerequisites (Docker, .env file)
2. 📦 Backup remote Moodle instance
3. 📂 Extract backup files
4. 🐳 Start Docker containers (web, database, PHPMyAdmin)
5. 💾 Import database
6. ⚙️  Configure Moodle for local development
7. 🚀 Launch your local environment

The entire process takes 10-30 minutes depending on your internet speed and Moodle size.

### 3. Access Your Local Moodle

Once setup is complete, access your local instance at:

- **Moodle**: http://localhost:8080
- **PHPMyAdmin**: http://localhost:8081
- **Database**: localhost:3306

Use the same admin credentials as your production site.

## Managing Your Local Environment

### Start Containers

```bash
docker compose up -d
```

### Stop Containers

```bash
docker compose down
```

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f web
docker compose logs -f db
```

### Access Container Shell

```bash
# Web server
docker compose exec web bash

# Database
docker compose exec db bash
```

### Clear Moodle Caches

```bash
docker compose exec web php /var/www/html/admin/cli/purge_caches.php
```

### Run Moodle CLI Commands

```bash
# General pattern
docker compose exec web php /var/www/html/admin/cli/COMMAND.php

# Examples
docker compose exec web php /var/www/html/admin/cli/maintenance.php --enable
docker compose exec web php /var/www/html/admin/cli/upgrade.php
docker compose exec web php /var/www/html/admin/cli/cron.php
```

## Development Workflow

### Making Code Changes

Your local Moodle files are in `./local-moodle/`. Changes are immediately reflected because Docker mounts this directory.

1. Edit files in `./local-moodle/`
2. Clear caches: `docker compose exec web php /var/www/html/admin/cli/purge_caches.php`
3. Refresh browser

### Database Changes

Access PHPMyAdmin at http://localhost:8081 or use CLI:

```bash
docker compose exec db mysql -u moodleuser -pmoodlepass moodle_local
```

### Testing Plugins

1. Add plugin to `./local-moodle/mod/` or appropriate directory
2. Visit Site Administration → Notifications
3. Follow installation prompts

## Syncing with Remote Changes

If your production site changes and you want to refresh your local copy:

```bash
# Backup remote again
./scripts/backup_moodle.sh

# Reset local environment
docker compose down -v  # WARNING: Destroys local database
rm -rf local-moodle local-moodledata

# Re-run setup
./scripts/setup_local_dev.sh
```

## Troubleshooting

### Docker Issues

**Docker not running:**
```bash
# Start Docker Desktop application
open -a Docker  # macOS
```

**Port conflicts (8080, 8081, 3306 already in use):**
```bash
# Edit .env and change ports
MOODLE_PORT=8082
PHPMYADMIN_PORT=8083

# Restart containers
docker compose down
docker compose up -d
```

### Database Issues

**"Cannot connect to database":**
```bash
# Check if database container is running
docker compose ps

# Check database logs
docker compose logs db

# Verify database credentials in .env match config.php
```

**"Table doesn't exist":**
```bash
# Database import may have failed - try re-importing
docker compose exec -T db mysql -u root -pmoodlepass moodle_local < ./moodle-backups/LATEST_BACKUP/database/moodle_database_*.sql
```

### Moodle Issues

**White screen or errors:**
```bash
# Enable debugging (if not already enabled)
docker compose exec web bash
# Edit config.php and set:
# $CFG->debug = E_ALL | E_STRICT;
# $CFG->debugdisplay = 1;

# Check PHP error logs
docker compose logs web
```

**"File not writable" errors:**
```bash
# Fix permissions
docker compose exec web chown -R www-data:www-data /var/www/html /var/moodledata
docker compose exec web chmod -R 755 /var/moodledata
```

### Performance Issues

**Moodle is slow:**
```bash
# Increase PHP memory limits
# Edit php-config/php.ini
memory_limit = 512M

# Restart containers
docker compose restart web
```

## Project Structure

```
microtutor-agent/
├── .env                          # Your configuration (DO NOT COMMIT)
├── .env.example                  # Template for .env
├── docker-compose.yml            # Docker services definition
├── LOCAL_DEVELOPMENT.md          # This file
├── scripts/
│   ├── backup_moodle.sh         # Backup remote Moodle
│   └── setup_local_dev.sh       # Setup local environment
├── moodle-backups/              # Downloaded backups
├── local-moodle/                # Local Moodle installation
├── local-moodledata/            # Local Moodle data directory
└── php-config/
    └── php.ini                   # PHP configuration
```

## Security Notes

- **Never commit `.env`** - it contains sensitive credentials
- Local environment has debugging enabled - DO NOT use for production
- Email is disabled by default (`$CFG->noemailever = true`)
- Use different database passwords for local vs production

## Advanced Configuration

### Custom PHP Settings

Edit `php-config/php.ini` and restart containers:

```bash
docker compose restart web
```

### Custom Database Settings

Edit `docker-compose.yml` under the `db` service and restart:

```bash
docker compose down
docker compose up -d
```

### Persistent vs Fresh Setup

The setup script preserves your data in Docker volumes. To completely reset:

```bash
# Remove all data (database, files)
docker compose down -v
rm -rf local-moodle local-moodledata moodle-backups

# Start fresh
./scripts/setup_local_dev.sh
```

## Getting Help

- Moodle Documentation: https://docs.moodle.org
- Docker Documentation: https://docs.docker.com
- Open an issue in this repository for script-specific problems

## Contributing

If you improve these scripts or documentation, please consider contributing back!
