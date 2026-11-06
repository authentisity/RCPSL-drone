#!/usr/bin/env bash
# Run a command in the Gazebo Jetty container (OSRF packages, no ROS); with no arguments, open a shell.
#   sim/gazebo/run.sh gz sim shapes.sdf
# GPU, X and mount details are in sim/docker-run.sh.
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$here/../docker-run.sh" nsfc-gazebo:jetty "$here" "$@"
