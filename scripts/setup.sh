#!/usr/bin/env bash
# Exit on error
set -euo pipefail

# shellcheck source=/dev/null
. ci/functions.sh
# Error handling
trap 'printf "\n\nERROR at $0 line $LINENO. Exiting.\n\n"' ERR

header "Checking dependencies"
# Check that jq is installed
if ! command -v jq >/dev/null 2>&1; then
    err "This script requires \"jq\". Please instal the package..."
    warn "sudo apt install jq"
    exit 1
fi

run ./scripts/gen-requirements.sh
header "Setup completed."
