class_name BoardGeometry
extends RefCounted

const MAP_EXPANSION = preload("res://src/data/map_expansion.gd")

const BAKED := "res://assets/models/baked/"
const FLOOR_TILE_PATH := BAKED + "Floor-Tile.glb"
const WALL_PILLAR_PATH := BAKED + "Pillar.glb"
const WALL_MODULE_PATH := BAKED + "Wall-Module.glb"
const FLOOR_TOP_Y := 0.154
const COLOR_ELEVATOR := Color(0.15, 0.95, 0.75)
const CHAPTER_FLOOR_TILES := {
	1: "res://assets/models/map_surfaces/archive_floor_variant.glb",
	2: "res://assets/models/map_surfaces/foundry_floor_variant.glb",
	3: "res://assets/models/map_surfaces/sanctuary_floor_variant.glb",
	4: "res://assets/models/map_surfaces/core_floor_variant.glb",
}

var layer_roots: Dictionary = {}
var floor_preview_roots: Dictionary = {}
var visible_floor := 0
var sequential_floors := false


func reset() -> void:
	layer_roots.clear()
	floor_preview_roots.clear()
	visible_floor = 0
	sequential_floors = false


func create_layer_roots(root: Node3D, logic: GameLogic) -> void:
	sequential_floors = logic.sequential_floors
	visible_floor = logic.active_floor
	for floor in logic.floor_count():
		var layer := Node3D.new()
		layer.name = "Floor_%d" % (floor + 1)
		root.add_child(layer)
		layer_roots[floor] = layer


func layer_parent(root: Node3D, cell: Vector3i) -> Node3D:
	return layer_roots.get(cell.y, root) as Node3D


func build_base(
		root: Node3D,
		logic: GameLogic,
		decorations: Array,
		materials: Dictionary,
		spawn: Callable,
		world_position: Callable,
		floor_surface_y: Callable,
		chapter := 1) -> void:
	var decor_wall_cells := {}
	var floor_skin_cells := {}
	var water_gap_cells := {}
	for decoration in decorations:
		if not decoration is Dictionary:
			continue
		var cell: Variant = decoration.get("grid_position", null)
		if cell is Vector3i and bool(decoration.get("water_gap", false)):
			water_gap_cells[cell] = true
		if cell is Vector3i and logic.walls.has(cell):
			decor_wall_cells[cell] = true
		if cell is Vector3i \
				and bool(decoration.get("surface_skin", false)) \
				and MAP_EXPANSION.FLOOR_SKINS.has(str(decoration.get("type", ""))):
			floor_skin_cells[cell] = true

	var board_bounds := bounds(logic)
	for raw_cell in logic.floors.keys():
		var cell: Vector3i = raw_cell
		if water_gap_cells.has(cell):
			continue
		var parent := layer_parent(root, cell)
		var position: Vector3 = world_position.call(cell)
		var on_x_edge: bool = cell.x == int(board_bounds["min_x"]) or cell.x == int(board_bounds["max_x"])
		var on_z_edge: bool = cell.z == int(board_bounds["min_z"]) or cell.z == int(board_bounds["max_z"])
		var is_outer_wall: bool = logic.walls.has(cell) and (on_x_edge or on_z_edge)
		if not is_outer_wall:
			MeshFactory.box(parent, position + Vector3(0, -0.18, 0), Vector3(0.98, 0.34, 0.98), materials["platform"])
			if not logic.walls.has(cell):
				if _platform_edge(logic, cell, Vector3i.RIGHT):
					MeshFactory.box(parent, position + Vector3(0.49, -0.18, 0), Vector3(0.035, 0.34, 0.92), materials["platform_edge"])
				if _platform_edge(logic, cell, Vector3i.LEFT):
					MeshFactory.box(parent, position + Vector3(-0.49, -0.18, 0), Vector3(0.035, 0.34, 0.92), materials["platform_edge"])
				if _platform_edge(logic, cell, Vector3i.BACK):
					MeshFactory.box(parent, position + Vector3(0, -0.18, 0.49), Vector3(0.92, 0.34, 0.035), materials["platform_edge"])
				if _platform_edge(logic, cell, Vector3i.FORWARD):
					MeshFactory.box(parent, position + Vector3(0, -0.18, -0.49), Vector3(0.92, 0.34, 0.035), materials["platform_edge"])
		if not is_outer_wall and not floor_skin_cells.has(cell):
			var floor_path: String = CHAPTER_FLOOR_TILES.get(chapter, FLOOR_TILE_PATH)
			var tile: Node3D = spawn.call(parent, floor_path, position, position.y)
			if tile == null:
				MeshFactory.box(parent, position, Vector3(0.98, 0.08, 0.98), materials["floor"])
				MeshFactory.box(parent, position + Vector3(0, 0.065, -0.43), Vector3(0.72, 0.018, 0.018), materials["grid"])
				MeshFactory.box(parent, position + Vector3(-0.43, 0.065, 0), Vector3(0.018, 0.018, 0.72), materials["grid"])

	for raw_cell in logic.walls.keys():
		var cell: Vector3i = raw_cell
		if decor_wall_cells.has(cell):
			continue
		var on_x_edge: bool = cell.x == int(board_bounds["min_x"]) or cell.x == int(board_bounds["max_x"])
		var on_z_edge: bool = cell.z == int(board_bounds["min_z"]) or cell.z == int(board_bounds["max_z"])
		var parent := layer_parent(root, cell)
		var position: Vector3 = world_position.call(cell)
		if on_x_edge and on_z_edge:
			var corner: Node3D = spawn.call(parent, WALL_PILLAR_PATH, position, floor_surface_y.call(cell))
			if corner == null:
				MeshFactory.box(parent, position + Vector3(0, 0.46, 0), Vector3.ONE, materials["wall"])
			continue
		if on_x_edge or on_z_edge:
			var panel: Node3D = spawn.call(parent, WALL_MODULE_PATH, position, floor_surface_y.call(cell))
			if panel != null:
				if on_x_edge:
					panel.rotate_y(deg_to_rad(90.0))
				continue
			MeshFactory.box(parent, position + Vector3(0, 0.31, 0), Vector3(0.94, 0.62, 0.94), materials["wall"])
			continue
		var pillar: Node3D = spawn.call(parent, WALL_PILLAR_PATH, position, floor_surface_y.call(cell))
		if pillar == null:
			MeshFactory.box(parent, position + Vector3(0, 0.46, 0), Vector3.ONE, materials["wall"])
			MeshFactory.box(parent, position + Vector3(0, 0.965, 0), Vector3(0.82, 0.035, 0.82), materials["wall_edge"])


