#!/bin/bash -x
# Title: Creation of artifacts with the test results from the service packages
# Description: This script adds to a tar file the files located in the packages/<package>/tests dir of this repository. The netsim folders are ignored. The resulting tar file is stored in the mounted volume /tmp/nso for easier access via the pipeline later on.
# Author: @ponchotitlan
#
# Usage:
#   ./create-artifact-tests.sh

# This function runs robot tests and returns 1 for success, 0 for failure based on exit code
# Usage run_robot_test <container_name(str)> <service_name(str)>
run_robot_test(){
    local container_name="$1"
    local service_name="$2"

    echo "🧪 Running tests for $service_name..." >&2
    
    # Run robot test and capture exit code (redirect output to stderr so it's not captured)
    if docker exec -i $container_name bash -lc "cd /nso/run/packages/$service_name/tests && robot $service_name.robot" >&2; then
        # Robot test passed (exit code 0)
        echo "✅ Tests passed for $service_name" >&2
        echo 1
    else
        # Robot test failed (non-zero exit code)
        echo "❌ Tests failed for $service_name" >&2
        echo 0
    fi
}

YAML_FILE_CONFIG="config.yaml"
PACKAGES_DIR="packages"
NEDS_PATH=".netsims | keys"

# Extract the name of the container from docker-compose.yml
container_name=$(awk '/container_name:/ {print $2; exit}' "docker-compose.yml")

# Extract the netsim folder names from the YAML file
ned_packages=$(yq "$NEDS_PATH" "$YAML_FILE_CONFIG")

# Get all the packages folders and remove the trailing slash from their names
all_packages=($(ls -d "$PACKAGES_DIR"/*/ | xargs -n 1 basename))

# Iterate over each folder and check if it's in the excluded list
all_tests_passed=1
for package in "${all_packages[@]}"; do

    is_ned=0
    for ned in $ned_packages; do
        ned=$(echo "$ned" | tr -d '"')
        ned=$(echo "$ned" | tr -d ',')
        if [[ $package == $ned ]]; then
            is_ned=1
        fi
    done

    if [[ $is_ned == 0 ]]; then
        this_test_pass=$(run_robot_test $container_name $package)

        # If at least one test didn't pass. This job is declared a failure
        if [[ $this_test_pass == 0 ]]; then
            all_tests_passed=0
        fi
        
        # Copy output.xml from container to host for AI analysis
        echo "📥 Copying test results for $package..."
        docker cp "$container_name:/nso/run/packages/$package/tests/output.xml" "$PACKAGES_DIR/$package/tests/output.xml" 2>/dev/null || echo "⚠️  No output.xml found for $package"
    fi
done

if [[ $all_tests_passed == 0 ]]; then
    # The job failed
    echo "❌ Test suite failed - at least one test did not pass"
    exit 1
else
    # The job is successful
    echo "✅ All tests passed successfully"
    exit 0
fi