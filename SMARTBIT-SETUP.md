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
