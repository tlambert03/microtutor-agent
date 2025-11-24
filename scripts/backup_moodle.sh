#!/usr/bin/env bash

################################################################################
# Moodle Site Backup Script
#
# This script backs up a Moodle instance from AWS Lightsail to your local machine
# following the official Moodle backup recommendations from:
# https://docs.moodle.org/en/Site_backup
#
# A complete Moodle backup includes three components:
# 1. Database (MySQL/MariaDB) - MOST IMPORTANT, changes frequently
# 2. Moodledata directory (uploaded files, user data) - MOST IMPORTANT, changes frequently
# 3. Moodle code (application files) - Less important, only changes during upgrades
#
################################################################################

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# AUTO-LOAD .env FILE FROM CURRENT WORKING DIRECTORY
if [[ -f ".env" ]]; then
    echo "Loading environment variables from .env file..."
    set -a  # Automatically export all variables
    source .env
    set +a  # Stop auto-exporting
fi

################################################################################
# CONFIGURATION - Uses Environment Variables
#
# REQUIRED Environment Variables:
#   MOODLE_LIGHTSAIL_IP       - IP address of your Lightsail instance
#   MOODLE_SSH_KEY            - Path to SSH private key (.pem file)
#   MOODLE_REMOTE_DIR         - Moodle installation directory (from $CFG->wwwroot)
#   MOODLE_REMOTE_DATA_DIR    - Moodledata directory (from $CFG->dataroot)
#   MOODLE_DB_NAME            - Database name (from $CFG->dbname)
#   MOODLE_DB_USER            - Database username (from $CFG->dbuser)
#
# OPTIONAL Environment Variables (with defaults):
#   MOODLE_LIGHTSAIL_USER     - SSH user (default: "ubuntu")
#   MOODLE_DB_PASSWORD        - Database password (default: auto-detect from config.php)
#   MOODLE_DB_HOST            - Database host (default: "localhost")
#   MOODLE_BACKUP_DIR         - Local backup directory (default: "$HOME/moodle-backups")
#   MOODLE_REMOTE_TMP_DIR     - Remote temp directory (default: "/tmp/moodle_backup")
#   MOODLE_MAINTENANCE_MODE   - Enable maintenance mode (default: "false")
#   MOODLE_COMPRESS_BACKUP    - Compress backup (default: "true")
#   MOODLE_KEEP_BACKUPS       - Number of backups to keep, 0=keep all (default: "0")
#
# TIP: Create a .env file in your working directory:
#   export MOODLE_LIGHTSAIL_IP="54.123.45.67"
#   export MOODLE_SSH_KEY="$HOME/.ssh/lightsail-key.pem"
#   ...etc
#
# The script will automatically load .env from the current directory.
# Alternatively, create $HOME/.moodle-backup.env for global configuration.
# Then run: ./backup_moodle.sh
################################################################################

# Remote Lightsail instance details
LIGHTSAIL_IP="${MOODLE_LIGHTSAIL_IP:-}"
LIGHTSAIL_USER="${MOODLE_LIGHTSAIL_USER:-ubuntu}"
LIGHTSAIL_SSH_KEY="${MOODLE_SSH_KEY:-}"

# Remote Moodle paths (on Lightsail instance)
REMOTE_MOODLE_DIR="${MOODLE_REMOTE_DIR:-/var/www/html/moodle}"
REMOTE_MOODLEDATA_DIR="${MOODLE_REMOTE_DATA_DIR:-/var/www/moodledata}"
REMOTE_TMP_DIR="${MOODLE_REMOTE_TMP_DIR:-/tmp/moodle_backup}"

# Database credentials (on remote server)
DB_NAME="${MOODLE_DB_NAME:-moodle}"
DB_USER="${MOODLE_DB_USER:-moodleuser}"
DB_PASSWORD="${MOODLE_DB_PASSWORD:-}"
DB_HOST="${MOODLE_DB_HOST:-localhost}"

# Local backup destination
LOCAL_BACKUP_DIR="${MOODLE_BACKUP_DIR:-moodle-backups}"
BACKUP_DATE=$(date +"%Y%m%d_%H%M%S")
LOCAL_BACKUP_PATH="$LOCAL_BACKUP_DIR/moodle_backup_$BACKUP_DATE"

# Backup options
ENABLE_MAINTENANCE_MODE="${MOODLE_MAINTENANCE_MODE:-false}"
COMPRESS_BACKUP="${MOODLE_COMPRESS_BACKUP:-true}"
KEEP_BACKUPS="${MOODLE_KEEP_BACKUPS:-0}"

