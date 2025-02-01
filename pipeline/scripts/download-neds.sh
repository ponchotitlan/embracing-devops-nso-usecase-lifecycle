#!/bin/bash -x
# Title: Download NED files
# Description: This script downloads the artifacts (tar files) specified in the "downloads" section of the config.yaml file and extracts them in the packages/ location of this repository. Afterwards, it deletes the tar files.
# Author: @ponchotitlan
#
# Usage:
#   ./download-neds.sh

YAML_FILE="pipeline/setup/config.yaml"
DOWNLOADS_PATH=".downloads[]"

# Extract the list of downloads
downloads=$(yq "$DOWNLOADS_PATH" "$YAML_FILE")

# Iterate over the list and print each URL
for url in $downloads; do
    # Remove quotes from the retrieved URLs
    url=$(echo "$url" | tr -d '"')

    # Get the download URLs from the config.yaml file and remove quotes
    output_file=$(basename "$url")
    output_file=$(echo "$output_file" | tr -d '"')

    # Download the files
    curl -L -o "$output_file" "$url"

    # Check if the download was successful
    if [ $? -eq 0 ]; then
        echo "[📦] Download successful: $output_file"
        # Extract the file to the packages/ directory of this repository
        tar -xvf $output_file -C "packages/"
        # Removes the tar file from the current directory
        rm -rf $output_file
    else
        echo "[📦] Download failed for $output_file ..."
    fi
done