# MicroTutor Agent

A specialized Claude Code Web agent repository for developing and maintaining
microtutorcourses.org

## Overview

This repository provides Claude Code with specialized knowledge and tools to work effectively with:

- **Moodle LMS** (Learning Management System)
- **Database systems** (MySQL/MariaDB)
- **Educational content management**

## Local Development

### Setup

1. **Prerequisites**: Docker Desktop installed and running
2. **Configure**: `.env` file exists with your Lightsail credentials (see `.env.example`)
3. **Run**: `./scripts/setup_local_dev.sh` (takes 10-30 min)
4. **Access**: <http://localhost:8080>

### Daily Use

```bash
# Start
docker compose up -d

# Stop
docker compose down

# View logs
docker compose logs -f web

# Clear Moodle cache
docker compose exec web bash -c "rm -rf /var/moodledata/cache/* /var/moodledata/localcache/*"
```

**Files**: Edit `./local-moodle/` directly - changes take effect immediately
**Database**: <http://localhost:8081> (PHPMyAdmin) - user: `moodleuser`, pass: `moodlepass`
