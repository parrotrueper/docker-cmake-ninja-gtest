#!/usr/bin/env bash
# Exit on error
set -euo pipefail

# shellcheck source=/dev/null
. ci/functions.sh

header "Generating requirements.txt"

# configuration file
cfg_file="build-config.json"
#output file
req_path="$(jq -r '.docker.data_path' "${cfg_file}")"
req_file="${req_path:?}/requirements.txt"

# Generate requirements.txt from build-config.json
{
    # Extract python packages and format as package==version
    jq -r '.python_packages | to_entries[] | "\(.key)==\(.value)"' "${cfg_file}"
} > "${req_file:?}"


