extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var slick := OilSlick.new()
	tree.root.add_child(slick)
	slick.activate(Vector3(0.0, 0.08, 10.0))
	var body := Contact.half_extents(1.0)
	if not slick.overlaps(Vector3(0.0, 0.0, 10.0), body):
		failed.append("center miss")
	var edge := OilSlick.HALF_X + body.x
	if slick.overlaps(Vector3(edge, 0.0, 10.0), body):
		failed.append("edge counts")
	if slick.overlaps(Vector3(12.0, 0.0, 10.0), body):
		failed.append("far hit")
	slick.free()
	var race: RaceDirector = load("res://scenes/race/race.tscn").instantiate()
	tree.root.add_child(race)
	race.set_process(false)
	var player: PlayerController = race.player
	player.speed_mps = 30.0
	var oil: OilManager = race.oil
	if oil.get_child_count() != OilManager.POOL_SIZE:
		failed.append("pool %s" % oil.get_child_count())
	var patch: OilSlick = oil.get_child(0)
	patch.activate(player.global_position)
	var crashes_before := race.crashes
	var multiplier_before := race.score_keeper.multiplier
	race.simulate(0.05)
	if not is_equal_approx(player.slip_s, OilManager.SLIP_S):
		failed.append("slip %s" % player.slip_s)
	if race.crashes != crashes_before or race.score_keeper.multiplier != multiplier_before:
		failed.append("oil counted as crash")
	race.free()
	return failed
