#!/bin/bash -x
# Title: Installing of libraries for testing
# Description: This script performs the pip installation of the requirements.txt file located in the pipeline/preconfigs dir of this repository. It is assumed that this file is a definition of python libraries for running the tests batteries of this repository, and that the dir is mounted as a volume in the NSO container associated to the specified service.
# Author: @ponchotitlan
#
# Usage:
#   ./install-testing-libraries.sh

echo "##### [🏃🏻‍♀️] Installing the libraries required for testing .... #####"

# Extract the name of the container from docker-compose.yml
container_name=$(awk '/container_name:/ {print $2; exit}' "docker-compose.yml")

docker exec -i $container_name bash -lc "cd /tmp/nso/ && pip install -r requirements.txt"

echo "[🏃🏻‍♀️] Installing done!"