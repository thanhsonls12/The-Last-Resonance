@tool
class_name GridMapLevelSync
extends RefCounted

# Utility to convert between GridMap 3D and The Last Resonance LevelData / GameLogic

# Name mappings from MeshLibrary item names to Level characters/types
const ITEM_TO_LOGIC: Dictionary = {
	"Floor_Tile": " ",
	"Pillar_Wall": "#",
	"Wall_Module": "#",
	"Corner_Wall": "#",
	"Core_Pedestal": ".",
	"Energy_Core": "$",
	"Pressure_Plate": "p",
	"Door": "D",
	"Portal": "a",
	"Elevator": "e",
	"Bridge": "r",
}

const ITEM_TO_DECORATION: Dictionary = {
	"Data_Storage_Rack": "data_rack",
	"Archive_Shelf": "archive_shelf",
	"Archive_Workbench": "workbench",
	"Hologram_Projector": "holo",
	"Cargo_Crate": "crate",
	"Machine_Unit": "machine",
	"Pipe_Cluster": "pipe",
	"Cable_Coil": "cable",
	"SciFi_Lamp": "lamp",
	"Broken_Wall": "broken_wall",
	"Broken_Pillar": "broken_pillar",
	"Broken_Robot": "broken_robot",
	"Debris_Pile": "debris",
	"Rubble_Patch": "rubble",
	"Moss_Patch": "moss",
	"Plant_Cluster": "plant",
	"Rock_Cluster": "rock",
	"Door_Frame": "door_frame",
}


static func export_gridmap_to_level_data(gridmap: GridMap, level_title := "Custom Level", chapter := 1) -> LevelData:
	if not gridmap or not gridmap.mesh_library:
		return null
	
	var mesh_lib := gridmap.mesh_library
	var used_cells := gridmap.get_used_cells()
	if used_cells.is_empty():
		return null
	
	var min_x := 999999
	var max_x := -999999
	var min_z := 999999
	var max_z := -999999
	
	for cell in used_cells:
		min_x = mini(min_x, cell.x)
		max_x = maxi(max_x, cell.x)
		min_z = mini(min_z, cell.z)
		max_z = maxi(max_z, cell.z)
	
	var width := max_x - min_x + 1
	var depth := max_z - min_z + 1
	
	var grid_chars: Dictionary = {}
	var decorations: Array = []
	
	for cell in used_cells:
		var item_id := gridmap.get_cell_item(cell)
		if item_id == GridMap.INVALID_CELL_ITEM:
			continue
		var item_name := mesh_lib.get_item_name(item_id)
		var rel_x := cell.x - min_x
		var rel_z := cell.z - min_z
		var grid_pos := Vector3i(rel_x, cell.y, rel_z)
		
		# Check if it maps to map character
		if ITEM_TO_LOGIC.has(item_name):
			grid_chars[Vector2i(rel_x, rel_z)] = ITEM_TO_LOGIC[item_name]
		elif ITEM_TO_DECORATION.has(item_name):
			decorations.append({
				"type": ITEM_TO_DECORATION[item_name],
				"grid_position": grid_pos,
				"yaw": 0.0
			})
			# Ensure there is a floor tile under decoration
			if not grid_chars.has(Vector2i(rel_x, rel_z)):
				grid_chars[Vector2i(rel_x, rel_z)] = " "
	
	# Build ASCII map array
	var map_lines: Array[String] = []
	for z in depth:
		var line := ""
		for x in width:
			var key := Vector2i(x, z)
			line += grid_chars.get(key, "#")
		map_lines.append(line)
	
	var level_data := LevelData.new()
	level_data.title = level_title
	level_data.chapter = chapter
	level_data.difficulty = 1
	level_data.par_moves = 0
	level_data.map = map_lines
	level_data.decorations = decorations
	return level_data


static func import_level_data_to_gridmap(level_data: LevelData, gridmap: GridMap) -> void:
	if not level_data or not gridmap or not gridmap.mesh_library:
		return
	
	gridmap.clear()
	var mesh_lib := gridmap.mesh_library
	
	# Build reverse lookup for item names to item IDs
	var name_to_id: Dictionary = {}
	for item_id in mesh_lib.get_item_list():
		name_to_id[mesh_lib.get_item_name(item_id)] = item_id
	
	# Paint Map characters
	for z in level_data.map.size():
		var row: String = level_data.map[z]
		for x in row.length():
			var char_code := row[x]
			var pos := Vector3i(x, 0, z)
			
			match char_code:
				"#":
					if name_to_id.has("Pillar_Wall"):
						gridmap.set_cell_item(pos, name_to_id["Pillar_Wall"])
				" ":
					if name_to_id.has("Floor_Tile"):
						gridmap.set_cell_item(pos, name_to_id["Floor_Tile"])
				".":
					if name_to_id.has("Core_Pedestal"):
						gridmap.set_cell_item(pos, name_to_id["Core_Pedestal"])
				"$":
					if name_to_id.has("Energy_Core"):
						gridmap.set_cell_item(pos, name_to_id["Energy_Core"])
				"p":
					if name_to_id.has("Pressure_Plate"):
						gridmap.set_cell_item(pos, name_to_id["Pressure_Plate"])
				"D":
					if name_to_id.has("Door"):
						gridmap.set_cell_item(pos, name_to_id["Door"])
				"a", "b":
					if name_to_id.has("Portal"):
						gridmap.set_cell_item(pos, name_to_id["Portal"])
				"e":
					if name_to_id.has("Elevator"):
						gridmap.set_cell_item(pos, name_to_id["Elevator"])
				"r":
					if name_to_id.has("Bridge"):
						gridmap.set_cell_item(pos, name_to_id["Bridge"])
				"@":
					if name_to_id.has("Floor_Tile"):
						gridmap.set_cell_item(pos, name_to_id["Floor_Tile"])
	
	# Paint Decorations
	for deco in level_data.decorations:
		if not deco is Dictionary:
			continue
		var type: String = str(deco.get("type", ""))
		var pos: Variant = deco.get("grid_position", null)
		if not pos is Vector3i:
			continue
		
		# Find matching item
		for item_name in ITEM_TO_DECORATION.keys():
			if ITEM_TO_DECORATION[item_name] == type and name_to_id.has(item_name):
				gridmap.set_cell_item(pos, name_to_id[item_name])
				break
