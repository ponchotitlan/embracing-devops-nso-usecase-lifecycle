#!/bin/bash -x
# Title: Compile packages
# Description: This script complies the service packages located in the following
#              directories of the target NSO container:
#              - /opt/ncs/packages
#              - /nso/run/packages
#
# Usage:
#   ./compile-packages.sh

set -xe

# This function issues the make clean all command on the src/directory of the package specified.
compile_package(){
    local nso_container_name="$1"
    local package_dir="$2"
    local package_name="$3"

    echo "[🛠️] Compiling package $package_name ..."
    docker exec -i $nso_container_name bash -lc "source /etc/profile && cd $package_dir/$package_name/src && make clean all"
}

CONFIG_FILE="config.yaml"
REPOSITORY_PACKAGES_DIRS=("/opt/ncs/packages" "/nso/run/packages")
echo "##### [🛠️] Compiling the services in this repository and skipping the NEDs.... #####"

# Get the name of the NSO container from the config.yaml file
nso_container_name=$(awk '/container_name:/ {print $2; exit}' "docker-compose.yml")

# Extract and read items under the "skip-compilation" key
no_compile_items=$(awk '/^skip-compilation:/{flag=1; next} /^$/{flag=0} flag' "$CONFIG_FILE")
no_compile_list=$(echo "$no_compile_items" | awk '{gsub(/^-|-$| - /, ""); gsub(/ /, "\n")} 1')

# Loop through the two different package locations mounted on this NSO node
for dir_packages in "${REPOSITORY_PACKAGES_DIRS[@]}"
do
    all_files=()
    while IFS= read -r file; do
        all_files+=("$file")
    done < <(docker exec "$nso_container_name" bash -c "ls -1 \"$dir_packages\"")

    for package in "${all_files[@]}"; do
        if ! echo "$no_compile_list" | grep -q "$package"; then
            echo "[📦] Compiling package ($package) from directory ($dir_packages) ..."
            compile_package "$nso_container_name" "$dir_packages" "$package"
        fi
    done
done

echo "[🛠️] Compiling done!"