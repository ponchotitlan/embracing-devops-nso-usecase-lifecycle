#!/bin/bash -x
# Title: Get latest Git tag
# Description: This script gets the latest Git tag from the most recent release.
# Author: @ponchotitlan
#
# Usage:
#   ./get-latest-git-tag.sh

latest_tag=$(git describe --tags $(git rev-list --tags --max-count=1))
echo "Latest tag: $latest_tag"
# Set the output for GitHub Actions
echo "::set-output name=tag::$latest_tag"