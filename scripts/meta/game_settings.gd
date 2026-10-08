class_name GameSettings
extends RefCounted

const PATH := "user://settings.cfg"

static var isolated := false
static var music := 0.35
static var sfx := 1.0
static var muted := false


static func load_state() -> void:
	if isolated:
		return
	var file := ConfigFile.new()
	if file.load(PATH) != OK:
		return
	music = clampf(float(file.get_value("audio", "music", music)), 0.0, 1.0)
	sfx = clampf(float(file.get_value("audio", "sfx", sfx)), 0.0, 1.0)
	muted = bool(file.get_value("audio", "muted", false))


static func save() -> void:
	if isolated:
		return
	var file := ConfigFile.new()
	file.set_value("audio", "music", music)
	file.set_value("audio", "sfx", sfx)
	file.set_value("audio", "muted", muted)
	file.save(PATH)


static func music_db() -> float:
	if muted or music <= 0.001:
		return -80.0
	return linear_to_db(music)


static func sfx_db(base_db: float) -> float:
	if muted or sfx <= 0.001:
		return -80.0
	return base_db + linear_to_db(sfx)


static func music_percent() -> int:
	return int(round(music * 100.0))


static func sfx_percent() -> int:
	return int(round(sfx * 100.0))
