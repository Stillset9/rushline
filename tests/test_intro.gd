extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	if not ResourceLoader.exists("res://assets/branding/Orbitron-Variable.ttf"):
		failed.append("font")
	if ResourceLoader.exists("res://scripts/branding/hj_mark.gd"):
		failed.append("monogram leftover")
	var intro_script: GDScript = load("res://scripts/branding/hj_intro.gd")
	var total: float = intro_script.duration()
	if total < 5.0 or total > 7.0:
		failed.append("length %s" % total)
	var at_dark: Dictionary = intro_script.presentation(0.1)
	if at_dark["formed"] != 0.0 or at_dark["presenta"] != 0.0 or at_dark["title"] != 0.0 or at_dark["done"]:
		failed.append("dark %s" % at_dark)
	if intro_script.audio_cue(0.1) != "ambient":
		failed.append("cue ambient")
	if intro_script.audio_cue(intro_script.DARK_END + 0.2) != "rise":
		failed.append("cue rise")
	var early: float = float(intro_script.letter_start(0)) + float(intro_script.LETTER_DUR) * 0.85
	if intro_script.letter_reveal(early, 0) <= 0.2 or intro_script.letter_reveal(early, 6) > 0.001:
		failed.append("letter order")
	var at_form: Dictionary = intro_script.presentation((intro_script.ENERGY_END + intro_script.FORM_END) * 0.5)
	if at_form["formed"] <= 0.2 or at_form["formed"] >= 1.0 or at_form["presenta"] != 0.0:
		failed.append("form %s" % at_form)
	if intro_script.audio_cue(intro_script.ENERGY_END + 0.2) != "metal":
		failed.append("cue metal")
	var at_impact: Dictionary = intro_script.presentation(intro_script.IMPACT_AT + 0.05)
	if at_impact["formed"] < 1.0 or at_impact["flash"] < 0.3 or at_impact["presenta"] != 0.0 or at_impact["title"] != 0.0:
		failed.append("impact %s" % at_impact)
	if intro_script.audio_cue(intro_script.IMPACT_AT) != "impact":
		failed.append("impact sync")
	if intro_script.audio_cue(intro_script.TITLE_AT - 0.2) != "tail":
		failed.append("cue tail")
	if absf(intro_script.sample(0.0)) > 0.001:
		failed.append("sample silence")
	if absf(intro_script.sample(intro_script.IMPACT_AT + 0.01)) <= 0.2:
		failed.append("sample impact %s" % intro_script.sample(intro_script.IMPACT_AT + 0.01))
	var brand: Dictionary = intro_script.presentation(intro_script.PRESENT_AT + 0.7)
	if brand["presenta"] < 0.8 or brand["title"] > 0.05:
		failed.append("brand %s" % brand)
	var titled: Dictionary = intro_script.presentation(intro_script.TITLE_AT + 0.85)
	if titled["title"] < 0.8 or titled["brand"] > 0.25:
		failed.append("title beat %s" % titled)
	var ended: Dictionary = intro_script.presentation(intro_script.duration())
	if not ended["done"] or ended["fade"] > 0.001:
		failed.append("fade %s" % ended)
	var key := InputEventKey.new()
	key.pressed = true
	key.echo = false
	key.physical_keycode = KEY_SPACE
	if not intro_script.wants_skip(key):
		failed.append("skip key")
	var click := InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	if not intro_script.wants_skip(click):
		failed.append("skip click")
	GameSettings.isolated = true
	GameSettings.skip_intro = false
	GameSettings.toggle_skip()
	if not GameSettings.skip_intro or GameSettings.skip_name() != "Sí":
		failed.append("skip option")
	GameSettings.skip_intro = false
	GameSettings.isolated = false
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
	intro._skipping = false
	intro.advance(HJIntro.IMPACT_AT + 0.05)
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
	var title: Label = intro.get_node("%TitleWord")
	if title.text != "RUSHLINE" or title.modulate.a > 0.05:
		failed.append("title early %s %s" % [title.text, title.modulate.a])
	intro.time_s = 0.0
	intro.advance(HJIntro.PRESENT_AT + 0.75)
	if presenta.modulate.a < 0.8 or title.modulate.a > 0.05:
		failed.append("presenta shown %s title %s" % [presenta.modulate.a, title.modulate.a])
	intro.time_s = 0.0
	intro.advance(HJIntro.TITLE_AT + 0.9)
	if title.modulate.a < 0.75:
		failed.append("rushline %s" % title.modulate.a)
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
