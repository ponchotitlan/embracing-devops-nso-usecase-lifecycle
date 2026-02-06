#!/bin/bash -x
# Title: Download artifact files
# Description: This script downloads the artifacts (tar files) specified in the "downloads"
#              section of the config.yaml file and extracts them in the packages/ location
#              of this repository. Afterwards, it deletes the tar files.
#
# Usage:
#   ./download-artifacts.sh

set -xe

YAML_FILE="/tmp/config.yaml"
TMP_NED_DIR="/opt/ncs/packages"
TMP_NED_DIR_RAW="$TMP_NED_DIR/raw"

# Create temporary folder for NED extraction
mkdir $TMP_NED_DIR_RAW

# Extract and read items under the "downloads" key. These are the signed files of the NEDs from the internal tail-f repository
neds_items=$(awk '/^downloads:/{flag=1; next} /^$/{flag=0} flag' "$YAML_FILE")

# Iterate through the NEDs
while read -r item; do

  # Remove leading/trailing spaces and print the item
  item=$(echo "$item" | sed 's/^[ \t-]*//')

  # Skip empty lines
  if [[ -z "$item" ]]; then
    continue
  fi

  # Extract the filename from the URL
  filename=$(basename "$item")

  # Use cURL to download the file
  echo "[📁] Downloading file $filename"

  # Download file based on type
  if [[ "$item" == *.signed.bin ]]; then
    curl -k --output-dir "$TMP_NED_DIR_RAW" -O "$item"
  else
    curl -k -L --output-dir "$TMP_NED_DIR_RAW" -O "$item"
  fi

  # Check if the download was successful
  if [[ $? -eq 0 ]]; then

    # The resource-manager service has a very peculiar packaging that needs
    # to be handled in a specific manner.
    # (Updated for version v6.5)
    if [[ "$filename" == *"resource-manager-project"* ]]; then
      # Extract the RM package from the signed file
      echo "[📦] Extracting resource-manager from file $filename ..."
      cd $TMP_NED_DIR_RAW && tar -xvf $filename
      folder_final_tar=$(echo "$filename" | awk '{sub(/\.tar\.gz$/, ""); print}')
      binary_final_tar=$(find "$TMP_NED_DIR_RAW/$folder_final_tar/packages" -maxdepth 1 -type f | head -n 1)
      cd $TMP_NED_DIR_RAW/$folder_final_tar/packages && tar -xvf $binary_final_tar
      cp -r $TMP_NED_DIR_RAW/$folder_final_tar/packages/resource-manager $TMP_NED_DIR
      cd /tmp

    else
      # Any other given artifact, nomeadly a NED
      # If the downloaded file is a signed bin, it is extracted differently
      if [[ "$item" == *.signed.bin ]]; then

        # Extract the NED from the signed file
        echo "[📦] Extracting the NED/RM from file $filename ..."
        chmod +x "$TMP_NED_DIR_RAW/$filename"
        cd $TMP_NED_DIR_RAW && ./"$filename" --skip-verification

        # Extract the file to the packages/ directory of this repository
        tar_ned_file=$(echo "$filename" | awk '{sub(/\.signed\.bin$/, ".tar.gz"); print}')
        echo "[📦] Unpacking the NED from file $tar_ned_file ..."
        tar -xvf $tar_ned_file -C "../"
        cd ../../
      
      # Otherwise, it is just extracted
      else
        echo "[📦] Unpacking $filename ..."
        cd $TMP_NED_DIR_RAW && tar -xvf $filename -C "../"
        cd ../../
      fi
    fi

  else
    echo "[📦🔥] Failed to download: $item"
  fi

done <<< "$neds_items"
rm -rf $TMP_NED_DIR_RAW