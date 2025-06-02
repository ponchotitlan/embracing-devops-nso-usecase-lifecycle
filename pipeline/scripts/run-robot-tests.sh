#!/bin/bash -x
# Title: Creation of artifacts with the test results from the service packages
# Description: This script adds to a tar file the files located in the packages/<package>/tests dir of this repository. The netsim folders are ignored. The resulting tar file is stored in the mounted volume /tmp/nso for easier access via the pipeline later on.
# Author: @ponchotitlan
#
# Usage:
#   ./create-artifact-tests.sh

# This function creates a tar file of the folder specified and saves it in the /tmp/nso location
# Usage tar_folders <container_name(str)> <package_folder_names(array(str))>
run_robot_test(){
    local container_name="$1"
    local service_name="$2"

    local TOKEN_SUCCESS="0 failed"
    local output=$(docker exec -i $container_name bash -lc "cd /nso/run/packages/$service_name/tests && robot $service_name.robot")

    if echo "$output" | grep -q "$TOKEN_SUCCESS"; then
        # This test passed!
        echo 1
    else
        # This test didn't pass!
        echo 0
    fi
}

YAML_FILE_CONFIG="pipeline/setup/config.yaml"
PACKAGES_DIR="packages"
NEDS_PATH=".netsims | keys"

# Extract the name of the container
NSO_DOCKER_NAME_GEN="pipeline/scripts/get-nso-docker-name.sh"
container_name=$("$NSO_DOCKER_NAME_GEN")

# Extract the netsim folder names from the YAML file
ned_packages=$(yq "$NEDS_PATH" "$YAML_FILE_CONFIG")

# Get all the packages folders and remove the trailing slash from their names
all_packages=($(ls -d "$PACKAGES_DIR"/*/ | xargs -n 1 basename))

# Iterate over each folder and check if it's in the excluded list
all_tests_passed=1
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
        this_test_pass=$(run_robot_test $container_name $package)

        # If at least one test didn't pass. This job is declared a failure
        if [[ $this_test_pass == 0 ]]; then
            all_tests_passed=0
        fi
    fi
done

if [[ $all_tests_passed == 0 ]]; then
    # The job failed
    echo "failed"
else
    # The job is successful
    echo "pass"
fi