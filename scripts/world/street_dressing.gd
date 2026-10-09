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
}

var _blocks: Array[Node3D] = []


func _ready() -> void:
	for index in RoadStreamer.CHUNK_COUNT:
		var block := _make_block(index)
		add_child(block)
		_blocks.append(block)


func follow(chunk_origins: Array) -> void:
	for index in _blocks.size():
		_blocks[index].position = Vector3(0.0, 0.0, float(chunk_origins[index]))


func apply_place(theme_id: String) -> void:
	var city := theme_id == "ciudad" or theme_id == "atardecer" or theme_id == "industrial"
	var ground_color: Color = GROUND.get(theme_id, GROUND["ciudad"])
	for block in _blocks:
		block.get_node("City").visible = city
		block.get_node("Palms").visible = theme_id == "costa"
		block.get_node("Desert").visible = theme_id == "desierto"
		block.get_node("Forest").visible = theme_id == "bosque"
		block.get_node("Snow").visible = theme_id == "nieve"
		var ground := block.get_node("Ground") as MeshInstance3D
		(ground.material_override as StandardMaterial3D).albedo_color = ground_color


func _make_block(index: int) -> Node3D:
	var block := Node3D.new()
	var ground := _slab(block, Vector3(0.0, -0.08, 20.0), Vector3(80.0, 0.16, 40.0), GROUND["ciudad"])
	ground.name = "Ground"
	_slab(block, Vector3(-8.4, 0.1, 20.0), Vector3(2.6, 0.1, 40.0), Color(0.78, 0.78, 0.76), SIDEWALK_TEX)
	_slab(block, Vector3(8.4, 0.1, 20.0), Vector3(2.6, 0.1, 40.0), Color(0.78, 0.78, 0.76), SIDEWALK_TEX)
	_stripe(block, -7.05)
	_stripe(block, 7.05)
	var city := _group(block, "City")
	if index % 2 == 0:
		_fit(city, CROSSING, Vector3(0.0, 0.16, 18.0), Vector3(12.0, 0.02, 3.0))
	_stand(city, LAMP, Vector3(-8.9, 0.0, 6.0), 6.2, PI, false)
	_stand(city, LAMP, Vector3(8.9, 0.0, 26.0), 6.2, 0.0, false)
	for step in 4:
		var rail_z := 5.0 + float(step) * 10.0
		_fit(city, BARRIER, Vector3(-7.35, 0.42, rail_z), Vector3(0.28, 0.75, 9.2))
		_fit(city, BARRIER, Vector3(7.35, 0.42, rail_z), Vector3(0.28, 0.75, 9.2))
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
		Vector3(-13.2, 0.0, 6.0),
		Vector3(-16.4, 0.0, 20.0),
		Vector3(-13.6, 0.0, 34.0),
		Vector3(13.2, 0.0, 8.0),
		Vector3(16.4, 0.0, 22.0),
		Vector3(13.6, 0.0, 36.0),
	]
	var heights: Array[float] = [14.0, 24.0, 11.0, 16.0, 28.0, 13.0]
	for spot in spots.size():
		var scene: PackedScene = BUILDINGS[(index + spot * 2) % BUILDINGS.size()]
		_stand(city, scene, spots[spot], heights[spot], 0.0 if spots[spot].x > 0.0 else PI, false)
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
	return block


func _group(parent: Node3D, node_name: String) -> Node3D:
	var group := Node3D.new()
	group.name = node_name
	parent.add_child(group)
	return group


func _stripe(parent: Node3D, x: float) -> void:
	var mesh_instance := _slab(parent, Vector3(x, 0.08, 20.0), Vector3(0.14, 0.025, 40.0), Color(0.74, 0.96, 1.0))
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


func _stand(parent: Node3D, scene: PackedScene, at: Vector3, height: float, yaw: float, matte: bool) -> void:
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
