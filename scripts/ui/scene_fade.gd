class_name SceneFade
extends RefCounted


static func to(path: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 120
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(shade)
	tree.root.add_child(layer)
	var tween := tree.create_tween()
	tween.tween_property(shade, "color:a", 1.0, 0.22)
	tween.tween_callback(func() -> void: tree.change_scene_to_file(path))
