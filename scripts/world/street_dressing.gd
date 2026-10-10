class_name StreetDressing
extends Node3D

const CROSSING: PackedScene = preload("res://assets/kenney/roads/road-crossing.glb")
const LAMP: PackedScene = preload("res://assets/kenney/roads/light-curved.glb")
const BARRIER: PackedScene = preload("res://assets/kenney/roads/road-straight-barrier.glb")
const SIGN: PackedScene = preload("res://assets/kenney/roads/road-sign-warning.glb")
const HIGHWAY: PackedScene = preload("res://assets/kenney/roads/sign-highway.glb")
const TRAFFIC_LIGHT: PackedScene = preload("res://assets/kenney/roads/traffic-light.glb")
const DUMPSTER: PackedScene = preload("res://assets/kenney/roads/dumpster.glb")
const BRIDGE: PackedScene = preload("res://assets/kenney/roads/road-bridge.glb")
const PALM: PackedScene = preload("res://assets/kenney/nature/tree_palmDetailedTall.glb")
const TREE: PackedScene = preload("res://assets/kenney/nature/tree_detailed.glb")
const OAK: PackedScene = preload("res://assets/kenney/nature/tree_oak.glb")
const PINE: PackedScene = preload("res://assets/kenney/nature/tree_pineRoundA.glb")
const PINE_TALL: PackedScene = preload("res://assets/kenney/nature/tree_pineDefaultB.glb")
const BUSH: PackedScene = preload("res://assets/kenney/nature/plant_bushDetailed.glb")
const CACTUS: PackedScene = preload("res://assets/kenney/nature/cactus_tall.glb")
const CACTUS_SHORT: PackedScene = preload("res://assets/kenney/nature/cactus_short.glb")
const ROCK: PackedScene = preload("res://assets/kenney/nature/rock_largeA.glb")
const SIDEWALK_TEX: Texture2D = preload("res://assets/world/concrete_diff.jpg")
const BUILDINGS: Array[PackedScene] = [
	preload("res://assets/kenney/buildings/building-a.glb"),
	preload("res://assets/kenney/buildings/building-c.glb"),
	preload("res://assets/kenney/buildings/building-e.glb"),
	preload("res://assets/kenney/buildings/building-g.glb"),
	preload("res://assets/kenney/buildings/building-j.glb"),
	preload("res://assets/kenney/buildings/building-n.glb"),
	preload("res://assets/kenney/buildings/building-skyscraper-a.glb"),
	preload("res://assets/kenney/buildings/building-skyscraper-b.glb"),
	preload("res://assets/kenney/buildings/building-skyscraper-c.glb"),
	preload("res://assets/kenney/buildings/building-skyscraper-d.glb"),
]

const GROUND := {
	"ciudad": Color(0.09, 0.1, 0.09),
	"costa": Color(0.62, 0.52, 0.32),
	"desierto": Color(0.72, 0.5, 0.24),
	"bosque": Color(0.1, 0.18, 0.08),
	"nieve": Color(0.78, 0.82, 0.86),
	"atardecer": Color(0.12, 0.07, 0.06),
	"industrial": Color(0.1, 0.1, 0.09),
	"noche": Color(0.03, 0.035, 0.04),
}

const ROAD_CLEAR := 20.0
const TOWER_CLEAR := 34.0

var _blocks: Array[Node3D] = []
var _fill: MeshInstance3D
var _lamps: Array[OmniLight3D] = []
var _night := false


func _ready() -> void:
	_fill = _slab(self, Vector3(0.0, -0.2, 0.0), Vector3(900.0, 0.2, 900.0), GROUND["ciudad"])
	_fill.name = "Fill"
	for index in RoadStreamer.CHUNK_COUNT:
		var block := _make_block(index)
		add_child(block)
		_blocks.append(block)
	for _i in 4:
		var lamp := OmniLight3D.new()
		lamp.shadow_enabled = false
		lamp.omni_range = 24.0
		lamp.omni_attenuation = 1.35
		lamp.light_energy = 1.35
		lamp.light_color = Color(1.0, 0.78, 0.48)
		lamp.light_specular = 0.08
		lamp.visible = false
		add_child(lamp)
		_lamps.append(lamp)


func follow(chunk_origins: Array) -> void:
	for index in _blocks.size():
		CoursePath.place_span(_blocks[index], float(chunk_origins[index]), RoadStreamer.CHUNK_LENGTH)
	if chunk_origins.is_empty() or _fill == null:
		return
	var mid := CoursePath.pose(float(chunk_origins[chunk_origins.size() / 2]) + RoadStreamer.CHUNK_LENGTH * 0.5, 0.0)
	var point: Vector3 = mid.position
	_fill.position = Vector3(point.x, -0.2, point.z)
	_place_lamps(float(chunk_origins[0]))


