extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var title: TitleScreen = load("res://scenes/menu/title.tscn").instantiate()
	title.auto_change_scene = false
	tree.root.add_child(title)
	title.set_process(false)
	if title.anchor_right != 1.0 or title.anchor_bottom != 1.0:
		failed.append("anchors")
	if title.get_node("%TitleLabel").text != "RUSHLINE":
		failed.append("title")
	if title.get_node("%PlayLabel").text != "Jugar":
		failed.append("play")
	if title.get_node("%QuitLabel").text != "Salir":
		failed.append("quit")
	if title.get_node("%GarageLabel").text != "Garaje":
		failed.append("garage")
	if title.RACE_SCENE != "res://scenes/race/race.tscn":
		failed.append("destination")
	title.request_play()
	if not title.started:
		failed.append("start")
	title.request_quit()
	if not title.quit_requested:
		failed.append("exit")
	title.free()
	return failed
