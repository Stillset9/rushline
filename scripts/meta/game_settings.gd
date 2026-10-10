class_name GameSettings
extends RefCounted

const PATH := "user://settings.cfg"

static var isolated := false
const LEVELS: Array[String] = ["bajo", "medio", "alto"]

static var music := 0.35
static var sfx := 1.0
static var muted := false
static var quality := "medio"


static func load_state() -> void:
	if isolated:
		return
	var file := ConfigFile.new()
	if file.load(PATH) != OK:
		return
	music = clampf(float(file.get_value("audio", "music", music)), 0.0, 1.0)
	sfx = clampf(float(file.get_value("audio", "sfx", sfx)), 0.0, 1.0)
	muted = bool(file.get_value("audio", "muted", false))
	var stored := str(file.get_value("video", "quality", quality))
	quality = stored if LEVELS.has(stored) else "medio"


static func save() -> void:
	if isolated:
		return
	var file := ConfigFile.new()
	file.set_value("audio", "music", music)
	file.set_value("audio", "sfx", sfx)
	file.set_value("audio", "muted", muted)
	file.set_value("video", "quality", quality)
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


static func cycle_quality(direction: int) -> void:
	var index := LEVELS.find(quality)
	if index < 0:
		index = 1
	quality = LEVELS[posmod(index + direction, LEVELS.size())]


static func quality_name() -> String:
	match quality:
		"bajo":
			return "Bajo"
		"alto":
			return "Alto"
		_:
			return "Medio"