func apply_place(theme_id: String) -> void:
	var city := theme_id == "ciudad" or theme_id == "atardecer" or theme_id == "industrial" or theme_id == "noche"
	var ground_color: Color = GROUND.get(theme_id, GROUND["ciudad"])
	for block in _blocks:
		block.get_node("City").visible = city
		block.get_node("Palms").visible = theme_id == "costa"
		block.get_node("Desert").visible = theme_id == "desierto"
		block.get_node("Forest").visible = theme_id == "bosque"
		block.get_node("Snow").visible = theme_id == "nieve"
		var ground := block.get_node("Ground") as MeshInstance3D
		(ground.material_override as StandardMaterial3D).albedo_color = ground_color
	if _fill != null:
		(_fill.material_override as StandardMaterial3D).albedo_color = ground_color


func _make_block(index: int) -> Node3D:
	var block := Node3D.new()
	var ground := _slab(block, Vector3(0.0, -0.08, 20.0), Vector3(80.0, 0.16, 56.0), GROUND["ciudad"])
	ground.name = "Ground"
	_slab(block, Vector3(-15.2, 0.12, 20.0), Vector3(6.2, 0.12, 48.0), Color(0.78, 0.78, 0.76), SIDEWALK_TEX)
	_slab(block, Vector3(15.2, 0.12, 20.0), Vector3(6.2, 0.12, 48.0), Color(0.78, 0.78, 0.76), SIDEWALK_TEX)
	_stripe(block, -11.8)
	_stripe(block, 11.8)
	var city := _group(block, "City")
	if index % 2 == 0:
		_fit(city, CROSSING, Vector3(0.0, 0.16, 18.0), Vector3(12.0, 0.02, 3.0))
	_stand(city, LAMP, Vector3(-12.2, 0.0, 6.0), 6.2, PI, false)
	_stand(city, LAMP, Vector3(12.2, 0.0, 26.0), 6.2, 0.0, false)
	for step in 4:
		var rail_z := 5.0 + float(step) * 10.0
		_fit(city, BARRIER, Vector3(-9.6, 0.42, rail_z), Vector3(0.28, 0.75, 9.2))
		_fit(city, BARRIER, Vector3(9.6, 0.42, rail_z), Vector3(0.28, 0.75, 9.2))
	_stand(city, SIGN, Vector3(-9.35, 0.0, 14.0), 2.3, PI, false)
	_stand(city, SIGN, Vector3(9.35, 0.0, 30.0), 2.3, 0.0, false)
	_stand(city, HIGHWAY, Vector3(11.2, 0.0, 4.0), 5.2, 0.0, false)
	_stand(city, DUMPSTER, Vector3(-11.0, 0.0, 16.0), 1.35, 0.3, false)
	if index % 2 == 0:
		_stand(city, TRAFFIC_LIGHT, Vector3(-8.8, 0.0, 15.2), 3.6, PI, false)
		_stand(city, TRAFFIC_LIGHT, Vector3(8.8, 0.0, 21.0), 3.6, 0.0, false)
	if index % 4 == 1:
		_fit(city, BRIDGE, Vector3(24.0, 3.4, 20.0), Vector3(8.0, 2.4, 18.0))
		_fit(city, BRIDGE, Vector3(-24.0, 3.4, 20.0), Vector3(8.0, 2.4, 18.0))
	var spots: Array[Vector3] = [
		Vector3(-24.0, 0.0, 6.0),
		Vector3(-30.0, 0.0, 20.0),
		Vector3(-24.5, 0.0, 34.0),
		Vector3(24.0, 0.0, 8.0),
		Vector3(30.0, 0.0, 22.0),
		Vector3(24.5, 0.0, 36.0),
	]
	var heights: Array[float] = [14.0, 24.0, 11.0, 16.0, 28.0, 13.0]
	for spot in spots.size():
		var scene: PackedScene = BUILDINGS[(index + spot * 2) % BUILDINGS.size()]
		var facade := _stand(city, scene, spots[spot], heights[spot], 0.0 if spots[spot].x > 0.0 else PI, false)
		_tone_facade(facade)
	_neon(city, Vector3(-18.5, 7.2, 14.0), Color(0.15, 0.85, 1.0))
	_neon(city, Vector3(18.8, 8.4, 28.0), Color(1.0, 0.28, 0.55))
	_stand(city, TREE, Vector3(-17.4, 0.0, 18.0), 8.5, 0.4, true)
	_stand(city, PALM, Vector3(17.6, 0.0, 12.0), 9.0, 0.2, true)
	var palms := _group(block, "Palms")
	_stand(palms, PALM, Vector3(-12.0, 0.0, 8.0), 12.0, 0.4, true)
	_stand(palms, PALM, Vector3(12.5, 0.0, 18.0), 14.0, -0.6, true)
	_stand(palms, PALM, Vector3(-13.5, 0.0, 28.0), 11.0, 1.2, true)
	_stand(palms, PALM, Vector3(14.0, 0.0, 36.0), 13.0, 0.2, true)
	palms.visible = false
	var desert := _group(block, "Desert")
	_stand(desert, CACTUS, Vector3(-12.0, 0.0, 12.0), 4.5, 0.2, true)
	_stand(desert, CACTUS_SHORT, Vector3(13.0, 0.0, 22.0), 3.2, 1.0, true)
	_stand(desert, ROCK, Vector3(-14.0, 0.0, 30.0), 2.4, 0.5, true)
	_stand(desert, ROCK, Vector3(15.0, 0.0, 8.0), 2.8, -0.4, true)
	desert.visible = false
	var forest := _group(block, "Forest")
	var woods: Array[PackedScene] = [TREE, OAK, PINE, PINE_TALL, OAK, TREE]
	var wood_spots: Array[Vector3] = [
		Vector3(-12.0, 0.0, 6.0),
		Vector3(-15.5, 0.0, 18.0),
		Vector3(-12.8, 0.0, 30.0),
		Vector3(12.2, 0.0, 10.0),
		Vector3(15.0, 0.0, 22.0),
		Vector3(13.0, 0.0, 34.0),
	]
	for wood in woods.size():
		_stand(forest, woods[wood], wood_spots[wood], 10.0 + float(wood % 3) * 2.0, float(wood) * 0.4, true)
		_stand(forest, BUSH, wood_spots[wood] + Vector3(1.6 if wood_spots[wood].x > 0.0 else -1.6, 0.0, 2.0), 1.6, 0.2, true)
	forest.visible = false
	var snow := _group(block, "Snow")
	_stand(snow, PINE, Vector3(-12.0, 0.0, 10.0), 11.0, 0.2, true)
	_stand(snow, PINE, Vector3(13.0, 0.0, 22.0), 13.0, 0.8, true)
	_stand(snow, PINE, Vector3(-14.5, 0.0, 32.0), 9.0, -0.4, true)
	snow.visible = false
	for group_name in ["City", "Palms", "Desert", "Forest", "Snow"]:
		var group := block.get_node(group_name)
		for child in group.get_children():
			if child is Node3D:
				_keep_off_road(child as Node3D)
	return block