# Advanced options
RSYNC_OPTIONS="${MOODLE_RSYNC_OPTIONS:--avz --progress}"
SSH_OPTIONS="${MOODLE_SSH_OPTIONS:--o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null}"

################################################################################
# COLOR OUTPUT
################################################################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
# VALIDATION FUNCTIONS
################################################################################
validate_config() {
    log_info "Validating configuration..."
    local has_error=false

    # Check required environment variables
    if [[ -z "$LIGHTSAIL_IP" ]]; then
        log_error "MOODLE_LIGHTSAIL_IP environment variable is not set"
        has_error=true
    fi

    if [[ -z "$LIGHTSAIL_SSH_KEY" ]]; then
        log_error "MOODLE_SSH_KEY environment variable is not set"
        has_error=true
    elif [[ ! -f "$LIGHTSAIL_SSH_KEY" ]]; then
        log_error "SSH key not found at: $LIGHTSAIL_SSH_KEY"
        has_error=true
    fi

    if [[ -z "$REMOTE_MOODLE_DIR" ]]; then
        log_error "MOODLE_REMOTE_DIR environment variable is not set"
        has_error=true
    fi

    if [[ -z "$REMOTE_MOODLEDATA_DIR" ]]; then
        log_error "MOODLE_REMOTE_DATA_DIR environment variable is not set"
        has_error=true
    fi

    if [[ -z "$DB_NAME" ]]; then
        log_error "MOODLE_DB_NAME environment variable is not set"
        has_error=true
    fi

    if [[ -z "$DB_USER" ]]; then
        log_error "MOODLE_DB_USER environment variable is not set"
        has_error=true
    fi

    if [[ "$has_error" == true ]]; then
        echo ""
        log_error "Missing required environment variables. Please set them before running this script."
        echo ""
        echo "Example .env file:"
        echo "  export MOODLE_LIGHTSAIL_IP=\"11.222.33.44\""
        echo "  export MOODLE_SSH_KEY=\"\$HOME/.ssh/lightsail-key.pem\""
        echo "  export MOODLE_REMOTE_DIR=\"/opt/bitnami/moodle\""
        echo "  export MOODLE_REMOTE_DATA_DIR=\"/opt/bitnami/moodledata\""
        echo "  export MOODLE_DB_NAME=\"bitnami_moodle\""
        echo "  export MOODLE_DB_USER=\"bn_moodle\""
        echo ""
        echo "Save this to .env in the current directory, then run: ./backup_moodle.sh"
        echo "The script will automatically load the .env file."
        echo ""
        exit 1
    fi

    # Test SSH connection
    log_info "Testing SSH connection to $LIGHTSAIL_USER@$LIGHTSAIL_IP..."
    if ! ssh -i "$LIGHTSAIL_SSH_KEY" $SSH_OPTIONS "$LIGHTSAIL_USER@$LIGHTSAIL_IP" "echo 'Connection successful'" &>/dev/null; then
        log_error "Cannot connect to Lightsail instance. Please check IP, user, and SSH key."
        exit 1
    fi

    log_success "Configuration validated successfully"
}

################################################################################
# DATABASE PASSWORD RETRIEVAL
################################################################################
get_db_password() {
    if [[ -z "$DB_PASSWORD" ]]; then
        log_info "MOODLE_DB_PASSWORD not set, attempting to retrieve from config.php..."

        DB_PASSWORD=$(ssh -i "$LIGHTSAIL_SSH_KEY" $SSH_OPTIONS "$LIGHTSAIL_USER@$LIGHTSAIL_IP" \
            "grep dbpass $REMOTE_MOODLE_DIR/config.php | sed -n \"s/.*= '\\([^']*\\)'.*/\\1/p\"" 2>/dev/null || echo "")

        if [[ -z "$DB_PASSWORD" ]]; then
            log_error "Could not retrieve database password. Please set MOODLE_DB_PASSWORD environment variable."
            exit 1
        fi

        log_success "Database password retrieved from config.php"
    fi
}

################################################################################
# MAINTENANCE MODE MANAGEMENT
################################################################################
enable_maintenance_mode() {
    if [[ "$ENABLE_MAINTENANCE_MODE" == true ]]; then
        log_info "Enabling maintenance mode..."
        ssh -i "$LIGHTSAIL_SSH_KEY" $SSH_OPTIONS "$LIGHTSAIL_USER@$LIGHTSAIL_IP" \
            "cd $REMOTE_MOODLE_DIR && sudo -u daemon php admin/cli/maintenance.php --enable" || {
            log_warning "Could not enable maintenance mode (may require different user)"
        }
        log_success "Maintenance mode enabled"
    fi
}

