class_name UiAudio
extends RefCounted

static var _tick: AudioStreamWAV


static func blip() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	if _tick == null:
		_tick = _tone()
	var player := AudioStreamPlayer.new()
	player.stream = _tick
	player.volume_db = GameSettings.sfx_db(-8.0)
	player.finished.connect(player.queue_free)
	tree.root.add_child(player)
	player.play()


static func _tone() -> AudioStreamWAV:
	var rate := 22050
	var count := int(0.045 * rate)
	var data := PackedByteArray()
	data.resize(count * 4)
	for i in count:
		var t := float(i) / float(rate)
		var env := exp(-t * 70.0)
		var pcm := int(round(sin(TAU * 880.0 * t) * env * 0.35 * 32767.0))
		data.encode_s16(i * 4, pcm)
		data.encode_s16(i * 4 + 2, pcm)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = true
	wav.data = data
	return wav
