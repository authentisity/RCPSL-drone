# Clover 4 model: what to measure and what to look up

The sim model is a Clover 4 stand-in. Every number in `params.yaml` is tagged
`[spec]` (COEX published or COEX sim geometry), `[placeholder]` (borrowed, mostly
from the 3DR Iris), or `[measured]`. This file lists what to replace, in priority
order for the MPC, and the hardware details we still need.

When you update a value in `params.yaml`, change its tag to `[measured]`. If it is a
rotor position, moment constant or max motor speed, also update
`sim/px4/airframes/4500_gz_clover4`; the comment at the top of that file says which
parameter maps to which.

## 1. Values to measure

Measure everything **with the final flight configuration**: battery, mounts,
standoffs and cameras installed.

### Mass and inertia (highest priority: they set the MPC's dynamics directly)

| Value | params.yaml key | Current | How to measure |
|---|---|---|---|
| Total takeoff mass | `body.mass` | 1.0 kg [spec] | Kitchen or postal scale, ±1 g. Include the battery you fly with. |
| CG position | (base_link origin) | assumed at geometric centre | Balance on a knife edge along x and y; for z, hang from two points and intersect the plumb lines. Report the offset from the frame centre. |
| Ixx, Iyy, Izz | `body.inertia.*` | box formula ≈ 0.011 / 0.011 / 0.020 kg·m² [placeholder] | Bifilar pendulum for each axis: I = m g T² d² / (16 π² L), where T = period, d = string spacing, L = string length. Or export from CAD if the CAD includes everything at real mass. |
| Rotor + prop mass | `rotor.mass` | 0.01 kg [placeholder] | Weigh one prop. The motor bell's spin inertia is second-order; skip unless easy. |

### Geometry

| Value | params.yaml key | Current | How to measure |
|---|---|---|---|
| Motor positions x, y from CG | `rotor.arm_x`, `rotor.arm_y` | 0.083 m [spec] | Calipers or ruler, motor shaft centre to CG, along x and y. |
| Rotor plane height above CG | `rotor.z_offset` | 0.026 m [spec] | Ruler, prop plane to CG height. |
| Prop diameter / pitch | `rotor.radius` | r = 0.06 m [spec] | Read off the prop (e.g. 5045 = 5.0" diameter, 4.5" pitch). |
| Forward camera pose | `front_camera.xyz`, `.rpy` | 0.09 m forward, level [placeholder] | Ruler from CG to the lens centre; tilt angle with a phone inclinometer. |
| Forward camera intrinsics (fx, fy, cx, cy, distortion) | `front_camera.hfov`, `.width`, `.height` | 640×480, HFOV 1.51 rad [placeholder] | Checkerboard calibration (ROS `camera_calibration` or OpenCV) at the resolution you fly. HFOV = 2 atan(width / (2 fx)). |
| Outer dimensions (with guards) | `body.width`, `body.height` | 0.35 × 0.124 m [spec] | Ruler. Only used for the collision box. |

### Motor and propeller (second priority: thrust mapping and the yaw/thrust model)

| Value | params.yaml key | Current | How to measure |
|---|---|---|---|
| Thrust coefficient k_T (thrust = k_T ω²) | `rotor.motor_constant` | 8.55e-6 N/(rad/s)² [placeholder, Iris] | Thrust stand (or motor on a scale, prop pushing down) with an optical tachometer: fit thrust against ω². Check the motor maker's datasheet first, which often lists thrust vs RPM for a given prop. |
| Torque/thrust ratio | `rotor.moment_constant` | 0.06 m [placeholder, likely too high for 5" props] | Thrust stand with torque cell. Or from the prop maker's data (C_Q/C_T × diameter). |
| Max motor speed | `rotor.max_rot_velocity` | 1100 rad/s [placeholder] | Tachometer at full throttle on a charged battery. |
| Motor time constant (spin up / down) | `rotor.time_constant_up`, `_down` | 12.5 ms / 25 ms [placeholder] | Throttle step on the stand, logging RPM (ESC telemetry or tachometer); the time to 63 %. |
| Hover throttle | PX4 `MPC_THR_HOVER` | 0.41 (computed) | Read the PX4 hover thrust estimate from a flight log (`hover_thrust_estimate`). |

### Sensor noise (lowest priority; PX4 x500 values are reasonable placeholders)

| Value | Current | How to measure |
|---|---|---|
| Gyro and accel noise | IIM42653 values [placeholder] | Log 60 s with the drone still and props off; take the standard deviation per axis. |
| Baro noise | BMP390 value [placeholder] | Same log, `sensor_baro`. |
| Mag noise | IIS2MDC value [placeholder] | Same log, `sensor_mag`. |

## 2. Hardware specs to obtain

These identify parts; most of the numbers above follow from their datasheets.

| Item | Why we need it | Where to find it |
|---|---|---|
| **Flight controller** (model, e.g. COEX Pix / Pixhawk variant) | IMU, baro and mag chips give the sensor noise models; also sets the PX4 board target. | Label on the board, or `ver all` in the PX4 shell. |
| **IMU, baro and mag chip part numbers** | Sensor noise models (section 1). | FC datasheet, or the PX4 boot log (`dmesg` in the PX4 shell). |
| **Forward camera model** | Replaces the generic RGB-D placeholder: resolution, frame rate, FOV, depth range, and depth vs mono/stereo. | Product page or datasheet. |
| **Any other cameras** (e.g. a downward Raspberry Pi camera for ArUco or optical flow) | Adds sensors to the model. | Product page. |
| **Companion computer** (e.g. Raspberry Pi 4) | Mass, and where the MPC and planner run on the real drone (compute budget). | Label / receipt. |
| **Motors** (model and KV) | Thrust/RPM data, max speed. | Motor label; maker datasheet. |
| **ESCs** (model, firmware, protocol: PWM, DShot, telemetry?) | Motor time constant; whether RPM telemetry is available for measuring it. | ESC label; flashing tool. |
| **Propellers** (model, diameter × pitch, blade count) | Thrust and torque coefficients. | Printed on the prop. |
| **Battery** (cells, capacity, mass) | Mass, max motor speed (voltage sag). | Battery label. |
| **Mounts, standoffs and added parts** (mass, position) | Mass, CG and inertia; also visual meshes for our own URDF. | CAD files or a scale and ruler. |
| **Positioning system for flights** (GPS, optical flow, motion capture, UWB) | What PX4's estimator fuses on the real drone, so the sim matches it. | Team decision. |
