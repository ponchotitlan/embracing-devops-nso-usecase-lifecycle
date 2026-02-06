#!/bin/bash -x
# Title: Mount registry server
# Description: This script checks the NSO base image provided in the config.yaml file.
#              If it doesn't have a registry URL (it is a bare image locally installed),
#              it creates a new registry container to mount it, and adds the prefix
#              localhost:5000/ to it (default for Docker registry). But if the image is
#              already part of a local/public repository, this script does nothing!
# Usage:
#   ./mount-registry-server.sh

CONFIG_FILE="config.yaml"
LOCAL_REGISTRY_HOST="localhost:5000"

nso_base=$(awk -F': ' '/^nso-base:/ {print $2}' "$CONFIG_FILE")

# Extract tag (part after the last colon, if any)
if [[ "$nso_base" == *:* ]]; then
    SOURCE_IMAGE_TAG="${nso_base##*:}"
    REPO_PATH_FOR_VALIDATION="${nso_base%:*}" # Part before the last colon
else
    SOURCE_IMAGE_TAG="latest" # Default tag if not specified
    REPO_PATH_FOR_VALIDATION="$nso_base" # Whole string for validation
fi

# The base name for tagging will be the repository path without the tag
SOURCE_IMAGE_BASE_NAME="${REPO_PATH_FOR_VALIDATION}"

# Derived variables
TARGET_IMAGE_NAME="${LOCAL_REGISTRY_HOST}/${SOURCE_IMAGE_BASE_NAME}"
FULL_TARGET_IMAGE="${TARGET_IMAGE_NAME}:${SOURCE_IMAGE_TAG}"

# Check if the source image name already has a registry URL
# Get the first component of the repository path
FIRST_PART_OF_REPO=$(echo "${REPO_PATH_FOR_VALIDATION}" | cut -d'/' -f1)

# Check if the first part contains a dot or a colon, indicating a registry hostname
if [[ "${FIRST_PART_OF_REPO}" == *.* || "${FIRST_PART_OF_REPO}" == *:* ]]; then
    echo "--- 📤 The provided image name '${nso_base}' already appears to contain a registry URL ('${FIRST_PART_OF_REPO}'). Nothing to do! ---"
    exit 1
fi

# In case the image does not belong to a registry already ...
# Start the local Docker registry if it's not already running
if ! docker ps --format '{{.Names}}' | grep -q "local-registry"; then
    echo "--- 📤 Starting local Docker registry on ${LOCAL_REGISTRY_HOST}... ---"
    docker run -d -p 5000:5000 --restart=always --name local-registry registry:2
else
    echo "--- 📤 Local Docker registry '${LOCAL_REGISTRY_HOST}' is already running ---"
fi

# Give the registry a moment to fully initialize
sleep 2

# Tag your existing local image for the local registry
echo "--- 📤 Tagging '${nso_base}' as '${FULL_TARGET_IMAGE}'... ---"
if docker images -q "${nso_base}" > /dev/null; then
    docker tag "${nso_base}" "${FULL_TARGET_IMAGE}"
else
    echo "--- ⚠️ Error: Source image '${nso_base}' not found locally. Please ensure it exists ---"
    exit 1
fi

# Push the image to your local registry
echo "--- 📤 Pushing '${FULL_TARGET_IMAGE}' to local registry... ---"
docker push "${FULL_TARGET_IMAGE}"
if [ $? -eq 0 ]; then
    echo "--- 📤 Image pushed to local registry successfully. ---"
else
    echo "--- ⚠️ Error pushing image to local registry. Check Docker daemon and registry logs. ---"
    exit 1
fi
