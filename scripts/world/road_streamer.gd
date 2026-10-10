class_name RoadStreamer
extends Node3D

const CHUNK_LENGTH := 40.0
const CHUNK_COUNT := 8
const RECYCLE_BEHIND := 20.0

const CHUNK_SCENE := preload("res://scenes/world/road_chunk.tscn")

var pressure := 0.18
var wetness := 0.0
var _chunks: Array[Node3D] = []
var _origins: Array[float] = []


func _ready() -> void:
	for _i in CHUNK_COUNT:
		var chunk: Node3D = CHUNK_SCENE.instantiate()
		add_child(chunk)
		_chunks.append(chunk)


static func initial_origins(player_z: float) -> Array[float]:
	var chunk_origins: Array[float] = []
	for i in CHUNK_COUNT:
		chunk_origins.append(player_z - CHUNK_LENGTH + float(i) * CHUNK_LENGTH)
	return chunk_origins


static func recycle_origins(current_origins: Array, player_z: float) -> Array[float]:
	var result: Array[float] = []
	for origin in current_origins:
		result.append(float(origin))
	var guard := 0
	while guard < 64:
		guard += 1
		var behind := -1
		for i in result.size():
			var front := result[i] + CHUNK_LENGTH
			if front < player_z - RECYCLE_BEHIND and (behind == -1 or result[i] < result[behind]):
				behind = i
		if behind == -1:
			break
		var furthest: float = result[0]
		for origin in result:
			furthest = maxf(furthest, origin)
		# Un frame lento puede dejar varios tramos atrás. Cada uno pasa al final.
		result[behind] = furthest + CHUNK_LENGTH
	return result


func setup(player_z: float) -> void:
	_apply(initial_origins(player_z))


func tick(player_z: float) -> void:
	_apply(recycle_origins(origins(), player_z))
	for index in _chunks.size():
		var chunk := _chunks[index] as RoadChunk
		if chunk == null:
			continue
		var half := StageRun.playable_half(_origins[index] + CHUNK_LENGTH * 0.5, pressure)
		chunk.set_playable(half)
		chunk.apply_wet(wetness)


func origins() -> Array[float]:
	return _origins.duplicate()


func apply_palette(asphalt: Color, paint: Color) -> void:
	for chunk in _chunks:
		if chunk is RoadChunk:
			(chunk as RoadChunk).apply_palette(asphalt, paint)


func _apply(chunk_origins: Array) -> void:
	_origins.clear()
	for i in _chunks.size():
		var origin := float(chunk_origins[i])
		_origins.append(origin)
		CoursePath.place_span(_chunks[i], origin, CHUNK_LENGTH)
