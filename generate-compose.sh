#!/bin/bash

# Generate docker-compose configuration for Smartbit Solutions ERPNext
# This merges the base compose file with necessary overrides

set -e

echo "📝 Generating docker-compose configuration..."
echo ""

docker compose --env-file .env \
    -f compose.yaml \
    -f overrides/compose.mariadb.yaml \
    -f overrides/compose.redis.yaml \
    -f overrides/compose.noproxy.yaml \
    config > docker-compose.smartbit.yaml

echo "✅ Configuration generated: docker-compose.smartbit.yaml"
echo ""
echo "📋 To start your containers:"
echo "   docker compose -f docker-compose.smartbit.yaml up -d"
echo ""
echo "📋 To view logs:"
echo "   docker compose -f docker-compose.smartbit.yaml logs -f"
echo ""
echo "📋 To stop containers:"
echo "   docker compose -f docker-compose.smartbit.yaml down"
echo ""
