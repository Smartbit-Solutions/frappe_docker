# Session Notes: Custom Smartbit ERPNext Docker Setup

## Date: 2026-02-03

## Summary

Successfully set up and tested custom Smartbit Solutions ERPNext containers from GitHub Container Registry (GHCR) after resolving platform compatibility issues.

---

## Changes Made

### 1. `.env` Configuration

**Before:**
```bash
CUSTOM_IMAGE=smartbit-erp
CUSTOM_TAG=latest
PULL_POLICY=missing
```

**After:**
```bash
CUSTOM_IMAGE=ghcr.io/smartbit-solutions/erpnext
CUSTOM_TAG=rebrand-to-smartbits-erp
PULL_POLICY=always
```

**Why:** The locally built image (`smartbit-erp:latest`) was not used. Instead, we switched to the pre-built GHCR images.

---

### 2. Removed Platform Constraints (ARM64 Support)

**Files Modified:**
- `compose.yaml` - Removed all `platform: linux/amd64` lines
- `overrides/compose.mariadb.yaml` - Removed platform constraints
- `overrides/compose.redis.yaml` - Removed platform constraints
- `overrides/compose.noproxy.yaml` - Removed platform constraints

**Why:** The GHCR images are built for **ARM64** (Apple Silicon), but the base compose files specified `linux/amd64`. This caused Docker to fail pulling the images.

**How to replicate:**
```bash
# Run from project root
sed -i '' 's/[[:space:]]*platform: linux\/amd64//g' compose.yaml
sed -i '' 's/[[:space:]]*platform: linux\/amd64//g' overrides/compose.*.yaml
./generate-compose.sh
```

---

### 3. Regenerated Docker Compose

**Command:**
```bash
./generate-compose.sh
```

**Output:** `docker-compose.smartbit.yaml` with correct ARM64 platform support.

---

## Site Creation Issues Resolved

### Problem 1: Database User Access Denied

**Issue:** The site was created with incorrect database user credentials.

**Solution:** Removed the incomplete site and recreated with proper MariaDB root password:
```bash
# Remove broken site
rm -rf /home/frappe/frappe-bench/sites/localhost

# Recreate site with root password flag
bench new-site localhost \
  --admin-password admin \
  --db-password xC4clRHsi5OGQ0lE0vTU4q3TM \
  --mariadb-root-password xC4clRHsi5OGQ0lE0vTU4q3TM
```

**Note:** The `--mariadb-root-password` flag was crucial for proper database setup.

---

### Problem 2: Missing `smartbits_erp_integrations` Module

**Issue:** ERPNext installation failed with: `No module named 'erpnext.smartbits_erp_integrations'`

**Solution:** Created a placeholder module:
```bash
mkdir -p /home/frappe/frappe-bench/apps/erpnext/erpnext/smartbits_erp_integrations
echo "# Smartbits ERP Integrations\n# Placeholder module\npass" > \
  /home/frappe/frappe-bench/apps/erpnext/erpnext/smartbits_erp_integrations/__init__.py
```

**Why:** Your custom ERPNext fork references this module in its hooks, but the module doesn't exist yet. This is a placeholder until the actual module is implemented.

---

### Problem 3: Database Connection Issues

**Solution:** Added `db_root_password` to `common_site_config.json`:
```json
{
  "db_host": "db",
  "db_port": 3306,
  "db_password": "xC4clRHsi5OGQ0lE0vTU4q3TM",
  "db_root_password": "xC4clRHsi5OGQ0lE0vTU4q3TM",
  "redis_cache": "redis://redis-cache:6379",
  "redis_queue": "redis://redis-queue:6379",
  "redis_socketio": "redis://redis-queue:6379",
  "socketio_port": 9000
}
```

---

## Final Working Configuration

### Images Used
- **ERPNext:** `ghcr.io/smartbit-solutions/erpnext:rebrand-to-smartbits-erp` (ARM64)
- **Frappe:** `ghcr.io/smartbit-solutions/frappe/rebrand-smartbits-lcs:latest` (ARM64)
- **MariaDB:** `mariadb:11.8`
- **Redis:** `redis:6.2-alpine`

### Database Credentials
- **Root Password:** `xC4clRHsi5OGQ0lE0vTU4q3TM`
- **Site DB Name:** `_63ffd6636b0899e0`
- **Site DB User:** `_63ffd6636b0899e0`
- **Site DB Password:** `xC4clRHsi5OGQ0lE0vTU4q3TM`

### ERPNext Access
- **URL:** http://localhost:8080
- **Username:** Administrator
- **Password:** admin

---

## Commands to Recreate This Setup

### 1. Pull and Start Containers
```bash
# Update .env if needed
cp .env.smartbit.example .env

# Generate compose (if platform constraints were removed)
./generate-compose.sh

# Start containers
docker compose -f docker-compose.smartbit.yaml up -d

# Wait for services to be healthy
docker compose -f docker-compose.smartbit.yaml ps
```

### 2. Create Site
```bash
# Set db_password in common_site_config.json
docker compose -f docker-compose.smartbit.yaml exec backend bash -c \
  'echo "{\"db_host\": \"db\", \"db_port\": 3306, \"db_password\": \"xC4clRHsi5OGQ0lE0vTU4q3TM\", \"db_root_password\": \"xC4clRHsi5OGQ0lE0vTU4q3TM\", \"redis_cache\": \"redis://redis-cache:6379\", \"redis_queue\": \"redis://redis-queue:6379\", \"redis_socketio\": \"redis://redis-queue:6379\", \"socketio_port\": 9000}" > /home/frappe/frappe-bench/sites/common_site_config.json'

# Create site
docker compose -f docker-compose.smartbit.yaml exec backend bench new-site localhost \
  --admin-password admin \
  --db-password xC4clRHsi5OGQ0lE0vTU4q3TM \
  --mariadb-root-password xC4clRHsi5OGQ0lE0vTU4q3TM

# Install ERPNext
docker compose -f docker-compose.smartbit.yaml exec backend bench --site localhost install-app erpnext

# Restart services
docker compose -f docker-compose.smartbit.yaml restart backend frontend
```

### 3. Access ERPNext
```bash
open http://localhost:8080
```

---

## Permanent Fixes Needed

### 1. Add `smartbits_erp_integrations` Module
The placeholder module needs to be replaced with actual implementation. This module is referenced in the ERPNext hooks but doesn't exist in your fork.

**Location:** `erpnext/erpnext/smartbits_erp_integrations/__init__.py`

### 2. Rebuild Images with ARM64 Support
The images were built for ARM64 (Apple Silicon). If you need AMD64 support, rebuild the images specifying the correct platform or use a multi-platform build.

### 3. Fix Platform Constraints in Base Files
The changes to remove `platform: linux/amd64` from `compose.yaml` and override files need to be committed or the platform constraints should be made conditional for multi-platform support.

---

## Useful Commands

```bash
# View logs
docker compose -f docker-compose.smartbit.yaml logs -f

# Stop containers
docker compose -f docker-compose.smartbit.yaml down

# Restart containers
docker compose -f docker-compose.smartbit.yaml restart

# Access backend shell
docker compose -f docker-compose.smartbit.yaml exec backend bash

# List sites
docker compose -f docker-compose.smartbit.yaml exec backend bench list-sites

# Check container status
docker compose -f docker-compose.smartbit.yaml ps
```

---

## Notes

- CRM workspace exists and is visible but needs to be **pinned** to appear in sidebar
- Access CRM at: http://localhost:8080/app/crm
- The custom ERPNext fork includes rebranding to "Smartbits ERP"
- All containers are running successfully with the custom Smartbit Solutions images
