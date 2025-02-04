#!/bin/bash -x
# Title: Increment the git tag
# Description: This script increments the git tag provided. It is assumed that the format is similar to vX.Y.Z.
# Author: @ponchotitlan
#
# Usage:
#   ./increment-git-tag-version.sh <git_tag>

version=$1
# Extract the prefix and numeric part of the version
prefix=${version%%[0-9]*}
version_number=${version#"$prefix"}
# Increment the patch version
IFS='.' read -r -a parts <<< "$version_number"
((parts[2]++))
new_version="${prefix}${parts[0]}.${parts[1]}.${parts[2]}"
echo "New version: $new_version"
# Set the output for GitHub Actions
echo "new_version=$new_version" >> $GITHUB_ENV