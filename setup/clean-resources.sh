#!/bin/bash -x
# Title: Clean resources
# Description: This script brings down the associated resources to all the services in the docker-compose file
# Author: @ponchotitlan
#
# Usage:
#   ./clean-resouces.sh

YAML_FILE="config.yaml"
NEDS_PATH=".netsims"

echo "##### [🧹] Bringing all staging services down .... #####"

# Extract the name of the container from docker-compose.yml
container_name=$(awk '/container_name:/ {print $2; exit}' "docker-compose.yml")
compose_file="docker-compose.yml"

# Stop all the services of the docker-compose file
docker compose -f $compose_file down

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

# Remove all the files mounted in the mounted volume ncs/ except for the file ncs.conf
rm -rf ncs/ssh/
rm -rf ncs/ssl/
rm -rf ncs/ncs.crypto_keys

echo "[🧹] Clean sweep done!"