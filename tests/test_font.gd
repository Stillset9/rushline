extends RefCounted

const ROOTS: PackedStringArray = ["res://scripts", "res://scenes"]


func run(_tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var theme: Theme = load("res://ui/rushline_theme.tres")
	var font := theme.default_font
	if font == null:
		failed.append("font")
		return failed
	var samples := {
		"·": "middle",
		"×": "times",
		"á": "a",
		"é": "e",
		"í": "i",
		"ó": "o",
		"ú": "u",
		"ñ": "n",
		"¿": "open",
		"¡": "bang",
	}
	for glyph in samples:
		if not font.has_char(glyph.unicode_at(0)):
			failed.append(samples[glyph])
	var seen := {}
	for path in _files():
		var source := FileAccess.get_file_as_string(path)
		if source == "":
			continue
		for literal in _literals(source):
			for index in literal.length():
				var code := literal.unicode_at(index)
				if code < 32 or font.has_char(code):
					continue
				var key := "%s:%d" % [path, code]
				if seen.has(key):
					continue
				seen[key] = true
				var around := literal.substr(maxi(0, index - 6), 14).replace("\n", " ")
				failed.append("U+%04X %s [%s]" % [code, around, path.get_file()])
				if failed.size() > 12:
					return failed
	return failed


func _files() -> PackedStringArray:
	var found: PackedStringArray = []
	for root in ROOTS:
		_walk(root, found)
	return found


func _walk(path: String, found: PackedStringArray) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name != "." and name != "..":
			var child := "%s/%s" % [path, name]
			if dir.current_is_dir():
				_walk(child, found)
			elif name.ends_with(".gd") or name.ends_with(".tscn"):
				found.append(child)
		name = dir.get_next()
	dir.list_dir_end()


func _literals(source: String) -> PackedStringArray:
	var found: PackedStringArray = []
	var index := 0
	var count := source.length()
	while index < count:
		var mark := source.unicode_at(index)
		if mark == 35:
			while index < count and source.unicode_at(index) != 10:
				index += 1
			continue
		if mark != 34 and mark != 39:
			index += 1
			continue
		var quote := mark
		index += 1
		var piece := ""
		while index < count:
			var code := source.unicode_at(index)
			if code == 92 and index + 1 < count:
				var escaped := source.unicode_at(index + 1)
				match escaped:
					110:
						piece += "\n"
					116:
						piece += "\t"
					_:
						piece += String.chr(escaped)
				index += 2
				continue
			if code == quote:
				index += 1
				break
			piece += String.chr(code)
			index += 1
		if piece != "":
			found.append(piece)
	return found
