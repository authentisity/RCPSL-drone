# PX4 SITL on top of the ROS 2 Lyrical image (sim/ros2), built against the
# Gazebo Jetty libraries that ROS vendors under /opt/ros/lyrical/opt. No OSRF
# gz packages are installed, so only one copy of Gazebo is on the system.
# sim/px4/run.sh builds the base image first.
FROM nsfc-ros2:lyrical

ARG DEBIAN_FRONTEND=noninteractive
ARG PX4_VERSION=v1.17.0

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential cmake ninja-build git ccache python3-venv python3-dev \
        libopencv-dev libeigen3-dev astyle file zip rsync xxd \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir /px4 && chown dev:dev /px4
USER dev
SHELL ["/bin/bash", "-c"]

RUN git clone --depth 1 --branch ${PX4_VERSION} --recurse-submodules --shallow-submodules \
        https://github.com/PX4/PX4-Autopilot.git /px4
RUN python3 -m venv /home/dev/venv \
    && /home/dev/venv/bin/pip install --no-cache-dir -q -r /px4/Tools/setup/requirements.txt pymavlink
ENV PATH=/home/dev/venv/bin:$PATH

# setup.bash puts the vendored gz CMake configs on CMAKE_PREFIX_PATH.
RUN source /opt/ros/lyrical/setup.bash && cd /px4 && make px4_sitl

WORKDIR /workspace
