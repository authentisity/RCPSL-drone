#!/usr/bin/env bash
# Start Gazebo, spawn the Clover 4 model from its xacro, and attach PX4 SITL to it.
# Runs inside the PX4 container:  sim/px4/run.sh sim/px4/sitl.sh [--headless] [--daemon]
#   --headless  no Gazebo GUI (sensors still render on the GPU)
#   --daemon    start PX4 without its interactive shell (for scripts); the log is /tmp/px4.log
# Environment: PX4_GZ_WORLD (default "default_400hz"; looked up in sim/worlds, then
# PX4's worlds), SPAWN_Z (default 0.1).
#
# Offboard MAVLink (the controller interface) is on UDP 14540; QGroundControl on 14550.
set -euo pipefail
gui=1 daemon=0
for a in "$@"; do
    case "$a" in
        --headless) gui=0 ;;
        --daemon) daemon=1 ;;
        *) echo "unknown option: $a" >&2; exit 2 ;;
    esac
done

px4=/px4/build/px4_sitl_default
repo=/workspace
world="${PX4_GZ_WORLD:-default_400hz}"

# PX4's model, world and plugin paths, plus our models (model://clover4/...).
export GZ_SIM_RESOURCE_PATH="${GZ_SIM_RESOURCE_PATH:-}" GZ_SIM_SYSTEM_PLUGIN_PATH="${GZ_SIM_SYSTEM_PLUGIN_PATH:-}"
source "$px4/rootfs/gz_env.sh"
export GZ_SIM_RESOURCE_PATH="$GZ_SIM_RESOURCE_PATH:$repo/sim/models"

# Our airframes go into the (container-local) PX4 tree, so edits need no image rebuild.
cp "$repo"/sim/px4/airframes/* "$px4/etc/init.d-posix/airframes/"

xacro "$repo/sim/models/clover4/urdf/clover4.urdf.xacro" > /tmp/clover4.urdf

world_file="$repo/sim/worlds/$world.sdf"
[ -f "$world_file" ] || world_file="$PX4_GZ_WORLDS/$world.sdf"
gz sim -r -s --verbose=1 "$world_file" > /tmp/gz.log 2>&1 &
(( gui )) && { gz sim -g > /tmp/gz_gui.log 2>&1 & }

until gz service -i --service "/world/$world/scene/info" 2>/dev/null | grep -q "Service providers"; do
    sleep 0.5
done
gz service -s "/world/$world/create" --reqtype gz.msgs.EntityFactory --reptype gz.msgs.Boolean \
    --timeout 5000 \
    --req "sdf_filename: \"/tmp/clover4.urdf\", name: \"clover4\", allow_renaming: false, pose: {position: {z: ${SPAWN_Z:-0.1}}}"

cd "$px4/rootfs"
export PX4_GZ_STANDALONE=1 PX4_GZ_MODEL_NAME=clover4 PX4_GZ_WORLD="$world" PX4_SIM_MODEL=gz_clover4
if (( daemon )); then
    ../bin/px4 -d > /tmp/px4.log 2>&1 &
else
    exec ../bin/px4
fi
