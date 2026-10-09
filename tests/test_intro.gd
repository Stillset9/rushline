extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	if not ResourceLoader.exists("res://assets/branding/Orbitron-Variable.ttf"):
		failed.append("font")
	var intro_script: GDScript = load("res://scripts/branding/hj_intro.gd")
	var at_dark: Dictionary = intro_script.presentation(0.5)
	if at_dark["formed"] != 0.0 or at_dark["presenta"] != 0.0 or at_dark["done"]:
		failed.append("dark %s" % at_dark)
	if intro_script.audio_cue(0.5) != "ambient":
		failed.append("cue ambient")
	if intro_script.audio_cue(1.4) != "rise":
		failed.append("cue rise")
	if intro_script.letter_reveal(2.85, 0) <= 0.2 or intro_script.letter_reveal(2.85, 6) > 0.001:
		failed.append("letter order")
	var at_form: Dictionary = intro_script.presentation(3.5)
	if at_form["formed"] <= 0.2 or at_form["formed"] >= 1.0 or at_form["presenta"] != 0.0:
		failed.append("form %s" % at_form)
	if intro_script.audio_cue(3.5) != "metal":
		failed.append("cue metal")
	var at_impact: Dictionary = intro_script.presentation(4.6)
	if at_impact["formed"] < 1.0 or at_impact["flash"] < 0.3 or at_impact["presenta"] != 0.0:
		failed.append("impact %s" % at_impact)
	if intro_script.audio_cue(intro_script.IMPACT_AT) != "impact":
		failed.append("impact sync")
	if intro_script.audio_cue(5.4) != "tail":
		failed.append("cue tail")
	if absf(intro_script.sample(0.0)) > 0.001:
		failed.append("sample silence")
	if absf(intro_script.sample(intro_script.IMPACT_AT + 0.01)) <= 0.2:
		failed.append("sample impact %s" % intro_script.sample(intro_script.IMPACT_AT + 0.01))
	var ended: Dictionary = intro_script.presentation(intro_script.HOLD_END + intro_script.FADE_DURATION)
	if not ended["done"] or ended["fade"] > 0.001:
		failed.append("fade %s" % ended)
	if ended["presenta"] < 1.0:
		failed.append("presenta hold")
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
	intro._process(0.05)
	if intro.time_s <= 0.0:
		failed.append("clock %s" % intro.time_s)
	intro.time_s = 0.0
	intro.advance(4.6)
	var label: Label = intro.get_node("%NameLabel")
	if label.text != "HJGAMES":
		failed.append("word %s" % label.text)
	var stage = intro.get_node("%Stage")
	if int(stage.logo_count()) != 7 and label.modulate.a <= 0.3:
		failed.append("readable alpha %s letters %s" % [label.modulate.a, stage.logo_count()])
	if int(stage.logo_count()) != 7:
		failed.append("logo %s" % stage.logo_count())
	var presenta: Label = intro.get_node("%PresentaLabel")
	if presenta.text != "PRESENTA" or presenta.modulate.a > 0.05:
		failed.append("presenta early %s %s" % [presenta.text, presenta.modulate.a])
	intro.advance(2.2)
	if presenta.modulate.a < 0.8:
		failed.append("presenta shown %s" % presenta.modulate.a)
	var word_before := label.text
	intro.request_skip()
	intro.advance(HJIntro.SKIP_FADE)
	if not intro.left or label.text != word_before:
		failed.append("skip")
	if intro.TITLE_SCENE != "res://scenes/menu/title.tscn":
		failed.append("destination")
	tree.root.remove_child(intro)
	intro.queue_free()
	return failed