disable_maintenance_mode() {
    if [[ "$ENABLE_MAINTENANCE_MODE" == true ]]; then
        log_info "Disabling maintenance mode..."
        ssh -i "$LIGHTSAIL_SSH_KEY" $SSH_OPTIONS "$LIGHTSAIL_USER@$LIGHTSAIL_IP" \
            "cd $REMOTE_MOODLE_DIR && sudo -u daemon php admin/cli/maintenance.php --disable" || {
            log_warning "Could not disable maintenance mode (may require different user)"
        }
        log_success "Maintenance mode disabled"
    fi
}

################################################################################
# BACKUP FUNCTIONS
################################################################################
backup_database() {
    log_info "Backing up Moodle database..."

    # Create remote temp directory
    ssh -i "$LIGHTSAIL_SSH_KEY" $SSH_OPTIONS "$LIGHTSAIL_USER@$LIGHTSAIL_IP" \
        "mkdir -p $REMOTE_TMP_DIR"

    # Dump database on remote server
    # Using flags from official Moodle documentation:
    # --default-character-set=utf8mb4: Ensures proper UTF-8 encoding (CRITICAL)
    # --single-transaction: Ensures backup consistency (avoid data changing mid-backup)
    # -C: Compress data between client and server
    # -Q: Quote identifiers with backticks
    # -e: Use extended-insert syntax (more efficient)
    # --create-options: Include MySQL-specific table options
    log_info "Creating database dump on remote server..."
    ssh -i "$LIGHTSAIL_SSH_KEY" $SSH_OPTIONS "$LIGHTSAIL_USER@$LIGHTSAIL_IP" \
        "mysqldump --host=$DB_HOST --user=$DB_USER --password='$DB_PASSWORD' \
        --default-character-set=utf8mb4 --single-transaction \
        -C -Q -e --create-options \
        $DB_NAME > $REMOTE_TMP_DIR/moodle_database_$BACKUP_DATE.sql"

    # Download database dump
    log_info "Downloading database dump..."
    mkdir -p "$LOCAL_BACKUP_PATH/database"
    scp -i "$LIGHTSAIL_SSH_KEY" $SSH_OPTIONS \
        "$LIGHTSAIL_USER@$LIGHTSAIL_IP:$REMOTE_TMP_DIR/moodle_database_$BACKUP_DATE.sql" \
        "$LOCAL_BACKUP_PATH/database/"

    # Clean up remote temp directory
    ssh -i "$LIGHTSAIL_SSH_KEY" $SSH_OPTIONS "$LIGHTSAIL_USER@$LIGHTSAIL_IP" \
        "rm -rf $REMOTE_TMP_DIR"

    log_success "Database backup completed"
}

backup_moodle_code() {
    log_info "Backing up Moodle code directory..."

    mkdir -p "$LOCAL_BACKUP_PATH/moodle"

    rsync $RSYNC_OPTIONS \
        -e "ssh -i $LIGHTSAIL_SSH_KEY $SSH_OPTIONS" \
        --exclude='.git' \
        --exclude='/cache' \
        "$LIGHTSAIL_USER@$LIGHTSAIL_IP:$REMOTE_MOODLE_DIR/" \
        "$LOCAL_BACKUP_PATH/moodle/"

    log_success "Moodle code backup completed"
}

backup_moodledata() {
    log_info "Backing up moodledata directory..."
    log_warning "This may take a while depending on the size of uploaded files..."

    mkdir -p "$LOCAL_BACKUP_PATH/moodledata"

    rsync $RSYNC_OPTIONS \
        -e "ssh -i $LIGHTSAIL_SSH_KEY $SSH_OPTIONS" \
        --exclude='/cache' \
        --exclude='/localcache' \
        --exclude='/sessions' \
        --exclude='/temp' \
        --exclude='/trashdir' \
        "$LIGHTSAIL_USER@$LIGHTSAIL_IP:$REMOTE_MOODLEDATA_DIR/" \
        "$LOCAL_BACKUP_PATH/moodledata/"

    log_success "Moodledata backup completed"
}

################################################################################
# COMPRESSION AND CLEANUP
################################################################################
compress_backup() {
    if [[ "$COMPRESS_BACKUP" == true ]]; then
        log_info "Compressing backup..."

        cd "$LOCAL_BACKUP_DIR"
        tar -czf "moodle_backup_$BACKUP_DATE.tar.gz" "moodle_backup_$BACKUP_DATE"

        # Verify compression succeeded
        if [[ -f "moodle_backup_$BACKUP_DATE.tar.gz" ]]; then
            log_success "Backup compressed successfully"
            log_info "Removing uncompressed backup..."
            rm -rf "moodle_backup_$BACKUP_DATE"
            log_info "Compressed backup saved to: $LOCAL_BACKUP_DIR/moodle_backup_$BACKUP_DATE.tar.gz"
        else
            log_error "Compression failed"
            exit 1
        fi
    fi
}

