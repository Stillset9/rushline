extends RefCounted

func run(_tree: SceneTree) -> Array:
	var failed: Array[String] = []
	if RaceAudio.pitch_for_speed(70.0) <= RaceAudio.pitch_for_speed(8.0):
		failed.append("pitch")
	if absf(RaceAudio.engine_sample(0.0)) > 0.001:
		failed.append("engine click")
	if absf(RaceAudio.hit_sample(0.01)) <= 0.2:
		failed.append("hit %s" % RaceAudio.hit_sample(0.01))
	if absf(RaceAudio.rise_sample(0.02)) <= 0.05:
		failed.append("rise %s" % RaceAudio.rise_sample(0.02))
	if absf(RaceAudio.music_length() - 6.4) > 0.001:
		failed.append("music length")
	if absf(RaceAudio.music_sample(0.0)) <= 0.2:
		failed.append("downbeat %s" % RaceAudio.music_sample(0.0))
	if absf(RaceAudio.music_sample(3.2)) <= 0.05:
		failed.append("hook %s" % RaceAudio.music_sample(3.2))
	return failed
