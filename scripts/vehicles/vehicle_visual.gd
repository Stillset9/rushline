class_name VehicleVisual
extends RefCounted

const BODY_COLOR := Color("e8e4dc")
const WHEEL_COLOR := Color("1a1a1a")


static func build(parent: Node3D) -> MeshInstance3D:
	var body := _box("Body", Vector3(0.0, 0.55, 0.0), Vector3(1.8, 0.5, 4.0), BODY_COLOR)
	parent.add_child(body)
	var offsets: Array[Vector3] = [
		Vector3(-0.85, 0.33, 1.4),
		Vector3(0.85, 0.33, 1.4),
		Vector3(-0.85, 0.33, -1.4),
		Vector3(0.85, 0.33, -1.4),
	]
	var wheel_names: Array[String] = ["WheelFL", "WheelFR", "WheelRL", "WheelRR"]
	for i in offsets.size():
		parent.add_child(_cylinder(wheel_names[i], offsets[i]))
	return body


static func _box(node_name: String, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = at
	mesh_instance.material_override = _material(color)
	return mesh_instance


static func _cylinder(node_name: String, at: Vector3) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.28
	mesh.bottom_radius = 0.28
	mesh.height = 0.2
	mesh_instance.mesh = mesh
	mesh_instance.position = at
	mesh_instance.rotation.z = PI / 2.0
	mesh_instance.material_override = _material(WHEEL_COLOR)
	return mesh_instance


static func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material
