class_name PlayerController
extends Node3D

const MIN_SPEED_MPS := 8.0
const ACCEL_MPS2 := 8.0
const BRAKE_MPS2 := 18.0
const LATERAL_SPEED_MPS := 12.0
const LATERAL_ACCEL_MPS2 := 28.0
const LATERAL_GRIP_MPS2 := 18.0
const X_LIMIT := 6.0

var speed_mps: float = MIN_SPEED_MPS
var lateral_speed_mps: float = 0.0
var max_speed_mps: float = 30.0
var read_input_devices: bool = true
var steer_input: float = 0.0
var brake_input: bool = false


static func step_longitudinal(speed: float, max_speed: float, braking: bool, delta: float) -> float:
	if braking:
		return maxf(move_toward(speed, MIN_SPEED_MPS, BRAKE_MPS2 * delta), MIN_SPEED_MPS)
	return clampf(move_toward(speed, max_speed, ACCEL_MPS2 * delta), MIN_SPEED_MPS, max_speed)


static func step_lateral(lateral: float, steer: float, delta: float) -> float:
	var target := steer * LATERAL_SPEED_MPS
	var rate := LATERAL_GRIP_MPS2 if is_zero_approx(steer) else LATERAL_ACCEL_MPS2
	return move_toward(lateral, target, rate * delta)


static func step_x(x: float, lateral: float, delta: float) -> Vector2:
	var next_x := x + lateral * delta
	if next_x < -X_LIMIT or next_x > X_LIMIT:
		return Vector2(clampf(next_x, -X_LIMIT, X_LIMIT), 0.0)
	return Vector2(next_x, lateral)


func _ready() -> void:
	VehicleVisual.build(self)


func tick(delta: float) -> void:
	speed_mps = step_longitudinal(speed_mps, max_speed_mps, _is_braking(), delta)
	lateral_speed_mps = step_lateral(lateral_speed_mps, _steer_value(), delta)
	var x_step := step_x(position.x, lateral_speed_mps, delta)
	lateral_speed_mps = x_step.y
	position.x = x_step.x
	position.z += speed_mps * delta


func _is_braking() -> bool:
	if not read_input_devices:
		return brake_input
	return Input.is_action_pressed("brake")


func _steer_value() -> float:
	if not read_input_devices:
		return steer_input
	return Input.get_axis("steer_left", "steer_right")
