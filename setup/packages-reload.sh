#!/bin/bash -x
# Title: Run Packages Reload in NSO container
# Description: This script executes a docker command in the NSO container
#              that issues a packages reload. If any of the services raises
#              an issue, this script exits with an error.
# Usage:
#   ./packages-reload.sh

set -xe
set +x

TOKEN_FAILED="result false"
CONFIG_FILE="config.yaml"

# Get the name of the NSO container from the config.yaml file
nso_container_name=$(awk '/container_name:/ {print $2; exit}' "docker-compose.yml")
set -x

# Issue a packages reload in the NSO container
reload_output=$(docker exec -i $nso_container_name bash -lc "echo 'packages reload' | ncs_cli -Cu admin")
if echo "$reload_output" | grep -q "$TOKEN_FAILED"; then
    # Packages reload failed!
    exit 1
else
    # Packages reload passed!
    exit 0
fi