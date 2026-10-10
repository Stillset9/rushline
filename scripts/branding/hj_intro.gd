class_name HJIntro
extends Control

const TITLE_SCENE := "res://scenes/menu/title.tscn"
const WORD := "HJGAMES"
const DARK_END := 0.35
const ENERGY_END := 1.15
const FORM_END := 2.35
const IMPACT_AT := 2.55
const PRESENT_AT := 2.9
const TITLE_AT := 4.2
const HOLD_END := 5.55
const FADE_DURATION := 0.6
const SKIP_FADE := 0.28
const MIX_RATE := 22050.0
const LETTER_DUR := 0.42

var auto_change_scene := true
var left := false
var time_s := 0.0

var _skipping := false
var _skip_at := 0.0
var _audio_started := false
var _await_gesture := false
var _pcm := PackedByteArray()
var _pcm_at := 0
var _pcm_count := 0
var _glint: ColorRect

@onready var _stage = %Stage
@onready var _stage_host: SubViewportContainer = $StageHost
@onready var _name_label: Label = %NameLabel
@onready var _presenta: Label = %PresentaLabel
@onready var _title_word: Label = %TitleWord
@onready var _rule_fallback: ColorRect = %RuleFallback
@onready var _flash: ColorRect = %Flash
@onready var _dust: Control = %Dust
@onready var _curtain: ColorRect = %Curtain
@onready var _audio: AudioStreamPlayer = %Audio


static func duration() -> float:
	return HOLD_END + FADE_DURATION


static func letter_start(index: int) -> float:
	var gaps := maxi(WORD.length() - 1, 1)
	var step := (FORM_END - ENERGY_END - LETTER_DUR) / float(gaps)
	return ENERGY_END + float(index) * step


static func letter_reveal(time_s: float, index: int) -> float:
	var u := clampf((time_s - letter_start(index)) / LETTER_DUR, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)


static func sweep_at(time_s: float) -> Vector2:
	if time_s >= DARK_END and time_s <= ENERGY_END + 0.85:
		var u := clampf((time_s - DARK_END) / (ENERGY_END + 0.85 - DARK_END), 0.0, 1.0)
		return Vector2(u, sin(u * PI))
	var flash_t := time_s - IMPACT_AT
	if flash_t >= 0.0 and flash_t <= 0.42:
		var u := flash_t / 0.42
		return Vector2(u, pow(1.0 - u, 0.55))
	return Vector2(0.5, 0.0)


