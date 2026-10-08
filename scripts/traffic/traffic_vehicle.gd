class_name TrafficVehicle
extends Node3D

var active: bool = false
var lane: int = 0
var lane_x: float = 0.0
var profile: AiProfile
var _body: MeshInstance3D


func _ready() -> void:
	_body = VehicleVisual.build(self)
	visible = false


func activate(lane_index: int, world_position: Vector3, material: StandardMaterial3D, scale_factor: float) -> void:
	active = true
	visible = true
	lane = lane_index
	lane_x = world_position.x
	global_position = world_position
	scale = Vector3.ONE * scale_factor
	_body.material_override = material


func deactivate() -> void:
	active = false
	visible = false


func tick(delta: float) -> void:
	if not active or profile == null:
		return
	global_position.x = lane_x
	global_position.z += profile.speed_mps * delta
