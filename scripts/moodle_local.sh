#!/usr/bin/env bash

################################################################################
# Moodle Local Development Helper Script
#
# Provides convenient shortcuts for common Docker operations
################################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_help() {
    cat << EOF
Moodle Local Development Helper

Usage: ./scripts/moodle_local.sh [command]

Commands:
    start           Start the local Moodle environment
    stop            Stop the local Moodle environment
    restart         Restart the local Moodle environment
    logs            Show logs from all containers
    logs-web        Show web server logs
    logs-db         Show database logs
    status          Show status of containers
    shell           Open bash shell in web container
    db-shell        Open MySQL shell
    cache           Clear Moodle caches
    cron            Run Moodle cron
    maintenance-on  Enable maintenance mode
    maintenance-off Disable maintenance mode
    upgrade         Run Moodle upgrade
    info            Show connection information
    help            Show this help message

Examples:
    ./scripts/moodle_local.sh start
    ./scripts/moodle_local.sh logs
    ./scripts/moodle_local.sh shell

EOF
}

# Load .env if it exists
if [[ -f ".env" ]]; then
    set -a
    source .env
    set +a
fi

LOCAL_MOODLE_URL="${LOCAL_MOODLE_URL:-http://localhost:8080}"
PHPMYADMIN_PORT="${PHPMYADMIN_PORT:-8081}"
LOCAL_DB_USER="${LOCAL_DB_USER:-moodleuser}"
LOCAL_DB_PASSWORD="${LOCAL_DB_PASSWORD:-moodlepass}"
LOCAL_DB_NAME="${LOCAL_DB_NAME:-moodle_local}"

case "${1:-help}" in
    start)
        echo -e "${BLUE}Starting Moodle environment...${NC}"
        docker compose up -d
        echo -e "${GREEN}Moodle is starting at: $LOCAL_MOODLE_URL${NC}"
        ;;

    stop)
        echo -e "${BLUE}Stopping Moodle environment...${NC}"
        docker compose down
        echo -e "${GREEN}Moodle stopped${NC}"
        ;;

    restart)
        echo -e "${BLUE}Restarting Moodle environment...${NC}"
        docker compose restart
        echo -e "${GREEN}Moodle restarted${NC}"
        ;;

    logs)
        docker compose logs -f
        ;;

    logs-web)
        docker compose logs -f web
        ;;

    logs-db)
        docker compose logs -f db
        ;;

    status)
        docker compose ps
        ;;

    shell)
        echo -e "${BLUE}Opening shell in web container...${NC}"
        docker compose exec web bash
        ;;

    db-shell)
        echo -e "${BLUE}Opening MySQL shell...${NC}"
        docker compose exec db mysql -u "$LOCAL_DB_USER" -p"$LOCAL_DB_PASSWORD" "$LOCAL_DB_NAME"
        ;;

    cache)
        echo -e "${BLUE}Clearing Moodle caches...${NC}"
        docker compose exec web php /var/www/html/admin/cli/purge_caches.php
        echo -e "${GREEN}Caches cleared${NC}"
        ;;

    cron)
        echo -e "${BLUE}Running Moodle cron...${NC}"
        docker compose exec web php /var/www/html/admin/cli/cron.php
        echo -e "${GREEN}Cron completed${NC}"
        ;;

    maintenance-on)
        echo -e "${BLUE}Enabling maintenance mode...${NC}"
        docker compose exec web php /var/www/html/admin/cli/maintenance.php --enable
        echo -e "${YELLOW}Maintenance mode enabled${NC}"
        ;;

    maintenance-off)
        echo -e "${BLUE}Disabling maintenance mode...${NC}"
        docker compose exec web php /var/www/html/admin/cli/maintenance.php --disable
        echo -e "${GREEN}Maintenance mode disabled${NC}"
        ;;

    upgrade)
        echo -e "${BLUE}Running Moodle upgrade...${NC}"
        docker compose exec web php /var/www/html/admin/cli/upgrade.php --non-interactive
        echo -e "${GREEN}Upgrade completed${NC}"
        ;;

    info)
        cat << EOF

${GREEN}Moodle Local Development Environment${NC}

URLs:
  Moodle:      $LOCAL_MOODLE_URL
  PHPMyAdmin:  http://localhost:$PHPMYADMIN_PORT

Database Connection:
  Host:        localhost:3306
  Database:    $LOCAL_DB_NAME
  User:        $LOCAL_DB_USER
  Password:    $LOCAL_DB_PASSWORD

Useful Commands:
  View logs:   ./scripts/moodle_local.sh logs
  Clear cache: ./scripts/moodle_local.sh cache
  Shell:       ./scripts/moodle_local.sh shell

EOF
        ;;

    help)
        show_help
        ;;

    *)
        echo "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