static func wants_skip(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventMouseButton:
		return event.pressed
	if event is InputEventJoypadButton:
		return event.pressed
	return false


static func presentation(time_s: float) -> Dictionary:
	var formed_u := clampf((time_s - ENERGY_END) / (FORM_END - ENERGY_END), 0.0, 1.0)
	var present_u := clampf((time_s - PRESENT_AT) / 0.55, 0.0, 1.0)
	var presenta := present_u * present_u * (3.0 - 2.0 * present_u)
	var title_u := clampf((time_s - TITLE_AT) / 0.7, 0.0, 1.0)
	var title := title_u * title_u * (3.0 - 2.0 * title_u)
	var brand := 1.0 - title
	var flash := 0.0
	var flash_t := time_s - IMPACT_AT
	if flash_t >= 0.0 and flash_t < 0.4:
		flash = exp(-flash_t * 6.2)
	var fade := 1.0
	if time_s > HOLD_END:
		fade = 1.0 - clampf((time_s - HOLD_END) / FADE_DURATION, 0.0, 1.0)
	return {
		"time": time_s,
		"formed": formed_u,
		"flash": flash,
		"presenta": presenta,
		"title": title,
		"brand": brand,
		"particles": clampf(time_s / 0.55, 0.0, 1.0) * brand,
		"glide": clampf(time_s / HOLD_END, 0.0, 1.0),
		"fade": fade,
		"done": time_s >= HOLD_END + FADE_DURATION,
	}


static func audio_cue(time_s: float) -> String:
	if time_s < DARK_END:
		return "ambient"
	if time_s < ENERGY_END:
		return "rise"
	if time_s < IMPACT_AT:
		return "metal"
	if time_s < IMPACT_AT + 0.18:
		return "impact"
	if time_s < HOLD_END:
		return "tail"
	return "close"


static func sample(time_s: float) -> float:
	var out := 0.0
	if time_s < ENERGY_END:
		var env := clampf(time_s / 0.25, 0.0, 1.0)
		var tail := 1.0
		if time_s > ENERGY_END - 0.3:
			tail = clampf((ENERGY_END - time_s) / 0.3, 0.0, 1.0)
		out += env * tail * (sin(TAU * 55.0 * time_s) * 0.12 + sin(TAU * 110.0 * time_s) * 0.03)
	if time_s >= DARK_END and time_s < ENERGY_END:
		var u := (time_s - DARK_END) / (ENERGY_END - DARK_END)
		var env := sin(u * PI)
		var freq := lerpf(140.0, 620.0, u * u)
		out += sin(TAU * freq * (time_s - DARK_END)) * 0.12 * env
		out += sin(time_s * 1733.0) * sin(time_s * 907.0) * 0.04 * env
	for index in WORD.length():
		var tick_t := time_s - letter_start(index)
		if tick_t >= 0.0 and tick_t < 0.06:
			var env := exp(-tick_t * 58.0)
			var tone := lerpf(2400.0, 1560.0, float(index) / 6.0)
			out += sin(TAU * tone * tick_t) * 0.12 * env
	var impact_t := time_s - IMPACT_AT
	if impact_t >= 0.0 and impact_t < 0.55:
		var env := exp(-impact_t * 6.4)
		var thump := sin(TAU * 52.0 * impact_t) * 0.62
		var crack := sin(TAU * 740.0 * impact_t) * exp(-impact_t * 24.0) * 0.7
		var grit := sin(impact_t * 1901.0) * sin(impact_t * 877.0) * exp(-impact_t * 12.0) * 0.2
		out += (thump + crack + grit) * env
	if time_s >= IMPACT_AT + 0.12 and time_s < TITLE_AT:
		var env := clampf((TITLE_AT - time_s) / 1.4, 0.0, 1.0)
		out += (sin(TAU * 98.0 * time_s) * 0.04 + sin(TAU * 147.0 * time_s) * 0.022) * env
	if time_s >= TITLE_AT and time_s < HOLD_END:
		var env := clampf((HOLD_END - time_s) / 1.2, 0.0, 1.0)
		out += sin(TAU * 196.0 * (time_s - TITLE_AT)) * exp(-(time_s - TITLE_AT) * 3.4) * 0.18 * maxf(env, 0.35)
	if time_s >= HOLD_END:
		var elapsed := time_s - HOLD_END
		var freq := maxf(48.0, 150.0 - elapsed * 140.0)
		out += sin(TAU * freq * elapsed) * exp(-elapsed * 3.4) * 0.14
	return clampf(out, -1.0, 1.0)


func _ready() -> void:
	GraphicsProfile.apply_viewport(get_viewport())
	if OS.has_feature("web"):
		_show_stage_in_main_view()
	theme = preload("res://ui/rushline_theme.tres")
	_name_label.text = WORD
	_presenta.text = "PRESENTA"
	_title_word.text = "RUSHLINE"
	_title_word.pivot_offset = Vector2(760, 80)
	var face: Font = _stage.word_font()
	if face != null:
		_name_label.add_theme_font_override("font", face)
		_presenta.add_theme_font_override("font", face)
		_title_word.add_theme_font_override("font", face)
	_glint = ColorRect.new()
	_glint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glint.color = Color(1, 1, 1, 0.0)
	_glint.size = Vector2(36, 220)
	_glint.position = Vector2(700, 360)
	add_child(_glint)
	_apply(presentation(0.0))
	_pcm_count = int(duration() * MIX_RATE)
	_pcm.resize(_pcm_count * 4)
	GameSettings.load_state()
	if auto_change_scene and GameSettings.skip_intro:
		call_deferred("_leave")


func _show_stage_in_main_view() -> void:
	# A SubViewport on WebGL is copied with glReadPixels every frame. The logo stays in the main view instead.
	if _stage_host == null or _stage == null:
		return
	var view := _stage_host.get_node_or_null("StageView") as SubViewport
	if view != null:
		view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var stage := _stage as Node
	if stage.get_parent() != self:
		stage.get_parent().remove_child(stage)
		add_child(stage)
		move_child(stage, 0)
	for child in stage.get_children():
		if child is Camera3D:
			(child as Camera3D).current = true
	_stage_host.visible = false
	var background := get_node_or_null("Background") as CanvasItem
	if background != null:
		background.visible = false


func request_skip() -> void:
	if _skipping or left:
		return
	_skipping = true
	_skip_at = time_s
	if _audio != null and is_instance_valid(_audio) and _audio.playing:
		_audio.seek(HOLD_END)


func advance(delta: float) -> void:
	if left:
		return
	time_s += delta
	var state := presentation(time_s)
	if _skipping:
		var fade := 1.0 - clampf((time_s - _skip_at) / SKIP_FADE, 0.0, 1.0)
		state["fade"] = fade
		state["done"] = time_s >= _skip_at + SKIP_FADE
	_apply(state)
	if state["done"]:
		_leave()


func _process(delta: float) -> void:
	_fill_audio()
	_resume_web_audio()
	if Input.is_action_just_pressed("skip_intro"):
		request_skip()
	advance(minf(delta, 0.05))


func _unhandled_input(event: InputEvent) -> void:
	if wants_skip(event):
		request_skip()
		get_viewport().set_input_as_handled()


func _resume_web_audio() -> void:
	if not _await_gesture or not Input.is_anything_pressed():
		return
	if _audio != null and is_instance_valid(_audio) and not _audio.playing:
		_audio.play()
	_await_gesture = false


func _fill_audio() -> void:
	if _audio_started:
		return
	var end := mini(_pcm_at + 8000, _pcm_count)
	while _pcm_at < end:
		var pcm := int(round(sample(float(_pcm_at) / MIX_RATE) * 32767.0))
		var offset := _pcm_at * 4
		_pcm.encode_s16(offset, pcm)
		_pcm.encode_s16(offset + 2, pcm)
		_pcm_at += 1
	if _pcm_at < _pcm_count:
		return
	if _audio == null or not is_instance_valid(_audio):
		_audio_started = true
		return
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(MIX_RATE)
	wav.stereo = true
	wav.data = _pcm
	_audio.stream = wav
	GameSettings.load_state()
	_audio.volume_db = GameSettings.music_db()
	_audio_started = true
	_await_gesture = OS.has_feature("web")
	if not _await_gesture:
		_audio.play()


func _apply(state: Dictionary) -> void:
	_stage.apply(state)
	if _dust.has_method("set_field"):
		_dust.set_field(float(state["particles"]) * float(state["fade"]), float(state["time"]))
	var brand := float(state["brand"])
	var fade := float(state["fade"])
	if _stage_host != null:
		_stage_host.modulate.a = brand * fade
	var formed := float(state["formed"])
	var show_flat: bool = (not bool(_stage.logo_built)) or OS.has_feature("web")
	var fallback := formed * brand if show_flat else 0.0
	_name_label.modulate.a = fallback * fade
	_rule_fallback.modulate.a = fallback * 0.85 * fade
	_rule_fallback.scale.x = lerpf(0.2, 1.0, formed)
	var presenta_alpha := float(state["presenta"]) * brand * fade
	_presenta.modulate.a = presenta_alpha
	var shift := (1.0 - float(state["presenta"])) * 18.0
	_presenta.offset_top = 132.0 + shift
	_presenta.offset_bottom = 188.0 + shift
	var title_alpha := float(state["title"]) * fade
	_title_word.modulate.a = title_alpha
	_title_word.scale = Vector2.ONE * lerpf(1.08, 1.0, title_alpha)
	_flash.modulate.a = float(state["flash"]) * 0.34 * fade
	_curtain.modulate.a = 1.0 - fade
	_place_glint(state)


func _place_glint(state: Dictionary) -> void:
	if _glint == null:
		return
	var sweep := sweep_at(float(state["time"]))
	var strength := float(sweep.y) * float(state["brand"]) * float(state["fade"])
	_glint.color.a = strength * 0.55
	_glint.position = Vector2(lerpf(520.0, 1360.0, float(sweep.x)), 390.0)
	_glint.visible = strength > 0.04


func _leave() -> void:
	if left:
		return
	left = true
	if not auto_change_scene:
		return
	get_tree().change_scene_to_file(TITLE_SCENE)


func _exit_tree() -> void:
	if _audio != null and is_instance_valid(_audio) and _audio.playing:
		_audio.stop()
