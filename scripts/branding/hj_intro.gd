class_name HJIntro
extends Control

const TITLE_SCENE := "res://scenes/menu/title.tscn"
const LINE_END := 1.0
const MARK_END := 2.0
const NAME_END := 3.0
const HOLD_END := 4.0
const FADE_DURATION := 0.55
const SKIP_FADE := 0.28
const MIX_RATE := 44100.0

var auto_change_scene := true
var left := false
var time_s := 0.0

var _skipping := false
var _skip_at := 0.0
var _audio_started := false

@onready var _mark: HJMark = %Mark
@onready var _name_label: Label = %NameLabel
@onready var _game_label: Label = %GameLabel
@onready var _audio: AudioStreamPlayer = %Audio


static func presentation(time_s: float) -> Dictionary:
	var name_alpha := clampf((time_s - MARK_END) / 0.4, 0.0, 1.0)
	var title_alpha := clampf((time_s - 2.55) / 0.5, 0.0, 1.0)
	var fade := 1.0
	if time_s > HOLD_END:
		fade = 1.0 - clampf((time_s - HOLD_END) / FADE_DURATION, 0.0, 1.0)
	return {
		"line": clampf(time_s / LINE_END, 0.0, 1.0),
		"mark": clampf((time_s - LINE_END) / (MARK_END - LINE_END), 0.0, 1.0),
		"name": name_alpha,
		"title": title_alpha,
		"energy": clampf((time_s - NAME_END) / (HOLD_END - NAME_END), 0.0, 1.0),
		"fade": fade,
		"done": time_s >= HOLD_END + FADE_DURATION,
	}


static func audio_cue(time_s: float) -> String:
	if time_s < MARK_END:
		return "appear"
	if time_s < MARK_END + 0.18:
		return "impact"
	if time_s < HOLD_END:
		return "hold"
	return "close"


static func sample(time_s: float) -> float:
	var appear := 0.0
	if time_s < MARK_END:
		var env := clampf(time_s / 0.12, 0.0, 1.0)
		appear = env * (sin(TAU * 55.0 * time_s) * 0.22 + sin(TAU * 82.5 * time_s) * 0.06)
	var impact := 0.0
	var impact_t := time_s - MARK_END
	if impact_t >= 0.0 and impact_t < 0.18:
		var env := exp(-impact_t * 22.0)
		var tick := sin(TAU * 520.0 * impact_t)
		var grit := sin(impact_t * 1703.0) * sin(impact_t * 917.0)
		impact = (tick * 0.7 + grit * 0.28) * env
	var close := 0.0
	if time_s >= HOLD_END:
		var elapsed := time_s - HOLD_END
		var freq := maxf(70.0, 210.0 - elapsed * 160.0)
		close = sin(TAU * freq * elapsed) * exp(-elapsed * 3.5) * 0.22
	return clampf(appear + impact + close, -1.0, 1.0)


func _ready() -> void:
	theme = preload("res://ui/rushline_theme.tres")
	_name_label.text = "HJgames presents"
	_name_label.modulate.a = 0.0
	_game_label.text = "RUSHLINE"
	_game_label.modulate.a = 0.0
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
	if _audio != null and _audio.playing:
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
	_ensure_audio()
	if Input.is_action_just_pressed("skip_intro"):
		request_skip()
	advance(delta)


func _ensure_audio() -> void:
	if _audio_started or _audio == null or not is_instance_valid(_audio):
		return
	if not _audio.is_inside_tree() or _audio.get_parent() != get_tree().root:
		return
	_audio_started = true
	_setup_audio()


func _apply(state: Dictionary) -> void:
	_mark.set_state(state["line"], state["mark"], state["energy"])
	_name_label.modulate.a = state["name"]
	_game_label.modulate.a = state["title"]
	modulate.a = state["fade"]


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
	_audio.play()
