# Logo Fix - Runtime Configuration

## Quick Runtime Fix (Temporary)

To change the app logo on the login page without rebuilding:

```bash
# Set the logo URL in site configuration
docker compose -f docker-compose.smartbit.yaml exec backend \
  bench --site localhost set-config app_logo_url "/assets/frappe/images/sbs-logo.png"

# Clear cache to apply changes
docker compose -f docker-compose.smartbit.yaml exec backend \
  bench --site localhost clear-cache
```

This updates the `app_logo_url` in `sites/localhost/site_config.json`.

**Note:** This change only persists in the Docker volume. For permanent changes, modify `frappe/frappe/hooks.py` in the source repository and rebuild the image.

## Permanent Fix

1. Edit `../frappe/frappe/hooks.py`: Change `app_logo_url = "/assets/frappe/images/sbs-logo.png"`
2. Commit and push to GitHub
3. Rebuild: `./build-custom-image.sh`
4. Restart: `docker compose -f docker-compose.smartbit.yaml down && docker compose -f docker-compose.smartbit.yaml up -d`
