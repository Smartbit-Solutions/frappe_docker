# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a customized fork of `frappe_docker` for Smartbit Solutions, containing Docker configurations to build and deploy custom ERPNext instances. The repository includes:

- **Custom Frappe fork**: https://github.com/Smartbit-Solutions/frappe (branch: `rebrand-smartbits-lcs`)
- **Custom ERPNext fork**: https://github.com/Smartbit-Solutions/erpnext (branch: `rebrand-to-smartbits-erp`)
- Base configuration from upstream `frappe_docker` repository

## Architecture

### Multi-Service Docker Architecture

The deployment uses a microservices architecture with these core services:

- **configurator** - Initialization service that runs once on startup to configure database and Redis connections
- **backend** - Gunicorn WSGI server for dynamic content processing (Python/Frappe)
- **frontend** - Nginx reverse proxy serving static assets and routing requests
- **websocket** - Node.js Socket.IO server for real-time communications
- **queue-short/long** - Python workers using RQ (Redis Queue) for background job processing
- **scheduler** - Python service running scheduled tasks
- **db** - MariaDB database (added via compose override)
- **redis-cache/queue** - Redis instances for caching and job queues (added via compose override)

### Custom Image Build Process

Custom images are built using a multi-stage Dockerfile (`images/smartbit/Containerfile`):

1. **Builder stage**: Uses `frappe/build:version-16` as base, runs `bench init` with custom Frappe and apps from `apps.json`
2. **Backend stage**: Uses `frappe/base:version-16`, copies built bench from builder stage
3. Apps are specified in `apps.json` as a JSON array with git URLs and branches
4. The `build-custom-image.sh` script base64-encodes `apps.json` and passes it as a build arg

## Common Commands

### Building Custom Image

```bash
# Build custom ERPNext image with Smartbit forks
./build-custom-image.sh
# This encodes apps.json and builds smartbit-erp:latest
```

### Generating Docker Compose Configuration

```bash
# Generate merged compose file from base + overrides
./generate-compose.sh
# Creates docker-compose.smartbit.yaml by merging:
#   - compose.yaml (base)
#   - overrides/compose.mariadb.yaml
#   - overrides/compose.redis.yaml
#   - overrides/compose.noproxy.yaml
```

### Starting/Stopping Services

```bash
# Start all services
docker compose -f docker-compose.smartbit.yaml up -d

# Stop all services
docker compose -f docker-compose.smartbit.yaml down

# View logs (all services)
docker compose -f docker-compose.smartbit.yaml logs -f

# View logs (specific service)
docker compose -f docker-compose.smartbit.yaml logs -f backend
docker compose -f docker-compose.smartbit.yaml logs -f create-site

# Restart services
docker compose -f docker-compose.smartbit.yaml restart
```

### Container Access

```bash
# Access backend container shell
docker compose -f docker-compose.smartbit.yaml exec backend bash

# Run bench commands
docker compose -f docker-compose.smartbit.yaml exec backend bench --help
docker compose -f docker-compose.smartbit.yaml exec backend bench list-sites
docker compose -f docker-compose.smartbit.yaml exec backend bench migrate
```

### Development Workflow

```bash
# After modifying apps.json or Frappe/ERPNext code
./build-custom-image.sh
./generate-compose.sh
docker compose -f docker-compose.smartbit.yaml down
docker compose -f docker-compose.smartbit.yaml up -d

# Watch site creation progress
docker compose -f docker-compose.smartbit.yaml logs -f create-site
```

## Environment Configuration

Environment variables are configured in `.env` file. Key variables:

- `CUSTOM_IMAGE` - Docker image name (default: `smartbit-erp`)
- `CUSTOM_TAG` - Image tag (default: `latest`)
- `PULL_POLICY` - When to pull image (default: `missing` for local builds)
- `DB_PASSWORD` - MariaDB root password (MUST be changed from example)
- `HTTP_PUBLISH_PORT` - Published HTTP port (default: `8080`)
- `FRAPPE_SITE_NAME_HEADER` - Override site name resolution (default: `$$host`)

**Important**: Always copy `.env.smartbit.example` to `.env` and change `DB_PASSWORD` before deploying.

## File Structure

### Key Configuration Files

- `apps.json` - Defines custom apps to install (Frappe apps as git URLs and branches)
- `compose.yaml` - Base Docker Compose file with service definitions
- `docker-compose.smartbit.yaml` - Generated merged compose configuration (DO NOT edit manually)
- `.env` - Environment variables (gitignored, copy from `.env.smartbit.example`)
- `build-custom-image.sh` - Script to build custom Docker image
- `generate-compose.sh` - Script to generate merged compose file

### Override Files

Located in `overrides/`:
- `compose.mariadb.yaml` - Adds MariaDB service
- `compose.redis.yaml` - Adds Redis services (cache and queue)
- `compose.noproxy.yaml` - Direct port publishing without Traefik
- `compose.https.yaml` - Adds SSL/TLS with Let's Encrypt
- `compose.proxy.yaml` - Adds Traefik reverse proxy

### Custom Image Files

