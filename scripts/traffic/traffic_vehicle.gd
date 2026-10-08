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
	global_position = world_position
	scale = Vector3.ONE * scale_factor
	VehicleVisual.paint(_body, material.albedo_color)


func deactivate() -> void:
	active = false
	visible = false
	in_contact = false
	lane_timer = 0.0


func tick(delta: float) -> void:
	if not active or profile == null:
		return
	global_position.z += profile.speed_mps * delta
	VehicleVisual.spin_wheels(self, profile.speed_mps, delta)
	if profile.lane_change_interval <= 0.0:
		global_position.x = lane_x
		return
	global_position.x = move_toward(global_position.x, lane_x, 10.0 * delta)
