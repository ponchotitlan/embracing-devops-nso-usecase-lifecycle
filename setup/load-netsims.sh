#!/bin/bash -x
# Title: Load Netsims
# Description: This script creates all the netsim devices specified in the config.yaml file. 
#              The devices are created in the /netsim directory of the NSO container from
#              the service specified. Once created, the netsim devices are subsequently onboarded
#              on NSO, connected and synced-from. 
#
# Usage:
#   ./load-netsims.sh

local_flag=$1

# This function issues the ncs-netsim commands in the target container for creating a netsim network with a dummy device.
# It is neccessary to do this for adding actual netsim devices later on.
# The directory for netsims will be /netsim
# Usage create_netsim_network <container_name(str)> <ned_name(str)>
create_netsim_network(){
    local container_name="$1"
    local ned="$2"

    echo "[🛸] Creating the netsim network ..."
    docker exec $container_name bash -lc "mkdir /netsim"
    docker exec $container_name bash -lc "ncs-netsim --dir /netsim create-network /opt/ncs/packages/$ned 1 dummy"
}

# This function issues the ncs-netsim commands in the target container for creating the specified netsim devices
# Usage create_netsim <ned_name(str)> <netsim_name(str)> <container_name(str)>
add_netsim(){
    local ned="$1"
    local netsim="$2"
    local container_name="$3"

    echo "[🛸] Creating netsim device ($netsim) with NED ($ned) ..."
    docker exec $container_name bash -lc "cd /netsim && ncs-netsim add-device /opt/ncs/packages/$ned/ $netsim"
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

CONFIG_FILE="config.yaml"

# Get the name of the NSO container from the config.yaml file
nso_container_name=$(awk '/container_name:/ {print $2; exit}' "docker-compose.yml")

# Extract neds and netsims from the config file
topology=$(sed -n '/^netsims:/,/^[^[:space:]]/p' "$CONFIG_FILE" | tail -n +2)
current_ned=""
is_first_ned=1

# Loop through the extracted topology
while IFS= read -r line; do
    # Match a NED
    if [[ "$line" =~ ^[[:space:]]+([a-zA-Z0-9._/-]+):$ ]]; then
        current_ned="${BASH_REMATCH[1]}"
        echo "[📦] NED: $current_ned"
    fi

    # Creation of the netsim network in the /netsim location of the container if this is the first NED
    if [ "$is_first_ned" -eq 1 ]; then
        create_netsim_network $nso_container_name $current_ned
        is_first_ned=0
    fi

    # Match a netsim
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*(.+) ]]; then
        netsim="${BASH_REMATCH[1]}"
        add_netsim $current_ned $netsim $nso_container_name
        echo "[🛸] Netsim: $netsim"
    fi
done <<< "$topology"

start_netsim $nso_container_name
generate_load_netsim_config $nso_container_name
connect_sync_netsims $nso_container_name

echo "[🛸] Loading done!"