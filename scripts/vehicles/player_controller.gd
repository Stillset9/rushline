class_name PlayerController
extends Node3D

const MIN_SPEED_MPS := 8.0
const ACCEL_MPS2 := 8.0
const BRAKE_MPS2 := 18.0
const LATERAL_SPEED_MPS := 12.0
const LATERAL_ACCEL_MPS2 := 28.0
const LATERAL_GRIP_MPS2 := 18.0
const X_LIMIT := 6.0
const SLIP_GRIP := 0.18
const DRIFT_STEER := 0.65
const DRIFT_GRIP := 0.42
const DRIFT_BLEED := 3.0
const DRIFT_MIN_SPEED := 18.0
const NITRO_BOOST_MPS := 12.0
const NITRO_DRAIN := 0.45
const NITRO_RECHARGE := 0.12

var speed_mps: float = MIN_SPEED_MPS
var lateral_speed_mps: float = 0.0
var max_speed_mps: float = 30.0
var slip_s: float = 0.0
var weather_grip: float = 1.0
var accel_mps2: float = ACCEL_MPS2
var nitro_tank: float = 1.0
var nitro_boost_mps: float = NITRO_BOOST_MPS
var nitro_drain: float = NITRO_DRAIN
var nitro_input: bool = false
var read_input_devices: bool = true
var steer_input: float = 0.0
var brake_input: bool = false


static func step_longitudinal(speed: float, max_speed: float, braking: bool, delta: float, accel: float = ACCEL_MPS2) -> float:
	if braking:
		return maxf(move_toward(speed, MIN_SPEED_MPS, BRAKE_MPS2 * delta), MIN_SPEED_MPS)
	return clampf(move_toward(speed, max_speed, accel * delta), MIN_SPEED_MPS, max_speed)


static func step_lateral(lateral: float, steer: float, delta: float, grip: float = 1.0) -> float:
	var target := steer * LATERAL_SPEED_MPS
	var rate := (LATERAL_GRIP_MPS2 if is_zero_approx(steer) else LATERAL_ACCEL_MPS2) * clampf(grip, 0.0, 1.0)
	return move_toward(lateral, target, rate * delta)


static func step_x(x: float, lateral: float, delta: float) -> Vector2:
	var next_x := x + lateral * delta
	if next_x < -X_LIMIT or next_x > X_LIMIT:
		return Vector2(clampf(next_x, -X_LIMIT, X_LIMIT), 0.0)
	return Vector2(next_x, lateral)


func _ready() -> void:
	VehicleVisual.build(self)


func tick(delta: float) -> void:
	var braking := _is_braking()
	var steering := _steer_value()
	var boosting := _nitro_held() and nitro_tank > 0.0 and not braking
	var cap := max_speed_mps + (nitro_boost_mps if boosting else 0.0)
	speed_mps = step_longitudinal(speed_mps, cap, braking, delta, accel_mps2)
	if boosting:
		nitro_tank = maxf(0.0, nitro_tank - nitro_drain * delta)
	else:
		nitro_tank = minf(1.0, nitro_tank + NITRO_RECHARGE * delta)
	var grip := weather_grip
	if slip_s > 0.0:
		grip = SLIP_GRIP
		slip_s = maxf(0.0, slip_s - delta)
	elif absf(steering) >= DRIFT_STEER and speed_mps > DRIFT_MIN_SPEED and not braking:
		grip *= DRIFT_GRIP
		speed_mps = maxf(MIN_SPEED_MPS, speed_mps - DRIFT_BLEED * delta)
	lateral_speed_mps = step_lateral(lateral_speed_mps, steering, delta, grip)
	var x_step := step_x(position.x, lateral_speed_mps, delta)
	lateral_speed_mps = x_step.y
	position.x = x_step.x
	position.z += speed_mps * delta
	VehicleVisual.spin_wheels(self, speed_mps, delta)
	VehicleVisual.show_boost(self, boosting)


func _is_braking() -> bool:
	if not read_input_devices:
		return brake_input
	return Input.is_action_pressed("brake")


func _steer_value() -> float:
	if not read_input_devices:
		return steer_input
	return Input.get_axis("steer_left", "steer_right")


func _nitro_held() -> bool:
	if not read_input_devices:
		return nitro_input
	return Input.is_action_pressed("nitro")
