class_name StageRun
extends RefCounted

# Etapas seguidas. La recta no se curva: la variedad sale del ancho y del clima.
const STAGES: Array[Dictionary] = [
	{"theme": 0, "weather": 0, "length": 1000.0, "spawn": 1.2, "pressure": 0.18},
	{"theme": 1, "weather": 0, "length": 1200.0, "spawn": 1.1, "pressure": 0.32},
	{"theme": 2, "weather": 2, "length": 1400.0, "spawn": 1.0, "pressure": 0.46},
	{"theme": 3, "weather": 1, "length": 1600.0, "spawn": 0.92, "pressure": 0.58},
	{"theme": 4, "weather": 2, "length": 1800.0, "spawn": 0.84, "pressure": 0.7},
	{"theme": 7, "weather": 1, "length": 2000.0, "spawn": 0.76, "pressure": 0.82},
]


static func count() -> int:
	return STAGES.size()


static func stage(index: int) -> Dictionary:
	return STAGES[clampi(index, 0, STAGES.size() - 1)]


static func playable_half(along: float, pressure: float) -> float:
	var weight := clampf(pressure, 0.0, 1.0)
	var band := int(maxf(along, 0.0) / 90.0) % 6
	match band:
		1, 4:
			return lerpf(6.0, 3.55, weight)
		3:
			return lerpf(6.0, 7.7, weight * 0.9)
		5:
			return lerpf(6.0, 6.4, weight)
		_:
			return 6.0
