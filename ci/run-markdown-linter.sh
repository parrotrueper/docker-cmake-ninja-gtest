#!/usr/bin/env bash
# Exit on error
set -e
set -u
set -o pipefail

# shellcheck source=/dev/null
. ci/functions.sh
# Error handling
trap 'printf "\n\nERROR at $0 line $LINENO. Exiting.\n\n"' ERR

# Script to print markdownlint issues for a given file or all .md files in a directory
# Usage: ./run-markdown-linter.sh [file_path | directory_path]
# If no argument, checks all .md files in current directory recursively

target="${1:-.}"

if [[ -f "${target}" ]]; then
    # Single file
    if [[ "${target}" != *.md ]]; then
        fatal 1 "Error: File '${target}' is not a .md file."
    fi
    files=("${target}")
elif [[ -d "${target}" ]]; then
    # Directory, find all .md files recursively
    mapfile -t files < <(find "${target}" -type f -name "*.md" || true)
    if [[ ${#files[@]} -eq 0 ]]; then
        info "No .md files found in '${target}'."
        exit 0
    fi
else
    fatal 1 "Error: '${target}' is not a valid file or directory."
fi

header "Running markdownlint on ${#files[@]} file(s)"

has_issues=false

for file in "${files[@]}"; do
    info "Checking: ${file}"
	if [[ "${file}" = "./CHANGELOG.md" ]]; then
		info "Skipping ${file}"
	else
		temp_file=$(mktemp)
		if command -v markdownlint-cli2 >/dev/null 2>&1; then
			# Use local markdownlint-cli2
			if markdownlint-cli2 "${file}" > "${temp_file}" 2>&1; then
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
			if docker run --rm -v "$(pwd):/workdir" -w /workdir davidanson/markdownlint-cli2:v0.13.0 "${file}" > "${temp_file}" 2>&1; then
				pass
				rm "${temp_file}"
			else
				has_issues=true
				cat "${temp_file}" >&2
				rm "${temp_file}"
			fi
		fi
	fi
done

if [[ "${has_issues}" == true ]]; then
    fatal 1 "Markdownlint issues detected in one or more files."
else
    info "No markdownlint issues found in any files."
fi
