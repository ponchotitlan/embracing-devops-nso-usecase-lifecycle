#!/bin/bash -x
# Title: Setup NSO
# Description: This script renders a docker-compose template based on the values provided in the pipeline/setup/config.yaml file and runs the service "nso-node" of this file. The docker-compose service is run in the background.
# Author: @ponchotitlan
#
# Usage:
#   ./run-nso-node.sh

YAML_FILE="pipeline/setup/docker-compose.yml"
COMPOSE_SERVICE="nso_node"
CONTAINER_NAME_PATH=".services.nso_node.container_name"

# Render a new docker-compose file and spin the service
echo "##### [🐋] Rendering docker-compose template .... #####"
python pipeline/utils/docker_compose_render.py pipeline/setup/docker-compose.j2 pipeline/setup/config.yaml yml
docker-compose -f pipeline/setup/docker-compose.yml up $COMPOSE_SERVICE -d

# Extract the name of the containerand remove quotes
container_name=$(yq "$CONTAINER_NAME_PATH" "$YAML_FILE")
container_name=$(echo "$container_name" | tr -d '"')

# Poll the health status
until [ "$(docker inspect --format='{{json .State.Health.Status}}' $container_name)" == "\"healthy\"" ]; do
    echo "Waiting for $container_name to become healthy..."
    sleep 10
done

echo "[🐋] $container_name is healthy and ready!"