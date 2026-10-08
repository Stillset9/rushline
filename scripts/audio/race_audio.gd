class_name RaceAudio
extends Node

const MIX_RATE := 44100
const MUSIC_RATE := 22050
const MUSIC_BPM := 150.0
const MUSIC_BARS := 4
static var _lead_hz := PackedFloat32Array([
	659.26, 783.99, 880.0, 783.99, 659.26, 587.33, 659.26, 523.25,
	880.0, 1046.5, 880.0, 783.99, 659.26, 783.99, 880.0, 783.99,
	659.26, 783.99, 880.0, 783.99, 659.26, 587.33, 659.26, 523.25,
	587.33, 659.26, 783.99, 880.0, 783.99, 659.26, 587.33, 440.0,
])
static var _bass_hz := PackedFloat32Array([
	110.0, 110.0, 164.81, 110.0,
	98.0, 98.0, 146.83, 98.0,
	87.31, 87.31, 130.81, 87.31,
	82.41, 98.0, 110.0, 82.41,
])

var _engine: AudioStreamPlayer
var _hit: AudioStreamPlayer
var _rise: AudioStreamPlayer
var _music: AudioStreamPlayer
var _audible := false


static func pitch_for_speed(speed_mps: float) -> float:
	var blend := clampf((speed_mps - PlayerController.MIN_SPEED_MPS) / (RaceDirector.SPEED_CAP_MPS - PlayerController.MIN_SPEED_MPS), 0.0, 1.0)
	return lerpf(0.72, 1.65, blend)


static func engine_sample(time_s: float) -> float:
	return clampf(sin(TAU * 48.0 * time_s) * 0.22 + sin(TAU * 96.0 * time_s) * 0.07, -1.0, 1.0)


static func hit_sample(time_s: float) -> float:
	var env := exp(-time_s * 18.0)
	return clampf(sin(TAU * 70.0 * time_s) * env * 0.8, -1.0, 1.0)


static func rise_sample(time_s: float) -> float:
	var freq := 520.0 + time_s * 700.0
	return clampf(sin(TAU * freq * time_s) * exp(-time_s * 8.0) * 0.28, -1.0, 1.0)


static func music_length() -> float:
	return float(MUSIC_BARS) * 4.0 * (60.0 / MUSIC_BPM)


static func music_sample(time_s: float) -> float:
	var beat_s := 60.0 / MUSIC_BPM
	var beat := fposmod(time_s / beat_s, float(MUSIC_BARS) * 4.0)
	var bar := int(beat / 4.0)
	var bar_beat := beat - float(bar) * 4.0
	var kick := _kick(bar_beat, beat_s)
	var snare := _snare(bar_beat, beat_s)
	var hat := _hat(bar_beat, beat_s)
	var bass := _note(_bass_hz[bar * 4 + int(bar_beat)], _local_seconds(bar_beat, 1.0, beat_s), 7.0, 0.34)
	var eighth := mini(int(bar_beat * 2.0), 7)
	var lead := _note(_lead_hz[bar * 8 + eighth], _local_seconds(bar_beat, 2.0, beat_s), 10.0, 0.2)
	return clampf(kick + snare + hat + bass + lead, -1.0, 1.0)


func _ready() -> void:
	GameSettings.load_state()
	_audible = DisplayServer.get_name() != "headless"
	_engine = _player("Engine", _wav(0.5, MIX_RATE, engine_sample), true)
	_hit = _player("Hit", _wav(0.16, MIX_RATE, hit_sample), false)
	_rise = _player("Rise", _wav(0.22, MIX_RATE, rise_sample), false)
	if _audible:
		_music = _player("Music", _wav(music_length(), MUSIC_RATE, music_sample), true)
		_music.volume_db = GameSettings.music_db()
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


func _exit_tree() -> void:
	for player in [_engine, _hit, _rise, _music]:
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


static func _kick(bar_beat: float, beat_s: float) -> float:
	return _hit_tone(bar_beat, 0.0, beat_s, 150.0, 42.0, 22.0) * 0.62 \
		+ _hit_tone(bar_beat, 0.5, beat_s, 120.0, 48.0, 26.0) * 0.28 \
		+ _hit_tone(bar_beat, 1.75, beat_s, 136.0, 46.0, 24.0) * 0.48 \
		+ _hit_tone(bar_beat, 2.5, beat_s, 128.0, 44.0, 24.0) * 0.42 \
		+ _hit_tone(bar_beat, 3.25, beat_s, 160.0, 50.0, 28.0) * 0.36


static func _snare(bar_beat: float, beat_s: float) -> float:
	return _hit_tone(bar_beat, 1.0, beat_s, 196.0, 170.0, 14.0) * 0.34 \
		+ _hit_tone(bar_beat, 3.0, beat_s, 196.0, 170.0, 14.0) * 0.34


static func _hat(bar_beat: float, beat_s: float) -> float:
	var slot := floorf(bar_beat * 2.0) * 0.5
	var accent := 0.16 if int(slot * 2.0) % 2 == 0 else 0.07
	return _hit_tone(bar_beat, slot, beat_s, 6400.0, 6400.0, 70.0) * accent


static func _hit_tone(bar_beat: float, hit: float, beat_s: float, from_hz: float, to_hz: float, decay: float) -> float:
	var local := bar_beat - hit
	if local < 0.0 or local > 0.42:
		return 0.0
	var seconds := local * beat_s
	var freq := lerpf(from_hz, to_hz, clampf(local / 0.08, 0.0, 1.0))
	return sin(TAU * freq * seconds + TAU * 0.25) * exp(-seconds * decay)


static func _local_seconds(bar_beat: float, slots_per_beat: float, beat_s: float) -> float:
	var slot := floorf(bar_beat * slots_per_beat) / slots_per_beat
	return (bar_beat - slot) * beat_s


static func _note(freq: float, seconds: float, decay: float, gain: float) -> float:
	if freq <= 0.0:
		return 0.0
	var body := sin(TAU * freq * seconds + TAU * 0.25) + sin(TAU * freq * 2.0 * seconds) * 0.28
	return body * exp(-seconds * decay) * gain


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