func blocks_path() -> bool:
	var origins: Array = []
	for index in _blocks.size():
		origins.append(480.0 + float(index) * 40.0)
	follow(origins)
	for block in _blocks:
		for group_name in ["City", "Palms", "Desert", "Forest", "Snow"]:
			var group := block.get_node(group_name)
			for child in group.get_children():
				var node := child as Node3D
				if node == null:
					continue
				var local := _bounds(node)
				if local.size.y < 4.0:
					continue
				var box := node.global_transform * local
				var along := 470.0
				while along < 820.0:
					var framed := CoursePath.pose(along, 0.0)
					var point: Vector3 = framed.position
					if _xz_gap(box, point) < 7.0:
						return true
					along += 8.0
	return false


func blocks_road() -> bool:
	for block in _blocks:
		for group_name in ["City", "Palms", "Desert", "Forest", "Snow"]:
			var group := block.get_node(group_name)
			for child in group.get_children():
				var node := child as Node3D
				if node == null:
					continue
				var local := _bounds(node)
				if local.size.y < 4.0:
					continue
				var box := node.transform * local
				var min_x := box.position.x
				var max_x := box.position.x + box.size.x
				var clear := _clearance(node)
				if min_x < clear and max_x > -clear:
					return true
	return false


func _xz_gap(box: AABB, point: Vector3) -> float:
	var dx := 0.0
	if point.x < box.position.x:
		dx = box.position.x - point.x
	elif point.x > box.position.x + box.size.x:
		dx = point.x - (box.position.x + box.size.x)
	var dz := 0.0
	if point.z < box.position.z:
		dz = box.position.z - point.z
	elif point.z > box.position.z + box.size.z:
		dz = point.z - (box.position.z + box.size.z)
	return Vector2(dx, dz).length()


func _keep_off_road(node: Node3D) -> void:
	var local := _bounds(node)
	if local.size.y < 1.2:
		return
	var box := node.transform * local
	var min_x := box.position.x
	var max_x := box.position.x + box.size.x
	var clear := _clearance(node)
	if min_x >= clear or max_x <= -clear:
		return
	if node.position.x >= 0.0:
		node.position.x += clear - min_x
	else:
		node.position.x -= max_x + clear


