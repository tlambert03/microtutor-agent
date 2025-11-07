# Moodle 4.3.3+ → 5.1 Upgrade Plan

## ⚠️ Critical Issues Identified

- **Disk space**: 95% used (only 2.1G free) - MUST address first
- **Composer**: Not installed (required for Moodle 5.1)
- **Major architectural change**: Moodle 5.1 uses new /public directory structure

## Current System Assessment

✅ PHP 8.3.6 (compatible)
✅ MariaDB 10.11.13 (compatible)
✅ max_input_vars = 5000
(meets requirement)
✅ Sodium extension installed
⚠️ Boost Union theme v4.3-r9 (needs upgrade to v5.1)
⚠️ Apache DocumentRoot: /var/www/html/moodle (needs → /var/www/html/moodle/public)

## Phase 1: Pre-Upgrade Preparation

1. Disk space cleanup (targeting 10-15G free space)
    - Analyze and remove old logs in /var/www/moodledata
    - Clean up old backups if any
    - Remove temporary files
    - Consider old course files/user data retention policies
    - If needed: Expand Lightsail disk volume
1. Install Composer (required for Moodle 5.1 vendor dependencies)
1. Create comprehensive backups
    - Full database dump (mysqldump)
    - Complete moodledata directory backup (28GB)
    - Moodle code directory backup (993MB)
    - Apache configuration files backup
    - Document current settings

## Phase 2: Staging Environment Setup

1. Create AWS Lightsail staging instance
    - Clone current production instance
    - Restore backups to staging
    - Update staging DNS or use IP for testing
    - Verify staging environment works

## Phase 3: Staging Upgrade Process

1. Download Moodle 5.1 to staging
    - Download from git.moodle.org
    - Preserve config.php from old installation
1. Update Boost Union theme to v5.1 compatible version
1. Run Composer to install vendor dependencies
    - composer install --no-dev --classmap-authoritative
1. Update Apache configuration on staging
    - Change DocumentRoot from /var/www/html/moodle → /var/www/html/moodle/public
    - Add FallbackResource /r.php for routing engine
    - Update both HTTP and HTTPS virtual hosts
1. Run Moodle upgrade on staging

    - Put site in maintenance mode
    - Access admin/index.php to trigger upgrade
    - Monitor for errors
    - Test thoroughly

1. Validate staging upgrade

    - Test all core functionality
    - Verify H5P modules work
    - Check Boost Union theme rendering
    - Test user login/enrollment
    - Verify course content
    - Test SSL certificates work with new structure

## Phase 4: Production Upgrade (if staging successful)

1. Production upgrade execution

    - Schedule maintenance window
    - Final backup
    - Replicate staging upgrade steps
    - Minimize downtime

Breaking Changes to Monitor

- New /public directory structure (MAJOR)
- Atto editor removed (replaced by TinyMCE)
- Chat and Survey activities removed from core
- Bootstrap 5 migration (Boost Union compatible)
- PostgreSQL minimum now 15 (doesn't affect MariaDB users)