- `images/smartbit/Containerfile` - Multi-stage Dockerfile for custom builds
- Uses base images: `frappe/build:version-16` and `frappe/base:version-16`
- Accepts build args: `BASE_VERSION`, `FRAPPE_BRANCH`, `FRAPPE_PATH`, `APPS_JSON_BASE64`

## Docker Compose Merging Pattern

The repository uses Docker Compose's native merging capability:

```bash
docker compose -f compose.yaml -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml -f overrides/compose.noproxy.yaml \
  config > docker-compose.smartbit.yaml
```

This merges multiple YAML files in order, with later files overriding earlier ones. The `generate-compose.sh` script automates this.

## Bench Commands Reference

Inside the backend container, `bench` CLI is available:

```bash
# Site management
bench new-site <site_name>
bench drop-site <site_name>
bench list-sites
bench use <site_name>

# App management
bench get-app <git_url>
bench install-app <app_name>
bench uninstall-app <app_name>
bench list-apps

# Development
bench migrate                    # Run database migrations
bench build                      # Build frontend assets
bench build --app <app_name>    # Build specific app
bench clear-cache                # Clear Redis cache

# Database
bench mariadb                    # Open MariaDB console
bench backup                     # Backup site
bench backup --with-files        # Backup with uploaded files
bench restore <path>             # Restore from backup

# Debugging
bench console                    # Python REPL with Frappe context
bench --site <site> execute "<python_code>"
```

## Important Notes

### Site Creation

After starting containers for the first time, the `create-site` service initializes a new ERPNext site. This process:
1. Waits for database and Redis to be healthy
2. Creates a new site with default credentials (Administrator/admin)
3. Installs ERPNext and configured apps
4. Exits when complete

Monitor with: `docker compose -f docker-compose.smartbit.yaml logs -f create-site`

### Volume Persistence

The deployment uses Docker named volumes:
- `frappe_docker_sites` - Site files and configuration
- `frappe_docker_db-data` - MariaDB database files
- `frappe_docker_redis-queue-data` - Redis queue persistence

These volumes persist data across container restarts. To completely reset:
```bash
docker compose -f docker-compose.smartbit.yaml down -v  # WARNING: Deletes all data
```

### ARM64 / Apple Silicon Support

The custom build supports ARM64 architecture. On Apple Silicon Macs:
- Use Docker Desktop with Rosetta emulation enabled for initial builds
- The base images (`frappe/build`, `frappe/base`) support multi-arch
- Local builds will automatically use the host architecture

### Updating Custom Forks

When Smartbit Solutions updates the custom Frappe or ERPNext branches:
1. The changes are automatically pulled during the next `./build-custom-image.sh` run
2. Docker build does NOT use cache for git operations by design
3. Rebuild and redeploy to apply updates

### Adding New Custom Apps

To add additional Frappe apps:
1. Edit `apps.json`:
```json
[
  {
    "url": "https://github.com/Smartbit-Solutions/erpnext",
    "branch": "rebrand-to-smartbits-erp"
  },
  {
    "url": "https://github.com/your-org/your-app",
    "branch": "main"
  }
]
```
2. Rebuild: `./build-custom-image.sh`
3. Regenerate: `./generate-compose.sh`
4. Redeploy: `docker compose -f docker-compose.smartbit.yaml down && docker compose -f docker-compose.smartbit.yaml up -d`

## Troubleshooting

### Build Failures
- Verify internet connectivity
- Check that branch names in `apps.json` exist in the repositories
- Ensure Docker has sufficient disk space (builds require ~5GB)
- Review build logs for Python/npm dependency errors

### Site Creation Failures
- Check `create-site` container logs
- Verify `DB_PASSWORD` in `.env` is set correctly
- Ensure ports 8080, 3306, 6379 are not in use
- Confirm database service is healthy: `docker compose -f docker-compose.smartbit.yaml ps`

### Cannot Access ERPNext
- Wait 2-5 minutes after startup for site creation to complete
- Check that `create-site` container has exited successfully
- Verify frontend container is running: `docker compose -f docker-compose.smartbit.yaml ps frontend`
- Check Nginx logs: `docker compose -f docker-compose.smartbit.yaml logs frontend`

### Database Connection Errors
- Verify Redis and MariaDB are running
- Check `common_site_config.json` inside backend container
- Ensure configurator service completed successfully

## Git Workflow

This is a fork with custom Smartbit modifications on the `smartbit-custom-setup` branch:

```bash
# Sync with upstream frappe_docker
git fetch upstream
git checkout main
git merge upstream/main
git push origin main

# Update custom branch
git checkout smartbit-custom-setup
git rebase main  # or merge main
```

Safe customization zones (won't conflict with upstream):
- `apps.json`
- `build-custom-image.sh`
- `generate-compose.sh`
- `images/smartbit/`
- `.env.smartbit.example`
- `SMARTBIT-SETUP.md`
- Any files prefixed with `smartbit-` or in custom directories

Avoid modifying core upstream files unless necessary:
- `compose.yaml` (use overrides instead)
- `images/*/` (except `images/smartbit/`)
- `resources/`
- `.github/workflows/`
