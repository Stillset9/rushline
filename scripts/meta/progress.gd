class_name Progress
extends RefCounted

const PATH := "user://progress.cfg"
const MAX_LEVEL := 3
const COSTS := {
	"motor": [400, 900, 1600],
	"tope": [500, 1100, 2000],
	"nitro": [450, 1000, 1800],
}

static var storage_path := PATH
static var isolated := false

var money: int = 0
var best_score: int = 0
var races: int = 0
var motor: int = 0
var tope: int = 0
var nitro: int = 0
var banked := false


static func load_state() -> Progress:
	var progress := Progress.new()
	if isolated:
		return progress
	var file := ConfigFile.new()
	if file.load(storage_path) != OK:
		return progress
	progress.money = int(file.get_value("save", "money", 0))
	progress.best_score = int(file.get_value("save", "best_score", 0))
	progress.races = int(file.get_value("save", "races", 0))
	progress.motor = int(file.get_value("save", "motor", 0))
	progress.tope = int(file.get_value("save", "tope", 0))
	progress.nitro = int(file.get_value("save", "nitro", 0))
	return progress


func save() -> void:
	if isolated:
		return
	var file := ConfigFile.new()
	file.set_value("save", "money", money)
	file.set_value("save", "best_score", best_score)
	file.set_value("save", "races", races)
	file.set_value("save", "motor", motor)
	file.set_value("save", "nitro", nitro)
	file.set_value("save", "tope", tope)
	file.save(storage_path)


func note_finish(score: int) -> bool:
	if banked:
		return false
	banked = true
	var record := score > best_score
	money += score
	if record:
		best_score = score
	races += 1
	save()
	return record


func level(upgrade_id: String) -> int:
	match upgrade_id:
		"motor":
			return motor
		"tope":
			return tope
		"nitro":
			return nitro
	return 0


func cost_for(upgrade_id: String) -> int:
	var current := level(upgrade_id)
	if current >= MAX_LEVEL or not COSTS.has(upgrade_id):
		return -1
	return int(COSTS[upgrade_id][current])


func buy(upgrade_id: String) -> bool:
	var price := cost_for(upgrade_id)
	if price < 0 or money < price:
		return false
	money -= price
	_set_level(upgrade_id, level(upgrade_id) + 1)
	save()
	return true


func _set_level(upgrade_id: String, value: int) -> void:
	match upgrade_id:
		"motor":
			motor = value
		"tope":
			tope = value
		"nitro":
			nitro = value
