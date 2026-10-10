class_name FuelTank
extends RefCounted

const CAPACITY := 100.0
const PER_METER := 0.045
const NITRO_PER_METER := 0.02
const CRASH_COST := 18.0
const WALL_COST := 9.0
const PICKUP := 26.0
const BONUS := 300.0
const CHECKPOINT := 38.0

var amount: float = CAPACITY


func drain(meters: float, boosting: bool) -> bool:
	var cost := maxf(0.0, meters) * PER_METER
	if boosting:
		cost += maxf(0.0, meters) * NITRO_PER_METER
	return spend(cost)


func spend(cost: float) -> bool:
	amount = maxf(0.0, amount - maxf(0.0, cost))
	return empty()


func add(gain: float) -> void:
	amount = minf(CAPACITY, amount + maxf(0.0, gain))


func empty() -> bool:
	return amount <= 0.001


func fraction() -> float:
	return clampf(amount / CAPACITY, 0.0, 1.0)
