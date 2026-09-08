extends RefCounted

## Keep the last valid generation until the replacement is fully written.
static func read_valid(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {}
	var value: Variant = parser.data
	if not value is Dictionary or not value.has("unlocked"):
		return {}
	for key in ["version", "unlocked", "current_level"]:
		if value.has(key) and not (value[key] is int or value[key] is float):
			return {}
	if not value.get("levels", {}) is Dictionary or not value.get("seen_chapters", []) is Array:
		return {}
	for record in value.get("levels", {}).values():
		if not record is Dictionary:
			return {}
		for key in ["best_moves", "best_pushes", "best_hints", "hints_used"]:
			if record.has(key) and not (record[key] is int or record[key] is float):
				return {}
		if record.has("best_run"):
			var run: Variant = record["best_run"]
			if not run is Dictionary:
				return {}
			for key in ["actual_moves", "hint_penalty", "score_moves", "pushes", "stars"]:
				if not run.has(key) or not (run[key] is int or run[key] is float) or int(run[key]) < 0:
					return {}
			if int(run.score_moves) != int(run.actual_moves) + int(run.hint_penalty):
				return {}
			if int(run.stars) < 1 or int(run.stars) > 3 or not run.get("perfect", false) is bool:
				return {}
		if record.has("legacy_achievement") and not record["legacy_achievement"] is Dictionary:
			return {}
	return value


static func load_progress(path: String) -> Dictionary:
	for candidate in [path, path + ".bak", path + ".tmp"]:
		var data := read_valid(candidate)
		if not data.is_empty():
			return data
	return {}


static func write_progress(path: String, data: Dictionary) -> Error:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	if read_valid(temporary).is_empty():
		return ERR_FILE_CORRUPT
	# Never replace a good backup with a corrupt primary file.
	if not read_valid(path).is_empty():
		error = DirAccess.copy_absolute(path, path + ".bak")
		if error != OK:
			return error
	return DirAccess.rename_absolute(temporary, path)
