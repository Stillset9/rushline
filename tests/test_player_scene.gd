extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var player: Node3D = load("res://scenes/vehicles/player_vehicle.tscn").instantiate()
	tree.root.add_child(player)
	var body := player.get_node_or_null("Body") as MeshInstance3D
	if body == null or body.mesh == null:
		failed.append("missing body")
		return failed
	var size: Vector3 = (body.mesh as BoxMesh).size
	if not size.is_equal_approx(Vector3(1.8, 0.5, 4.0)):
		failed.append("body size %s" % size)
	var paint: Color = body.material_override.albedo_color
	if paint != Color("e8e4dc"):
		failed.append("body color %s" % paint)
	if player.get_children().filter(func(node: Node) -> bool: return str(node.name).begins_with("Wheel")).size() != 4:
		failed.append("wheel count")
	player.read_input_devices = false
	player.brake_input = false
	player.steer_input = 0.0
	player.max_speed_mps = 30.0
	player.tick(1.0)
	if not is_equal_approx(player.speed_mps, 16.0):
		failed.append("tick speed %s" % player.speed_mps)
	if not is_equal_approx(player.position.z, 16.0):
		failed.append("tick z %s" % player.position.z)
	player.steer_input = -1.0
	player.tick(0.1)
	if player.position.x >= 0.0:
		failed.append("tick x %s" % player.position.x)
	player.queue_free()
	return failed
