#!/usr/bin/env bash
# Exit on error
set -u
set -o pipefail

# shellcheck source=/dev/null
. ci/functions.sh
# Error handling
trap 'printf "\n\nERROR at $0 line $LINENO. Exiting.\n\n"' ERR

# Function to check if a file is a shell script
is_shell_script() {
    local file="$1"
    # Check if it's a .sh file
    if [[ "${file}" == *.sh ]]; then
        return 0
    fi
    # Check if it has a shebang indicating shell script
    if head -1 "${file}" 2>/dev/null | grep -q '^#!/.*sh'; then
        return 0
    fi
    return 1
}

# Wrapper to avoid set -e issues
check_shell_script() {
    local result
    is_shell_script "$1"
    result=$?
    return "${result}"
}

# Script to print shellcheck issues for a given file or all .sh files in a
# directory
# Usage: ./shellcheck_printer.sh [file_path | directory_path]
# If no argument, checks all .sh files in current directory recursively

target="${1:-.}"

if [[ -f "${target}" ]]; then
    # Single file
    check_shell_script "${target}"
    result=$?
    if [[ ${result} -ne 0 ]]; then
        fatal 1 "Error: File '${target}' is not a shell script."
    fi
    files=("${target}")
elif [[ -d "${target}" ]]; then
    # Directory, find all files recursively and filter shell scripts
    if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
        # Use git ls-files to get non-ignored files
        mapfile -t all_files < <(git ls-files --cached --others --exclude-standard | sed 's|^|./|' | if [[ "${target}" != "." ]]; then grep "^${target}"; else cat; fi || true)
    else
        # Fallback if git not available or not in git repo
        mapfile -t all_files < <(find "${target}" -type f -not -path '*/.git/*' -not -path '*/venv/*' || true)
    fi
    files=()
    for file in "${all_files[@]}"; do
        if check_shell_script "${file}"; then
            files+=("${file}")
        fi
    done
    if [[ ${#files[@]} -eq 0 ]]; then
        info "No shell scripts found in '${target}'."
        exit 0
    fi
else
    fatal 1 "Error: '${target}' is not a valid file or directory."
fi

header "Running shellcheck on ${#files[@]} file(s)"

has_issues=false

for file in "${files[@]}"; do
    if [[ ! -f "${file}" ]]; then
        warn "File '${file}' no longer exists, skipping."
        continue
    fi
    info "Checking: ${file}"
    if command -v shellcheck >/dev/null 2>&1; then
        if shellcheck -o all "${file}" 2>&1; then
            pass
        else
            has_issues=true
        fi
    else
        info "shellcheck not found, using Docker to run shellcheck"
		#shellcheck disable=2312
        if docker run --rm -v "$(pwd):/workdir" -w /workdir koalaman/shellcheck:stable -o all "${file}" 2>&1; then
            pass
        else
            has_issues=true
        fi
    fi
done

if [[ "${has_issues}" == true ]]; then
    fatal 1 "Shellcheck issues detected in one or more files."
else
    info "No shellcheck issues found in any files."
fi
