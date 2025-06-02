#!/bin/bash -x
# Title: Creation of artifacts with the service packages
# Description: This script adds to a tar file the service packages located in the packages/ dir of this repository. The netsim folders are ignored. The resulting tar file is stored in the mounted volume /tmp/nso for easier access via the pipeline later on.
# Author: @ponchotitlan
#
# Usage:
#   ./create-artifact-packages.sh

# This function creates a tar file of the folder specified and saves it in the /tmp/nso location
# Usage tar_folders <container_name(str)> <package_folder_names(array(str))>
tar_folders(){
    local container_name="$1"
    local packages_array="$@"
    local ARTIFACT_NAME="ciscolive_demo_packages.tar.gz"
    local ARTIFACT_DIR="/tmp/nso"

    docker exec -i $container_name bash -lc "cd /nso/run/packages/ && tar -czvf $ARTIFACT_DIR/$ARTIFACT_NAME ${packages_array[@]}"
}

YAML_FILE_CONFIG="pipeline/setup/config.yaml"
PACKAGES_DIR="packages"
NEDS_PATH=".netsims | keys"

echo "##### [📦] Zipping the compiled packages into an artifact.... #####"

# Extract the name of the container
NSO_DOCKER_NAME_GEN="pipeline/scripts/get-nso-docker-name.sh"
container_name=$("$NSO_DOCKER_NAME_GEN")

# Extract the netsim folder names from the YAML file
ned_packages=$(yq "$NEDS_PATH" "$YAML_FILE_CONFIG")

# Get all the packages folders and remove the trailing slash from their names
all_packages=($(ls -d "$PACKAGES_DIR"/*/ | xargs -n 1 basename))

service_packages=()
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
        service_packages+=($package)
    fi
done

tar_folders $container_name ${service_packages[@]}

echo "[📦] Creation of the artifact ciscolive_demo_packages.tar.gz done!"