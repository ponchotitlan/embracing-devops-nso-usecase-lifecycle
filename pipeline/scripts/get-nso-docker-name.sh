#!/bin/bash -x
# Title: Get NSO Docker Name
# Description: This script returns the name of the NSO Docker container. This name has the following format:
# <nso.container_prefix from pipeline/setup/docker-compose.yml><Git branch>-<Git build number>.
# It is expected that the path nso.container_prefix exists in pipeline/setup/docker-compose.yml.
# Author: @ponchotitlan
#
# Usage:
#   ./get-nso-docker-name.sh

get_branch_name() {
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: Not inside a Git repository."
    exit 1
  fi

  branch_name=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD)
  echo "$branch_name"
}

get_build_number() {
  build_number=$(git rev-list --count HEAD 2>/dev/null)
  if [ -z "$build_number" ]; then
    build_number=1
  fi

  echo "$build_number"
}

get_container_prefix() {
    CONFIG_YAML="pipeline/setup/config.yaml"
    container_prefix=$(grep -A 5 '^nso:' "$CONFIG_YAML" | grep 'container_prefix:' | sed 's/.*container_prefix: //')

    echo "$container_prefix"
}

main() {
  branch_name=$(get_branch_name)
  build_number=$(get_build_number)
  container_prefix=$(get_container_prefix)

  result="${container_prefix}${branch_name}-${build_number}"
  echo "$result"
}

main