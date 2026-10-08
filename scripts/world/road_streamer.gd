class_name RoadStreamer
extends Node3D

const CHUNK_LENGTH := 40.0
const CHUNK_COUNT := 8
const RECYCLE_BEHIND := 20.0

const CHUNK_SCENE := preload("res://scenes/world/road_chunk.tscn")

var _chunks: Array[Node3D] = []


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


func origins() -> Array[float]:
	var values: Array[float] = []
	for chunk in _chunks:
		values.append(chunk.position.z)
	return values


func _apply(chunk_origins: Array) -> void:
	for i in _chunks.size():
		_chunks[i].position = Vector3(0.0, 0.0, float(chunk_origins[i]))
