#!/usr/bin/env bash
# Check the ROS 2 image end to end: GPU rendering, Gazebo, the ROS 2 bridge and xacro.
# Run from the host:  sim/ros2/run.sh sim/ros2/smoke_test.sh
set -u
export PYTHONUNBUFFERED=1  # ros2 topic hz output is otherwise held in a pipe buffer
fail=0
check() { if eval "$2"; then echo "PASS  $1"; else echo "FAIL  $1"; fail=1; fi; }

renderer=$(glxinfo -B 2>/dev/null | grep "renderer string")
echo "$renderer"
check "renders on the RX 9070" '[[ "$renderer" == *"RX 9070"* ]]'
echo "gz-sim $(gz sim --versions)"

worlds=/opt/ros/lyrical/opt/gz_sim_vendor/share/gz/gz-sim/worlds
gz sim -s -r "$worlds/multicopter_velocity_control.sdf" -v 1 > /tmp/gz.log 2>&1 &
sleep 8
img=/world/multicopter/model/X4/link/base_link/sensor/camera_front/image
ros2 run ros_gz_bridge parameter_bridge \
    /clock@rosgraph_msgs/msg/Clock[gz.msgs.Clock \
    "$img@sensor_msgs/msg/Image[gz.msgs.Image" \
    /model/X4/odometry@nav_msgs/msg/Odometry[gz.msgs.Odometry > /tmp/bridge.log 2>&1 &
sleep 5

rate() { timeout 10 ros2 topic hz "$1" 2>&1 | grep -m1 "average rate" | awk '{print int($3)}'; }
for t in /clock /model/X4/odometry "$img"; do
    r=$(rate "$t"); echo "$t: ${r:-none} Hz"
    check "$t publishes in ROS 2" '[ -n "$r" ] && [ "$r" -gt 0 ]'
done

xml='<robot xmlns:xacro="http://www.ros.org/wiki/xacro" name="t"><xacro:property name="m" value="1.5"/><link name="b"><inertial><mass value="${m*2}"/></inertial></link></robot>'
check "xacro expands properties" 'echo "$xml" > /tmp/t.xacro && xacro /tmp/t.xacro | grep -q "mass value=\"3.0\""'

pkill -f parameter_bridge; pkill -f "gz sim"
exit $fail
