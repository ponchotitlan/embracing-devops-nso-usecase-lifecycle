#!/bin/bash -x
# Title: Creation of artifacts with the test results from the service packages
# Description: This script adds to a tar file the files located in the packages/<package>/tests dir of this repository. The netsim folders are ignored. The resulting tar file is stored in the mounted volume /tmp/nso for easier access via the pipeline later on.
# Author: @ponchotitlan
#
# Usage:
#   ./create-artifact-tests.sh <service-name>

# This function creates a tar file of the folder specified and saves it in the /tmp/nso location
# Usage tar_folders <container_name(str)> <package_folder_names(array(str))>
run_robot_test(){
    local container_name="$1"
    local service_name="$2"

    docker exec -i $container_name bash -lc "cd /nso/run/packages/$service_name/tests && robot $service_name.robot"
}

YAML_FILE_CONFIG="pipeline/setup/config.yaml"
YAML_FILE_DOCKER="pipeline/setup/docker-compose.yml"
PACKAGES_DIR="packages"
NEDS_PATH=".netsims | keys"

if [ -z "$1" ]; then
    echo "Usage: $0 <container_name> ..."
    exit 1
fi

echo "##### [🤖] Executing Robot tests of each service.... #####"

# Extract the name of the container and remove quotes
CONTAINER_NAME_PATH=".services.$1.container_name"
container_name=$(yq "$CONTAINER_NAME_PATH" "$YAML_FILE_DOCKER")
container_name=$(echo "$container_name" | tr -d '"')

# Extract the netsim folder names from the YAML file
ned_packages=$(yq "$NEDS_PATH" "$YAML_FILE_CONFIG")

# Get all the packages folders and remove the trailing slash from their names
all_packages=($(ls -d "$PACKAGES_DIR"/*/ | xargs -n 1 basename))

# Iterate over each folder and check if it's in the excluded list
for package in "${all_packages[@]}"; do

    is_ned=0
    for ned in $ned_packages; do
        ned=$(echo "$ned" | tr -d '"')
        ned=$(echo "$ned" | tr -d ',')
        if [[ $package == $ned ]]; then
            is_ned=1
        fi
    done

    if [[ $is_ned == 0 ]]; then
        run_robot_test $container_name $package
    fi
done

echo "[🤖] Robot test cases done!"