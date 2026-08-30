extends Node

const SAVE_PATH := "user://progress.json"
const LEGACY_SAVE_PATH := "user://progress.save"
const SAVE_VERSION := 1

var unlocked := 1
var current_level := 0
var fullscreen := true
var sfx_enabled := true
var level_records: Dictionary = {}
var seen_chapters: Array = []


func _ready() -> void:
	_load()
	_apply_fullscreen()


func set_fullscreen(on: bool) -> void:
	fullscreen = on
	_apply_fullscreen()
	_save()


func set_sfx_enabled(on: bool) -> void:
	sfx_enabled = on
	_save()


func _apply_fullscreen() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen
		else DisplayServer.WINDOW_MODE_WINDOWED)


func is_unlocked(i: int) -> bool:
	return not Levels.ALL.is_empty() and i >= 0 and i < unlocked


func get_level_record(i: int) -> Dictionary:
	return level_records.get(str(i), {})


func get_best_moves(i: int) -> int:
	var rec := get_level_record(i)
	return int(rec.get("best_moves", 0))


func get_best_pushes(i: int) -> int:
	var rec := get_level_record(i)
	return int(rec.get("best_pushes", 0))


func complete_level(i: int, moves := -1, pushes := -1, memory_collected := false) -> void:
	if Levels.ALL.is_empty():
		return
	unlocked = maxi(unlocked, mini(i + 2, Levels.ALL.size()))
	var key := str(i)
	var record: Dictionary = level_records.get(key, {})
	record["completed"] = true
	if moves >= 0:
		var previous_moves := int(record.get("best_moves", 0))
		if previous_moves == 0 or moves < previous_moves:
			record["best_moves"] = moves
	if pushes >= 0:
		var previous_pushes := int(record.get("best_pushes", 0))
		if previous_pushes == 0 or pushes < previous_pushes:
			record["best_pushes"] = pushes
	if memory_collected:
		record["memory_collected"] = true
	level_records[key] = record
	_save()


func has_seen_chapter(chapter: int) -> bool:
	return seen_chapters.has(chapter)


func mark_chapter_seen(chapter: int) -> void:
	if not seen_chapters.has(chapter):
		seen_chapters.append(chapter)
		_save()


func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Khong the mo file save: %s" % SAVE_PATH)
		return
	var data := {
		"version": SAVE_VERSION,
		"unlocked": unlocked,
		"fullscreen": fullscreen,
		"sfx_enabled": sfx_enabled,
		"levels": level_records,
		"seen_chapters": seen_chapters,
	}
	f.store_string(JSON.stringify(data, "\t"))


func _load() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				unlocked = clampi(int(parsed.get("unlocked", 1)), 1, maxi(1, Levels.ALL.size()))
				fullscreen = bool(parsed.get("fullscreen", true))
				sfx_enabled = bool(parsed.get("sfx_enabled", true))
				var records: Variant = parsed.get("levels", {})
				level_records = records if records is Dictionary else {}
				var seen: Variant = parsed.get("seen_chapters", [])
				seen_chapters = seen if seen is Array else []
				return
	_load_legacy()


func _load_legacy() -> void:
	if not FileAccess.file_exists(LEGACY_SAVE_PATH):
		return
	var f := FileAccess.open(LEGACY_SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	if f.get_length() >= 4:
		unlocked = clampi(f.get_32(), 1, maxi(1, Levels.ALL.size()))
	if f.get_length() >= 5:
		fullscreen = f.get_8() != 0
	_save()


func reset_progress() -> void:
	unlocked = 1
	current_level = 0
	level_records.clear()
	seen_chapters.clear()
	_save()


func memory_fragment_count() -> int:
	var count := 0
	for record in level_records.values():
		if record is Dictionary and bool(record.get("memory_collected", false)):
			count += 1
	return count
