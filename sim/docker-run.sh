#!/usr/bin/env bash
# Build an image from a sim/ directory and run a command in it; with no command, open a shell.
#   sim/docker-run.sh <image-tag> <dockerfile-dir> [cmd...]
# Use the per-image wrappers (sim/gazebo/run.sh, sim/ros2/run.sh) rather than calling this directly.
# The repo is mounted at /workspace. The GUI goes through the host X server
# (XWayland), and the GPU is passed in via /dev/dri. DRI_PRIME selects the RX 9070
# by PCI address (0000:03:00.0), not DRI_PRIME=1: "1" means "not the X server's
# GPU", which flips to the iGPU whenever the monitors are on the RX 9070.
# Override DRI_PRIME from the host if the card moves.
# Rendering goes through X, so sensors render on the discrete GPU even in a
# server-only run (gz sim -s). Avoid --headless-rendering on this machine: its
# EGL path ignores DRI_PRIME and takes the first GPU, which is the iGPU.
set -euo pipefail

image="$1" context="$2"
shift 2
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

docker build -q -t "$image" \
    --build-arg USER_UID="$(id -u)" --build-arg USER_GID="$(id -g)" \
    "$context" >/dev/null

tty_flags=(-i)
[ -t 0 ] && tty_flags+=(-t)

# Host networking so gz-transport and ROS 2 discovery work between containers and the host.
exec docker run --rm "${tty_flags[@]}" \
    --network host \
    --device /dev/dri \
    --group-add "$(getent group video | cut -d: -f3)" \
    --group-add "$(getent group render | cut -d: -f3)" \
    -e DISPLAY="${DISPLAY:-:0}" \
    -e DRI_PRIME="${DRI_PRIME:-pci-0000_03_00_0}" \
    -e QT_X11_NO_MITSHM=1 \
    -e ROS_DOMAIN_ID="${ROS_DOMAIN_ID:-0}" \
    -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
    -v nsfc-gz-cache:/home/dev/.gz \
    -v "$repo":/workspace \
    "$image" "${@:-bash}"
