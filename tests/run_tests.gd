extends SceneTree

func _initialize() -> void:
	# El árbol todavía no está listo dentro de _initialize. Las pruebas que
	# instancian escenas necesitan _ready inmediato, y eso ocurre al diferir.
	call_deferred("_run_all")


func _run_all() -> void:
	var failed := 0
	var dir := DirAccess.open("res://tests")
	if dir == null:
		print("FAIL tests directory missing")
		quit(1)
		return
	var names: Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.begins_with("test_") and file_name.ends_with(".gd"):
			names.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	names.sort()
	for test_name in names:
		var suite: RefCounted = load("res://tests/%s" % test_name).new()
		var errors: Array = suite.run(self)
		if errors.is_empty():
			print("PASS %s" % test_name)
		else:
			failed += 1
			print("FAIL %s %s" % [test_name, ", ".join(errors)])
	quit(1 if failed > 0 else 0)
