class_name RoadChunk
extends Node3D

const LENGTH := 40.0
const ASPHALT := Color(0.16, 0.18, 0.2)
const PAINT := Color(0.9, 0.88, 0.84)
const ASPHALT_TEX: Texture2D = preload("res://assets/world/asphalt_diff.jpg")


func _ready() -> void:
	# El asfalto se solapa con el tramo siguiente para que la curva no abra una grieta.
	_add_box(Vector3(0.0, 0.0, LENGTH * 0.5), Vector3(14.0, 0.1, LENGTH + 8.0), ASPHALT)
	# La pintura debe quedar sobre el asfalto; si no, queda oculta bajo la losa.
	_add_box(Vector3(-6.0, 0.06, LENGTH * 0.5), Vector3(0.12, 0.02, LENGTH), PAINT)
	_add_box(Vector3(6.0, 0.06, LENGTH * 0.5), Vector3(0.12, 0.02, LENGTH), PAINT)
	var dash_z := 1.0
	while dash_z < LENGTH:
		_add_box(Vector3(-2.0, 0.06, dash_z), Vector3(0.12, 0.02, 2.0), PAINT)
		_add_box(Vector3(2.0, 0.06, dash_z), Vector3(0.12, 0.02, 2.0), PAINT)
		dash_z += 4.0


func _add_box(at: Vector3, size: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = at
	var material := StandardMaterial3D.new()
	var wide := size.x > 1.0
	material.albedo_color = color
	material.roughness = 0.9 if wide else 0.4
	if not wide:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.55
	if wide:
		material.albedo_texture = ASPHALT_TEX
		material.uv1_triplanar = true
		material.uv1_scale = Vector3(0.33, 0.33, 0.33)
	mesh_instance.material_override = material
	add_child(mesh_instance)


func set_playable(half: float) -> void:
	var edge := maxf(3.2, half)
	var asphalt_width := edge * 2.0 + 2.0
	for child in get_children():
		var mesh_instance := child as MeshInstance3D
		if mesh_instance == null:
			continue
		var box := mesh_instance.mesh as BoxMesh
		if box == null:
			continue
		if box.size.x > 2.0:
			box.size = Vector3(asphalt_width, box.size.y, box.size.z)
		elif box.size.z >= LENGTH - 0.1 and absf(mesh_instance.position.x) > 1.0:
			mesh_instance.position.x = signf(mesh_instance.position.x) * edge


func apply_wet(amount: float) -> void:
	for child in get_children():
		var mesh_instance := child as MeshInstance3D
		if mesh_instance == null:
			continue
		var box := mesh_instance.mesh as BoxMesh
		var material := mesh_instance.material_override as StandardMaterial3D
		if box == null or material == null or box.size.x < 2.0:
			continue
		material.roughness = lerpf(0.88, 0.06, amount)
		material.metallic = lerpf(0.04, 0.66, amount)
		material.metallic_specular = lerpf(0.2, 0.8, amount)


func apply_palette(asphalt: Color, paint: Color) -> void:
	for child in get_children():
		var mesh_instance := child as MeshInstance3D
		if mesh_instance == null:
			continue
		var box := mesh_instance.mesh as BoxMesh
		var material := mesh_instance.material_override as StandardMaterial3D
		if box == null or material == null:
			continue
		var wide := box.size.x > 1.0
		material.albedo_color = asphalt if wide else paint
		if not wide:
			material.emission_enabled = true
			material.emission = paint
			material.emission_energy_multiplier = 0.55
