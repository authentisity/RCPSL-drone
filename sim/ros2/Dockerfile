# ROS 2 Lyrical on Ubuntu 26.04 (Resolute), with Gazebo Jetty from ROS's vendor packages.
# This image does not install OSRF's gz-jetty: ros-lyrical-ros-gz brings its own Gazebo
# under /opt/ros/lyrical, and mixing the two would load two copies of the Gazebo libraries.
FROM ubuntu:26.04

ARG DEBIAN_FRONTEND=noninteractive
ARG USER_UID=1000
ARG USER_GID=1000
ARG ROS_APT_SOURCE_VERSION=1.3.0

# Install steps follow https://docs.ros.org/en/lyrical/Installation/Ubuntu-Install-Debs.html
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl locales mesa-utils \
    && locale-gen en_US.UTF-8 \
    && codename="$(. /etc/os-release && echo "$VERSION_CODENAME")" \
    && curl -fsSL -o /tmp/ros2-apt-source.deb \
        "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.${codename}_all.deb" \
    && dpkg -i /tmp/ros2-apt-source.deb && rm /tmp/ros2-apt-source.deb \
    && apt-get update && apt-get install -y --no-install-recommends \
        ros-lyrical-ros-base \
        ros-lyrical-ros-gz \
        ros-lyrical-xacro \
        ros-lyrical-robot-state-publisher \
    && rm -rf /var/lib/apt/lists/*
ENV LANG=en_US.UTF-8

# Run as the host user so files written to the mounted repo keep host ownership.
RUN (userdel -r ubuntu 2>/dev/null || true) \
    && groupadd -g ${USER_GID} dev \
    && useradd -m -u ${USER_UID} -g ${USER_GID} -s /bin/bash dev
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
USER dev
RUN mkdir -p /home/dev/.gz \
    && echo "source /opt/ros/lyrical/setup.bash" >> /home/dev/.bashrc
WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
