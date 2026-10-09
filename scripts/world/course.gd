class_name Course
extends RefCounted

const STAGE_M := 2000.0

const THEMES: Array[Dictionary] = [
	{
		"id": "ciudad",
		"name": "Ciudad",
		"asphalt": Color(0.16, 0.18, 0.2),
		"paint": Color(0.9, 0.88, 0.84),
		"sky": Color(0.55, 0.72, 0.85),
	},
	{
		"id": "costa",
		"name": "Costa",
		"asphalt": Color(0.24, 0.28, 0.3),
		"paint": Color(0.93, 0.9, 0.78),
		"sky": Color(0.4, 0.68, 0.82),
	},
	{
		"id": "desierto",
		"name": "Desierto",
		"asphalt": Color(0.5, 0.38, 0.22),
		"paint": Color(0.95, 0.84, 0.52),
		"sky": Color(0.86, 0.62, 0.36),
	},
	{
		"id": "bosque",
		"name": "Bosque",
		"asphalt": Color(0.18, 0.22, 0.16),
		"paint": Color(0.74, 0.82, 0.52),
		"sky": Color(0.42, 0.62, 0.46),
	},
	{
		"id": "nieve",
		"name": "Nieve",
		"asphalt": Color(0.72, 0.76, 0.8),
		"paint": Color(0.28, 0.42, 0.58),
		"sky": Color(0.74, 0.82, 0.9),
	},
	{
		"id": "atardecer",
		"name": "Atardecer",
		"asphalt": Color(0.24, 0.14, 0.16),
		"paint": Color(0.95, 0.68, 0.42),
		"sky": Color(0.84, 0.38, 0.3),
	},
	{
		"id": "industrial",
		"name": "Industrial",
		"asphalt": Color(0.2, 0.2, 0.18),
		"paint": Color(0.86, 0.52, 0.16),
		"sky": Color(0.42, 0.4, 0.36),
	},
	{
		"id": "noche",
		"name": "Noche",
		"asphalt": Color(0.07, 0.08, 0.1),
		"paint": Color(0.72, 0.8, 0.95),
		"sky": Color(0.015, 0.02, 0.06),
		"night": true,
	},
]

const WEATHERS: Array[Dictionary] = [
	{"id": "despejado", "name": "Despejado", "grip": 1.0, "fog": 0.0, "sky": Color(1, 1, 1), "mix": 0.0},
	{"id": "lluvia", "name": "Lluvia", "grip": 0.72, "fog": 0.004, "sky": Color(0.35, 0.4, 0.48), "mix": 0.45},
	{"id": "niebla", "name": "Niebla", "grip": 0.88, "fog": 0.016, "sky": Color(0.7, 0.72, 0.74), "mix": 0.55},
]


static func theme_count() -> int:
	return THEMES.size()


static func weather_count() -> int:
	return WEATHERS.size()


static func theme(index: int) -> Dictionary:
	return THEMES[posmod(index, THEMES.size())]


static func weather(index: int) -> Dictionary:
	return WEATHERS[posmod(index, WEATHERS.size())]


static func sky_color(theme_index: int, weather_index: int) -> Color:
	var place: Dictionary = theme(theme_index)
	var state: Dictionary = weather(weather_index)
	return (place["sky"] as Color).lerp(state["sky"], float(state["mix"]))
