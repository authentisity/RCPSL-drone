#!/usr/bin/env bash
# Headless end-to-end check: Gazebo + Clover 4 + PX4, then fly ctbr_check.py over MAVLink.
# Run from the host:  sim/px4/run.sh sim/px4/check_ctbr.sh
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PYTHONUNBUFFERED=1

"$here/sitl.sh" --headless --daemon || { echo "FAIL  sitl.sh"; tail -20 /tmp/gz.log; exit 1; }
for _ in $(seq 90); do grep -q "home set" /tmp/px4.log 2>/dev/null && break; sleep 1; done
grep -q "home set" /tmp/px4.log || { echo "FAIL  PX4 never got a home position"; tail -30 /tmp/px4.log; exit 1; }

status=0
for t in /model/clover4/ground_truth/odometry /clover4/front_camera/image /clover4/front_camera/depth_image; do
    if timeout 10 gz topic -e -n 1 -t "$t" > /dev/null; then echo "PASS  $t publishes"; else echo "FAIL  $t publishes"; status=1; fi
done

timeout 90 python3 "$here/ctbr_check.py" || status=1
grep -E "ERROR|Arming denied|Preflight Fail|ailsafe" /tmp/px4.log | sort | uniq -c | head -10
pkill -f "bin/px4"; pkill -f "gz sim"
exit $status
