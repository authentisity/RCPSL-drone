#!/usr/bin/env bash
# Run a command in the ROS 2 Lyrical + Gazebo Jetty container; with no arguments, open a shell.
#   sim/ros2/run.sh ros2 topic list
#   sim/ros2/run.sh gz sim -s -r shapes.sdf
# ROS 2 is sourced for every command. GPU, X and mount details are in sim/docker-run.sh.
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$here/../docker-run.sh" nsfc-ros2:lyrical "$here" "$@"
