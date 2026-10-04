extends Node

const CATALOG = preload("res://src/data/module_motion_catalog.gd")


func _ready() -> void:
	var entries := {}
	for index in range(15):
		var data: LevelData = Levels.get_data(index)
		for deco in data.decorations:
			var kind: String = deco.type
			var path := ""
			if BoardView.DECOR_ASSETS.has(kind):
				path = BoardView.DECOR_ASSETS[kind].path
			elif BoardView.CHAPTER_PROPS.ASSETS.has(kind):
				path = BoardView.CHAPTER_PROPS.ASSETS[kind]
			elif BoardView.MODULAR_PROPS.ASSETS.has(kind):
				path = BoardView.MODULAR_PROPS.ASSETS[kind]
			elif BoardView.MAP_EXPANSION.ASSETS.has(kind):
				path = BoardView.MAP_EXPANSION.ASSETS[kind]
			if bool(deco.get("surface_skin", false)) and BoardView.MAP_EXPANSION.FLOOR_SKINS.has(kind):
				path = BoardView.MAP_EXPANSION.FLOOR_SKINS[kind]
			var profile := CATALOG.profile_for(path, data.chapter)
			if not entries.has(kind):
				entries[kind] = {"type": kind, "path": path, "profile": str(profile), "levels": [],
					"blender_clip": CATALOG.ANIMATED_NAMES.has(path.get_file().get_basename()),
					"decision": "dynamic" if profile != &"" else "static_structure_or_inert_prop"}
			if not entries[kind].levels.has(index + 1):
				entries[kind].levels.append(index + 1)
	var keys := entries.keys()
	keys.sort()
	var output: Array = []
	var dynamic := 0
	for key in keys:
		output.append(entries[key])
		if entries[key].profile != "":
			dynamic += 1
	var file := FileAccess.open("res://docs/MODULE_MOTION_COVERAGE.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(output, "\t") + "\n")
	print("Module coverage: ", entries.size(), " scenery types; ", dynamic, " dynamic; ", entries.size() - dynamic, " structural/inert")
	get_tree().quit()
