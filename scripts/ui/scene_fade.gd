class_name SceneFade
extends CanvasLayer

var _path := ""
var _shade: ColorRect
var _phase := 0
var _time := 0.0


static func to(path: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or path.is_empty():
		return
	if tree.root.get_node_or_null("SceneFade") != null:
		return
	var layer := SceneFade.new()
	layer.name = "SceneFade"
	layer._path = path
	layer.layer = 120
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(layer)


func _ready() -> void:
	_shade = ColorRect.new()
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shade.color = Color(0, 0, 0, 0)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_shade)


func _process(delta: float) -> void:
	if _shade == null:
		return
	_time += delta
	if _phase == 0:
		_shade.color.a = clampf(_time / 0.18, 0.0, 1.0)
		if _time < 0.18:
			return
		_phase = 1
		_time = 0.0
		get_tree().change_scene_to_file(_path)
		return
	if _phase == 1:
		if _time < 0.06:
			return
		_phase = 2
		_time = 0.0
		_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shade.color.a = 1.0 - clampf(_time / 0.26, 0.0, 1.0)
	if _time >= 0.26:
		queue_free()
