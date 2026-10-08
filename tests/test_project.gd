extends RefCounted

func run(_tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var width: int = int(ProjectSettings.get_setting("display/window/size/viewport_width"))
	var height: int = int(ProjectSettings.get_setting("display/window/size/viewport_height"))
	var mode: String = str(ProjectSettings.get_setting("display/window/stretch/mode"))
	var aspect: String = str(ProjectSettings.get_setting("display/window/stretch/aspect"))
	var renderer: String = str(ProjectSettings.get_setting("rendering/renderer/rendering_method"))
	if width != 1920:
		failed.append("width %s" % width)
	if height != 1080:
		failed.append("height %s" % height)
	if mode != "viewport":
		failed.append("stretch mode %s" % mode)
	if aspect != "expand":
		failed.append("stretch aspect %s" % aspect)
	if renderer != "forward_plus":
		failed.append("renderer %s" % renderer)
	return failed
