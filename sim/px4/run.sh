#!/usr/bin/env bash
# Run a command in the PX4 SITL container (ROS 2 Lyrical + Gazebo Jetty + PX4); with no
# arguments, open a shell.
#   sim/px4/run.sh sim/px4/sitl.sh              # Clover 4 in Gazebo + PX4, with the GUI
#   sim/px4/run.sh sim/px4/sitl.sh --headless
#   sim/px4/run.sh sim/px4/check_ctbr.sh        # automated hover and rate-step check
# The first build clones and compiles PX4 (~10 min). GPU, X and mount details are in sim/docker-run.sh.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The PX4 image is FROM nsfc-ros2:lyrical, so build that first (a no-op when cached).
docker build -q -t nsfc-ros2:lyrical \
    --build-arg USER_UID="$(id -u)" --build-arg USER_GID="$(id -g)" \
    "$here/../ros2" >/dev/null
exec "$here/../docker-run.sh" nsfc-px4:v1.17.0 "$here" "$@"
