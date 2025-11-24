#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Fixing Moodle cache issues...${NC}"

# Sync the complete cache directory from production
echo -e "${BLUE}Syncing cache directory...${NC}"
rsync -av -e "ssh -i ~/.ssh/microtutor-lightsail-key.pem" \
    ubuntu@52.45.180.231:/var/www/html/moodle/cache/ \
    local-moodle/cache/

# Copy the missing boost_union cache loader class
echo -e "${BLUE}Copying boost_union cache loader...${NC}"
mkdir -p local-moodle/theme/boost_union/classes/cache
scp -i ~/.ssh/microtutor-lightsail-key.pem \
    ubuntu@52.45.180.231:/var/www/html/moodle/theme/boost_union/classes/cache/loader.php \
    local-moodle/theme/boost_union/classes/cache/

# Create localcache directory in moodledata
echo -e "${BLUE}Creating moodledata cache directories...${NC}"
docker compose exec web bash -c "mkdir -p /var/moodledata/localcache /var/moodledata/cache"

# Fix permissions
echo -e "${BLUE}Fixing permissions...${NC}"
docker compose exec web bash -c "chown -R www-data:www-data /var/www/html /var/moodledata"

# Clear and rebuild caches
echo -e "${BLUE}Clearing Moodle caches...${NC}"
docker compose exec web bash -c "rm -rf /var/moodledata/cache/* /var/moodledata/localcache/*"

echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo -e "${BLUE}Your Moodle is now running at:${NC}"
echo "  http://localhost:8080"
echo ""
