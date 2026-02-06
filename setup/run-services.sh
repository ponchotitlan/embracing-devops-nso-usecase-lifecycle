#!/bin/bash -x
# Title: Run Docker Compose Services
# Description: This script runs the services of the docker-compose.yml file
#              available in the root directory of this repository.
#              A script was needed for this as we don't know how long is the
#              NSO container going to take to become healthy.
#
# Usage:
#   ./run-services.sh

set -xe
set +x
NSO_HEALTHY_MAX_ATTEMPTS=50
CONFIG_FILE="config.yaml"
COMPOSE_FILE="docker-compose.yml"

# Run the services in the Docker Compose file
docker compose -f $COMPOSE_FILE up -d

# Get the actual container name from the rendered docker-compose.yml file
nso_container_name=$(awk '/container_name:/ {print $2; exit}' "$COMPOSE_FILE")
set -x

# Poll the health status
echo "⌛️ Waiting for $nso_container_name to become healthy..."
current_attempt=0

while true; do
    current_attempt=$((current_attempt + 1))
    if [ "$current_attempt" -gt "$NSO_HEALTHY_MAX_ATTEMPTS" ]; then
        echo "[🐋🔥] Error: Exceeded maximum of $NSO_HEALTHY_MAX_ATTEMPTS attempts. Container '$nso_container_name' did not become healthy."
        exit 1
    fi

    set +x
    inspect_output=$(docker inspect --format='{{json .State.Running}} {{json .State.Health.Status}}' "$nso_container_name" 2>/dev/null)
    set -x
    
    if [ -z "$inspect_output" ]; then
        echo "[🐋🔥] Error: Container '$nso_container_name' not found or docker inspect failed. Exiting."
        exit 1
    fi

    set +x
    running_status=$(echo "$inspect_output" | awk '{print $1}')
    health_status=$(echo "$inspect_output" | awk '{print $2}')
    set -x

    if [ "$running_status" == "false" ]; then
        echo "[🐋🔥] Error: Container '$nso_container_name' stopped or exited unexpectedly during boot."
        exit 1
    elif [ "$health_status" == "\"healthy\"" ]; then
        echo "[🐋] $nso_container_name is healthy and ready!"
        break
    else
        echo "[🐋💤] Waiting for '$nso_container_name' to become healthy (current status: $health_status)..."
        sleep 10
    fi
done
