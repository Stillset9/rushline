extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var previous_isolated := Progress.isolated
	var previous_path := Progress.storage_path
	Progress.isolated = false
	Progress.storage_path = "user://test_progress.cfg"
	_erase()
	var fresh := Progress.load_state()
	if fresh.money != 0 or fresh.best_score != 0:
		failed.append("fresh %s %s" % [fresh.money, fresh.best_score])
	if not fresh.note_finish(120):
		failed.append("first record")
	var loaded := Progress.load_state()
	if loaded.money != 120 or loaded.best_score != 120 or loaded.races != 1:
		failed.append("saved %s %s races %s" % [loaded.money, loaded.best_score, loaded.races])
	if loaded.note_finish(40):
		failed.append("lower score replaced the record")
	if loaded.money != 160 or loaded.best_score != 120:
		failed.append("after lower %s %s" % [loaded.money, loaded.best_score])
	loaded.money = 400
	if not loaded.buy("motor") or loaded.motor != 1 or loaded.money != 0:
		failed.append("buy %s money %s" % [loaded.motor, loaded.money])
	if loaded.buy("motor"):
		failed.append("bought without money")
	if loaded.cost_for("missing") != -1:
		failed.append("unknown upgrade")
	var garage: GarageScreen = load("res://scenes/menu/garage.tscn").instantiate()
	garage.auto_change_scene = false
	tree.root.add_child(garage)
	garage.set_process(false)
	garage.progress.money = 500
	garage.progress.motor = 0
	garage.progress.tope = 0
	garage.progress.nitro = 0
	if not garage.buy_selected() or garage.progress.motor != 1:
		failed.append("garage buy")
	garage.free()
	_erase()
	Progress.isolated = previous_isolated
	Progress.storage_path = previous_path
	return failed


func _erase() -> void:
	var absolute := ProjectSettings.globalize_path(Progress.storage_path)
	if FileAccess.file_exists(absolute):
		DirAccess.remove_absolute(absolute)
