extends Node

const SAVE_PATH := "user://progress.json"
const LEGACY_SAVE_PATH := "user://progress.save"
const SAVE_VERSION := 4
const ProgressStore = preload("res://src/core/progress_store.gd")
const ScoreRules = preload("res://src/core/score_rules.gd")

signal settings_changed

var unlocked := 1
var current_level := 0
var fullscreen := true
var sfx_enabled := true
## Audio levels are linear UI values and are converted to dB by the audio manager.
var master_volume := 1.0
var music_volume := 0.8
var sfx_volume := 1.0
## Accessibility preferences are kept in the same save so they follow the player
## between the title screen, gameplay and the ending scene.
var haptics_enabled := true
var reduced_motion := false
var high_contrast := false
var unlock_all_levels := false
var level_records: Dictionary = {}
var seen_chapters: Array = []
var echo_chamber: Dictionary = {}


func complete_tidal_trial(with_memory: bool) -> void:
	if bool(echo_chamber.get("completed", false)) and (not with_memory or bool(echo_chamber.get("tidal_unlocked", false))):
		return
	echo_chamber["completed"] = true
	if with_memory:
		echo_chamber["memory"] = true
		echo_chamber["tidal_unlocked"] = true
		if not echo_chamber.has("tidal_equipped"):
			echo_chamber["tidal_equipped"] = true
	_save()


func equip_tidal_cosmetic(enabled: bool) -> void:
	if not bool(echo_chamber.get("tidal_unlocked", false)):
		return
	echo_chamber["tidal_equipped"] = enabled
	_save()


func kiro_glow_color() -> Color:
	return Color(.28, .95, .64) if bool(echo_chamber.get("tidal_unlocked", false)) and bool(echo_chamber.get("tidal_equipped", false)) else Color(.12, .92, 1.0)


func _ready() -> void:
	_load()
	if _reconcile_progress():
		_save()
	_apply_fullscreen()
	_apply_audio_settings()


func set_fullscreen(on: bool) -> void:
	if fullscreen == on:
		return
	fullscreen = on
	_apply_fullscreen()
	settings_changed.emit()
	_save()


func set_sfx_enabled(on: bool) -> void:
	if sfx_enabled == on:
		return
	sfx_enabled = on
	_apply_audio_settings()
	settings_changed.emit()
	_save()


func set_master_volume(value: float) -> void:
	var next := clampf(value, 0.0, 1.0)
	if is_equal_approx(master_volume, next):
		return
	master_volume = next
	_apply_audio_settings()
	settings_changed.emit()
	_save()


func set_music_volume(value: float) -> void:
	var next := clampf(value, 0.0, 1.0)
	if is_equal_approx(music_volume, next):
		return
	music_volume = next
	_apply_audio_settings()
	settings_changed.emit()
	_save()


func set_sfx_volume(value: float) -> void:
	var next := clampf(value, 0.0, 1.0)
	if is_equal_approx(sfx_volume, next):
		return
	sfx_volume = next
	_apply_audio_settings()
	settings_changed.emit()
	_save()


func set_haptics_enabled(on: bool) -> void:
	if haptics_enabled == on:
		return
	haptics_enabled = on
	settings_changed.emit()
	_save()


func set_reduced_motion(on: bool) -> void:
	if reduced_motion == on:
		return
	reduced_motion = on
	settings_changed.emit()
	_save()


func set_high_contrast(on: bool) -> void:
	if high_contrast == on:
		return
	high_contrast = on
	settings_changed.emit()
	_save()


func set_unlock_all_levels(on: bool) -> void:
	if unlock_all_levels == on:
		return
	unlock_all_levels = on
	settings_changed.emit()
	_save()


func haptic_feedback(duration_ms := 18, amplitude := 0.28) -> void:
	if not haptics_enabled:
		return
	# Do not call the mobile-only API on desktop/headless builds. Android and iOS
	# both expose the "mobile" feature in Godot, while this guard keeps desktop
	# input and CI completely silent.
	if not OS.has_feature("mobile") and not OS.has_feature("android") and not OS.has_feature("ios"):
		return
	Input.vibrate_handheld(duration_ms, amplitude)


func _apply_fullscreen() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen
		else DisplayServer.WINDOW_MODE_WINDOWED)


