#!/bin/bash -x
# Title: Clean resources
# Description: This script brings down the associated resources to all the services in the docker-compose file
# Author: @ponchotitlan
#
# Usage:
#   ./clean-resouces.sh

# This function issues the ncs-netsim commands in the target container for creating a netsim network with a dummy device.
# It is neccessary to do this for adding actual netsim devices later on.
# The directory for netsims will be /netsim
# Usage create_netsim_network <container_name(str)> <ned_name(str)>
create_netsim_network(){
    local container_name="$1"
    local ned="$2"

    echo "[🛸] Creating the netsim network ..."
    docker exec -i $container_name bash -lc "mkdir /netsim"
    docker exec -i $container_name bash -lc "ncs-netsim --dir /netsim create-network /nso/run/packages/$ned 1 dummy"
}

# This function issues the ncs-netsim commands in the target container for creating the specified netsim devices
# Usage create_netsim <ned_name(str)> <netsim_name(str)> <container_name(str)>
add_netsim(){
    local ned="$1"
    local netsim="$2"
    local container_name="$3"

    echo "[🛸] Creating netsim device ($netsim) with NED ($ned) ..."
    docker exec -i $container_name bash -lc "cd /netsim && ncs-netsim add-device /nso/run/packages/$ned/ $netsim"
}

YAML_FILE_CONFIG="pipeline/setup/config.yaml"
YAML_FILE_DOCKER="pipeline/setup/docker-compose.yml"
NEDS_PATH=".netsims"

echo "##### [🛸] Loading netsims .... #####"

# Extract the name of the container and remove quotes
CONTAINER_NAME_PATH=".services.$1.container_name"
container_name=$(yq "$CONTAINER_NAME_PATH" "$YAML_FILE_DOCKER")
container_name=$(echo "$container_name" | tr -d '"')

# Get the NEDs from the config.yaml file
is_first_ned=true
neds=$(yq "$NEDS_PATH" "$YAML_FILE_CONFIG")
for ned in $neds; do
    # The NEDs are the keys of the netsims structure in the config.yaml file
    if echo "$ned" | grep -q '\:'; then
        ned=$(echo "$ned" | tr -d '"')
        ned=$(echo "$ned" | tr -d ':')

        # Creation of the netsim network in the /netsim location of the container if this is the first NED
        if $is_first_ned; then
            create_netsim_network $container_name $ned
            $is_first_ned=false
        fi
        
        # Get the netsims of this NED
        netsims_path=".netsims.\"$ned\""
        netsims=$(yq "$netsims_path" "$YAML_FILE_CONFIG")
        for netsim in $netsims; do
            if [[ "$netsim" != *[\[\]]* ]]; then
                netsim=$(echo "$netsim" | tr -d '"')
                netsim=$(echo "$netsim" | tr -d ',')
                add_netsim $ned $netsim $container_name
            fi
        done
    fi
done

echo "[🛸] Loading done!"