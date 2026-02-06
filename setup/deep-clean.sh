#!/bin/bash
# Title: Deep clean resources
# Description: This script performs a deep clean of all resources including volumes, state files, and generated files
# Author: @ponchotitlan
#
# Usage:
#   ./deep-clean.sh

DOCKER_COMPOSE_FILE="docker-compose.yml"

# Check if docker-compose.yml exists
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    echo "⚠️  docker-compose.yml not found. Skipping container cleanup."
else
    # Extract the name of the container from docker-compose.yml
    container_name=$(awk '/container_name:/ {print $2; exit}' "$DOCKER_COMPOSE_FILE")
    
    if [ -n "$container_name" ]; then
        # Derive volume name from container name (replace last segment with 'etc')
        volume_name=$(echo "$container_name" | sed 's/-[^-]*$/-etc/')
        
        echo "🛑 Stopping Docker Compose services and removing volumes..."
        docker compose down -v
        
        echo "🗑️  Removing named volume: $volume_name"
        docker volume rm -f "$volume_name" 2>/dev/null || true
    else
        echo "⚠️  Could not extract container name. Running basic docker compose down..."
        docker compose down -v
    fi
fi

# Remove NSO state files
echo "🧹 Removing NSO state files..."
rm -rf ncs/ssh/ ncs/ssl/ ncs/ncs.crypto_keys

# Remove generated files
echo "🧹 Removing generated template files..."
rm -f docker-compose.yml Dockerfile

echo "✅ Deep clean complete. Run 'make up' to rebuild"
