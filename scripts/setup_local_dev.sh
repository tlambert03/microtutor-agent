#!/usr/bin/env bash

################################################################################
# Local Moodle Development Environment Setup Script
#
# This script automates the process of cloning your AWS Lightsail Moodle
# instance to a local Docker-based development environment.
#
# Prerequisites:
# - Docker Desktop installed and running
# - SSH access to your Lightsail instance
# - .env file configured with your Lightsail credentials
#
# Usage:
#   ./scripts/setup_local_dev.sh
#
# What this script does:
# 1. Validates prerequisites (Docker, .env file)
# 2. Backs up remote Moodle instance using backup_moodle.sh
# 3. Extracts backup files
# 4. Sets up Docker containers (web, database, PHPMyAdmin)
# 5. Imports database
# 6. Configures Moodle for local development
# 7. Starts the local development environment
################################################################################

set -euo pipefail

# Load color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

################################################################################
# LOGGING FUNCTIONS
################################################################################
log_info() {
    echo -e "${BLUE}[INFO]   ${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]  ${NC} $1"
}

################################################################################
# PREREQUISITE CHECKS
################################################################################
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker Desktop:"
        echo "  https://www.docker.com/products/docker-desktop"
        exit 1
    fi

    # Check if Docker Compose is available
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not available. Please update Docker Desktop."
        exit 1
    fi

    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker Desktop."
        exit 1
    fi

    # Check if .env file exists
    if [[ ! -f ".env" ]]; then
        log_error ".env file not found!"
        echo ""
        echo "Please create a .env file with your configuration."
        echo "You can copy .env.example as a template:"
        echo "  cp .env.example .env"
        echo "  # Edit .env with your Lightsail credentials"
        echo ""
        exit 1
    fi

    # Load .env file
    set -a
    source .env
    set +a

    log_success "All prerequisites met"
}

################################################################################
# BACKUP REMOTE MOODLE
################################################################################
backup_remote_moodle() {
    log_info "Starting backup of remote Moodle instance..."

    if [[ ! -f "scripts/backup_moodle.sh" ]]; then
        log_error "Backup script not found: scripts/backup_moodle.sh"
        exit 1
    fi

    # Make backup script executable
    chmod +x scripts/backup_moodle.sh

    # Run backup script
    ./scripts/backup_moodle.sh

    log_success "Remote Moodle backup completed"
}

################################################################################
# EXTRACT BACKUP
################################################################################
extract_backup() {
    log_info "Extracting backup files..."

    # Find the most recent backup
    BACKUP_DIR="${MOODLE_BACKUP_DIR:-./moodle-backups}"

    if [[ "$MOODLE_COMPRESS_BACKUP" == "true" ]] || [[ -z "$MOODLE_COMPRESS_BACKUP" ]]; then
        LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/moodle_backup_*.tar.gz 2>/dev/null | head -1)

        if [[ -z "$LATEST_BACKUP" ]]; then
            log_error "No backup file found in $BACKUP_DIR"
            exit 1
        fi

        log_info "Extracting: $LATEST_BACKUP"
        tar -xzf "$LATEST_BACKUP" -C "$BACKUP_DIR"

        # Get extracted directory name
        EXTRACTED_DIR=$(tar -tzf "$LATEST_BACKUP" | head -1 | cut -f1 -d"/")
        BACKUP_PATH="$BACKUP_DIR/$EXTRACTED_DIR"
    else
        LATEST_BACKUP=$(ls -td "$BACKUP_DIR"/moodle_backup_*/ 2>/dev/null | head -1)

        if [[ -z "$LATEST_BACKUP" ]]; then
            log_error "No backup directory found in $BACKUP_DIR"
            exit 1
        fi

        BACKUP_PATH="$LATEST_BACKUP"
    fi

    log_success "Backup extracted to: $BACKUP_PATH"
}

################################################################################
# SETUP LOCAL DIRECTORIES
################################################################################
setup_local_directories() {
    log_info "Setting up local directories..."

    # Create local directories
    mkdir -p local-moodle
    mkdir -p local-moodledata
    mkdir -p php-config
    mkdir -p backups

    # Copy Moodle code
    log_info "Copying Moodle code..."
    rsync -av --progress "$BACKUP_PATH/moodle/" local-moodle/

    # Copy Moodledata
    log_info "Copying Moodledata..."
    rsync -av --progress "$BACKUP_PATH/moodledata/" local-moodledata/

    # Set permissions
    chmod -R 755 local-moodle
    chmod -R 777 local-moodledata

    log_success "Local directories set up successfully"
}

################################################################################
# CREATE PHP CONFIGURATION
################################################################################
create_php_config() {
    log_info "Creating PHP configuration..."

    cat > php-config/php.ini << 'EOF'
[PHP]
max_execution_time = 300
max_input_time = 300
memory_limit = 256M
post_max_size = 64M
upload_max_filesize = 64M
max_input_vars = 5000

[opcache]
opcache.enable = 1
opcache.memory_consumption = 128
opcache.max_accelerated_files = 4000
opcache.revalidate_freq = 60

[Date]
date.timezone = America/New_York
EOF

    log_success "PHP configuration created"
}

################################################################################
# START DOCKER CONTAINERS
################################################################################
start_docker_containers() {
    log_info "Starting Docker containers..."

    # Stop any existing containers
    docker compose down 2>/dev/null || true

    # Build and start containers
    docker compose up -d

    # Wait for database to be ready
    log_info "Waiting for database to be ready..."
    sleep 10

    local max_attempts=30
    local attempt=0

    while [[ $attempt -lt $max_attempts ]]; do
        if docker compose exec -T db mysqladmin ping -h localhost -u root -p"${LOCAL_MYSQL_ROOT_PASSWORD:-moodlepass}" &>/dev/null; then
            log_success "Database is ready"
            break
        fi

        attempt=$((attempt + 1))
        log_info "Waiting for database... ($attempt/$max_attempts)"
        sleep 2
    done

    if [[ $attempt -eq $max_attempts ]]; then
        log_error "Database failed to start"
        exit 1
    fi
}

