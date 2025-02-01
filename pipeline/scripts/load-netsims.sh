#!/bin/bash -x
# Title: Load Netsims
# Description: This script creates all the netsim devices specified in the config.yaml file. The devices are created in the /netsim directory of the NSO container from the service specified. It is assumed that the container in the service is a NSO container. Once created, the netsim devices are subsequently onboarded on NSO, connected and synced-from. 
# Author: @ponchotitlan
#
# Usage:
#   ./load-netsims.sh <service-name>

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

# This function starts all the netsims available in the /netsim location
# Usage start_netsim <container_name(str)>
start_netsim(){
    local container_name="$1"

    echo "[🛸] Starting the netsim network ..."
    docker exec -i $container_name bash -lc "cd /netsim && ncs-netsim start"
}

# This function generates the netsim_config.xml file with all the configurations of the netsims located in the /netsim dir.
# Subsequently, the file is loaded to the NSO server.
# Usage generate_load_netsim_config <container_name(str)>
generate_load_netsim_config(){
    local container_name="$1"

    echo "[🛸] Loading the netsim devices into the NSO server ..."
    docker exec -i $container_name bash -lc "cd /netsim && ncs-netsim ncs-xml-init > netsim_config.xml"
    docker exec -i $container_name bash -lc "ncs_load -l -m /netsim/netsim_config.xml"
}

# This function performs connect and sync-from operations on all the devices of the NSO node
# Usage connect_sync_netsims <container_name(str)>
connect_sync_netsims(){
    local container_name="$1"

    echo "[🛸] Connecting and syncing the netsims ..."
    docker exec -i $container_name bash -lc "echo 'devices connect' | ncs_cli -Cu admin"
    docker exec -i $container_name bash -lc "echo 'devices sync-from' | ncs_cli -Cu admin"
}


YAML_FILE_CONFIG="pipeline/setup/config.yaml"
YAML_FILE_DOCKER="pipeline/setup/docker-compose.yml"
NEDS_PATH=".netsims"

if [ -z "$1" ]; then
    echo "Usage: $0 <container_name> ..."
    exit 1
fi

echo "##### [🛸] Loading netsims .... #####"

# Extract the name of the container and remove quotes
CONTAINER_NAME_PATH=".services.$1.container_name"
container_name=$(yq "$CONTAINER_NAME_PATH" "$YAML_FILE_DOCKER")
container_name=$(echo "$container_name" | tr -d '"')

# Get the NEDs from the config.yaml file
is_first_ned=1
neds=$(yq "$NEDS_PATH" "$YAML_FILE_CONFIG")
for ned in $neds; do
    # The NEDs are the keys of the netsims structure in the config.yaml file
    if echo "$ned" | grep -q '\:'; then
        ned=$(echo "$ned" | tr -d '"')
        ned=$(echo "$ned" | tr -d ':')

        # Creation of the netsim network in the /netsim location of the container if this is the first NED
        if [ "$is_first_ned" -eq 1 ]; then
            create_netsim_network $container_name $ned
            is_first_ned=0
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

start_netsim $container_name
generate_load_netsim_config $container_name
connect_sync_netsims $container_name

echo "[🛸] Loading done!"