cleanup_old_backups() {
    # Skip cleanup if KEEP_BACKUPS is 0 (keep all backups)
    if [[ $KEEP_BACKUPS -eq 0 ]]; then
        log_info "KEEP_BACKUPS=0, skipping cleanup (keeping all backups)"
        return
    fi

    log_info "Cleaning up old backups (keeping last $KEEP_BACKUPS)..."

    cd "$LOCAL_BACKUP_DIR"

    # Count backups
    if [[ "$COMPRESS_BACKUP" == true ]]; then
        backup_count=$(ls -1 moodle_backup_*.tar.gz 2>/dev/null | wc -l)

        if [[ $backup_count -gt $KEEP_BACKUPS ]]; then
            ls -1t moodle_backup_*.tar.gz | tail -n +$((KEEP_BACKUPS + 1)) | xargs rm -f
            log_success "Removed old backups"
        fi
    else
        backup_count=$(ls -1d moodle_backup_*/ 2>/dev/null | wc -l)

        if [[ $backup_count -gt $KEEP_BACKUPS ]]; then
            ls -1td moodle_backup_*/ | tail -n +$((KEEP_BACKUPS + 1)) | xargs rm -rf
            log_success "Removed old backups"
        fi
    fi
}

################################################################################
# BACKUP VERIFICATION
################################################################################
verify_backup() {
    log_info "Verifying backup integrity..."

    local backup_path
    if [[ "$COMPRESS_BACKUP" == true ]]; then
        backup_path="$LOCAL_BACKUP_DIR/moodle_backup_$BACKUP_DATE.tar.gz"
        if [[ -f "$backup_path" ]]; then
            local size=$(du -h "$backup_path" | cut -f1)
            log_success "Backup file exists: $backup_path ($size)"
        else
            log_error "Backup file not found!"
            exit 1
        fi
    else
        backup_path="$LOCAL_BACKUP_PATH"
        if [[ -d "$backup_path/database" ]] && [[ -d "$backup_path/moodle" ]] && [[ -d "$backup_path/moodledata" ]]; then
            local size=$(du -sh "$backup_path" | cut -f1)
            log_success "Backup directory structure is valid: $backup_path ($size)"
        else
            log_error "Backup directory structure is incomplete!"
            exit 1
        fi
    fi
}

################################################################################
# MAIN EXECUTION
################################################################################
main() {
    echo ""
    log_info "=========================================="
    log_info "  Moodle Site Backup Script"
    log_info "  Started at: $(date)"
    log_info "=========================================="
    echo ""

    # Create local backup directory
    mkdir -p "$LOCAL_BACKUP_DIR"
    mkdir -p "$LOCAL_BACKUP_PATH"

    # Validate configuration
    validate_config

    # Get database password if not set
    get_db_password

    # Enable maintenance mode
    enable_maintenance_mode

    # Trap to ensure maintenance mode is disabled on exit
    trap disable_maintenance_mode EXIT

    # Perform backups
    backup_database
    backup_moodle_code
    backup_moodledata

    # Disable maintenance mode
    disable_maintenance_mode
    trap - EXIT  # Remove trap

    # Compress backup
    compress_backup

    # Cleanup old backups
    cleanup_old_backups

    # Verify backup
    verify_backup

    echo ""
    log_success "=========================================="
    log_success "  Backup completed successfully!"
    log_success "  Finished at: $(date)"
    log_success "=========================================="
    echo ""

    if [[ "$COMPRESS_BACKUP" == true ]]; then
        log_info "Backup location: $LOCAL_BACKUP_DIR/moodle_backup_$BACKUP_DATE.tar.gz"
    else
        log_info "Backup location: $LOCAL_BACKUP_PATH"
    fi

    echo ""
    log_info "To restore this backup, use the restore script or manually:"
    log_info "  1. Extract/copy Moodle files to web server"
    log_info "  2. Extract/copy moodledata to appropriate location"
    log_info "  3. Import database: mysql -u user -p database_name < backup.sql"
    log_info "  4. Update config.php with correct paths and database settings"
    log_info "  5. Run: php admin/cli/purge_caches.php"
    echo ""
}

# Run main function
main "$@"
