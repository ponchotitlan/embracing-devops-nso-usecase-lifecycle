#!/bin/bash -x
# Title: NSO packages reload
# Description: This script issues a packages reload in the container of the specified service from the docker-compose file. It is assumed that the name provided corresponds to a NSO container service.
# Author: @ponchotitlan
#
# Usage:
#   ./packages-reload.sh <service_name>

YAML_FILE="pipeline/setup/docker-compose.yml"

if [ -z "$1" ]; then
    echo "Usage: $0 <container_name> ..."
    exit 1
fi

# Extract the name of the container and remove quotes
CONTAINER_NAME_PATH=".services.$1.container_name"
container_name=$(yq "$CONTAINER_NAME_PATH" "$YAML_FILE")
container_name=$(echo "$container_name" | tr -d '"')

echo "##### [🔄] Performing packages reload in container $container_name .... #####"
docker exec -i $container_name bash -lc "echo 'packages reload' | ncs_cli -Cu admin"
echo "[🔄] Packages reload done!"