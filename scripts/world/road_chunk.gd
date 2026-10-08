class_name RoadChunk
extends Node3D

const LENGTH := 40.0
const ASPHALT := Color(0.16, 0.18, 0.2)
const PAINT := Color(0.9, 0.88, 0.84)


func _ready() -> void:
	_add_box(Vector3(0.0, 0.0, LENGTH * 0.5), Vector3(14.0, 0.1, LENGTH), ASPHALT)
	_add_box(Vector3(-6.0, 0.02, LENGTH * 0.5), Vector3(0.12, 0.04, LENGTH), PAINT)
	_add_box(Vector3(6.0, 0.02, LENGTH * 0.5), Vector3(0.12, 0.04, LENGTH), PAINT)
	var dash_z := 1.0
	while dash_z < LENGTH:
		_add_box(Vector3(-2.0, 0.02, dash_z), Vector3(0.12, 0.04, 2.0), PAINT)
		_add_box(Vector3(2.0, 0.02, dash_z), Vector3(0.12, 0.04, 2.0), PAINT)
		dash_z += 4.0


func _add_box(at: Vector3, size: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.material_override = material
	add_child(mesh_instance)
