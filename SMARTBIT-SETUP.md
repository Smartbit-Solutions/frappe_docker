# Smartbit Solutions - Custom ERPNext Docker Setup

This guide explains how to build and run your custom Smartbit Solutions ERPNext Docker image.

## 🎯 What's Configured

- **Frappe Framework**: Your custom fork at https://github.com/Smartbit-Solutions/frappe (branch: `rebrand-smartbits-lcs`)
- **ERPNext**: Your custom fork at https://github.com/Smartbit-Solutions/erpnext (branch: `rebrand-to-smartbits-erp`)
- **Docker Image**: Auto-built by GitHub Actions at `ghcr.io/smartbit-solutions/frappe:rebrand-smartbits-lcs`

## 🚀 CI/CD Pipeline

Your setup includes **automatic Docker builds** via GitHub Actions:

### Frappe Repository (`.github/workflows/docker-build.yml`)
- Triggers on push to `rebrand-smartbits-lcs` branch
- Builds when `frappe/www/login.html` or `frappe/public/images/**` change
- Pushes to: `ghcr.io/smartbit-solutions/frappe:rebrand-smartbits-lcs`

### Frappe_docker Repository (`.github/workflows/docker-build.yml`)
- Triggers on push to `smartbit-custom-setup` branch
- Builds when Docker config changes
- Uses the auto-built frappe image from above

**No manual builds required!** Just push changes to your GitHub repos and the images will be auto-built.

## 📋 Prerequisites

Make sure you have installed:
- Docker Desktop (or Docker Engine + Docker Compose)
- git

## 🚀 Quick Start

### 1. Configure Environment Variables

First, create your `.env` file from the example:

```bash
cp .env.smartbit.example .env
```

Then edit the `.env` file and **change the database password**:

```bash
# Change this line in .env:
DB_PASSWORD=your_super_secure_password_here
```

**Choose your image source:**
```bash
# Option A: Use CI-built image from GitHub Container Registry (recommended)
CUSTOM_IMAGE=ghcr.io/smartbit-solutions/frappe
CUSTOM_TAG=rebrand-smartbits-lcs
PULL_POLICY=always

# Option B: Build locally (for development)
# CUSTOM_IMAGE=smartbit-erp
# CUSTOM_TAG=latest
# PULL_POLICY=never
```

### 2. Generate Docker Compose Configuration

```bash
./generate-compose.sh
```

This creates `docker-compose.smartbit.yaml` with all the necessary services.

### 3. Start the Containers

```bash
docker compose -f docker-compose.smartbit.yaml up -d
```

### 4. Access ERPNext

- **URL**: http://localhost:8080
- **Username**: Administrator
- **Password**: admin

## 🔧 Common Commands

### View all container logs
```bash
docker compose -f docker-compose.smartbit.yaml logs -f
```

### Stop containers
```bash
docker compose -f docker-compose.smartbit.yaml down
```

### Restart containers
```bash
docker compose -f docker-compose.smartbit.yaml restart
```

### Access the backend container shell
```bash
docker compose -f docker-compose.smartbit.yaml exec backend bash
```

### Run bench commands
```bash
docker compose -f docker-compose.smartbit.yaml exec backend bench --help
```

## 📝 Adding More Custom Apps Later

When you want to add more custom apps, edit `frappe_docker/apps.json`:

```json
[
  {
    "url": "https://github.com/Smartbit-Solutions/erpnext",
    "branch": "rebrand-to-smartbits-erp"
  },
  {
    "url": "https://github.com/your-org/your-custom-app",
    "branch": "main"
  }
]
```

Commit and push the changes to your `frappe_docker` fork. GitHub Actions will automatically rebuild the image.

## 🐛 Troubleshooting

### Build fails
- Check your internet connection
- Verify the branch names exist in your repositories
- Make sure Docker has enough disk space

### Site creation fails
- Check logs: `docker compose -f docker-compose.smartbit.yaml logs create-site`
- Verify database password in `.env` matches across all services
- Ensure ports 8080, 3306, 6379 are not already in use

### Can't access localhost:8080
- Check if containers are running: `docker compose -f docker-compose.smartbit.yaml ps`
- Verify the port in `.env` (HTTP_PUBLICY_PORT)
- Check firewall settings

### Database connection errors after redeploy
If containers get new IPs after redeploy, the DB user might have wrong host permissions:
```bash
# Grant access for wildcard host
docker compose -f docker-compose.smartbit.yaml exec db bash -c \
  "mariadb -u root -p${MARIADB_ROOT_PASSWORD} -e \"GRANT ALL PRIVILEGES ON _63ffd6636b0899e0.* TO '_63ffd6636b0899e0'@'%' IDENTIFIED BY 'YOUR_PASSWORD'; FLUSH PRIVILEGES\""
```

