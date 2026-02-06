#!/bin/bash -x
# Title: Build Image
# Description: This script builds a custom NSO image with the variables provided in the YAML file config.yaml.
# Usage:
#   ./build-image.sh

set -xe
CONFIG_FILE="config.yaml"

# Manual parsing of the YAML file to extract values
nso_image=$(awk -F': ' '/^nso-image:/ {print $2}' "$CONFIG_FILE")

# Docker build. The resulting image will have the name provided in the config.yaml file
# Force linux/amd64 platform for M1 Mac compatibility (NSO native libraries are x86_64 only)
DOCKER_BUILDKIT=1 docker build \
--platform linux/amd64 \
-t $nso_image .