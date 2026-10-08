class_name StreetDressing
extends Node3D

const CROSSING: PackedScene = preload("res://assets/kenney/roads/road-crossing.glb")
const LAMP: PackedScene = preload("res://assets/kenney/roads/light-curved.glb")
const PALM: PackedScene = preload("res://assets/kenney/nature/tree_palmTall.glb")
const TREE: PackedScene = preload("res://assets/kenney/nature/tree_default.glb")
const PINE: PackedScene = preload("res://assets/kenney/nature/tree_pineDefaultA.glb")
const CACTUS: PackedScene = preload("res://assets/kenney/nature/cactus_tall.glb")
const CACTUS_SHORT: PackedScene = preload("res://assets/kenney/nature/cactus_short.glb")
const ROCK: PackedScene = preload("res://assets/kenney/nature/rock_largeA.glb")
const BUILDINGS: Array[PackedScene] = [
	preload("res://assets/kenney/buildings/building-a.glb"),
	preload("res://assets/kenney/buildings/low-detail-building-a.glb"),
	preload("res://assets/kenney/buildings/low-detail-building-b.glb"),
	preload("res://assets/kenney/buildings/building-skyscraper-a.glb"),
	preload("res://assets/kenney/buildings/low-detail-building-c.glb"),
	preload("res://assets/kenney/buildings/low-detail-building-wide-a.glb"),
]

const GROUND := {
	"ciudad": Color(0.14, 0.15, 0.13),
	"costa": Color(0.74, 0.66, 0.42),
	"desierto": Color(0.78, 0.58, 0.3),
	"bosque": Color(0.18, 0.3, 0.14),
	"nieve": Color(0.86, 0.89, 0.92),
	"atardecer": Color(0.2, 0.12, 0.1),
	"industrial": Color(0.15, 0.15, 0.13),
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
	_slab(block, Vector3(-8.4, 0.1, 20.0), Vector3(2.6, 0.1, 40.0), Color(0.62, 0.63, 0.61))
	_slab(block, Vector3(8.4, 0.1, 20.0), Vector3(2.6, 0.1, 40.0), Color(0.62, 0.63, 0.61))
	var city := _group(block, "City")
	if index % 2 == 0:
		_fit(city, CROSSING, Vector3(0.0, 0.16, 18.0), Vector3(12.0, 0.02, 3.0))
	_stand(city, LAMP, Vector3(-8.9, 0.0, 6.0), 6.2, PI, false)
	_stand(city, LAMP, Vector3(8.9, 0.0, 26.0), 6.2, 0.0, false)
	var spots: Array[Vector3] = [
		Vector3(-16.0, 0.0, 10.0),
		Vector3(-18.5, 0.0, 28.0),
		Vector3(16.0, 0.0, 14.0),
		Vector3(18.5, 0.0, 32.0),
	]
	var heights: Array[float] = [12.0, 18.0, 14.0, 22.0]
	for spot in spots.size():
		var scene: PackedScene = BUILDINGS[(index + spot * 2) % BUILDINGS.size()]
		_stand(city, scene, spots[spot], heights[spot], 0.0 if spots[spot].x > 0.0 else PI, false)
	var palms := _group(block, "Palms")
	_stand(palms, PALM, Vector3(-12.0, 0.0, 8.0), 11.0, 0.4, true)
	_stand(palms, PALM, Vector3(12.5, 0.0, 24.0), 13.0, -0.6, true)
	_stand(palms, PALM, Vector3(-13.5, 0.0, 32.0), 10.0, 1.2, true)
	palms.visible = false
	var desert := _group(block, "Desert")
	_stand(desert, CACTUS, Vector3(-12.0, 0.0, 12.0), 4.5, 0.2, true)
	_stand(desert, CACTUS_SHORT, Vector3(13.0, 0.0, 22.0), 3.2, 1.0, true)
	_stand(desert, ROCK, Vector3(-14.0, 0.0, 30.0), 2.4, 0.5, true)
	_stand(desert, ROCK, Vector3(15.0, 0.0, 8.0), 2.8, -0.4, true)
	desert.visible = false
	var forest := _group(block, "Forest")
	_stand(forest, TREE, Vector3(-12.0, 0.0, 8.0), 9.0, 0.3, true)
	_stand(forest, TREE, Vector3(12.5, 0.0, 18.0), 11.0, 1.1, true)
	_stand(forest, PINE, Vector3(-14.0, 0.0, 28.0), 12.0, 0.0, true)
	_stand(forest, TREE, Vector3(14.5, 0.0, 34.0), 8.0, -0.7, true)
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


func _slab(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
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
