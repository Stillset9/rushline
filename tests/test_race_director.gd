extends RefCounted

func run(_tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var director_script: GDScript = load("res://scripts/core/race_director.gd")
	if not is_equal_approx(director_script.planned_max_speed(0.0), 30.0):
		failed.append("initial cap")
	if not is_equal_approx(director_script.planned_max_speed(10.0), 31.5):
		failed.append("ramp")
	if not is_equal_approx(director_script.planned_max_speed(1000.0), 70.0):
		failed.append("cap")
	var director: Node = director_script.new()
	var speeds: Array[float] = []
	var distances: Array[float] = []
	director.speed_changed.connect(func(value: float) -> void: speeds.append(value))
	director.distance_changed.connect(func(value: float) -> void: distances.append(value))
	director.advance_race(0.0, 8.0)
	director.advance_race(0.0, 8.05)
	director.advance_race(0.0, 8.2)
	if speeds.size() != 2:
		failed.append("speed signals %s" % speeds.size())
	# Delta 0 deja la distancia en 0, pero el centinela -1 emite ese 0 una vez.
	if distances.size() != 1:
		failed.append("zero distance signals %s" % distances.size())
	director.advance_race(0.1, 10.0)
	director.advance_race(0.05, 10.0)
	director.advance_race(0.05, 10.0)
	# Metros enteros emitidos: 0, 1 y 2. 1.5 no emite.
	if distances.size() != 3:
		failed.append("distance signals %s" % distances.size())
	if not is_equal_approx(director.distance_m, 2.0):
		failed.append("distance %s" % director.distance_m)
	if director_script.displayed_score(750.4) != 750:
		failed.append("truncate")
	var score_before: float = director.score_keeper.score
	director.advance_race(1.0, 20.0)
	if not is_equal_approx(director.score_keeper.score, score_before) or director.score_keeper.multiplier != 1:
		failed.append("advance scored")
	director.free()
	return failed
