#!/bin/bash -x
# Title: NSO packages reload
# Description: This script issues a packages reload in the container of the specified service from the docker-compose file.
# Author: @ponchotitlan
#
# Usage:
#   ./packages-reload.sh

NSO_DOCKER_NAME_GEN="pipeline/scripts/get-nso-docker-name.sh"
container_name=$("$NSO_DOCKER_NAME_GEN")

echo "##### [🔄] Performing packages reload in container $container_name .... #####"
docker exec -i $container_name bash -lc "echo 'packages reload' | ncs_cli -Cu admin"
echo "[🔄] Packages reload done!"