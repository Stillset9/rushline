extends SceneTree

class _ScriptErrorProbe:
	extends Logger
	var saw_script_error := false

	func _log_error(
		_function: String,
		_file: String,
		_line: int,
		_code: String,
		_rationale: String,
		_editor_notify: bool,
		error_type: int,
		_script_backtraces: Array
	) -> void:
		if error_type == Logger.ERROR_TYPE_SCRIPT:
			saw_script_error = true


func _initialize() -> void:
	# El árbol todavía no está listo dentro de _initialize. Las pruebas que
	# instancian escenas necesitan _ready inmediato, y eso ocurre al diferir.
	call_deferred("_run_all")


func _run_all() -> void:
	Progress.isolated = true
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
		var script: GDScript = load("res://tests/%s" % test_name)
		if script == null:
			failed += 1
			print("FAIL %s failed to load" % test_name)
			continue
		var suite: RefCounted = script.new()
		var probe := _ScriptErrorProbe.new()
		OS.add_logger(probe)
		var errors = suite.run(self)
		OS.remove_logger(probe)
		if errors == null or not (errors is Array) or probe.saw_script_error:
			failed += 1
			print("FAIL %s script error" % test_name)
			continue
		if errors.is_empty():
			print("PASS %s" % test_name)
		else:
			failed += 1
			print("FAIL %s %s" % [test_name, ", ".join(errors)])
	quit(1 if failed > 0 else 0)
