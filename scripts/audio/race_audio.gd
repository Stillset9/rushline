class_name RaceAudio
extends Node

const MIX_RATE := 44100
const MUSIC_PATH := "res://assets/music/pure_raceway.mp3"

var _engine: AudioStreamPlayer
var _hit: AudioStreamPlayer
var _rise: AudioStreamPlayer
var _music: AudioStreamPlayer
var _whoosh: AudioStreamPlayer
var _audible := false


static func pitch_for_speed(speed_mps: float) -> float:
	var blend := clampf((speed_mps - PlayerController.MIN_SPEED_MPS) / (RaceDirector.SPEED_CAP_MPS - PlayerController.MIN_SPEED_MPS), 0.0, 1.0)
	return lerpf(0.72, 1.65, blend)


static func engine_sample(time_s: float) -> float:
	return clampf(sin(TAU * 48.0 * time_s) * 0.22 + sin(TAU * 96.0 * time_s) * 0.07, -1.0, 1.0)


static func hit_sample(time_s: float) -> float:
	var env := exp(-time_s * 18.0)
	return clampf(sin(TAU * 70.0 * time_s) * env * 0.8, -1.0, 1.0)


static func whoosh_sample(time_s: float) -> float:
	var env := exp(-time_s * 4.0) * clampf(time_s * 20.0, 0.0, 1.0)
	return clampf(sin(TAU * 180.0 * time_s) * 0.45 * env, -1.0, 1.0)


static func rise_sample(time_s: float) -> float:
	var freq := 520.0 + time_s * 700.0
	return clampf(sin(TAU * freq * time_s) * exp(-time_s * 8.0) * 0.28, -1.0, 1.0)


static func race_music() -> AudioStreamMP3:
	var stream := (load(MUSIC_PATH) as AudioStreamMP3).duplicate() as AudioStreamMP3
	stream.loop = true
	return stream


func _ready() -> void:
	GameSettings.load_state()
	_audible = DisplayServer.get_name() != "headless"
	_engine = _player("Engine", _wav(0.5, MIX_RATE, engine_sample), true)
	_hit = _player("Hit", _wav(0.16, MIX_RATE, hit_sample), false)
	_rise = _player("Rise", _wav(0.22, MIX_RATE, rise_sample), false)
	_whoosh = _player("Whoosh", _wav(0.45, MIX_RATE, whoosh_sample), false)
	if _audible:
		_music = AudioStreamPlayer.new()
		_music.name = "Music"
		_music.stream = race_music()
		_music.volume_db = GameSettings.music_db()
		add_child(_music)
		_music.play()
		_engine.play()


func apply_speed(speed_mps: float) -> void:
	if _engine == null:
		return
	var blend := clampf((speed_mps - PlayerController.MIN_SPEED_MPS) / (RaceDirector.SPEED_CAP_MPS - PlayerController.MIN_SPEED_MPS), 0.0, 1.0)
	_engine.pitch_scale = pitch_for_speed(speed_mps)
	_engine.volume_db = GameSettings.sfx_db(lerpf(-22.0, -10.0, blend))


func play_hit() -> void:
	_restart(_hit)


func play_rise() -> void:
	_restart(_rise)


func play_whoosh() -> void:
	_restart(_whoosh)


func _exit_tree() -> void:
	for player in [_engine, _hit, _rise, _whoosh, _music]:
		if player != null and is_instance_valid(player) and player.playing:
			player.stop()


func _player(node_name: String, stream: AudioStreamWAV, looping: bool) -> AudioStreamPlayer:
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.data.size() / 4)
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.stream = stream
	add_child(player)
	return player


func _restart(player: AudioStreamPlayer) -> void:
	if not _audible or player == null:
		return
	player.volume_db = GameSettings.sfx_db(-6.0)
	player.play()


func _wav(seconds: float, rate: int, sampler: Callable) -> AudioStreamWAV:
	var count := int(seconds * float(rate))
	var data := PackedByteArray()
	data.resize(count * 4)
	for i in count:
		var pcm := int(round(sampler.call(float(i) / float(rate)) * 32767.0))
		var offset := i * 4
		data.encode_s16(offset, pcm)
		data.encode_s16(offset + 2, pcm)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = true
	wav.data = data
	return wav
