class_name Contact
extends RefCounted

const BODY_HALF_X := 0.9
const BODY_HALF_Z := 2.0
const SPEED_DROP := 15.0


static func half_extents(scale_factor: float) -> Vector2:
	return Vector2(BODY_HALF_X, BODY_HALF_Z) * scale_factor


static func overlaps(a_center: Vector2, a_half: Vector2, b_center: Vector2, b_half: Vector2) -> bool:
	var separated_x := absf(a_center.x - b_center.x) >= a_half.x + b_half.x
	var separated_z := absf(a_center.y - b_center.y) >= a_half.y + b_half.y
	return not separated_x and not separated_z


static func speed_after_hits(speed: float, hits: int) -> float:
	var result := speed
	for _i in hits:
		result = maxf(PlayerController.MIN_SPEED_MPS, result - SPEED_DROP)
	return result
