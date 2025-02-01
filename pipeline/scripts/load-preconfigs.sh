#!/bin/bash -x
# Title: Load pre-configurations
# Description: This script goes through the files in the pipeline/preconfigs location of this repository, extracts the names, and performs a ncs_load operation on the container of the specified service. It is implied that the service provided has a NSO container associated, and that this container has a volume mounted on the pipeline/preconfigs location which points to /tmp/nso inside of the container.
# Author: @ponchotitlan
#
# Usage:
#   ./load-preconfigs.sh <service_name>

DIRECTORY="pipeline/preconfigs"
YAML_FILE="pipeline/setup/docker-compose.yml"

if [ -z "$1" ]; then
    echo "Usage: $0 <service_name> ..."
    exit 1
fi

# Extract the name of the container and remove quotes
CONTAINER_NAME_PATH=".services.$1.container_name"
container_name=$(yq "$CONTAINER_NAME_PATH" "$YAML_FILE")
container_name=$(echo "$container_name" | tr -d '"')

echo "##### [⬇️] Loading preconfiguration files in container $container_name .... #####"

if [ -d "$DIRECTORY" ]; then
    # Iterate over the files in the directory
    for FILE in "$DIRECTORY"/*; do
        # Check if it's a file and ends with .xml
        if [ -f "$FILE" ] && [[ "$FILE" == *.xml ]]; then
            # Extract and the file name
            file_name=$(echo "$(basename "$FILE")")
            # Load the files in the mounted volume into NSO
            docker exec -i $container_name bash -lc "ncs_load -l -m /tmp/nso/$file_name"
        fi
    done
fi

echo "[⬇️] Loading done!"