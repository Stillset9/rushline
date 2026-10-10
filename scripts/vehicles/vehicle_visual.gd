class_name VehicleVisual
extends RefCounted

const BODY_COLOR := Color(1, 1, 1, 1)
const TARGET_LENGTH := 4.0
const WHEEL_RADIUS := 0.45

const PLAYER_MODEL: PackedScene = preload("res://assets/vehicles/sports-car.glb")


static func build(parent: Node3D, model: PackedScene = null, with_boost: bool = true) -> MeshInstance3D:
	var packed: PackedScene = model if model != null else PLAYER_MODEL
	var root := packed.instantiate() as Node3D
	parent.add_child(root)
	var bounds := _bounds(root)
	var factor := TARGET_LENGTH / bounds.size.z
	root.scale = Vector3.ONE * factor
	root.position = Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z) * factor
	var body := _find_body(root)
	_reparent(body, parent)
	body.name = "Body"
	paint(body, BODY_COLOR)
	_take_wheels(root, parent)
	_paint_shell(root, body)
	if root.get_child_count() == 0:
		root.free()
	else:
		root.name = "Model"
	_lamps(parent, body, with_boost)
	if with_boost:
		_boost_fx(parent, body)
		_impact(parent)
	return body


static func paint(body: MeshInstance3D, color: Color) -> void:
	var source := body.get_active_material(0) as StandardMaterial3D
	var material := StandardMaterial3D.new()
	if source != null and source.albedo_texture != null:
		material = source.duplicate() as StandardMaterial3D
	else:
		material.roughness = 0.22
		material.metallic = 0.42
	if _clearcoat_ok():
		material.clearcoat_enabled = true
		material.clearcoat = 0.55
		material.clearcoat_roughness = 0.18
	material.albedo_color = color
	body.material_override = material
	for child in body.get_children():
		var mesh_instance := child as MeshInstance3D
		if mesh_instance != null and not _is_glass(str(mesh_instance.name)):
			mesh_instance.material_override = material


static func spin_wheels(vehicle: Node3D, speed_mps: float, delta: float, steer: float = 0.0) -> void:
	var angle := speed_mps / WHEEL_RADIUS * delta
	var yaw := clampf(steer, -1.0, 1.0) * 0.38
	for child in vehicle.get_children():
		var node := child as Node3D
		if node == null or not str(node.name).begins_with("Wheel"):
			continue
		node.rotate_x(angle)
		if str(node.name).begins_with("WheelF"):
			var euler := node.rotation
			euler.y = yaw
			node.rotation = euler


static func show_brake(vehicle: Node3D, braking: bool) -> void:
	var energy := 3.4 if braking else 0.7
	for node_name in ["TailL", "TailR"]:
		var lamp := vehicle.get_node_or_null(node_name) as MeshInstance3D
		if lamp != null and lamp.material_override is StandardMaterial3D:
			(lamp.material_override as StandardMaterial3D).emission_energy_multiplier = energy


static func show_boost(vehicle: Node3D, enabled: bool) -> void:
	for child in vehicle.get_children():
		if str(child.name).begins_with("Exhaust"):
			(child as Node3D).visible = enabled


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


static func _find_body(root: Node) -> MeshInstance3D:
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var node_name := str(node.name).to_lower()
		if node_name == "body" or node_name.ends_with("_body"):
			return node
	return null


static func _take_wheels(root: Node3D, parent: Node3D) -> void:
	var found: Array[MeshInstance3D] = []
	for node in root.find_children("*", "MeshInstance3D", true, false):
		if _wheel_name(str(node.name)) != "":
			found.append(node)
	for wheel in found:
		var mapped := _wheel_name(str(wheel.name))
		_reparent(wheel, parent)
		wheel.name = mapped


static func _wheel_name(source: String) -> String:
	var node_name := source.to_lower()
	if "front-left" in node_name or "front_l" in node_name or node_name.ends_with("_fl"):
		return "WheelFL"
	if "front-right" in node_name or "front_r" in node_name or node_name.ends_with("_fr"):
		return "WheelFR"
	if "back-left" in node_name or "rear_l" in node_name or node_name.ends_with("_rl"):
		return "WheelRL"
	if "back-right" in node_name or "rear_r" in node_name or node_name.ends_with("_rr"):
		return "WheelRR"
	return ""


static func _paint_shell(root: Node, body: MeshInstance3D) -> void:
	if body == null or body.material_override == null:
		return
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var node_name := str(node.name).to_lower()
		if _is_glass(node_name) or "light" in node_name or "wheel" in node_name:
			continue
		if "tail" in node_name or "spoiler" in node_name or node_name.ends_with("_body"):
			(node as MeshInstance3D).material_override = body.material_override


static func _is_glass(node_name: String) -> bool:
	var lower := node_name.to_lower()
	return "window" in lower or "glass" in lower


static func _shell_point(body: MeshInstance3D, local: Vector3) -> Vector3:
	return body.transform * local