################################################################################
# IMPORT DATABASE
################################################################################
import_database() {
    log_info "Importing database..."

    # Find database backup file
    DB_FILE=$(find "$BACKUP_PATH/database" -name "*.sql" | head -1)

    if [[ -z "$DB_FILE" ]]; then
        log_error "No database backup file found in $BACKUP_PATH/database"
        exit 1
    fi

    log_info "Importing: $DB_FILE"

    # Copy database file to container
    docker cp "$DB_FILE" moodle_db:/tmp/moodle.sql

    # Import database
    docker compose exec -T db mysql \
        -u root \
        -p"${LOCAL_MYSQL_ROOT_PASSWORD:-moodlepass}" \
        "${LOCAL_DB_NAME:-moodle_local}" \
        < "$DB_FILE"

    log_success "Database imported successfully"
}

################################################################################
# CONFIGURE MOODLE
################################################################################
configure_moodle() {
    log_info "Configuring Moodle for local development..."

    # Backup original config.php
    if [[ -f "local-moodle/config.php" ]]; then
        cp local-moodle/config.php local-moodle/config.php.backup
    fi

    # Get local configuration
    LOCAL_DB_NAME="${LOCAL_DB_NAME:-moodle_local}"
    LOCAL_DB_USER="${LOCAL_DB_USER:-moodleuser}"
    LOCAL_DB_PASSWORD="${LOCAL_DB_PASSWORD:-moodlepass}"
    LOCAL_MOODLE_URL="${LOCAL_MOODLE_URL:-http://localhost:8080}"

    # Create new config.php
    cat > local-moodle/config.php << EOF
<?php  // Moodle configuration file

unset(\$CFG);
global \$CFG;
\$CFG = new stdClass();

\$CFG->dbtype    = 'mariadb';
\$CFG->dblibrary = 'native';
\$CFG->dbhost    = 'db';
\$CFG->dbname    = '$LOCAL_DB_NAME';
\$CFG->dbuser    = '$LOCAL_DB_USER';
\$CFG->dbpass    = '$LOCAL_DB_PASSWORD';
\$CFG->prefix    = 'mdl_';
\$CFG->dboptions = array(
    'dbpersist' => 0,
    'dbport' => 3306,
    'dbsocket' => '',
    'dbcollation' => 'utf8mb4_unicode_ci',
);

\$CFG->wwwroot   = '$LOCAL_MOODLE_URL';
\$CFG->dataroot  = '/var/moodledata';
\$CFG->admin     = 'admin';

\$CFG->directorypermissions = 0777;

// Local development settings
\$CFG->debug = E_ALL | E_STRICT;
\$CFG->debugdisplay = 1;
\$CFG->debugsmtp = true;

// Disable email in development
\$CFG->noemailever = true;

// Performance settings for development
\$CFG->cachejs = false;
\$CFG->themedesignermode = true;

require_once(__DIR__ . '/lib/setup.php');

// There is no php closing tag in this file,
// it is intentional because it prevents trailing whitespace problems!
EOF

    log_success "Moodle configured for local development"
}

################################################################################
# CLEAR MOODLE CACHES
################################################################################
clear_caches() {
    log_info "Clearing Moodle caches..."

    # Wait for web server to be fully ready
    sleep 5

    docker compose exec web bash -c "cd /var/www/html && php admin/cli/purge_caches.php" || {
        log_warning "Could not purge caches (web server may still be starting)"
    }

    log_success "Caches cleared"
}

################################################################################
# DISPLAY SUCCESS MESSAGE
################################################################################
display_success() {
    echo ""
    log_success "=========================================="
    log_success "  Local Development Environment Ready!"
    log_success "=========================================="
    echo ""
    log_info "Your local Moodle instance is running at:"
    log_info "  Moodle: ${LOCAL_MOODLE_URL:-http://localhost:8080}"
    log_info "  PHPMyAdmin: http://localhost:${PHPMYADMIN_PORT:-8081}"
    echo ""
    log_info "Database credentials:"
    log_info "  Host: localhost:3306"
    log_info "  Database: ${LOCAL_DB_NAME:-moodle_local}"
    log_info "  User: ${LOCAL_DB_USER:-moodleuser}"
    log_info "  Password: ${LOCAL_DB_PASSWORD:-moodlepass}"
    echo ""
    log_info "Useful commands:"
    log_info "  View logs:        docker compose logs -f"
    log_info "  Stop containers:  docker compose down"
    log_info "  Start containers: docker compose up -d"
    log_info "  Access shell:     docker compose exec web bash"
    echo ""
    log_warning "Note: Use the same admin credentials as your production site"
    echo ""
}

################################################################################
# MAIN EXECUTION
################################################################################
main() {
    echo ""
    log_info "=========================================="
    log_info "  Moodle Local Development Setup"
    log_info "  Started at: $(date)"
    log_info "=========================================="
    echo ""

    check_prerequisites
    backup_remote_moodle
    extract_backup
    setup_local_directories
    create_php_config
    start_docker_containers
    import_database
    configure_moodle
    clear_caches
    display_success

    echo ""
    log_success "Setup completed successfully at: $(date)"
    echo ""
}

# Run main function
main "$@"
