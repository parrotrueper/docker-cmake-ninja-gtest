# Docker CMake Ninja GTest Development Environment

This project provides a Docker-based development environment configured for C++
projects using CMake, Ninja build system, and Google Test framework.

## Project Overview

- A Docker container with Ubuntu 24.04 as the base image is configured with:
  - gcc version 13
  - Python 3.13
  - CMake 4.1.0
  - Ninja build system
  - Google Test framework 1.17.0
  - Various Python packages for linting and testing (e.g., clang-format,
    cpplint, flawfinder, pytest, numpy)

## Host Requirements

- Docker Engine
- `jq` command-line JSON processor installed (required for build scripts)
- Optional: `hadolint`, `dclint`, `shellcheck` for local linting (otherwise lint
scripts fall  back to Docker containers)

## Build Docker Image

To build the Docker image with all dependencies installed:

```shell
./build-image.sh
```

This will build the Docker image tagged as defined in `build-config.json`
(default:`cmake-ninja-gtest:latest`).

## Run the Docker Image

```shell
docker run --rm -it -v "./":/workspace cmake-ninja-gtest /bin/bash
```

## Configuration

The `build-config.json` file controls versions and configurations:

- Docker base image and build image naming.
- User UID, GID, and username inside the container.
- Versions for gcc, python, Google Test framework.
- Python package dependencies with specific versions.

Example snippet:

```json
"python_packages": {
  "clang-format": "21.1.0",
  "cmake": "4.1.0",
  "cpplint": "2.0.2",
  "flawfinder": "2.0.19",
  "gcovr": "8.3",
  "lizard": "1.17.31",
  "numpy": "2.3.2",
  "pytest": "8.4.2"
}
```

## Customization

- To customize the user inside the container (username, UID, GID), edit the
relevant fields in
  `build-config.json`.
- To update Python packages or build dependencies, modify `build-config.json`
and run `./ci/test` this will build and run some basic tests.
