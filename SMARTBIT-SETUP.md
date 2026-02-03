# Smartbit Solutions - Custom ERPNext Docker Setup

This guide explains how to build and run your custom Smartbit Solutions ERPNext Docker image.

## 🎯 What's Configured

- **Frappe Framework**: Your custom fork at https://github.com/Smartbit-Solutions/frappe (branch: `rebrand-smartbits-lcs`)
- **ERPNext**: Your custom fork at https://github.com/Smartbit-Solutions/erpnext (branch: `rebrand-to-smartbits-erp`)
- **Image name**: `smartbit-erp:latest`

## 📋 Prerequisites

Make sure you have installed:
- Docker Desktop (or Docker Engine + Docker Compose)
- git

## 🚀 Quick Start

### 1. Build the Docker Image

```bash
./build-custom-image.sh
```

This will:
- Encode your `apps.json` configuration
- Build a Docker image with your custom Frappe and ERPNext forks
- Tag it as `smartbit-erp:latest`

**Note**: This can take 15-30 minutes depending on your internet speed and computer.

### 2. Configure Environment Variables

First, create your `.env` file from the example:

```bash
cp .env.smartbit.example .env
```

Then edit the `.env` file and **change the database password**:

```bash
# Change this line in .env:
DB_PASSWORD=your_super_secure_password_here
```

You can also customize other settings like:
- `HTTP_PUBLISH_PORT` (default: 8080)
- `LETSENCRYPT_EMAIL` (for SSL certificates)
- `FRAPPE_SITE_NAME_HEADER` (for custom site names)

### 3. Generate Docker Compose Configuration

```bash
./generate-compose.sh
```

This creates `docker-compose.smartbit.yaml` with all the necessary services:
- Your custom ERPNext application
- MariaDB database
- Redis cache and queue
- Nginx proxy

### 4. Start the Containers

```bash
docker compose -f docker-compose.smartbit.yaml up -d
```

Wait a few minutes for the site to be created. You can watch the logs:

```bash
docker compose -f docker-compose.smartbit.yaml logs -f create-site
```

### 5. Access ERPNext

Once the `create-site` container finishes:

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

When you want to add more custom apps:

1. Edit `apps.json` and add your new app:
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

2. Rebuild the image:
```bash
./build-custom-image.sh
```

3. Regenerate and restart:
```bash
./generate-compose.sh
docker compose -f docker-compose.smartbit.yaml down
docker compose -f docker-compose.smartbit.yaml up -d
```

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
- Verify the port in `.env` (HTTP_PUBLISH_PORT)
- Check firewall settings

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

1. Rebuild the image: `./build-custom-image.sh`
2. Recreate containers:
```bash
docker compose -f docker-compose.smartbit.yaml down
docker compose -f docker-compose.smartbit.yaml up -d
```

---

**Need help?** Check the [official frappe_docker docs](./docs/) or the [troubleshooting guide](./docs/07-troubleshooting/01-troubleshoot.md).
