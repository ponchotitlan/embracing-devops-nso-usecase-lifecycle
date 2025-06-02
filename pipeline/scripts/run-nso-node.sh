#!/bin/bash -x
# Title: Setup NSO
# Description: This script renders a docker-compose template based on the values provided in the pipeline/setup/config.yaml file and runs the service "nso-node" of this file. The docker-compose service is run in the background.
# Author: @ponchotitlan
#
# Usage:
#   ./run-nso-node.sh

NSO_DOCKER_NAME_GEN="pipeline/scripts/get-nso-docker-name.sh"
DOCKER_COMPOSE_TEMPLATE_RENDER="pipeline/scripts/render-docker-compose-template.sh"

compose_service=$("$NSO_DOCKER_NAME_GEN")
compose_file="pipeline/setup/docker-compose-${compose_service}.yml"

# Render a new docker-compose file and spin the service
echo "##### [🐋] Rendering docker-compose template .... #####"
bash "$DOCKER_COMPOSE_TEMPLATE_RENDER"
docker compose -f $compose_file up $compose_service -d

# Poll the health status
until [ "$(docker inspect --format='{{json .State.Health.Status}}' $compose_service)" == "\"healthy\"" ]; do
    echo "Waiting for $compose_service to become healthy..."
    sleep 10
done

echo "[🐋] $compose_service is healthy and ready!"