#!/usr/bin/env bash
# Source ROS 2 so ros2, gz and xacro are on PATH for non-interactive commands too.
source /opt/ros/lyrical/setup.bash
exec "$@"
