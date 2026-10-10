class_name ScoreKeeper
extends RefCounted

const CLEAN_STEP_M := 200.0
const MULTIPLIER_MAX := 5

var score: float = 0.0
var multiplier: int = 1
var clean_m: float = 0.0


func add_clean_distance(meters: float) -> void:
	var left := meters
	while left > 0.0:
		if multiplier >= MULTIPLIER_MAX:
			score += left * float(multiplier)
			left = 0.0
			continue
		var room := CLEAN_STEP_M - clean_m
		var step := minf(left, room)
		score += step * float(multiplier)
		clean_m += step
		left -= step
		if clean_m >= CLEAN_STEP_M:
			clean_m -= CLEAN_STEP_M
			multiplier += 1


func register_hit() -> void:
	multiplier = 1
	clean_m = 0.0


func add_hit_distance(meters: float) -> void:
	score += meters * float(multiplier)


func add_bonus(points: float) -> void:
	score += maxf(0.0, points)
