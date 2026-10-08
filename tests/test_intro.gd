extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var intro_script: GDScript = load("res://scripts/branding/hj_intro.gd")
	var at_half: Dictionary = intro_script.presentation(0.5)
	if at_half["line"] <= 0.0 or at_half["line"] >= 1.0 or at_half["mark"] != 0.0 or at_half["name"] != 0.0:
		failed.append("half %s" % at_half)
	if intro_script.audio_cue(0.5) != "appear":
		failed.append("cue appear")
	var at_name: Dictionary = intro_script.presentation(2.1)
	if at_name["mark"] < 1.0 or at_name["name"] <= 0.0 or at_name["title"] != 0.0:
		failed.append("name in %s" % at_name)
	var at_game: Dictionary = intro_script.presentation(3.1)
	if at_game["title"] < 1.0 or at_game["name"] < 1.0:
		failed.append("game title %s" % at_game)
	if intro_script.audio_cue(2.1) != "impact":
		failed.append("cue impact")
	if intro_script.audio_cue(intro_script.MARK_END) != "impact":
		failed.append("impact sync")
	if absf(intro_script.sample(0.0)) > 0.001:
		failed.append("sample silence")
	if absf(intro_script.sample(2.01)) <= 0.2:
		failed.append("sample impact %s" % intro_script.sample(2.01))
	var ended: Dictionary = intro_script.presentation(intro_script.HOLD_END + intro_script.FADE_DURATION)
	if not ended["done"] or ended["fade"] > 0.001:
		failed.append("fade %s" % ended)
	for view in [Vector2(1920, 1080), Vector2(2560, 1440)]:
		var origin: Vector2 = HJMark.origin_for(view)
		if origin.x < view.x * 0.45 or origin.x > view.x * 0.55:
			failed.append("center x %s" % view)
		if origin.y < view.y * 0.35 or origin.y > view.y * 0.6:
			failed.append("center y %s" % view)
	failed.append_array(_scene(tree))
	return failed


func _scene(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var intro: HJIntro = load("res://scenes/branding/HJGamesIntro.tscn").instantiate()
	intro.auto_change_scene = false
	tree.root.add_child(intro)
	intro.set_process(false)
	if intro.anchor_right != 1.0 or intro.anchor_bottom != 1.0:
		failed.append("anchors")
	intro.advance(2.2)
	var label: Label = intro.get_node("%NameLabel")
	if label.text != "HJgames presents" or label.modulate.a <= 0.3:
		failed.append("readable %s alpha %s" % [label.text, label.modulate.a])
	var game_label: Label = intro.get_node("%GameLabel")
	if game_label.text != "RUSHLINE":
		failed.append("rushline %s" % game_label.text)
	if intro.get_node("%Mark").line < 1.0 or intro.get_node("%Mark").reveal < 1.0:
		failed.append("mark")
	var score_before := label.text
	intro.request_skip()
	intro.advance(HJIntro.SKIP_FADE)
	if not intro.left or label.text != score_before:
		failed.append("skip")
	if intro.TITLE_SCENE != "res://scenes/menu/title.tscn":
		failed.append("destination")
	intro.free()
	return failed
