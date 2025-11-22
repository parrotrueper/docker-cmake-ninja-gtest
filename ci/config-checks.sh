#!/usr/bin/env bash
# Exit on error
set -e
set -u
set -o pipefail

# shellcheck source=/dev/null
. ci/functions.sh
# Error handling
trap 'printf "\n\nERROR at $0 line $LINENO. Exiting.\n\n"' ERR

header "Tests that run inside the Docker container"

# configuration file
cfg_file="build-config.json"

header "Check base image matches build configuration"
expected_base_image="$(jq -r '.docker.pretty_name' "${cfg_file}")"

info "Expected base image: ${expected_base_image}"

actual_pretty_name=$(grep 'PRETTY_NAME' /etc/os-release | cut -d= -f2- | tr -d '"')
info "Actual PRETTY_NAME: ${actual_pretty_name}"

echo "${actual_pretty_name}" | grep -iq "${expected_base_image}" || {
	err "Base image mismatch. Expected (substring): ${expected_base_image}"
	exit 1
}

header "Check required tools and libraries are installed"

# Check gcc version 13
if command -v gcc >/dev/null 2>&1; then
    gcc_version=$(gcc -dumpversion)
    if [[ ${gcc_version} == 13* ]]; then
        info "gcc version 13 is installed: ${gcc_version}"
    else
        err "gcc version 13 is required but found version: ${gcc_version}"
        exit 1
    fi
else
    err "gcc is not installed"
    exit 1
fi

# Check cmake
if command -v cmake >/dev/null 2>&1; then
    cmake_version=$(cmake --version | head -n1)
    info "${cmake_version} found"
else
    err "cmake is not installed"
    exit 1
fi

# Check ninja with minimum version 1.10
if command -v ninja >/dev/null 2>&1; then
    ninja_version=$(ninja --version)
    # Parse major.minor version numbers
    ninja_major=$(echo "${ninja_version}" | cut -d. -f1)
    ninja_minor=$(echo "${ninja_version}" | cut -d. -f2)

    if [[ "${ninja_major}" -gt 1 ]] || { [[ "${ninja_major}" -eq 1 ]] && [[ "${ninja_minor}" -ge 10 ]]; }; then
        info "ninja version ${ninja_version} found"
    else
        err "ninja version 1.10 or higher is required but found version: ${ninja_version}"
        exit 1
    fi
else
    err "ninja is not installed"
    exit 1
fi

# Check gtest installation (headers, libraries, or sources in /opt)
if [[ -d "/usr/include/gtest" ]]; then
    info "gtest headers found in /usr/include/gtest"
elif ldconfig -p 2>/dev/null | grep -q libgtest; then
    info "gtest library found via ldconfig"
elif [[ -d "/opt/gtest" ]] || compgen -G "/opt/*gtest*" > /dev/null; then
    info "gtest source files found in /opt"
else
    err "gtest is not installed (headers, library, or source files not found)"
    exit 1
fi

header "All required tools and libraries are installed"


