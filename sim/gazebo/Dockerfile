# Gazebo Jetty on Ubuntu 26.04 (Resolute). The host is Arch, so Gazebo runs in this container.
FROM ubuntu:26.04

ARG DEBIAN_FRONTEND=noninteractive
ARG USER_UID=1000
ARG USER_GID=1000

# Install steps follow https://gazebosim.org/docs/jetty/install_ubuntu/
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg lsb-release mesa-utils \
    && curl -fsSL https://packages.osrfoundation.org/gazebo.gpg \
        -o /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] https://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" \
        > /etc/apt/sources.list.d/gazebo-stable.list \
    && apt-get update && apt-get install -y gz-jetty \
    && rm -rf /var/lib/apt/lists/*

# Run as the host user so files written to the mounted repo keep host ownership.
RUN (userdel -r ubuntu 2>/dev/null || true) \
    && groupadd -g ${USER_GID} dev \
    && useradd -m -u ${USER_UID} -g ${USER_GID} -s /bin/bash dev
USER dev
# Pre-create so the named cache volume mounted here is owned by dev.
RUN mkdir -p /home/dev/.gz
WORKDIR /workspace
