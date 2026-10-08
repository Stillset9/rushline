extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var player: Node3D = load("res://scenes/vehicles/player_vehicle.tscn").instantiate()
	tree.root.add_child(player)
	var body := player.get_node_or_null("Body") as MeshInstance3D
	if body == null or body.mesh == null:
		failed.append("missing body")
		return failed
	if body.mesh.get_aabb().size.z < 2.0:
		failed.append("body length %s" % body.mesh.get_aabb().size)
	var paint: Color = body.material_override.albedo_color
	if paint != VehicleVisual.BODY_COLOR:
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
	player.position.x = 0.0
	player.lateral_speed_mps = 0.0
	player.read_input_devices = true
	Input.action_press("steer_right")
	player.tick(0.2)
	Input.action_release("steer_right")
	if player.position.x >= 0.0:
		failed.append("D should move right, x %s" % player.position.x)
	player.position.x = 0.0
	player.lateral_speed_mps = 0.0
	Input.action_press("steer_left")
	player.tick(0.2)
	Input.action_release("steer_left")
	if player.position.x <= 0.0:
		failed.append("A should move left, x %s" % player.position.x)
	player.queue_free()
	return failed
