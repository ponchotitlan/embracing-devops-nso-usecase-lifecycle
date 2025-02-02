#!/bin/bash -x
# Title: Installing of libraries for testing
# Description: This script performs the pip installation of the requirements.txt file located in the pipeline/preconfigs dir of this repository. It is assumed that this file is a definition of python libraries for running the tests batteries of this repository, and that the dir is mounted as a volume in the NSO container associated to the specified service.
# Author: @ponchotitlan
#
# Usage:
#   ./install-testing-libraries.sh <service-name>

YAML_FILE_DOCKER="pipeline/setup/docker-compose.yml"

if [ -z "$1" ]; then
    echo "Usage: $0 <cservice_name> ..."
    exit 1
fi

echo "##### [🏃🏻‍♀️] Installing the libraries required for testing .... #####"

# Extract the name of the container and remove quotes
CONTAINER_NAME_PATH=".services.$1.container_name"
container_name=$(yq "$CONTAINER_NAME_PATH" "$YAML_FILE_DOCKER")
container_name=$(echo "$container_name" | tr -d '"')

docker exec -i $container_name bash -lc "cd /tmp/nso/ && pip install -r requirements.txt"

echo "[🏃🏻‍♀️] Installing done!"