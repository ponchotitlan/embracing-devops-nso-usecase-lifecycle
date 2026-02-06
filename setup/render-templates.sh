#!/bin/bash -x
# Title: Render templates
# Description: This script renders the Jinja templates docker-compose.j2, Dockerfile.j2 
#              and Makefile.j2 with the variables provided in the YAML file config.yaml.
#              If the NSO image provided in the config.yaml file doesn't have a registry
#              URL (it is a bare image locally installed), this script adds the prefix
#              localhost:5000/ to it (default for Docker registry) in all the templates.
# Usage:
#   ./render-templates.sh

set -xe

CONFIG_FILE="config.yaml"
TEMPLATE_FILE_COMPOSE="docker-compose.j2"
TEMPLATE_FILE_DOCKERFILE="Dockerfile.j2"
OUTPUT_COMPOSE="docker-compose.yml"
OUTPUT_DOCKERFILE="Dockerfile"

LOCAL_REGISTRY_HOST="localhost:5000"

# Manual parsing of the YAML file to extract values
nso_base=$(awk -F': ' '/^nso-base:/ {print $2}' "$CONFIG_FILE")
nso_name=$(awk -F': ' '/^nso-name:/ {print $2}' "$CONFIG_FILE")
nso_image=$(awk -F': ' '/^nso-image:/ {print $2}' "$CONFIG_FILE")

# Append branch and build information to container name if environment variables are set
BRANCH_NAME="${GITHUB_REF_NAME:-${GIT_BRANCH:-local}}"
BUILD_NUMBER="${GITHUB_RUN_NUMBER:-${BUILD_NUMBER:-dev}}"

# Sanitize branch name (replace / with -, remove special chars)
BRANCH_NAME_CLEAN=$(echo "$BRANCH_NAME" | sed 's/\//-/g' | sed 's/[^a-zA-Z0-9._-]//g')

# Append suffix to container name
nso_name="${nso_name}-${BRANCH_NAME_CLEAN}-${BUILD_NUMBER}"

echo "-- ✨ NSO container name: ${nso_name} --"

# If the NSO base image name doesn't have a URL (is a non-registered image),
# it needs to be registered on a local registry so it can be used in a Dockerfile
# later on. Therefore, the prefix localhost:5000/ is added
if [[ "$nso_base" == *:* ]]; then
    SOURCE_IMAGE_TAG="${nso_base##*:}"
    REPO_PATH_FOR_VALIDATION="${nso_base%:*}" # Part before the last colon
else
    SOURCE_IMAGE_TAG="latest" # Default tag if not specified
    REPO_PATH_FOR_VALIDATION="$nso_base" # Whole string for validation
fi

# The base name for tagging will be the repository path without the tag
SOURCE_IMAGE_BASE_NAME="${REPO_PATH_FOR_VALIDATION}"

TARGET_IMAGE_NAME="${LOCAL_REGISTRY_HOST}/${SOURCE_IMAGE_BASE_NAME}"
FULL_TARGET_IMAGE="${TARGET_IMAGE_NAME}:${SOURCE_IMAGE_TAG}"

# Check if the source image name already has a registry URL
FIRST_PART_OF_REPO=$(echo "${REPO_PATH_FOR_VALIDATION}" | cut -d'/' -f1)

# Check if the first part contains a dot or a colon, indicating a registry hostname
if [[ "${FIRST_PART_OF_REPO}" == *.* || "${FIRST_PART_OF_REPO}" == *:* ]]; then
    echo "-- ✨ The provided image name '${nso_base}' already appears to contain a registry URL ('${FIRST_PART_OF_REPO}') --"
else
    nso_base=$FULL_TARGET_IMAGE
    echo "-- ✨ The image will be retagged as ${nso_base} in all the templates! --"
fi

# Replace placeholders in the Jinja2 template with values from the YAML file
sed \
  -e "s/{{ nso-name }}/$nso_name/g" \
  -e "s/{{ nso-image }}/$nso_image/g" \
  "$TEMPLATE_FILE_COMPOSE" > "$OUTPUT_COMPOSE"

sed \
  -e "s|{{ nso-base }}|$nso_base|g" \
  "$TEMPLATE_FILE_DOCKERFILE" > "$OUTPUT_DOCKERFILE"
