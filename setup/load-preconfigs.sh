#!/bin/bash -x
# Title: Load pre-configurations
# Description: This script goes through the files in the pipeline/preconfigs location of this repository, 
#              extracts the names, and performs a ncs_load operation on the container of the specified service.
#
# Usage:
#   ./load-preconfigs.sh

DIRECTORY="preconfigs"
CONFIG_FILE="config.yaml"

# Get the name of the NSO container from the config.yaml file
nso_container_name=$(awk '/container_name:/ {print $2; exit}' "docker-compose.yml")

if [ -d "$DIRECTORY" ]; then
    # Iterate over the files in the directory
    for FILE in "$DIRECTORY"/*; do
        # Check if it's a file and ends with .xml
        if [ -f "$FILE" ] && [[ "$FILE" == *.xml ]]; then
            # Extract and the file name
            file_name=$(echo "$(basename "$FILE")")
            # Load the files in the mounted volume into NSO
            docker exec -i $nso_container_name bash -lc "ncs_load -l -m /tmp/nso/$file_name"
        fi
    done
fi

echo "[⬇️] Loading done!"