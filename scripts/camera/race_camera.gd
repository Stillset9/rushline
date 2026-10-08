class_name RaceCamera
extends Camera3D

const HEIGHT := 7.5
const BEHIND := 10.5
const LOOK_AHEAD := 12.0
const LOOK_HEIGHT := 1.4
const SMOOTH := 5.0
const FOV_BASE := 60.0
const FOV_AT_CAP := 72.0
const SPEED_FOR_FOV := 70.0


static func target_position(player_position: Vector3) -> Vector3:
	return Vector3(player_position.x, HEIGHT, player_position.z - BEHIND)


static func look_target(player_position: Vector3) -> Vector3:
	return Vector3(player_position.x, LOOK_HEIGHT, player_position.z + LOOK_AHEAD)


static func smooth_position(current: Vector3, target: Vector3, delta: float) -> Vector3:
	var weight := 1.0 - exp(-SMOOTH * delta)
	return current.lerp(target, weight)


static func fov_for_speed(speed_mps: float) -> float:
	var weight := clampf(speed_mps / SPEED_FOR_FOV, 0.0, 1.0)
	return lerpf(FOV_BASE, FOV_AT_CAP, weight)


func snap_to(player_position: Vector3) -> void:
	global_position = target_position(player_position)
	look_at(look_target(player_position), Vector3.UP)


func tick(delta: float, player_position: Vector3) -> void:
	var target := target_position(player_position)
	var smoothed := smooth_position(global_position, target, delta)
	global_position = Vector3(smoothed.x, target.y, target.z)
	look_at(look_target(player_position), Vector3.UP)


func apply_speed(speed_mps: float) -> void:
	fov = fov_for_speed(speed_mps)
