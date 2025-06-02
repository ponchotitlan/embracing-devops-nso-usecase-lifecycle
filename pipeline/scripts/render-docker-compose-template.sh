#!/bin/bash -x
# Title: Render Docker Compose template
# Description: This script renders the Jinja template pipeline/setup/docker-compose.yml with the variables provided in the YAML file pipeline/setup/config/yaml.
# It is assumed that the structure of both files matches with the following (as mapping is hardcoded in this script's logic):

# config.yaml -

# nso:
#   container_prefix: nso-ci-
#   image: cisco-nso-prod:6.4
#   username: admin
#   password: admin
#   http_port: 8080
#   https_port: 8888
#   cli_port: 1024

# docker-compose.j2 - 

# services:
#   {{ nso.container_name }}:
#     container_name: {{ nso.container_name }}
#     image: {{ nso.image }}
#     ports:
#       - "{{ nso.http_port }}:8080"
#       - "{{ nso.https_port }}:8888"
#       - "{{ nso.cli_port }}:1024"
#     volumes:
#       - type: bind
#         source: ../../packages/
#         target: /nso/run/packages
#       - type: bind
#         source: ../preconfigs/
#         target: /tmp/nso
#       - type: bind
#         source: ../conf/
#         target: /nso/etc
#     environment:
#       - EXTRA_ARGS=--with-package-reload
#       - ADMIN_USERNAME={{ nso.username }}
#       - ADMIN_PASSWORD={{ nso.password }}
#     healthcheck:
#       test: ncs_cmd -c "wait-start 2"
#       interval: 5s
#       retries: 5
#       start_period: 10s
#       timeout: 10s

# Author: @ponchotitlan
#
# Usage:
#   ./get-nso-docker-name.sh

YAML_FILE="pipeline/setup/config.yaml"
TEMPLATE_FILE="pipeline/setup/docker-compose.j2"
NSO_DOCKER_NAME_GEN="pipeline/scripts/get-nso-docker-name.sh"

# Manual parsing of the YAML file to extract values
nso_image=$(grep "image:" "$YAML_FILE" | awk '{print $2}')
nso_username=$(grep "username:" "$YAML_FILE" | awk '{print $2}')
nso_password=$(grep "password:" "$YAML_FILE" | awk '{print $2}')
nso_http_port=$(grep "http_port:" "$YAML_FILE" | awk '{print $2}')
nso_https_port=$(grep "https_port:" "$YAML_FILE" | awk '{print $2}')
nso_cli_port=$(grep "cli_port:" "$YAML_FILE" | awk '{print $2}')

# Define the container name (derived from container_prefix)
nso_container_name=$("$NSO_DOCKER_NAME_GEN")

# Get the output docker-compose file name
output_docker_compose="pipeline/setup/docker-compose-${nso_container_name}.yml"

# Replace placeholders in the Jinja2 template with values from the YAML file
sed \
  -e "s/{{ nso.container_name }}/$nso_container_name/g" \
  -e "s/{{ nso.image }}/$nso_image/g" \
  -e "s/{{ nso.username }}/$nso_username/g" \
  -e "s/{{ nso.password }}/$nso_password/g" \
  -e "s/{{ nso.http_port }}/$nso_http_port/g" \
  -e "s/{{ nso.https_port }}/$nso_https_port/g" \
  -e "s/{{ nso.cli_port }}/$nso_cli_port/g" \
  "$TEMPLATE_FILE" > "$output_docker_compose"

# Print the output file location
echo "Rendered docker-compose file saved to: $output_docker_compose"