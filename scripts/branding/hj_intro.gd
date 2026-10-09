class_name HJIntro
extends Control

const TITLE_SCENE := "res://scenes/menu/title.tscn"
const WORD := "HJGAMES"
const DARK_END := 1.0
const ENERGY_END := 2.5
const FORM_END := 4.5
const IMPACT_AT := 4.5
const PRESENT_AT := 6.0
const HOLD_END := 7.4
const FADE_DURATION := 0.6
const SKIP_FADE := 0.28
const MIX_RATE := 22050.0
const LETTER_DUR := 0.55

var auto_change_scene := true
var left := false
var time_s := 0.0

var _skipping := false
var _skip_at := 0.0
var _audio_started := false
var _await_gesture := false

@onready var _stage = %Stage
@onready var _name_label: Label = %NameLabel
@onready var _presenta: Label = %PresentaLabel
@onready var _rule_fallback: ColorRect = %RuleFallback
@onready var _flash: ColorRect = %Flash
@onready var _dust: Control = %Dust
@onready var _curtain: ColorRect = %Curtain
@onready var _audio: AudioStreamPlayer = %Audio


static func letter_start(index: int) -> float:
	var gaps := maxi(WORD.length() - 1, 1)
	var step := (FORM_END - ENERGY_END - LETTER_DUR) / float(gaps)
	return ENERGY_END + float(index) * step


static func letter_reveal(time_s: float, index: int) -> float:
	var u := clampf((time_s - letter_start(index)) / LETTER_DUR, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)


static func sweep_at(time_s: float) -> Vector2:
	if time_s >= DARK_END and time_s <= ENERGY_END:
		var u := (time_s - DARK_END) / (ENERGY_END - DARK_END)
		return Vector2(u, sin(u * PI))
	var flash_t := time_s - IMPACT_AT
	if flash_t >= 0.0 and flash_t <= 0.36:
		var u := flash_t / 0.36
		return Vector2(u, pow(1.0 - u, 0.65))
	return Vector2(0.5, 0.0)


