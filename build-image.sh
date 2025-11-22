#!/usr/bin/env bash
# Exit on error
set -e
set -u
set -o pipefail

# shellcheck source=/dev/null
. ci/functions.sh
# Error handling
trap 'printf "\n\nERROR at $0 line $LINENO. Exiting.\n\n"' ERR

config_file="build-config.json"

info "Setup the environment"
run ./scripts/setup.sh

info "Loading build configuration from ${config_file}"

base_image=$(jq -r '.docker.base_image' "${config_file}")
build_name=$(jq -r '.docker.build_name' "${config_file}")
data_path=$(jq -r '.docker.data_path' "${config_file}")
doker_user=$(jq -r '.docker.user.name' "${config_file}")
doker_userid=$(jq -r '.docker.user.uid' "${config_file}")
doker_groupid=$(jq -r '.docker.user.gid' "${config_file}")
gtest_hash=$(jq -r '.gtest.hash' "${config_file}")
gtest_parallel_hash=$(jq -r '.gtest_parallel.hash' "${config_file}")
gcc_version=$(jq -r '.gcc' "${config_file}")
python_version=$(jq -r '.python' "${config_file}")

info "Building Docker image with tag: ${build_name}"
info "Using base image: ${base_image}"
info "Using GCC version: ${gcc_version}"
info "Using Python version: ${python_version}"

docker_file="src/Dockerfile"
build_context="."

run docker build \
  --file "${docker_file}" \
  --tag "${build_name}" \
  --build-arg BASE_IMAGE="${base_image}" \
  --build-arg DKR_PYTHON_VERSION="${python_version}" \
  --build-arg DKR_GTEST_HASH="${gtest_hash}" \
  --build-arg DKR_GTEST_PARALLEL_HASH="${gtest_parallel_hash}" \
  --build-arg DKR_GCC_VER="${gcc_version}" \
  --build-arg DKR_DATA_PATH="${data_path}" \
  --build-arg DKR_USER_UID="${doker_userid}" \
  --build-arg DKR_USER_GID="${doker_groupid}" \
  --build-arg DKR_USER_NAME="${doker_user}" \
  "${build_context}"

info "Docker image ${build_name} built successfully."