func build_floor_previews(root: Node3D, logic: GameLogic, edge_color: Color, world_position: Callable) -> void:
	if not logic.sequential_floors:
		return
	var structure_material := MeshFactory.transparent_mat(Color(edge_color.r, edge_color.g, edge_color.b, 0.34), 0.65)
	for raw_position in logic.elevators.keys():
		var position: Vector3i = raw_position
		if position.y <= 0 or not logic.elevator_links.has(position):
			continue
		var lower := logic.elevator_destination(position)
		if lower.y >= position.y:
			continue
		var preview := Node3D.new()
		preview.name = "Floor_%d_Approach" % (position.y + 1)
		root.add_child(preview)
		floor_preview_roots[position.y] = preview
		var upper: Vector3 = world_position.call(position)
		MeshFactory.box(preview, upper + Vector3(0, -0.49, 0), Vector3(1.18, 0.10, 1.18), structure_material)
		for offset in [Vector3(-0.42, -0.76, -0.42), Vector3(0.42, -0.76, 0.42)]:
			MeshFactory.box(preview, upper + offset, Vector3(0.075, 0.52, 0.075), structure_material)


func set_active_floor(floor: int) -> int:
	visible_floor = maxi(0, floor)
	for layer in layer_roots.keys():
		var root: Node3D = layer_roots[layer]
		root.visible = not sequential_floors or int(layer) == visible_floor
	for preview_floor in floor_preview_roots.keys():
		var preview: Node3D = floor_preview_roots[preview_floor]
		preview.visible = sequential_floors and int(preview_floor) == visible_floor + 1
	return visible_floor


func bounds(logic: GameLogic) -> Dictionary:
	var min_x := INF
	var max_x := -INF
	var min_z := INF
	var max_z := -INF
	for raw_cell in logic.floors.keys():
		var cell: Vector3i = raw_cell
		min_x = minf(min_x, float(cell.x))
		max_x = maxf(max_x, float(cell.x))
		min_z = minf(min_z, float(cell.z))
		max_z = maxf(max_z, float(cell.z))
	return {"min_x": min_x, "max_x": max_x, "min_z": min_z, "max_z": max_z}


func _platform_edge(logic: GameLogic, cell: Vector3i, direction: Vector3i) -> bool:
	var neighbor := cell + direction
	return not logic.floors.has(neighbor) or logic.walls.has(neighbor)
