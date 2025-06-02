#!/bin/bash -x
# Title: Load pre-configurations
# Description: This script goes through the files in the pipeline/preconfigs location of this repository, extracts the names, and performs a ncs_load operation on the container of the specified service.
# Author: @ponchotitlan
#
# Usage:
#   ./load-preconfigs.sh

DIRECTORY="pipeline/preconfigs"

# Extract the name of the container
NSO_DOCKER_NAME_GEN="pipeline/scripts/get-nso-docker-name.sh"
container_name=$("$NSO_DOCKER_NAME_GEN")

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