func _volume_to_db(value: float) -> float:
	return -80.0 if value <= 0.001 else linear_to_db(value)


func _ensure_audio_buses() -> void:
	var music_bus := AudioServer.get_bus_index(&"Music")
	if music_bus < 0:
		AudioServer.add_bus()
		music_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(music_bus, &"Music")
		AudioServer.set_bus_send(music_bus, &"Master")
	var sfx_bus := AudioServer.get_bus_index(&"SFX")
	if sfx_bus < 0:
		AudioServer.add_bus()
		sfx_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(sfx_bus, &"SFX")
		AudioServer.set_bus_send(sfx_bus, &"Master")


func _apply_audio_settings() -> void:
	_ensure_audio_buses()
	var master_bus := AudioServer.get_bus_index(&"Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, _volume_to_db(master_volume))
		AudioServer.set_bus_mute(master_bus, not sfx_enabled or master_volume <= 0.001)
	var music_bus := AudioServer.get_bus_index(&"Music")
	if music_bus >= 0:
		AudioServer.set_bus_volume_db(music_bus, _volume_to_db(music_volume))
		AudioServer.set_bus_mute(music_bus, music_volume <= 0.001)
	var sfx_bus := AudioServer.get_bus_index(&"SFX")
	if sfx_bus >= 0:
		AudioServer.set_bus_volume_db(sfx_bus, _volume_to_db(sfx_volume))
		AudioServer.set_bus_mute(sfx_bus, sfx_volume <= 0.001)


func is_unlocked(i: int) -> bool:
	if Levels.ALL.is_empty() or i < 0 or i >= Levels.ALL.size():
		return false
	if unlock_all_levels:
		return true
	return i < unlocked


func get_level_record(i: int) -> Dictionary:
	var record: Dictionary = level_records.get(str(i), {})
	if unlock_all_levels:
		var rec := record.duplicate(true)
		rec["completed"] = true
		rec["memory_collected"] = true
		return rec
	return record


func get_level_achievement(i: int) -> Dictionary:
	var record := get_level_record(i)
	var best_run: Dictionary = record.get("best_run", {})
	var legacy: Dictionary = record.get("legacy_achievement", {})
	if unlock_all_levels:
		var base: Dictionary = best_run if not best_run.is_empty() else legacy
		var result: Dictionary = base.duplicate(true)
		result["stars"] = 3
		if not result.has("score_moves"):
			var par_moves := 0
			var level_data: LevelData = Levels.get_data(i)
			if level_data:
				par_moves = level_data.par_moves
			result["score_moves"] = par_moves
			result["actual_moves"] = par_moves
		return result
	if best_run.is_empty():
		return legacy.duplicate(true)
	if legacy.is_empty() or int(best_run.get("stars", 0)) >= int(legacy.get("stars", 0)):
		return best_run.duplicate(true)
	return legacy.duplicate(true)


func get_best_moves(i: int) -> int:
	var achievement := get_level_achievement(i)
	return int(achievement.get("actual_moves", achievement.get("best_moves", 0)))


func get_best_pushes(i: int) -> int:
	return int(get_level_achievement(i).get("pushes", 0))


func get_best_hints(i: int) -> int:
	return int(get_level_achievement(i).get("hint_penalty", -1))


func get_level_stars(i: int, _par_moves := 0) -> int:
	return int(get_level_achievement(i).get("stars", 0))


func set_current_level(i: int) -> void:
	var next := 0
	if not Levels.ALL.is_empty():
		next = clampi(i, 0, Levels.ALL.size() - 1)
		next = clampi(next, 0, maxi(0, unlocked - 1))
	if current_level == next:
		return
	current_level = next
	_save()


func complete_level(i: int, run: Dictionary = {}, memory_collected := false) -> void:
	if i < 0 or i >= Levels.ALL.size():
		return
	unlocked = maxi(unlocked, mini(i + 2, Levels.ALL.size()))
	var key := str(i)
	var record: Dictionary = level_records.get(key, {})
	record["completed"] = true
	if memory_collected:
		record["memory_collected"] = true
	if not run.is_empty():
		var candidate := run.duplicate(true)
		var current: Dictionary = record.get("best_run", {})
		if ScoreRules.is_better_run(candidate, current):
			record["best_run"] = candidate
	level_records[key] = record
	_save()


func has_seen_chapter(chapter: int) -> bool:
	return seen_chapters.has(chapter)


func mark_chapter_seen(chapter: int) -> void:
	if not seen_chapters.has(chapter):
		seen_chapters.append(chapter)
		_save()


func _save() -> void:
	var data := {
		"version": SAVE_VERSION,
		"unlocked": unlocked,
		"current_level": current_level,
		"fullscreen": fullscreen,
		"sfx_enabled": sfx_enabled,
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"haptics_enabled": haptics_enabled,
		"reduced_motion": reduced_motion,
		"high_contrast": high_contrast,
		"unlock_all_levels": unlock_all_levels,
		"levels": level_records,
		"seen_chapters": seen_chapters,
		"echo_chamber": echo_chamber,
	}
	var error := ProgressStore.write_progress(SAVE_PATH, data)
	if error != OK:
		push_error("Khong the luu tien do (%s): %s" % [error_string(error), SAVE_PATH])


func _load() -> void:
	var parsed := ProgressStore.load_progress(SAVE_PATH)
	if not parsed.is_empty():
		unlocked = clampi(int(parsed.get("unlocked", 1)), 1, maxi(1, Levels.ALL.size()))
		current_level = clampi(int(parsed.get("current_level", 0)), 0, maxi(0, unlocked - 1))
		fullscreen = bool(parsed.get("fullscreen", true))
		sfx_enabled = bool(parsed.get("sfx_enabled", true))
		master_volume = clampf(float(parsed.get("master_volume", 1.0)), 0.0, 1.0)
		music_volume = clampf(float(parsed.get("music_volume", 0.8)), 0.0, 1.0)
		sfx_volume = clampf(float(parsed.get("sfx_volume", 1.0)), 0.0, 1.0)
		haptics_enabled = bool(parsed.get("haptics_enabled", true))
		reduced_motion = bool(parsed.get("reduced_motion", false))
		high_contrast = bool(parsed.get("high_contrast", false))
		unlock_all_levels = bool(parsed.get("unlock_all_levels", false))
		level_records = parsed.get("levels", {})
		var loaded_version := int(parsed.get("version", 1))
		_migrate_level_records(loaded_version)
		seen_chapters = parsed.get("seen_chapters", [])
		var trial_data: Variant = parsed.get("echo_chamber", {})
		echo_chamber = trial_data.duplicate() if trial_data is Dictionary else {}
		if loaded_version < SAVE_VERSION:
			_save()
		return
	_load_legacy()


func _migrate_level_records(version: int) -> void:
	if version >= SAVE_VERSION:
		return
	for key in level_records.keys():
		var record: Dictionary = level_records[key]
		if record.has("legacy_achievement") or record.has("best_run"):
			continue
		var best_moves := int(record.get("best_moves", 0))
		if best_moves <= 0:
			continue
		var level_index := int(key)
		var data: LevelData = Levels.get_data(level_index)
		var par_moves := data.par_moves if data else 0
		var stars := 1
		if par_moves <= 0 or best_moves <= par_moves:
			stars = 3
		elif best_moves <= roundi(par_moves * 1.35):
			stars = 2
		record["legacy_achievement"] = {
			"best_moves": best_moves,
			"stars": stars,
			"legacy": true,
		}
		level_records[key] = record


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


func _reconcile_progress() -> bool:
	# Older builds clamped `unlocked` to the four Chapter I levels. Rebuild the
	# frontier from completion records whenever new chapter content is installed.
	var previous_unlocked := unlocked
	var previous_current := current_level
	unlocked = Levels.reconciled_unlocked(level_records, unlocked)
	current_level = clampi(current_level, 0, maxi(0, unlocked - 1))
	return unlocked != previous_unlocked or current_level != previous_current


func reset_progress() -> void:
	unlocked = 1
	current_level = 0
	level_records.clear()
	seen_chapters.clear()
	echo_chamber.clear()
	_save()


func memory_fragment_count() -> int:
	if unlock_all_levels:
		return Levels.ALL.size()
	var count := 0
	for record in level_records.values():
		if record is Dictionary and bool(record.get("memory_collected", false)):
			count += 1
	return count