static func presentation(time_s: float) -> Dictionary:
	var formed_u := clampf((time_s - ENERGY_END) / (FORM_END - ENERGY_END), 0.0, 1.0)
	var present_u := clampf((time_s - PRESENT_AT) / 0.7, 0.0, 1.0)
	var presenta := present_u * present_u * (3.0 - 2.0 * present_u)
	var flash := 0.0
	var flash_t := time_s - IMPACT_AT
	if flash_t >= 0.0 and flash_t < 0.45:
		flash = exp(-flash_t * 6.5)
	var fade := 1.0
	if time_s > HOLD_END:
		fade = 1.0 - clampf((time_s - HOLD_END) / FADE_DURATION, 0.0, 1.0)
	return {
		"time": time_s,
		"formed": formed_u,
		"flash": flash,
		"presenta": presenta,
		"particles": clampf(time_s / 0.8, 0.0, 1.0),
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
	if time_s < IMPACT_AT + 0.2:
		return "impact"
	if time_s < HOLD_END:
		return "tail"
	return "close"


static func sample(time_s: float) -> float:
	var out := 0.0
	if time_s < ENERGY_END:
		var env := clampf(time_s / 0.4, 0.0, 1.0)
		var tail := 1.0
		if time_s > ENERGY_END - 0.45:
			tail = clampf((ENERGY_END - time_s) / 0.45, 0.0, 1.0)
		out += env * tail * (sin(TAU * 46.0 * time_s) * 0.14 + sin(TAU * 92.0 * time_s) * 0.035)
	if time_s >= DARK_END and time_s < ENERGY_END:
		var u := (time_s - DARK_END) / (ENERGY_END - DARK_END)
		var env := sin(u * PI)
		var freq := lerpf(120.0, 540.0, u * u)
		out += sin(TAU * freq * (time_s - DARK_END)) * 0.11 * env
		out += sin(time_s * 1733.0) * sin(time_s * 907.0) * 0.035 * env
	for index in WORD.length():
		var tick_t := time_s - letter_start(index)
		if tick_t >= 0.0 and tick_t < 0.07:
			var env := exp(-tick_t * 52.0)
			var tone := lerpf(2100.0, 1480.0, float(index) / 6.0)
			out += sin(TAU * tone * tick_t) * 0.14 * env
	var impact_t := time_s - IMPACT_AT
	if impact_t >= 0.0 and impact_t < 0.62:
		var env := exp(-impact_t * 6.2)
		var thump := sin(TAU * 48.0 * impact_t) * 0.58
		var crack := sin(TAU * 680.0 * impact_t) * exp(-impact_t * 22.0) * 0.72
		var grit := sin(impact_t * 1901.0) * sin(impact_t * 877.0) * exp(-impact_t * 11.0) * 0.22
		out += (thump + crack + grit) * env
	if time_s >= IMPACT_AT + 0.18 and time_s < HOLD_END:
		var env := clampf((HOLD_END - time_s) / 1.7, 0.0, 1.0)
		out += (sin(TAU * 92.0 * time_s) * 0.045 + sin(TAU * 138.0 * time_s) * 0.026) * env
	if time_s >= HOLD_END:
		var elapsed := time_s - HOLD_END
		var freq := maxf(54.0, 168.0 - elapsed * 120.0)
		out += sin(TAU * freq * elapsed) * exp(-elapsed * 3.1) * 0.15
	return clampf(out, -1.0, 1.0)


func _ready() -> void:
	theme = preload("res://ui/rushline_theme.tres")
	_name_label.text = WORD
	_presenta.text = "PRESENTA"
	var face: Font = _stage.word_font()
	if face != null:
		_name_label.add_theme_font_override("font", face)
		_presenta.add_theme_font_override("font", face)
	_apply(presentation(0.0))
	if not auto_change_scene:
		return
	_audio = AudioStreamPlayer.new()
	_audio.name = "HJIntroSting"
	get_tree().root.add_child.call_deferred(_audio)


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
	var booting := time_s <= 0.0 and not _skipping
	_ensure_audio()
	_resume_web_audio()
	if Input.is_action_just_pressed("skip_intro"):
		request_skip()
	if _skipping:
		advance(delta)
		return
	if booting:
		return
	var step := minf(delta, 0.05)
	if _audio != null and is_instance_valid(_audio) and _audio.playing:
		var ahead := _audio.get_playback_position() - time_s
		if ahead > step:
			step = minf(ahead, 0.05)
	advance(step)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
		GameSettings.load_state()
		GameSettings.muted = not GameSettings.muted
		GameSettings.save()
		if _audio != null and is_instance_valid(_audio):
			_audio.volume_db = GameSettings.music_db()
		get_viewport().set_input_as_handled()


func _resume_web_audio() -> void:
	if not _await_gesture or not Input.is_anything_pressed():
		return
	if _audio != null and is_instance_valid(_audio) and not _audio.playing:
		_audio.play()
	_await_gesture = false


func _ensure_audio() -> void:
	if _audio_started or _audio == null or not is_instance_valid(_audio):
		return
	if not _audio.is_inside_tree() or _audio.get_parent() != get_tree().root:
		return
	_audio_started = true
	_setup_audio()
	_await_gesture = OS.has_feature("web")


func _apply(state: Dictionary) -> void:
	_stage.apply(state)
	if _dust.has_method("set_field"):
		_dust.set_field(float(state["particles"]) * float(state["fade"]), float(state["time"]))
	var fallback := 0.0 if _stage.logo_built else float(state["formed"])
	_name_label.modulate.a = fallback
	_rule_fallback.modulate.a = fallback * 0.85
	_rule_fallback.scale.x = lerpf(0.2, 1.0, float(state["formed"]))
	var presenta_alpha := float(state["presenta"])
	_presenta.modulate.a = presenta_alpha
	var shift := (1.0 - presenta_alpha) * 16.0
	_presenta.offset_top = 132.0 + shift
	_presenta.offset_bottom = 188.0 + shift
	_flash.modulate.a = float(state["flash"]) * 0.16
	_curtain.modulate.a = 1.0 - float(state["fade"])


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


func _setup_audio() -> void:
	var seconds := HOLD_END + FADE_DURATION
	var count := int(seconds * MIX_RATE)
	var data := PackedByteArray()
	data.resize(count * 4)
	for i in count:
		var pcm := int(round(sample(float(i) / MIX_RATE) * 32767.0))
		var offset := i * 4
		data.encode_s16(offset, pcm)
		data.encode_s16(offset + 2, pcm)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(MIX_RATE)
	wav.stereo = true
	wav.data = data
	_audio.stream = wav
	GameSettings.load_state()
	_audio.volume_db = GameSettings.music_db()
	_audio.play()
