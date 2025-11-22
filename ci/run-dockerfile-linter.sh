#!/usr/bin/env bash
# Exit on error
set -e
set -u
set -o pipefail

# shellcheck source=/dev/null
. ci/functions.sh
# Error handling
trap 'printf "\n\nERROR at $0 line $LINENO. Exiting.\n\n"' ERR

# Script to print hadolint issues for a given Dockerfile or all Dockerfiles in a directory
# Usage: ./run-dockerfile-linter.sh [file_path | directory_path]
# If no argument, checks all Dockerfiles in current directory recursively

target="${1:-.}"

if [[ -f "${target}" ]]; then
    # Single file
    if [[ "${target}" != Dockerfile* ]]; then
        fatal 1 "Error: File '${target}' is not a Dockerfile."
    fi
    files=("${target}")
elif [[ -d "${target}" ]]; then
    # Directory, find all Dockerfiles recursively
    mapfile -t files < <(find "${target}" -type f -name "Dockerfile*" || true)
    if [[ ${#files[@]} -eq 0 ]]; then
        info "No Dockerfiles found in '${target}'."
        exit 0
    fi
else
    fatal 1 "Error: '${target}' is not a valid file or directory."
fi

header "Running hadolint on ${#files[@]} file(s)"

has_issues=false

for file in "${files[@]}"; do
    info "Checking: ${file}"
    temp_file=$(mktemp)
    if command -v hadolint >/dev/null 2>&1; then
        # Use local hadolint
        if hadolint "${file}" > "${temp_file}" 2>&1; then
            pass
            rm "${temp_file}"
        else
            has_issues=true
            cat "${temp_file}" >&2
            rm "${temp_file}"
        fi
    else
        # Fall back to Docker
        # shellcheck disable=SC2312
        if docker run --rm -v "$(pwd):/workdir" -w /workdir hadolint/hadolint:latest hadolint "${file}" > "${temp_file}" 2>&1; then
            pass
            rm "${temp_file}"
        else
            has_issues=true
            cat "${temp_file}" >&2
            rm "${temp_file}"
        fi
    fi
done

if [[ "${has_issues}" == true ]]; then
    fatal 1 "Hadolint issues detected in one or more files."
else
    info "No hadolint issues found in any files."
fi
