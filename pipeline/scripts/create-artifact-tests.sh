#!/bin/bash -x
# Title: Creation of artifacts with the test results from the service packages
# Description: This script adds to a tar file the files located in the packages/<package>/tests dir of this repository. The netsim folders are ignored. The resulting tar file is stored in the mounted volume /tmp/nso for easier access via the pipeline later on.
# Author: @ponchotitlan
#
# Usage:
#   ./create-artifact-tests.sh <service-name>

# This function creates a tar file of the folder specified and saves it in the /tmp/nso location
# Usage tar_folders <container_name(str)> <package_folder_names(array(str))>
tar_folders(){
    local container_name="$1"
    local tests_array="$@"
    local ARTIFACT_NAME="ciscolive_demo_test.tar.gz"
    local ARTIFACT_DIR="/tmp/nso"

    docker exec -i $container_name bash -lc "cd /nso/run/packages/ && tar -czvf $ARTIFACT_DIR/$ARTIFACT_NAME ${tests_array[@]}"
}

YAML_FILE_CONFIG="pipeline/setup/config.yaml"
PACKAGES_DIR="packages"
NEDS_PATH=".netsims | keys"

echo "##### [📦] Zipping the test results into an artifact.... #####"

# Extract the name of the container
NSO_DOCKER_NAME_GEN="pipeline/scripts/get-nso-docker-name.sh"
container_name=$("$NSO_DOCKER_NAME_GEN")

# Extract the netsim folder names from the YAML file
ned_packages=$(yq "$NEDS_PATH" "$YAML_FILE_CONFIG")

# Get all the packages folders and remove the trailing slash from their names
all_packages=($(ls -d "$PACKAGES_DIR"/*/ | xargs -n 1 basename))

service_tests=()
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
        service_tests+=("${package}/tests")
    fi
done

tar_folders $container_name ${service_tests[@]}

echo "[📦] Creation of the artifact ciscolive_demo_test.tar.gz done!"