func set_night(active: bool) -> void:
	_night = active
	var count := GraphicsProfile.lamp_count() if active else 0
	for index in _lamps.size():
		_lamps[index].visible = index < count


func _place_lamps(origin: float) -> void:
	if _lamps.is_empty():
		return
	var count := GraphicsProfile.lamp_count() if _night else 0
	for index in _lamps.size():
		var lamp := _lamps[index]
		lamp.visible = index < count
		if not lamp.visible:
			continue
		var side := -1.0 if index % 2 == 0 else 1.0
		var along := origin + 8.0 + float(index) * 16.0
		var pose := CoursePath.pose(along, side * 12.4)
		var point: Vector3 = pose.position
		lamp.global_position = point + Vector3(0.0, 5.6, 0.0)


func _neon(parent: Node3D, at: Vector3, color: Color) -> void:
	_slab(parent, at + Vector3(0.0, 0.0, 0.08), Vector3(3.7, 1.4, 0.08), Color(0.02, 0.02, 0.03))
	var mesh_instance := _slab(parent, at, Vector3(3.2, 0.95, 0.06), color.darkened(0.35))
	var material := mesh_instance.material_override as StandardMaterial3D
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.55
	material.roughness = 0.4
	material.metallic = 0.05


func _clearance(node: Node3D) -> float:
	var local := _bounds(node)
	if local.size.y >= 18.0:
		return TOWER_CLEAR
	return ROAD_CLEAR


func _group(parent: Node3D, node_name: String) -> Node3D:
	var group := Node3D.new()
	group.name = node_name
	parent.add_child(group)
	return group


func _stripe(parent: Node3D, x: float) -> void:
	var mesh_instance := _slab(parent, Vector3(x, 0.08, 20.0), Vector3(0.14, 0.025, 48.0), Color(0.74, 0.96, 1.0))
	var material := mesh_instance.material_override as StandardMaterial3D
	material.emission_enabled = true
	material.emission = Color(0.45, 0.82, 1.0)
	material.emission_energy_multiplier = 0.8
	material.roughness = 0.35


func _slab(parent: Node3D, at: Vector3, size: Vector3, color: Color, texture: Texture2D = null) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92 if texture != null else 1.0
	if texture != null:
		material.albedo_texture = texture
		material.uv1_triplanar = true
		material.uv1_scale = Vector3(0.33, 0.33, 0.33)
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance


func _fit(parent: Node3D, scene: PackedScene, center: Vector3, size: Vector3) -> void:
	var node := scene.instantiate() as Node3D
	parent.add_child(node)
	var bounds := _bounds(node)
	node.scale = Vector3(size.x / bounds.size.x, size.y / bounds.size.y, size.z / bounds.size.z)
	node.position = center - Vector3(bounds.get_center().x * node.scale.x, bounds.get_center().y * node.scale.y, bounds.get_center().z * node.scale.z)


func _stand(parent: Node3D, scene: PackedScene, at: Vector3, height: float, yaw: float, matte: bool) -> Node3D:
	var node := scene.instantiate() as Node3D
	parent.add_child(node)
	var bounds := _bounds(node)
	var factor := height / bounds.size.y
	node.scale = Vector3.ONE * factor
	node.rotation.y = yaw
	var flat := Vector3(bounds.get_center().x, 0.0, bounds.get_center().z) * factor
	var rotated := flat.rotated(Vector3.UP, yaw)
	node.position = Vector3(at.x - rotated.x, -bounds.position.y * factor, at.z - rotated.z)
	if matte:
		_matte(node)
	return node


func _tone_facade(root: Node) -> void:
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		for surface in mesh_instance.mesh.get_surface_count():
			var source := mesh_instance.mesh.surface_get_material(surface) as StandardMaterial3D
			if source == null:
				continue
			var material := source.duplicate() as StandardMaterial3D
			material.albedo_color = Color(0.55, 0.62, 0.72)
			material.roughness = 0.78
			material.metallic = 0.0
			material.emission_enabled = false
			mesh_instance.set_surface_override_material(surface, material)


func _matte(root: Node) -> void:
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		for surface in mesh_instance.mesh.get_surface_count():
			var source := mesh_instance.mesh.surface_get_material(surface) as StandardMaterial3D
			if source == null:
				continue
			var material := source.duplicate() as StandardMaterial3D
			material.metallic = 0.0
			material.roughness = 0.86
			mesh_instance.set_surface_override_material(surface, material)


func _bounds(root: Node3D) -> AABB:
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


func _to_root(root: Node, node: Node) -> Transform3D:
	var xform := Transform3D.IDENTITY
	var current := node
	while current != root and current is Node3D:
		xform = (current as Node3D).transform * xform
		current = current.get_parent()
	return xform
