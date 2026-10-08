class_name VehicleVisual
extends RefCounted

const BODY_COLOR := Color(1, 1, 1, 1)
const TARGET_LENGTH := 4.0
const WHEEL_RADIUS := 0.45

const PLAYER_MODEL: PackedScene = preload("res://assets/kenney/cars/sedan-sports.glb")

const WHEEL_NAMES := {
	"wheel-front-left": "WheelFL",
	"wheel-front-right": "WheelFR",
	"wheel-back-left": "WheelRL",
	"wheel-back-right": "WheelRR",
}


static func build(parent: Node3D, model: PackedScene = null, with_boost: bool = true) -> MeshInstance3D:
	var packed: PackedScene = model if model != null else PLAYER_MODEL
	var root := packed.instantiate() as Node3D
	parent.add_child(root)
	var bounds := _bounds(root)
	var factor := TARGET_LENGTH / bounds.size.z
	root.scale = Vector3.ONE * factor
	root.position = Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z) * factor
	var body := root.find_child("body", true, false) as MeshInstance3D
	_reparent(body, parent)
	body.name = "Body"
	paint(body, BODY_COLOR)
	for source_name in WHEEL_NAMES:
		var wheel := root.find_child(source_name, true, false) as MeshInstance3D
		_reparent(wheel, parent)
		wheel.name = WHEEL_NAMES[source_name]
	if root.get_child_count() == 0:
		root.free()
	else:
		root.name = "Model"
	if with_boost:
		_exhaust(parent, "ExhaustL", Vector3(-0.42, 0.42, -2.15))
		_exhaust(parent, "ExhaustR", Vector3(0.42, 0.42, -2.15))
	return body


static func paint(body: MeshInstance3D, color: Color) -> void:
	var source := body.get_active_material(0) as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.42
	material.metallic = 0.18
	if source != null and source.albedo_texture != null:
		material.albedo_texture = source.albedo_texture
	body.material_override = material
	for child in body.get_children():
		var mesh_instance := child as MeshInstance3D
		if mesh_instance != null:
			mesh_instance.material_override = material


static func spin_wheels(vehicle: Node3D, speed_mps: float, delta: float) -> void:
	var angle := speed_mps / WHEEL_RADIUS * delta
	for child in vehicle.get_children():
		if str(child.name).begins_with("Wheel"):
			(child as Node3D).rotate_x(angle)


static func show_boost(vehicle: Node3D, enabled: bool) -> void:
	for node_name in ["ExhaustL", "ExhaustR"]:
		var exhaust := vehicle.get_node_or_null(node_name) as Node3D
		if exhaust != null:
			exhaust.visible = enabled


static func _reparent(node: Node3D, parent: Node3D) -> void:
	var transform := node.global_transform
	node.get_parent().remove_child(node)
	parent.add_child(node)
	node.global_transform = transform


static func _bounds(root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var piece := _to_root(root, mesh_instance) * mesh_instance.mesh.get_aabb()
		if first:
			box = piece
			first = false
		else:
			box = box.merge(piece)
	return box


static func _to_root(root: Node, node: Node) -> Transform3D:
	var xform := Transform3D.IDENTITY
	var current := node
	while current != root and current is Node3D:
		xform = (current as Node3D).transform * xform
		current = current.get_parent()
	return xform


static func _exhaust(parent: Node3D, node_name: String, at: Vector3) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.16, 0.16, 0.85)
	mesh_instance.mesh = mesh
	mesh_instance.position = at
	mesh_instance.visible = false
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.42, 0.08, 0.9)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.38, 0.05)
	material.emission_energy_multiplier = 3.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
