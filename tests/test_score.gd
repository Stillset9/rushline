extends RefCounted

func run(_tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var fresh := ScoreKeeper.new()
	fresh.add_clean_distance(199.0)
	if not _is(fresh, 199.0, 1, 199.0):
		failed.append("199 %s" % _dump(fresh))
	var exact := ScoreKeeper.new()
	exact.add_clean_distance(200.0)
	if not _is(exact, 200.0, 2, 0.0):
		failed.append("200 %s" % _dump(exact))
	var run_on := ScoreKeeper.new()
	run_on.add_clean_distance(450.0)
	if not _is(run_on, 750.0, 3, 50.0):
		failed.append("450 %s" % _dump(run_on))
	var crossing := ScoreKeeper.new()
	crossing.multiplier = 4
	crossing.clean_m = 150.0
	crossing.add_clean_distance(100.0)
	if not _is(crossing, 450.0, 5, 0.0):
		failed.append("cross cap %s" % _dump(crossing))
	var capped := ScoreKeeper.new()
	capped.add_clean_distance(800.0)
	if not _is(capped, 2000.0, 5, 0.0):
		failed.append("reach cap %s" % _dump(capped))
	capped.add_clean_distance(10.0)
	if not _is(capped, 2050.0, 5, 0.0):
		failed.append("stay cap %s" % _dump(capped))
	var hit := ScoreKeeper.new()
	hit.score = 750.0
	hit.multiplier = 3
	hit.clean_m = 50.0
	hit.register_hit()
	if not _is(hit, 750.0, 1, 0.0):
		failed.append("reset %s" % _dump(hit))
	hit.add_hit_distance(12.0)
	if not _is(hit, 762.0, 1, 0.0):
		failed.append("hit meters %s" % _dump(hit))
	return failed


func _is(keeper: ScoreKeeper, score: float, multiplier: int, clean_m: float) -> bool:
	return is_equal_approx(keeper.score, score) and keeper.multiplier == multiplier and is_equal_approx(keeper.clean_m, clean_m)


func _dump(keeper: ScoreKeeper) -> String:
	return "%s x%s clean %s" % [keeper.score, keeper.multiplier, keeper.clean_m]
