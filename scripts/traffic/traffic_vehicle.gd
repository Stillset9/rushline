class_name TrafficVehicle
extends Node3D

var active: bool = false
var lane: int = 0
var lane_x: float = 0.0
var profile: AiProfile
var in_contact: bool = false
var lane_timer: float = 0.0
var visual_model: PackedScene
var _body: MeshInstance3D
var road_x: float = 0.0
var road_z: float = 0.0
var _road_live: bool = false


func _ready() -> void:
	_body = VehicleVisual.build(self, visual_model, false)
	visible = false


func activate(lane_index: int, world_position: Vector3, material: StandardMaterial3D, scale_factor: float) -> void:
	active = true
	visible = true
	in_contact = false
	lane = lane_index
	lane_x = world_position.x
	lane_timer = 0.0
	road_x = world_position.x
	road_z = world_position.z
	_road_live = true
	scale = Vector3.ONE * scale_factor
	position.y = world_position.y
	CoursePath.present(self, road_z, road_x)
	VehicleVisual.paint(_body, material.albedo_color)


func track_x() -> float:
	return road_x if _road_live else global_position.x


func track_z() -> float:
	return road_z if _road_live else global_position.z


func road_center() -> Vector2:
	if _road_live and not CoursePath.on_straight(road_z):
		return Vector2(road_x, road_z)
	return Vector2(global_position.x, global_position.z)


func deactivate() -> void:
	active = false
	visible = false
	in_contact = false
	lane_timer = 0.0
	_road_live = false


func tick(delta: float) -> void:
	if not active or profile == null:
		return
	if not _road_live or CoursePath.on_straight(road_z):
		road_x = global_position.x
		road_z = global_position.z
		_road_live = true
	road_z += profile.speed_mps * delta
	if profile.lane_change_interval <= 0.0:
		road_x = lane_x
	else:
		road_x = move_toward(road_x, lane_x, 10.0 * delta)
	CoursePath.present(self, road_z, road_x)
	VehicleVisual.spin_wheels(self, profile.speed_mps, delta)
