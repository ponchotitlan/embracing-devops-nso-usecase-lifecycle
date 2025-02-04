#!/bin/bash -x
# Title: Get latest Git tag
# Description: This script gets the latest Git tag from the most recent release.
# Author: @ponchotitlan
#
# Usage:
#   ./get-latest-git-tag.sh
git fetch --tags
latest_rev=$(git rev-list --tags --max-count=1)
latest_tag_standalone=$(git describe --tags)
latest_tag=$(git describe --tags $(git rev-list --tags --max-count=1))
if [ -z "$latest_tag" ]; then
  latest_tag="0.0.1"
fi
echo "Latest tag: $latest_tag"
# Set the output for GitHub Actions
echo "tag=$latest_tag" >> $GITHUB_ENV