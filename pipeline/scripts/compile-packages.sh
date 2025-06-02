#!/bin/bash -x
# Title: Compile packages
# Description: This script complies the service packages located in the packages/ directory of this repository. The packages which correspond to the NEDs enlisted as keys in the netsims path of the config.yaml file are skipped. It is required to provide a service name associated to a NSO container as given in the docker-compose file.
# Author: @ponchotitlan
#
# Usage:
#   ./compile-packages.sh

# This function issues the make clean all command on the src/directory of the package specified.
# It is assumed that the package already exists on the /packages dir of this repository and that this dir is a mounted volume in the NSO container provided.
# Usage compile_package <container_name(str)> <package_folder_name(str)>
compile_package(){
    local container_name="$1"
    local package_name="$2"

    echo "[🛠️] Compiling package $package_name ..."
    docker exec -i $container_name bash -lc "cd /nso/run/packages/$package_name/src && make clean all"
}

YAML_FILE_CONFIG="pipeline/setup/config.yaml"
PACKAGES_DIR="packages"
NEDS_PATH=".netsims | keys"

echo "##### [🛠️] Compiling the services in this repository and skipping the NEDs.... #####"

# Extract the name of the container
NSO_DOCKER_NAME_GEN="pipeline/scripts/get-nso-docker-name.sh"
container_name=$("$NSO_DOCKER_NAME_GEN")

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
        compile_package $container_name $package
    fi
done

echo "[🛠️] Compiling done!"