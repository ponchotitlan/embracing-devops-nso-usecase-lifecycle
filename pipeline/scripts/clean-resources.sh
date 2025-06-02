#!/bin/bash -x
# Title: Clean resources
# Description: This script brings down the associated resources to all the services in the docker-compose file
# Author: @ponchotitlan
#
# Usage:
#   ./clean-resouces.sh

YAML_FILE="pipeline/setup/config.yaml"
NEDS_PATH=".netsims"

echo "##### [🧹] Bringing all staging services down .... #####"

# Extract the name of the container
NSO_DOCKER_NAME_GEN="pipeline/scripts/get-nso-docker-name.sh"
container_name=$("$NSO_DOCKER_NAME_GEN")
compose_file="pipeline/setup/docker-compose-${container_name}.yml"

# Stop all the services of the docker-compose file
docker compose -f $compose_file down

# Remove the rendered docker-compose file
rm -rf $compose_file

# Remove the NEDs from the packages/ folder of this repository
neds=$(yq "$NEDS_PATH" "$YAML_FILE")
for ned in $neds; do
    # The NEDs are the keys of the netsims structure in the config.yaml file
    if echo "$ned" | grep -q '\:'; then
        ned=$(echo "$ned" | tr -d '"')
        ned=$(echo "$ned" | tr -d ':')
        rm -rf packages/$ned/
    fi
done

# Remove all the files mounted in the mounted volume pipeline/conf except for the file ncs.conf
rm -rf pipeline/conf/ssh/
rm -rf pipeline/conf/ssl/
rm -rf pipeline/conf/ncs.crypto_keys

echo "[🧹] Clean sweep done!"