static func set_headlights(vehicle: Node3D, night: bool, spots: bool) -> void:
	for node_name in ["HeadL", "HeadR"]:
		var lamp := vehicle.get_node_or_null(node_name) as MeshInstance3D
		if lamp != null and lamp.material_override is StandardMaterial3D:
			(lamp.material_override as StandardMaterial3D).emission_energy_multiplier = 8.5 if night else 1.5
		var spot := vehicle.get_node_or_null(node_name + "Spot") as SpotLight3D
		if spot != null:
			spot.visible = night and spots
	for node_name in ["TailL", "TailR"]:
		var lamp := vehicle.get_node_or_null(node_name) as MeshInstance3D
		if lamp != null and lamp.material_override is StandardMaterial3D:
			(lamp.material_override as StandardMaterial3D).emission_energy_multiplier = 2.4 if night else 0.7


static func _clearcoat_ok() -> bool:
	return DisplayServer.get_name() != "headless" and RenderingServer.get_current_rendering_method() == "forward_plus" and not OS.has_feature("web")


static func _lamps(parent: Node3D, body: MeshInstance3D, with_spots: bool) -> void:
	var box := body.mesh.get_aabb()
	var y := box.position.y + box.size.y * 0.30
	var half_x := minf(0.58, box.size.x * 0.27)
	var nose := box.position.z + box.size.z - 0.72
	var tail := box.position.z + 0.62
	_lamp(parent, "HeadL", _shell_point(body, Vector3(-half_x, y, nose)), Color(1.0, 0.94, 0.75), Color(1.0, 0.9, 0.6), 1.6, with_spots)
	_lamp(parent, "HeadR", _shell_point(body, Vector3(half_x, y, nose)), Color(1.0, 0.94, 0.75), Color(1.0, 0.9, 0.6), 1.6, with_spots)
	_lamp(parent, "TailL", _shell_point(body, Vector3(-half_x, y, tail)), Color(0.85, 0.05, 0.04), Color(1.0, 0.08, 0.05), 0.7, false)
	_lamp(parent, "TailR", _shell_point(body, Vector3(half_x, y, tail)), Color(0.85, 0.05, 0.04), Color(1.0, 0.08, 0.05), 0.7, false)


static func _lamp(parent: Node3D, node_name: String, at: Vector3, albedo: Color, emission: Color, energy: float, with_spot: bool) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.2, 0.07, 0.05)
	mesh_instance.mesh = mesh
	mesh_instance.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = energy
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	if not with_spot:
		return
	var spot := SpotLight3D.new()
	spot.name = node_name + "Spot"
	spot.position = at
	spot.rotation.y = PI
	spot.spot_range = 34.0
	spot.spot_angle = 22.0
	spot.spot_attenuation = 0.7
	spot.light_energy = 7.5
	spot.light_color = Color(1.0, 0.93, 0.78)
	spot.shadow_enabled = false
	spot.visible = false
	parent.add_child(spot)


static func _boost_fx(parent: Node3D, body: MeshInstance3D) -> void:
	var box := body.mesh.get_aabb()
	var y := box.position.y + box.size.y * 0.28
	var tail := box.position.z - 0.35
	var span := box.size.x * 0.28
	_boost_side(parent, body, "L", -span, y, tail)
	_boost_side(parent, body, "R", span, y, tail)


static func _boost_side(parent: Node3D, body: MeshInstance3D, side: String, x: float, y: float, tail: float) -> void:
	var origin := _shell_point(body, Vector3(x, y, tail))
	_exhaust(parent, "Exhaust" + side, origin, Vector3(0.16, 0.16, 1.15), Color(1.0, 0.42, 0.08, 0.75), Color(1.0, 0.28, 0.04), 2.4)
	_exhaust(parent, "ExhaustCore" + side, origin + Vector3(0.0, 0.02, -0.28), Vector3(0.06, 0.06, 1.45), Color(0.85, 0.96, 1.0, 0.9), Color(0.75, 0.95, 1.0), 4.0)


static func _exhaust(parent: Node3D, node_name: String, at: Vector3, size: Vector3, albedo: Color, emission: Color, energy: float) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = at
	mesh_instance.visible = false
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = energy
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)


static func _impact(parent: Node3D) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Impact"
	mesh_instance.visible = false
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.85
	mesh.outer_radius = 1.25
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3(0.0, 0.55, 0.2)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.55, 0.16, 0.55)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(1.0, 0.42, 0.08)
	material.emission_energy_multiplier = 2.2
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	_burst(parent, "Sparks", Color(1.0, 0.74, 0.28, 1.0), 26, 0.04, Vector3(0.0, -4.0, 0.0), 12.0, 0.32, 0.95)
	_burst(parent, "Smoke", Color(0.62, 0.62, 0.64, 0.4), 16, 0.28, Vector3(0.0, 2.2, 0.0), 2.8, 0.85, 0.4)


static func _burst(parent: Node3D, node_name: String, color: Color, amount: int, radius: float, gravity: Vector3, speed: float, life: float, explosiveness: float) -> void:
	var particles := CPUParticles3D.new()
	particles.name = node_name
	particles.emitting = false
	particles.one_shot = true
	particles.amount = amount
	particles.lifetime = life
	particles.explosiveness = explosiveness
	particles.randomness = 0.4
	particles.direction = Vector3(0.0, 0.35, -0.15)
	particles.spread = 55.0
	particles.gravity = gravity
	particles.initial_velocity_min = speed * 0.45
	particles.initial_velocity_max = speed
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	particles.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b)
	material.emission_energy_multiplier = 2.2 if radius < 0.1 else 0.2
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	particles.material_override = material
	parent.add_child(particles)
