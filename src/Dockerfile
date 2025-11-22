ARG BASE_IMAGE=ubuntu:noble-20251013
FROM ${BASE_IMAGE} AS base-installer

ARG DKR_PYTHON_VERSION="3.13"
ARG DKR_GTEST_HASH=52eb810
ARG DKR_GTEST_PARALLEL_HASH=cd488bd
ARG DKR_GCC_VER=13

ARG DKR_DATA_PATH="src/docker-data"

# Set WORKDIR before COPY to avoid DL3045
WORKDIR /app

COPY ${DKR_DATA_PATH}/custom_bashrc /etc/bash.bashrc
COPY ${DKR_DATA_PATH}/requirements.txt ./

RUN DEBIAN_FRONTEND=noninteractive apt-get -y update \
    && apt-get install -y --no-install-recommends \
    gpg-agent \
    # python version dependencies
    software-properties-common \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    # aptitude packages
    build-essential \
    ccze \
    doctest \
    doctest-dev \
    doxygen \
    # gcc
    gcc-${DKR_GCC_VER} \
    g++-${DKR_GCC_VER} \
    git-all \
    libglib2.0-dev \
    # doxygen dependency
    graphviz \
    lcov \
    jq \
    ninja-build \
    nlohmann-json3-dev \
    pkg-config \
    # python install desired version
    python${DKR_PYTHON_VERSION} \
    python3-pip \
    shellcheck \
    zip \
    # --- Python packages
    ######################
    # make python latest version the default
    && ln -sf /usr/bin/python${DKR_PYTHON_VERSION} /usr/bin/python \
    && pip install --no-cache-dir --no-input --break-system-packages -r requirements.txt \
    # set to the latest versions of the toolchain
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${DKR_GCC_VER} 60 \
        --slave /usr/bin/g++ g++ /usr/bin/g++-${DKR_GCC_VER}     \
        --slave /usr/bin/gcov gcov /usr/bin/gcov-${DKR_GCC_VER}  \
    # clear out the cache
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/tmp/* ./requirements.txt

WORKDIR /opt/
# Install GoogleTest framework
##############################
RUN git clone https://github.com/google/googletest.git
WORKDIR /opt/googletest
RUN git reset --hard ${DKR_GTEST_HASH}

#
# Install GoogleTest Parallel
###############################
# Latest main as of Aug 2025 (no release / tags available)
WORKDIR /opt/
RUN git clone https://github.com/google/gtest-parallel.git
WORKDIR /opt/gtest-parallel
RUN git reset --hard ${DKR_GTEST_PARALLEL_HASH}

#########################################
# scratch  is Docker's reserved minimal image but it is not runnable
FROM scratch
ARG DKR_USER_UID=1000
ARG DKR_USER_GID=${DKR_USER_UID}
ARG DKR_USER_NAME=ubuntu

COPY --from=base-installer / /

RUN chown -R ${DKR_USER_UID}:${DKR_USER_GID} /opt \
    # Do not use dash, make /bin/sh symlink to bash instead of dash:
    && echo "dash dash/sh boolean false" | debconf-set-selections \
    && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash \
    # Add a new user with specified UID and GID, but only if it doesn't already
    # exist, if uid/gid are taken use the existing ones and rename the user
    # Check if user with UID exists
    && existing_user_by_uid=$(getent passwd ${DKR_USER_UID} | cut -d: -f1) \
    # Removed unused variable existing_group_by_gid to fix SC2034 warning
    # && existing_group_by_gid=$(getent group ${DKR_USER_GID} | cut -d: -f1) \
    # If user with this UID exists and is 'ubuntu', rename it
    && if [ "$existing_user_by_uid" = "ubuntu" ]; then \
      usermod -l ${DKR_USER_NAME} ubuntu && \
      groupmod -n ${DKR_USER_NAME} ubuntu && \
      usermod -d /home/${DKR_USER_NAME} -m ${DKR_USER_NAME}; \
    # Else if desired user does not exist, add group and user
    elif ! id -u ${DKR_USER_NAME} >/dev/null 2>&1; then \
      groupadd --gid ${DKR_USER_GID} ${DKR_USER_NAME} && \
      useradd --uid ${DKR_USER_UID} --gid ${DKR_USER_GID} --shell /bin/bash ${DKR_USER_NAME}; \
    fi \
    # add the workspace dir
    && mkdir -p /home/${DKR_USER_NAME}/workspace \
    # add an .ssh directory for the keys
    && mkdir -p /home/${DKR_USER_NAME}/.ssh \
    && chown -R ${DKR_USER_UID}:${DKR_USER_GID} /home/${DKR_USER_NAME}

USER ${DKR_USER_NAME}
WORKDIR /workspace
# to update the path edit docker-data/custom_bashrc
ENV PATH="$PATH"
# Set shell option -o pipefail before any RUN with pipes to avoid DL4006 warnings
SHELL ["/usr/bin/bash", "-o", "pipefail", "-c"]
RUN source /etc/bash.bashrc
