#!/usr/bin/env bash
# Run a command in the Gazebo Jetty container; with no arguments, open a shell.
#   sim/gazebo/run.sh gz sim shapes.sdf
# The repo is mounted at /workspace. The GUI goes through the host X server
# (XWayland), and the GPU is passed in via /dev/dri. DRI_PRIME=1 selects the
# discrete GPU; override it from the host if needed.
# Rendering goes through X, so sensors render on the discrete GPU even in a
# server-only run (gz sim -s). Avoid --headless-rendering on this machine: its
# EGL path ignores DRI_PRIME and takes the first GPU, which is the iGPU.
set -euo pipefail

IMAGE=nsfc-gazebo:jetty
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$here/../.." && pwd)"

docker build -q -t "$IMAGE" \
    --build-arg USER_UID="$(id -u)" --build-arg USER_GID="$(id -g)" \
    "$here" >/dev/null

tty_flags=(-i)
[ -t 0 ] && tty_flags+=(-t)

# Host networking so gz-transport discovery works between containers and the host.
exec docker run --rm "${tty_flags[@]}" \
    --network host \
    --device /dev/dri \
    --group-add "$(getent group video | cut -d: -f3)" \
    --group-add "$(getent group render | cut -d: -f3)" \
    -e DISPLAY="${DISPLAY:-:0}" \
    -e DRI_PRIME="${DRI_PRIME:-1}" \
    -e QT_X11_NO_MITSHM=1 \
    -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
    -v nsfc-gz-cache:/home/dev/.gz \
    -v "$repo":/workspace \
    "$IMAGE" "${@:-bash}"
