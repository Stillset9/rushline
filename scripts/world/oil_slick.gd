class_name OilSlick
extends Node3D

const HALF_X := 1.6
const HALF_Z := 3.5

var active: bool = false


func _ready() -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(HALF_X * 2.0, 0.04, HALF_Z * 2.0)
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.03, 0.035, 0.04, 0.92)
	mesh_instance.material_override = material
	add_child(mesh_instance)
	visible = false


func activate(at: Vector3) -> void:
	active = true
	visible = true
	global_position = at


func deactivate() -> void:
	active = false
	visible = false


func overlaps(point: Vector3, body_half: Vector2) -> bool:
	if not active:
		return false
	var separated_x := absf(point.x - global_position.x) >= HALF_X + body_half.x
	var separated_z := absf(point.z - global_position.z) >= HALF_Z + body_half.y
	return not separated_x and not separated_z
