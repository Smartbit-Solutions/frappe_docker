#!/bin/bash

# Build script for Smartbit Solutions custom ERPNext Docker image
# This script builds a Docker image with your custom Frappe and ERPNext forks

set -e

echo "🏗️  Building Smartbit Solutions ERPNext Docker image..."
echo ""

# Encode apps.json to base64
echo "📦 Encoding apps.json..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    export APPS_JSON_BASE64=$(base64 -i apps.json)
else
    # Linux
    export APPS_JSON_BASE64=$(base64 -w 0 apps.json)
fi

echo "✅ Apps configuration encoded"
echo ""

# Build the Docker image
echo "🐳 Building Docker image..."
echo "   Frappe: https://github.com/Smartbit-Solutions/frappe (branch: rebrand-smartbits-lcs)"
echo "   Apps from: apps.json"
echo ""

docker build \
  --build-arg=BASE_VERSION=version-16 \
  --build-arg=FRAPPE_PATH=https://github.com/Smartbit-Solutions/frappe \
  --build-arg=FRAPPE_BRANCH=rebrand-smartbits-lcs \
  --build-arg=APPS_JSON_BASE64=$APPS_JSON_BASE64 \
  --tag=smartbit-erp:latest \
  --file=images/smartbit/Containerfile \
  --progress=plain \
  .

echo ""
echo "✅ Build complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Copy .env.smartbit.example to .env: cp .env.smartbit.example .env"
echo "   2. Edit .env and update DB_PASSWORD with a secure password"
echo "   3. Generate compose file: ./generate-compose.sh"
echo "   4. Start containers: docker compose -f docker-compose.smartbit.yaml up -d"
echo ""