### Logo shows ERPNext instead of custom logo
The logo is controlled by `Navbar Settings` in the database:
```bash
# Set custom logo
docker compose -f docker-compose.smartbit.yaml exec backend bench --site localhost mariadb -e \
  "UPDATE \`tabSingles\` SET value = '/images/sbs-logo.png' WHERE doctype = 'Navbar Settings' AND field = 'app_logo';"

# Then restart all containers to clear cache
docker compose -f docker-compose.smartbit.yaml down
docker compose -f docker-compose.smartbit.yaml up -d
```

## 🎨 Customizing Branding (Login Page, App Name, etc.)

Branding in ERPNext/Frappe is controlled at **two levels**:

### 1. Template Level (Code)
The login page template uses a fallback in `frappe/www/login.html`:
```html
<h4>{{ _('Login to {0}').format(app_name or _("Smartbits LCS")) }}</h4>
```
This is your custom branding text that appears if `app_name` is not set.

### 2. Database Level (Critical!)
The actual value is read from the `tabSingles` table in the database. Even if your templates have the correct fallback text, the database may have `app_name: "Frappe"` set.

**To check current app_name:**
```bash
docker compose -f docker-compose.smartbit.yaml exec backend bench --site localhost mariadb -e \
  "SELECT field, value FROM \`tabSingles\` WHERE doctype = 'Website Settings' AND field = 'app_name';"
```

**To update app_name:**
```bash
docker compose -f docker-compose.smartbit.yaml exec backend bench --site localhost mariadb -e \
  "UPDATE \`tabSingles\` SET value = 'Smartbits LCS' WHERE doctype = 'Website Settings' AND field = 'app_name';"
```

**After changing, restart services:**
```bash
docker compose -f docker-compose.smartbit.yaml exec backend bench --site localhost clear-cache
docker compose -f docker-compose.smartbit.yaml restart backend frontend
```

### Why This Matters
The `frappe.get_website_settings("app_name")` function in `frappe/www/login.py` reads from the database, not from your template fallback. If the database has "Frappe", that's what will display.

### Other Branding Settings in tabSingles
The `tabSingles` table stores many single-document settings. Check what else might need updating:
```sql
SELECT field, value FROM \`tabSingles\` WHERE doctype = 'Website Settings';
```

## 🖼️ Changing the Login Logo

To customize the logo shown on the login page:

### 1. Add Logo Files
Place your logo files in `frappe/frappe/public/images/`:
- `sbs-logo.png` - Primary logo (light)
- `sbs-logo-dark.png` - Dark variant (optional)

### 2. Update Login Template
Edit `frappe/frappe/www/login.html` and update the `logo_section` macro:

```html
{% macro logo_section(title=null) %}
<div class="page-card-head">
	<img class="app-logo" src="/images/sbs-logo.png">
	{% if title %}
	<h4>{{ _(title)}}</h4>
	{% else %}
	<h4>{{ _('Login to {0}').format(app_name or _("Smartbits LCS")) }}</h4>
	{% endif %}
</div>
{% endmacro %}
```

### 3. Rebuild and Deploy
```bash
# Commit changes to your frappe fork first
cd /path/to/frappe
git add .
git commit -m "Add Smartbits logo"
git push origin rebrand-smartbits-lcs

# Rebuild Docker image
cd /path/to/frappe_docker
./build-custom-image.sh
docker compose -f docker-compose.smartbit.yaml down
docker compose -f docker-compose.smartbit.yaml up -d
```

### Quick Fix (Container Running)
Copy files directly to running container:
```bash
docker cp sbs-logo.png frappe_docker-backend-1:/home/frappe/frappe-bench/apps/frappe/frappe/public/images/sbs-logo.png
docker compose -f docker-compose.smartbit.yaml restart backend frontend
```

**Note**: For production, always push changes to your GitHub fork so they're included in the Docker build.

## 📚 Additional Resources

- [frappe_docker Documentation](./docs/)
- [Frappe Framework Docs](https://frappeframework.com/docs)
- [ERPNext User Manual](https://docs.erpnext.com/)

## 🔄 Updating Your Custom Fork

When you update your custom Frappe or ERPNext code:

1. **Push changes to GitHub**:
```bash
git add .
git commit -m "Your changes"
git push origin rebrand-smartbits-lcs
```

2. **GitHub Actions automatically rebuilds** the Docker image (~5-10 minutes)

3. **Pull the new image and restart**:
```bash
docker compose -f docker-compose.smartbit.yaml down
docker compose -f docker-compose.smartbit.yaml pull
docker compose -f docker-compose.smartbit.yaml up -d
```

---

**Need help?** Check the [official frappe_docker docs](./docs/) or the [troubleshooting guide](./docs/07-troubleshooting/01-troubleshoot.md).
