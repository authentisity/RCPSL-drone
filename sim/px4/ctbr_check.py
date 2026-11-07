"""Fly the Clover 4 in SITL using only thrust + body-rate commands, as the MPC will.

Acts as the GCS (PX4 will not arm without one), switches to OFFBOARD, arms, climbs on
collective thrust, then holds hover thrust and steps the roll rate.
Exits non-zero if a check fails.
Usage: python3 ctbr_check.py [hover_thrust]
"""
import math
import sys
import time

from pymavlink import mavutil

HOVER = float(sys.argv[1]) if len(sys.argv) > 1 else 0.41
IGNORE_ATTITUDE = 1 << 7  # type_mask: use body rates + thrust, ignore the quaternion
OFFBOARD = 6              # PX4 main mode

m = mavutil.mavlink_connection("udpin:0.0.0.0:14540", source_system=255)
m.wait_heartbeat(timeout=60)
t0 = time.time()
last_hb = 0.0
latest = {}
failures = []


def send(rates, thrust):
    global last_hb
    if time.time() - last_hb > 0.5:
        m.mav.heartbeat_send(mavutil.mavlink.MAV_TYPE_GCS, mavutil.mavlink.MAV_AUTOPILOT_INVALID, 0, 0, 0)
        last_hb = time.time()
    m.mav.set_attitude_target_send(int((time.time() - t0) * 1000), m.target_system, m.target_component,
                                   IGNORE_ATTITUDE, [1, 0, 0, 0], *rates, thrust)


def run(duration, rates, thrust):
    """Stream one command at 100 Hz; return the extreme roll rates and the last messages seen."""
    end = time.time() + duration
    rr = []
    while time.time() < end:
        send(rates, thrust)
        time.sleep(0.01)
        while (msg := m.recv_match(blocking=False)) is not None:
            latest[msg.get_type()] = msg
            if msg.get_type() == "ATTITUDE":
                rr.append(msg.rollspeed)
    return rr


def state():
    a, p, h = latest.get("ATTITUDE"), latest.get("LOCAL_POSITION_NED"), latest.get("HEARTBEAT")
    armed = bool(h and h.base_mode & mavutil.mavlink.MAV_MODE_FLAG_SAFETY_ARMED)
    offboard = bool(h and (h.custom_mode >> 16) & 0xFF == OFFBOARD)
    return a, p, armed, offboard


def check(name, ok, detail):
    print(f"{'PASS' if ok else 'FAIL'}  {name}: {detail}", flush=True)
    if not ok:
        failures.append(name)


def command(cmd, *params):
    m.mav.command_long_send(m.target_system, m.target_component, cmd, 0, *params, *([0] * (7 - len(params))))


run(3.0, (0, 0, 0), 0.0)  # setpoints must already be streaming before OFFBOARD is accepted
command(mavutil.mavlink.MAV_CMD_DO_SET_MODE, mavutil.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED, OFFBOARD)
run(0.5, (0, 0, 0), 0.0)
command(mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM, 1)
run(0.5, (0, 0, 0), 0.0)
_, _, armed, offboard = state()
check("armed in OFFBOARD", armed and offboard, f"armed={armed} offboard={offboard}")

# Thrust-to-weight is ~4, so small offsets from hover thrust already accelerate hard.
run(1.0, (0, 0, 0), HOVER + 0.1)  # climb
run(1.0, (0, 0, 0), HOVER - 0.1)  # brake
_, p, _, _ = state()
check("climbs on collective thrust", p is not None and -p.z > 0.5, f"height {-p.z:.2f} m" if p else "no position")

# At hover thrust the vertical speed should stay (nearly) constant.
vz0 = -p.vz
run(2.0, (0, 0, 0), HOVER)
a, p2, _, _ = state()
accel = (-p2.vz - vz0) / 2.0
check("hover thrust gives ~zero vertical acceleration", abs(accel) < 0.5,
      f"{accel:+.2f} m/s^2 at thrust {HOVER} (vz {vz0:+.2f} -> {-p2.vz:+.2f} m/s)")
check("level at zero rates", abs(a.roll) < math.radians(10) and abs(a.pitch) < math.radians(10),
      f"roll {math.degrees(a.roll):+.1f} deg, pitch {math.degrees(a.pitch):+.1f} deg")

up = run(0.4, (1.0, 0, 0), HOVER)
down = run(0.4, (-1.0, 0, 0), HOVER)
check("tracks +1 rad/s roll-rate step", max(up, default=0) > 0.7, f"peak {max(up, default=0):+.2f} rad/s")
check("tracks -1 rad/s roll-rate step", min(down, default=0) < -0.7, f"peak {min(down, default=0):+.2f} rad/s")
run(1.0, (0, 0, 0), HOVER)

run(4.0, (0, 0, 0), HOVER - 0.1)  # descend, then stop the motors
command(mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM, 0, 21196)  # force disarm
sys.exit(1 if failures else 0)
