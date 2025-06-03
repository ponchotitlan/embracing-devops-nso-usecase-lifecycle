#!/bin/bash -x
# Title: NSO packages reload
# Description: This script issues a packages reload in the container of the specified service from the docker-compose file.
# Author: @ponchotitlan
#
# Usage:
#   ./packages-reload.sh

TOKEN_FAILED="result false"
NSO_DOCKER_NAME_GEN="pipeline/scripts/get-nso-docker-name.sh"
container_name=$("$NSO_DOCKER_NAME_GEN")

reload_output=$(docker exec -i $container_name bash -lc "echo 'packages reload' | ncs_cli -Cu admin")
if echo "$reload_output" | grep -q "$TOKEN_FAILED"; then
    # Packages reload failed!
    echo "failed"
else
    # Packages reload passed!
    echo "pass"
fi