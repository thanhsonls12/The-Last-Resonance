@tool
class_name GridMapEditorController
extends Node3D

# Attach this script to GridMap Level Editor Scene.
# Allows loading existing levels onto GridMap or exporting GridMap to a new Level Resource!

@export_group("GridMap Sync Actions")
@export var target_level_index: int = 0
@export var export_level_title: String = "GridMap Level"

@export var action_load_from_level_data: bool = false:
	set(val):
		if val:
			_load_current_level_into_gridmap()

@export var action_save_to_level_resource: bool = false:
	set(val):
		if val:
			_save_gridmap_to_level_resource()

@export var action_clear_gridmap: bool = false:
	set(val):
		if val:
			var gm := get_node_or_null("GridMap") as GridMap
			if gm:
				gm.clear()

func _load_current_level_into_gridmap() -> void:
	var gm := get_node_or_null("GridMap") as GridMap
	if not gm:
		print("GridMap node not found!")
		return
	var data: LevelData = Levels.get_data(target_level_index)
	if not data:
		print("LevelData not found for index: ", target_level_index)
		return
	GridMapLevelSync.import_level_data_to_gridmap(data, gm)
	print("[GridMap] Loaded level #%d: '%s' into GridMap." % [target_level_index, data.title])

func _save_gridmap_to_level_resource() -> void:
	var gm := get_node_or_null("GridMap") as GridMap
	if not gm:
		print("GridMap node not found!")
		return
	var level_data := GridMapLevelSync.export_gridmap_to_level_data(gm, export_level_title)
	if not level_data:
		print("GridMap is empty or invalid.")
		return
	var save_path := "res://resources/levels/gridmap_exported_level.tres"
	var err := ResourceSaver.save(level_data, save_path)
	if err == OK:
		print("[GridMap] Successfully exported level to: ", save_path)
	else:
		print("[GridMap] Error saving level: ", err)
