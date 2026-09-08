class_name BoardView
extends Node3D

const COLOR_FLOOR := Color(0.10, 0.09, 0.18)
const COLOR_PLATFORM := Color(0.07, 0.05, 0.13)
const COLOR_PLATFORM_EDGE := Color(0.09, 0.15, 0.24)
const COLOR_GRID := Color(0.11, 0.20, 0.30)
const COLOR_WALL := Color(0.16, 0.22, 0.35)
const COLOR_WALL_EDGE := Color(0.13, 0.22, 0.33)
const COLOR_GOAL := Color(0.12, 0.95, 1.0)
const COLOR_PLATE := Color(1.0, 0.78, 0.12)
const COLOR_DOOR := Color(0.95, 0.18, 0.18)
const COLOR_PORTAL := Color(0.80, 0.25, 1.0)
const COLOR_ELEVATOR := Color(0.15, 0.95, 0.75)
const COLOR_BRIDGE := Color(1.0, 0.45, 0.15)
const COLOR_ENERGY := Color(0.35, 1.0, 0.88)
const COLOR_BLOCK := Color(0.55, 0.18, 0.85)
const COLOR_BLOCK_EDGE := Color(0.90, 0.45, 1.0)
const COLOR_PLAYER := Color(0.92, 0.12, 0.34)
const COLOR_ARCHIVE_STEEL := Color(0.035, 0.055, 0.085)
const COLOR_ARCHIVE_PANEL := Color(0.055, 0.085, 0.13)
const COLOR_ARCHIVE_CYAN := Color(0.10, 0.82, 1.0)
const COLOR_ARCHIVE_AMBER := Color(1.0, 0.30, 0.08)
const COLOR_FOUNDRY_STEEL := Color(0.075, 0.045, 0.032)
const COLOR_FOUNDRY_PANEL := Color(0.15, 0.07, 0.025)
const COLOR_FOUNDRY_ORANGE := Color(1.0, 0.32, 0.055)
## Central Core palette: a cold, almost sacred reactor space. Cyan carries the
## live network, violet marks EVA's presence, and amber is reserved for Elias'
## archival signal and the active Energy Node.
const COLOR_CORE_STEEL := Color(0.018, 0.028, 0.050)
const COLOR_CORE_PANEL := Color(0.035, 0.075, 0.120)
const COLOR_CORE_RECESS := Color(0.006, 0.014, 0.026)
const COLOR_CORE_CYAN := Color(0.72, 0.94, 1.0)
const COLOR_CORE_TEAL := Color(0.30, 0.78, 0.88)
const COLOR_CORE_VIOLET := Color(0.42, 0.35, 0.66)
const COLOR_CORE_AMBER := Color(1.0, 0.64, 0.22)
const COLOR_CORE_GRID := Color(0.16, 0.42, 0.52)
const COLOR_CORE_WALL_EDGE := Color(0.32, 0.60, 0.72)
const COLOR_CORE_BLOCK := Color(0.34, 0.20, 0.68)
const KIRO_MODEL_PATH := "res://assets/models/animations/Kiro_K7/Kiro_K7_Animation_Library.glb"
const KIRO_MODEL_SCALE := 0.28
const KIRO_MODEL_FLOOR_OFFSET := -0.38
const EVA_MODEL_PATH := "res://assets/models/characters/EVA_v5.glb"
const HOLOGRAM_SHADER_PATH := "res://assets/shaders/hologram_eva.gdshader"
const ENERGY_CABLE_SHADER_PATH := "res://assets/shaders/energy_cable_flow.gdshader"
const WATER_SHADER_PATH := "res://assets/shaders/ice_water_sanctuary.gdshader"
const FRAGMENT_SHADER_PATH := "res://assets/shaders/resonance_fragment.gdshader"
const ENERGY_CABLE_PATH := "res://assets/models/gameplay/Interaction/Energy-Cable.glb"
const FRAGMENT_MODEL_PATH := "res://assets/models/gameplay/Core/Memory-Fragment.glb"
const ELIAS_MODEL_PATH := "res://assets/models/characters/Dr-Elias-Vale_v3.glb"

const BAKED := "res://assets/models/baked/"
const CHAPTER_PROPS = preload("res://src/data/chapter_props.gd")
const MODULAR_PROPS = preload("res://src/data/modular_props.gd")
const MATERIAL_PROFILES = preload("res://src/data/chapter_material_profiles.gd")
const RENDER_QUALITY = preload("res://src/data/render_quality.gd")
# The Blender modular kit is authored on a 2-unit cell; gameplay uses 1 unit.
const ASSET_SCALE := 0.5
const FLOOR_TILE_PATH := BAKED + "Floor-Tile.glb"
const WALL_PILLAR_PATH := BAKED + "Pillar.glb"
const WALL_MODULE_PATH := BAKED + "Wall-Module.glb"
const PEDESTAL_PATH := BAKED + "Core-Pedestal.glb"
const ENERGY_CORE_PATH := BAKED + "Energy-Core.glb"
const PLATE_PATH := BAKED + "Pressure-Plate.glb"
const FLOOR_TOP_Y := 0.154
const BLOCK_ROOT_HEIGHT := 0.45

const DECOR_ASSETS := {
	"archive_shelf": {"path": BAKED + "Archive-Shelf.glb"},
	"data_rack": {"path": BAKED + "Data-Storage-Rack.glb"},
	"holo": {"path": BAKED + "Hologram-Projector.glb"},
	"workbench": {"path": BAKED + "Archive-Workbench.glb"},
	"broken_robot": {"path": BAKED + "Broken-Robot.glb"},
	"debris": {"path": BAKED + "Debris-Pile.glb"},
	"plant": {"path": BAKED + "Plant-Cluster.glb"},
	"moss": {"path": BAKED + "Moss-Patch.glb"},
	"rock": {"path": BAKED + "Rock-Cluster.glb"},
	"cable": {"path": BAKED + "Cable-Coil.glb"},
	"crate": {"path": BAKED + "Cargo-Crate.glb"},
	"pipe": {"path": BAKED + "Pipe-Cluster.glb"},
	"machine": {"path": BAKED + "Machine-Unit.glb"},
	"conveyor": {"path": BAKED + "Conveyor.glb"},
	"door_frame": {"path": BAKED + "Door-Frame.glb"},
	"lamp": {"path": BAKED + "SciFi-Lamp.glb"},
	"broken_pillar": {"path": BAKED + "Broken-Pillar.glb"},
	"rubble": {"path": BAKED + "Rubble-Patch.glb"},
	"broken_wall": {"path": BAKED + "Broken-Wall.glb"},
	"bookshelf": {"path": BAKED + "Archive-Bookshelf.glb"},
	"data_vault": {"path": BAKED + "Archive-Data-Vault.glb"},
	"broken_column": {"path": BAKED + "Archive-Broken-Column.glb"},
	"terminal": {"path": BAKED + "Archive-Terminal.glb"},
	"plinth": {"path": BAKED + "Archive-Plinth.glb"},
	"holo_projector": {"path": BAKED + "Archive-Holo-Projector.glb"},
	"railing": {"path": BAKED + "Railing-Module.glb"},
	"stair": {"path": BAKED + "Stair-Module.glb"},
	"window": {"path": BAKED + "Window-Module.glb"},
	"ceiling": {"path": BAKED + "Ceiling-Module.glb"},
	"energy_cable": {"path": "res://assets/models/gameplay/Interaction/Energy-Cable.glb"},
	"terminal_desk": {"path": BAKED + "Terminal.glb"},
	"switch": {"path": BAKED + "Switch.glb"},
	"archive_lock_node": {"path": BAKED + "Machine-Unit.glb"},
	"foundry_line": {"path": BAKED + "Conveyor.glb"},
	"k_series_mold": {"path": BAKED + "Broken-Robot.glb"},
	"bridge_console": {"path": BAKED + "Terminal.glb"},
	"reactor_switch": {"path": BAKED + "Switch.glb"},
	"soul_archive": {"path": BAKED + "Narrative-soul_archive.glb"},
	# Chapter III landmarks reuse the baked portal/plinth meshes with semantic
	# names, so level resources can describe the Flooded Sanctuary directly.
	"sanctuary_pool": {"path": BAKED + "Portal.glb"},
	"resonance_altar": {"path": BAKED + "Archive-Plinth.glb"},
	"silence_reliquary": {"path": BAKED + "Narrative-silence_reliquary.glb"},
	"elias_testament": {"path": BAKED + "Narrative-elias_testament.glb"},
	"eva_conduit": {"path": BAKED + "Narrative-eva_conduit.glb"},
	"judgement_engine": {"path": BAKED + "Narrative-judgement_engine.glb"},
}

static var _asset_cache: Dictionary = {}
var decor_nodes := []
var sector_power_lights: Array[Dictionary] = []
var sector_power_materials: Array[Dictionary] = []
var _is_sector_powered: bool = false
var _flicker_timer: float = 0.0
## LevelData.power_level of the level currently built. 0 = emergency power only.
var power_level: float = 0.0
## Controls the material and architectural palette used for the current sector.
var chapter: int = 1
## Stable palette identifier used by diagnostics and UI/theme integrations.
var palette_name: StringName = &"archive"




var player_node: Node3D
var player_animation: AnimationPlayer
var player_visual_offset := Vector3.ZERO
var _current_clip: StringName = &""
var _turn_tween: Tween
var block_nodes := {}
var plate_nodes := {}
var plate_status_materials := {}
var plate_status_lights := {}
var door_nodes := {}
var door_status_lights := {}
## Door position -> its own edge material, so two doors in different states never
## share one colour.
var door_status_materials := {}
## Door group -> cable material for that group's plate/door trace.
var lock_cable_materials := {}
var lock_cable_material: StandardMaterial3D
var portal_nodes := {}
var elevator_nodes := {}
var elevator_status_materials := {}
var elevator_status_labels := {}
var bridge_nodes := {}
var bridge_rail_nodes := {}
var bridge_rail_tweens := {}
var energy_nodes := {}
var energy_cable_materials: Array[ShaderMaterial] = []
var fragment_node: Node3D
## Gameplay geometry is grouped per floor so a sequential level never lets an
## upper floor cover the current Sokoban board.
var layer_roots := {}
var floor_preview_roots := {}
var visible_floor := 0
var _sequential_floors := false
var _logic: GameLogic
var _elevator_cabin: Node3D
var _mobile_color_pools_used := 0
## Authored, presentation-only environment motion. Profiles are opt-in from
## LevelData decorations so the effect can be rolled out level by level instead
## of silently animating every reused prop in the campaign.
var environment_dynamic_profiles: Array[StringName] = []
var environment_dynamic_nodes: Array[Dictionary] = []
var environment_dynamic_materials: Array[Dictionary] = []
var environment_dynamic_water_materials: Array[ShaderMaterial] = []
var _environment_time := 0.0
var hint_marker: Node3D
var _hint_marker_tween: Tween


func build(logic: GameLogic, decorations := []) -> void:
	_logic = logic
	if _hint_marker_tween and _hint_marker_tween.is_valid():
		_hint_marker_tween.kill()
	_hint_marker_tween = null
	hint_marker = null
	player_animation = null
	_current_clip = &""
	if _turn_tween and _turn_tween.is_valid():
		_turn_tween.kill()
	_turn_tween = null
	if _eva_bob_tween and _eva_bob_tween.is_valid():
		_eva_bob_tween.kill()
	_eva_bob_tween = null
	_eva_hologram_node = null
	_eva_hologram_material = null
	if _elias_bob_tween and _elias_bob_tween.is_valid():
		_elias_bob_tween.kill()
	_elias_bob_tween = null
	_elias_hologram_node = null
	for child in get_children():
		child.free()
	block_nodes.clear()
	plate_nodes.clear()
	plate_status_materials.clear()
	plate_status_lights.clear()
	door_nodes.clear()
	door_status_lights.clear()
	door_status_materials.clear()
	lock_cable_materials.clear()
	lock_cable_material = null
	portal_nodes.clear()
	elevator_nodes.clear()
	elevator_status_materials.clear()
	elevator_status_labels.clear()
	bridge_nodes.clear()
	for tween in bridge_rail_tweens.values():
		if tween and tween.is_valid():
			tween.kill()
	bridge_rail_nodes.clear()
	bridge_rail_tweens.clear()
	energy_nodes.clear()
	energy_cable_materials.clear()
	fragment_node = null
	layer_roots.clear()
	floor_preview_roots.clear()
	_mobile_color_pools_used = 0
	decor_nodes.clear()
	sector_power_lights.clear()
	sector_power_materials.clear()
	environment_dynamic_profiles.clear()
	environment_dynamic_nodes.clear()
	environment_dynamic_materials.clear()
	environment_dynamic_water_materials.clear()
	_environment_time = 0.0

	# Wall cells that a prop replaces (skip the default pillar there).
	var decor_wall_cells := {}
	for deco in decorations:
		var cell: Variant = deco.get("grid_position", null)
		if cell is Vector3i and logic.walls.has(cell):
			decor_wall_cells[cell] = true


	var foundry_theme := chapter == 2
	var sanctuary_theme := chapter == 3
	var central_core_theme := chapter == 4
	palette_name = &"foundry" if foundry_theme else (&"sanctuary" if sanctuary_theme else (&"central_core" if central_core_theme else &"archive"))
	var floor_color := COLOR_FLOOR
	var platform_color := COLOR_PLATFORM
	var platform_edge_color := COLOR_PLATFORM_EDGE
	var grid_color := COLOR_GRID
	var wall_color := COLOR_WALL
	var wall_edge_color := COLOR_WALL_EDGE
	if foundry_theme:
		floor_color = Color(0.115, 0.055, 0.028)
		platform_color = Color(0.095, 0.048, 0.030)
		platform_edge_color = Color(0.30, 0.095, 0.025)
		grid_color = Color(0.55, 0.15, 0.025)
		wall_color = Color(0.21, 0.105, 0.055)
		wall_edge_color = Color(0.58, 0.16, 0.035)
	elif sanctuary_theme:
		floor_color = Color(0.025, 0.12, 0.15)
		platform_color = Color(0.018, 0.065, 0.09)
		platform_edge_color = Color(0.035, 0.28, 0.30)
		grid_color = Color(0.08, 0.42, 0.40)
		wall_color = Color(0.055, 0.17, 0.20)
		wall_edge_color = Color(0.10, 0.42, 0.42)
	elif central_core_theme:
		floor_color = Color(0.030, 0.060, 0.095)
		platform_color = Color(0.014, 0.032, 0.060)
		platform_edge_color = Color(0.10, 0.30, 0.40)
		grid_color = COLOR_CORE_GRID
		wall_color = Color(0.050, 0.090, 0.145)
		wall_edge_color = COLOR_CORE_WALL_EDGE
	var slot_color := Color(0.025, 0.12, 0.15) if sanctuary_theme else Color(0.20, 0.06, 0.025)
	var goal_color := COLOR_GOAL
	var plate_color := COLOR_PLATE
	var door_base_color := Color(0.20, 0.035, 0.035)
	var door_edge_color := COLOR_DOOR
	var portal_base_color := Color(0.08, 0.025, 0.16)
	var portal_color := COLOR_PORTAL
	var elevator_base_color := Color(0.025, 0.16, 0.13)
	var elevator_color := COLOR_ELEVATOR
	var bridge_base_color := Color(0.18, 0.05, 0.025)
	var bridge_color := COLOR_BRIDGE
	var energy_base_color := Color(0.025, 0.16, 0.14)
	var energy_color := COLOR_ENERGY
	var block_color := COLOR_BLOCK
	var block_edge_color := COLOR_BLOCK_EDGE
	if central_core_theme:
		slot_color = Color(0.035, 0.080, 0.120)
		goal_color = COLOR_CORE_CYAN
		plate_color = COLOR_CORE_AMBER
		door_base_color = Color(0.070, 0.035, 0.120)
		door_edge_color = COLOR_CORE_VIOLET
		portal_base_color = Color(0.045, 0.025, 0.105)
		portal_color = COLOR_CORE_VIOLET
		elevator_base_color = Color(0.020, 0.105, 0.125)
		elevator_color = COLOR_CORE_TEAL
		bridge_base_color = Color(0.105, 0.055, 0.060)
		bridge_color = COLOR_CORE_AMBER
		energy_base_color = Color(0.018, 0.105, 0.125)
		energy_color = COLOR_CORE_CYAN
		block_color = COLOR_CORE_BLOCK
		block_edge_color = COLOR_CORE_CYAN
	# The accessibility toggle keeps interactable edges separated from the dark
	# reactor floor. It is evaluated at build time so changing it from Settings
	# takes effect as soon as the next level is loaded without rebuilding a live
	# puzzle in the middle of a move.
	if GameState.high_contrast:
		floor_color = floor_color.lightened(0.12)
		platform_color = platform_color.lightened(0.10)
		grid_color = grid_color.lightened(0.30)
		wall_color = wall_color.lightened(0.16)
		wall_edge_color = wall_edge_color.lightened(0.30)
		goal_color = Color(0.45, 1.0, 1.0)
		plate_color = Color(1.0, 0.86, 0.20)
		door_edge_color = Color(1.0, 0.45, 0.45)
		portal_color = Color(0.92, 0.55, 1.0)
		elevator_color = Color(0.42, 1.0, 0.86)
		bridge_color = Color(1.0, 0.72, 0.30)
		energy_color = Color(0.58, 1.0, 0.94)
		block_edge_color = Color(1.0, 0.72, 1.0)
	var floor_mat := MeshFactory.mat(floor_color)
	var platform_mat := MeshFactory.mat(platform_color)
	var platform_edge_mat := MeshFactory.mat(platform_edge_color)
	var grid_mat := MeshFactory.mat(grid_color)
	var wall_mat := MeshFactory.mat(wall_color)
	var wall_edge_mat := MeshFactory.mat(wall_edge_color)
	var slot_mat := MeshFactory.mat(slot_color, 0.15)
	var slot_ring_mat := MeshFactory.mat(goal_color, 2.4)
	var plate_mat := MeshFactory.mat(Color(0.18, 0.12, 0.025), 0.15)
	var plate_ring_mat := MeshFactory.mat(plate_color, 2.2)
	var door_mat := MeshFactory.mat(door_base_color)
	var door_edge_mat := MeshFactory.mat(door_edge_color, 2.0)
	lock_cable_material = MeshFactory.mat(COLOR_CORE_VIOLET if central_core_theme else Color(0.55, 0.04, 0.04), 0.65)
	var portal_mat := MeshFactory.mat(portal_base_color, 0.25)
	var portal_ring_mat := MeshFactory.mat(portal_color, 3.0)
	var elevator_mat := MeshFactory.mat(elevator_base_color, 0.25)
	var elevator_ring_mat := MeshFactory.mat(elevator_color, 2.8)
	var bridge_mat := MeshFactory.mat(bridge_base_color, 0.2)
	var bridge_ring_mat := MeshFactory.mat(bridge_color, 2.6)
	var energy_mat := MeshFactory.mat(energy_base_color, 0.25)
	var energy_ring_mat := MeshFactory.mat(energy_color, 3.0)
	var block_mat := MeshFactory.mat(block_color)
	var block_edge_mat := MeshFactory.mat(block_edge_color, 2.0)
	var player_mat := MeshFactory.mat(COLOR_PLAYER, 1.2)
	var player_edge_mat := MeshFactory.mat(Color(0.65, 0.95, 1.0), 2.8)

	_create_layer_roots(logic)
	_build_sector_shell(logic)
	var board_bounds := _board_bounds(logic)

	for v in logic.floors.keys():
		var layer_parent := _layer_parent(v)
		if not logic.walls.has(v):
			MeshFactory.box(layer_parent, world_position(v) + Vector3(0, -0.18, 0), Vector3(0.98, 0.34, 0.98), platform_mat)
			if _platform_edge(logic, v, Vector3i(1, 0, 0)):
				MeshFactory.box(layer_parent, world_position(v) + Vector3(0.49, -0.18, 0), Vector3(0.035, 0.34, 0.92), platform_edge_mat)
			if _platform_edge(logic, v, Vector3i(-1, 0, 0)):
				MeshFactory.box(layer_parent, world_position(v) + Vector3(-0.49, -0.18, 0), Vector3(0.035, 0.34, 0.92), platform_edge_mat)
			if _platform_edge(logic, v, Vector3i(0, 0, 1)):
				MeshFactory.box(layer_parent, world_position(v) + Vector3(0, -0.18, 0.49), Vector3(0.92, 0.34, 0.035), platform_edge_mat)
			if _platform_edge(logic, v, Vector3i(0, 0, -1)):
				MeshFactory.box(layer_parent, world_position(v) + Vector3(0, -0.18, -0.49), Vector3(0.92, 0.34, 0.035), platform_edge_mat)
		if not logic.walls.has(v):
			var tile := _spawn(layer_parent, FLOOR_TILE_PATH, world_position(v), world_position(v).y)
			if tile == null:
				MeshFactory.box(layer_parent, world_position(v), Vector3(0.98, 0.08, 0.98), floor_mat)
				MeshFactory.box(layer_parent, world_position(v) + Vector3(0, 0.065, -0.43), Vector3(0.72, 0.018, 0.018), grid_mat)
				MeshFactory.box(layer_parent, world_position(v) + Vector3(-0.43, 0.065, 0), Vector3(0.018, 0.018, 0.72), grid_mat)
	for v in logic.walls.keys():
		if decor_wall_cells.has(v):
			continue
		var on_x_edge: bool = v.x == int(board_bounds["min_x"]) or v.x == int(board_bounds["max_x"])
		var on_z_edge: bool = v.z == int(board_bounds["min_z"]) or v.z == int(board_bounds["max_z"])
		# Corners get a full column; straight perimeter runs get wall panels so the
		# room reads as architecture rather than one pillar per cell.
		if on_x_edge and on_z_edge:
			var corner := _spawn(_layer_parent(v), WALL_PILLAR_PATH, world_position(v), _floor_surface_y(v))
			if corner == null:
				MeshFactory.box(_layer_parent(v), world_position(v) + Vector3(0, 0.46, 0), Vector3(1, 1, 1), wall_mat)
			continue
		if on_x_edge or on_z_edge:
			var panel := _spawn(_layer_parent(v), WALL_MODULE_PATH, world_position(v), _floor_surface_y(v))
			if panel != null:
				if on_x_edge:
					panel.rotate_y(deg_to_rad(90.0))
				continue
			MeshFactory.box(_layer_parent(v), world_position(v) + Vector3(0, 0.31, 0), Vector3(0.94, 0.62, 0.94), wall_mat)
			continue
		var pillar := _spawn(_layer_parent(v), WALL_PILLAR_PATH, world_position(v), _floor_surface_y(v))
		if pillar == null:
			MeshFactory.box(_layer_parent(v), world_position(v) + Vector3(0, 0.46, 0), Vector3(1, 1, 1), wall_mat)
			MeshFactory.box(_layer_parent(v), world_position(v) + Vector3(0, 0.965, 0), Vector3(0.82, 0.035, 0.82), wall_edge_mat)
	for v in logic.slots.keys():
		var slot_root := Node3D.new()
		slot_root.position = world_position(v) + Vector3(0, 0.07, 0)
		_layer_parent(v).add_child(slot_root)
		var pedestal := _spawn(_layer_parent(v), PEDESTAL_PATH, world_position(v), _floor_surface_y(v), 1.0, false)
		if pedestal == null:
			MeshFactory.cylinder(slot_root, Vector3.ZERO, 0.30, 0.025, slot_mat)
		# Keep the objective readable even when the authored pedestal model loads.
		# On a phone the model alone blends into the floor; this emissive ring is the
		# gameplay language for "put a Lumina Core here".
		MeshFactory.torus(slot_root, Vector3(0, 0.035, 0), 0.26, 0.36, slot_ring_mat)
		if RENDER_QUALITY.local_lights_enabled():
			var slot_light := OmniLight3D.new()
			slot_light.light_color = goal_color
			slot_light.light_energy = 0.85
			slot_light.omni_range = 2.2
			slot_light.position = Vector3(0, 0.2, 0)
			slot_root.add_child(slot_light)

	for v in logic.plates.keys():
		var plate_root := Node3D.new()
		plate_root.position = world_position(v) + Vector3(0, 0.07, 0)
		_layer_parent(v).add_child(plate_root)
		plate_nodes[v] = plate_root
		var plate := _spawn(_layer_parent(v), PLATE_PATH, world_position(v), _floor_surface_y(v), 1.0, false)
		if plate == null:
			MeshFactory.cylinder(plate_root, Vector3.ZERO, 0.34, 0.035, plate_mat)
		var status_mat := plate_ring_mat.duplicate() as StandardMaterial3D
		MeshFactory.torus(plate_root, Vector3(0, 0.045, 0), 0.25, 0.34, status_mat)
		plate_status_materials[v] = status_mat
		if RENDER_QUALITY.local_lights_enabled():
			var plate_light := OmniLight3D.new()
			plate_light.light_color = plate_color
			plate_light.light_energy = 0.45
			plate_light.omni_range = 1.35
			plate_light.position = Vector3(0, 0.16, 0)
			plate_root.add_child(plate_light)
			plate_status_lights[v] = plate_light
	for v in logic.portals.keys():
		var portal_root := Node3D.new()
		portal_root.position = world_position(v) + Vector3(0, 0.075, 0)
		_layer_parent(v).add_child(portal_root)
		MeshFactory.cylinder(portal_root, Vector3.ZERO, 0.31, 0.025, portal_mat)
		MeshFactory.torus(portal_root, Vector3(0, 0.035, 0), 0.23, 0.31, portal_ring_mat)
		portal_nodes[v] = portal_root
	for v in logic.elevators.keys():
		var elevator_root := Node3D.new()
		elevator_root.position = world_position(v) + Vector3(0, 0.075, 0)
		_layer_parent(v).add_child(elevator_root)
		MeshFactory.cylinder(elevator_root, Vector3.ZERO, 0.34, 0.035, elevator_mat)
		var elevator_status_mat := elevator_ring_mat.duplicate() as StandardMaterial3D
		MeshFactory.torus(elevator_root, Vector3(0, 0.03, 0), 0.25, 0.34, elevator_status_mat)
		elevator_nodes[v] = elevator_root
		elevator_status_materials[v] = elevator_status_mat
		var elevator_label := Label3D.new()
		elevator_label.font_size = 30
		elevator_label.pixel_size = 0.008
		elevator_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		elevator_label.position = Vector3(0, 0.20, 0)
		elevator_root.add_child(elevator_label)
		elevator_status_labels[v] = elevator_label
	for v in logic.bridges.keys():
		var bridge_root := Node3D.new()
		bridge_root.position = world_position(v) + Vector3(0, 0.08, 0)
		_layer_parent(v).add_child(bridge_root)
		MeshFactory.box(bridge_root, Vector3.ZERO, Vector3(0.84, 0.08, 0.84), bridge_mat)
		var rail_root := Node3D.new()
		rail_root.name = "Rails"
		bridge_root.add_child(rail_root)
		MeshFactory.box(rail_root, Vector3(-0.38, 0.18, 0), Vector3(0.045, 0.28, 0.84), bridge_ring_mat)
		MeshFactory.box(rail_root, Vector3(0.38, 0.18, 0), Vector3(0.045, 0.28, 0.84), bridge_ring_mat)
		bridge_nodes[v] = bridge_root
		bridge_rail_nodes[v] = rail_root
	for v in logic.energy_nodes:
		var energy_root := Node3D.new()
		energy_root.position = world_position(v) + Vector3(0, 0.08, 0)
		_layer_parent(v).add_child(energy_root)
		MeshFactory.cylinder(energy_root, Vector3.ZERO, 0.28, 0.025, energy_mat)
		MeshFactory.torus(energy_root, Vector3(0, 0.035, 0), 0.21, 0.30, energy_ring_mat)
		energy_nodes[v] = energy_root
		if chapter == 4:
			var number := Label3D.new()
			number.name = "NodeNumber"
			number.text = str(logic.energy_nodes.find(v) + 1)
			number.font_size = 64
			number.pixel_size = 0.008
			number.position.y = 0.48
			number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			energy_root.add_child(number)
	_build_energy_cables(logic)
	for v in logic.doors.keys():
		var door_edge := door_edge_mat.duplicate() as StandardMaterial3D
		door_status_materials[v] = door_edge
		var door_root := _build_door(
			_layer_parent(v),
			door_position(v, logic.door_open(v)),
			door_mat,
			door_edge)
		door_nodes[v] = door_root
		if RENDER_QUALITY.local_lights_enabled():
			var status_light := OmniLight3D.new()
			status_light.light_color = door_edge_color
			status_light.light_energy = 1.0
			status_light.omni_range = 2.0
			status_light.position = Vector3(0, 0.35, 0)
			door_root.add_child(status_light)
			door_status_lights[v] = status_light
	_build_lock_cables(logic)
	for v in logic.blocks.keys():
		block_nodes[v] = _build_block(_layer_parent(v), world_position(v) + Vector3(0, BLOCK_ROOT_HEIGHT, 0), block_mat, block_edge_mat)
	player_node = _build_player(self, player_position(logic.player, logic.blocks), player_mat, player_edge_mat)
	_build_decorations(decorations)
	_build_story_lighting(logic)
	_build_mobile_color_pools(logic, goal_color, plate_color, portal_color, elevator_color, block_edge_color)
	_build_floor_previews(logic, platform_edge_color)
	_build_hint_marker()
	set_bridges_open(logic.bridge_open)
	set_energy_progress(logic.energy_progress)
	set_lock_state(logic)
	_apply_power_baseline()
	set_sector_powered(false, true)
	set_active_floor(logic.active_floor, false)


func _create_layer_roots(logic: GameLogic) -> void:
	_sequential_floors = logic.sequential_floors
	visible_floor = logic.active_floor
	for floor in logic.floor_count():
		var root := Node3D.new()
		root.name = "Floor_%d" % (floor + 1)
		add_child(root)
		layer_roots[floor] = root


func _layer_parent(cell: Vector3i) -> Node3D:
	return layer_roots.get(cell.y, self) as Node3D


func set_active_floor(floor: int, animated := false) -> void:
	visible_floor = maxi(0, floor)
	for layer in layer_roots.keys():
		var root: Node3D = layer_roots[layer]
		root.visible = not _sequential_floors or int(layer) == visible_floor
	for preview_floor in floor_preview_roots.keys():
		var preview: Node3D = floor_preview_roots[preview_floor]
		preview.visible = _sequential_floors and int(preview_floor) == visible_floor + 1
	set_elevator_state(_logic, animated)


func set_elevator_state(logic: GameLogic, animated := false) -> void:
	if logic == null:
		return
	for position in elevator_nodes.keys():
		var unlocked := logic.elevator_is_unlocked(position)
		var material := elevator_status_materials.get(position) as StandardMaterial3D
		var label := elevator_status_labels.get(position) as Label3D
		var active: bool = not logic.sequential_floors or position.y == visible_floor
		var leads_up: bool = logic.elevator_destination(position).y > position.y
		var color := COLOR_ELEVATOR if unlocked else COLOR_DOOR
		if material != null:
			material.albedo_color = color
			material.emission = color
			material.emission_enabled = true
			material.emission_energy_multiplier = 3.4 if unlocked else 1.1
		if label != null:
			label.visible = active and logic.sequential_floors and leads_up
			label.text = "UP" if unlocked else "LOCKED"
			label.modulate = color
		var root := elevator_nodes[position] as Node3D
		if animated and root != null and active:
			var pulse := root.create_tween()
			pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			pulse.tween_property(root, "scale", Vector3.ONE * 1.10, 0.16)
			pulse.tween_property(root, "scale", Vector3.ONE, 0.26)


func play_elevator_ride(entry: Vector3i, destination: Vector3i, duration: float) -> void:
	if is_instance_valid(_elevator_cabin):
		_elevator_cabin.queue_free()
	_elevator_cabin = Node3D.new()
	_elevator_cabin.name = "ElevatorCabin"
	_elevator_cabin.position = world_position(entry) + Vector3(0, 0.04, 0)
	add_child(_elevator_cabin)
	var cabin_mat := MeshFactory.transparent_mat(Color(COLOR_ELEVATOR.r, COLOR_ELEVATOR.g, COLOR_ELEVATOR.b, 0.20), 1.8)
	MeshFactory.cylinder(_elevator_cabin, Vector3(0, 0.42, 0), 0.42, 0.84, cabin_mat)
	MeshFactory.torus(_elevator_cabin, Vector3(0, 0.03, 0), 0.32, 0.42, cabin_mat)
	MeshFactory.torus(_elevator_cabin, Vector3(0, 0.82, 0), 0.32, 0.42, cabin_mat)
	var from_root := elevator_nodes.get(entry) as Node3D
	var to_root := elevator_nodes.get(destination) as Node3D
	for raw_root in [from_root, to_root]:
		var root := raw_root as Node3D
		if root == null:
			continue
		var tween: Tween = root.create_tween()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(root, "scale", Vector3.ONE * 1.16, duration * 0.24)
		tween.tween_property(root, "scale", Vector3.ONE, duration * 0.36)
	var cabin_tween := _elevator_cabin.create_tween()
	cabin_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	cabin_tween.tween_interval(duration * 0.32)
	cabin_tween.tween_property(_elevator_cabin, "position", world_position(destination) + Vector3(0, 0.04, 0), duration * 0.68)
	cabin_tween.tween_callback(_elevator_cabin.queue_free)


func _build_floor_previews(logic: GameLogic, edge_color: Color) -> void:
	if not logic.sequential_floors:
		return
	var structure_mat := MeshFactory.transparent_mat(Color(edge_color.r, edge_color.g, edge_color.b, 0.34), 0.65)
	for position in logic.elevators.keys():
		if position.y <= 0 or not logic.elevator_links.has(position):
			continue
		var lower := logic.elevator_destination(position)
		if lower.y >= position.y:
			continue
		var preview := Node3D.new()
		preview.name = "Floor_%d_Approach" % (position.y + 1)
		add_child(preview)
		floor_preview_roots[position.y] = preview
		var upper := world_position(position)
		# Only the underside, support struts and lift shaft are shown while the
		# floor is locked. They imply the space above without masking any tile.
		MeshFactory.box(preview, upper + Vector3(0, -0.49, 0), Vector3(1.18, 0.10, 1.18), structure_mat)
		for offset in [Vector3(-0.42, -0.76, -0.42), Vector3(0.42, -0.76, 0.42)]:
			MeshFactory.box(preview, upper + offset, Vector3(0.075, 0.52, 0.075), structure_mat)
		var marker := Label3D.new()
		marker.text = "%02d UP" % (position.y + 1)
		marker.font_size = 36
		marker.pixel_size = 0.008
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.modulate = Color(COLOR_ELEVATOR.r, COLOR_ELEVATOR.g, COLOR_ELEVATOR.b, 0.82)
		marker.position = upper + Vector3(0, -0.35, 0)
		preview.add_child(marker)


func _apply_power_baseline() -> void:
	# power_level lifts the unpowered baseline, so a later level of a chapter
	# starts visibly more awake than the first one without touching the win flash.
	var gain := lerpf(1.0, 2.6, clampf(power_level, 0.0, 1.0))
	if is_equal_approx(gain, 1.0):
		return
	for info in sector_power_lights:
		info["off"] = minf(float(info["off"]) * gain, float(info["on"]))
	for info in sector_power_materials:
		info["off"] = minf(float(info["off"]) * gain, float(info["on"]))


func _build_lock_cables(logic: GameLogic) -> void:
	# One trace bundle per door group, so the floor cabling shows which plate
	# feeds which door instead of implying every plate feeds every door.
	if logic.plates.is_empty() or logic.doors.is_empty() or lock_cable_material == null:
		return
	for door in logic.doors.keys():
		var group: String = logic.doors[door]
		if not lock_cable_materials.has(group):
			lock_cable_materials[group] = lock_cable_material.duplicate() as StandardMaterial3D
	for group in lock_cable_materials.keys():
		var group_doors: Array = logic.doors_in_group(group)
		var group_plates: Array = logic.plates_in_group(group)
		if group_doors.is_empty() or group_plates.is_empty():
			continue
		var material: StandardMaterial3D = lock_cable_materials[group]
		var door_sum := Vector3i.ZERO
		for door_position_value in group_doors:
			door_sum += door_position_value
		var hub := Vector3i(
			roundi(float(door_sum.x) / float(group_doors.size())),
			roundi(float(door_sum.y) / float(group_doors.size())),
			roundi(float(door_sum.z) / float(group_doors.size())))
		for plate_position in group_plates:
			_build_lock_trace(plate_position, hub, material)
		for door_position_value in group_doors:
			_build_lock_trace(hub, door_position_value, material)


func _build_lock_trace(from: Vector3i, to: Vector3i, material: StandardMaterial3D) -> void:
	var parent := _layer_parent(from) if from.y == to.y else self
	var start := world_position(from) + Vector3(0, 0.145, 0)
	var finish := world_position(to) + Vector3(0, 0.145, 0)
	var corner := Vector3(finish.x, start.y, start.z)
	if not is_equal_approx(start.x, corner.x):
		MeshFactory.box(
			parent,
			(start + corner) * 0.5,
			Vector3(absf(corner.x - start.x) + 0.08, 0.025, 0.075),
			material)
	if not is_equal_approx(corner.z, finish.z):
		MeshFactory.box(
			parent,
			(corner + finish) * 0.5,
			Vector3(0.075, 0.025, absf(finish.z - corner.z) + 0.08),
			material)
	MeshFactory.sphere(parent, world_position(to) + Vector3(0, 0.16, 0), 0.055, material)


func set_lock_state(logic: GameLogic) -> void:
	set_elevator_state(logic)
	if logic.plates.is_empty():
		return
	for plate_position in logic.plates.keys():
		var is_active := logic.blocks.has(plate_position)
		var hold_req := bool(logic.plate_hold_required.get(plate_position, true))
		var plate_color := COLOR_GOAL if is_active else (COLOR_PLATE if hold_req else Color(1.0, 0.50, 0.12))
		var plate_material := plate_status_materials.get(plate_position) as StandardMaterial3D
		_set_status_material(plate_material, plate_color, 3.2 if is_active else (1.7 if hold_req else 2.2))
		var plate_light := plate_status_lights.get(plate_position) as OmniLight3D
		if plate_light:
			plate_light.light_color = plate_color
			plate_light.light_energy = 1.15 if is_active else (0.4 if hold_req else 0.65)
	for door_position_value in logic.doors.keys():
		var group: String = logic.doors[door_position_value]
		var open := logic.door_open(door_position_value)
		var group_active := _active_plates_in_group(logic, group)
		var status_color := COLOR_GOAL if open else (COLOR_PLATE if group_active > 0 else COLOR_DOOR)
		_set_status_material(
			door_status_materials.get(door_position_value) as StandardMaterial3D,
			status_color,
			3.2 if open else 2.0)
		_set_status_material(
			lock_cable_materials.get(group) as StandardMaterial3D,
			status_color,
			2.6 if open else (1.4 if group_active > 0 else 0.55))
		var light := door_status_lights.get(door_position_value) as OmniLight3D
		if light:
			light.light_color = status_color
			light.light_energy = 1.8 if open else (1.15 if group_active > 0 else 0.75)


func _active_plates_in_group(logic: GameLogic, group: String) -> int:
	var active := 0
	for plate_position in logic.plates_in_group(group):
		if logic.blocks.has(plate_position):
			active += 1
	return active


func _set_status_material(material: StandardMaterial3D, color: Color, energy: float) -> void:
	if material == null:
		return
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy


func _build_decorations(decorations: Array) -> void:
	for deco in decorations:
		if not deco is Dictionary:
			continue
		var kind := str(deco.get("type", ""))
		if not DECOR_ASSETS.has(kind) and not CHAPTER_PROPS.ASSETS.has(kind) and not MODULAR_PROPS.ASSETS.has(kind):
			continue
		var cell: Variant = deco.get("grid_position", null)
		if not cell is Vector3i:
			continue
		var spec: Dictionary = DECOR_ASSETS.get(kind, {})
		if CHAPTER_PROPS.ASSETS.has(kind):
			spec = {"path": CHAPTER_PROPS.ASSETS[kind]}
		elif MODULAR_PROPS.ASSETS.has(kind):
			spec = {"path": MODULAR_PROPS.ASSETS[kind]}
		var center := world_position(cell) + Vector3(
			float(deco.get("offset_x", 0.0)),
			float(deco.get("offset_y", 0.0)),
			float(deco.get("offset_z", 0.0)))
		var node := _spawn(
			_layer_parent(cell),
			str(spec["path"]),
			center,
			FLOOR_TOP_Y + center.y - world_position(Vector3i.ZERO).y,
			float(deco.get("scale", 1.0)),
			true,
			true)
		if node == null:
			continue
		var yaw: float = float(deco.get("yaw", 0.0))
		if yaw != 0.0:
			node.rotate_y(deg_to_rad(yaw))
		decor_nodes.append(node)
		if str(kind).begins_with("kit_water") or kind in ["sanctuary_water_pool", "sanctuary_pool"]:
			_apply_water_shader(node, chapter == 3 and kind == "sanctuary_pool")
		_register_environment_dynamic(node, deco, center, yaw, cell)
		if kind == "lamp":
			_add_sector_lamp(
				center + Vector3(0, 0.78, 0),
				COLOR_FOUNDRY_ORANGE if chapter == 2 else (COLOR_CORE_AMBER if chapter == 4 else COLOR_ARCHIVE_AMBER),
				_layer_parent(cell))
		elif kind in ["holo", "terminal", "archive_lock_node", "bridge_console", "reactor_switch", "sanctuary_pool", "resonance_altar", "silence_reliquary", "elias_testament", "soul_archive", "eva_conduit", "judgement_engine"]:
			var glow_color := COLOR_CORE_CYAN if chapter == 4 else COLOR_ARCHIVE_CYAN
			if chapter == 4 and kind in ["soul_archive", "eva_conduit"]:
				glow_color = COLOR_CORE_VIOLET
			elif chapter == 4 and kind == "judgement_engine":
				glow_color = COLOR_CORE_AMBER
			_add_hologram_glow(center + Vector3(0, 0.48, 0), glow_color, _layer_parent(cell))
			# Character holograms are story-controlled. The projector/altar can exist
			# from level load, but Elias/EVA must only appear when the narrative beat
			# actually fires.


func _build_sector_shell(logic: GameLogic) -> void:
	if logic.floors.is_empty():
		return
	var bounds := _board_bounds(logic)
	var min_x: float = bounds["min_x"]
	var max_x: float = bounds["max_x"]
	var min_z: float = bounds["min_z"]
	var max_z: float = bounds["max_z"]
	var center := Vector3((min_x + max_x) * 0.5, 0.0, (min_z + max_z) * 0.5)
	var width := max_x - min_x + 1.0
	var depth := max_z - min_z + 1.0
	var sanctuary_theme := chapter == 3
	var central_core_theme := chapter == 4
	var steel_color := COLOR_ARCHIVE_STEEL
	var panel_color := COLOR_ARCHIVE_PANEL
	var recess_color := Color(0.012, 0.018, 0.035)
	if chapter == 2:
		steel_color = COLOR_FOUNDRY_STEEL
		panel_color = COLOR_FOUNDRY_PANEL
		recess_color = Color(0.025, 0.008, 0.003)
	elif sanctuary_theme:
		steel_color = Color(0.018, 0.09, 0.11)
		panel_color = Color(0.025, 0.14, 0.16)
		recess_color = Color(0.006, 0.035, 0.05)
	elif central_core_theme:
		steel_color = COLOR_CORE_STEEL
		panel_color = COLOR_CORE_PANEL
		recess_color = COLOR_CORE_RECESS
	var steel := MeshFactory.mat(steel_color)
	steel.metallic = 0.72
	steel.roughness = 0.32
	var panel := MeshFactory.mat(panel_color)
	panel.metallic = 0.55
	panel.roughness = 0.42
	var recess := MeshFactory.mat(recess_color)
	recess.metallic = 0.25
	recess.roughness = 0.7

	# A deep, layered plinth makes the grid read as a real sector instead of a
	# collection of floating tiles.
	MeshFactory.box(self, center + Vector3(0, -0.49, 0), Vector3(width + 0.9, 0.62, depth + 0.9), steel)
	MeshFactory.box(self, center + Vector3(0, -0.83, 0), Vector3(width + 0.3, 0.16, depth + 0.3), recess)
	for x in range(int(min_x), int(max_x) + 1, 2):
		MeshFactory.box(self, Vector3(float(x), -0.54, max_z + 0.58), Vector3(1.42, 0.25, 0.11), panel)
	for z in range(int(min_z), int(max_z) + 1, 2):
		MeshFactory.box(self, Vector3(max_x + 0.58, -0.54, float(z)), Vector3(0.11, 0.25, 1.42), panel)

	# North/west facades sit behind the default isometric view. Their uneven
	# silhouette keeps the sector physical without hiding walkable cells.
	_build_sector_facade(Vector3(center.x, 1.18, min_z - 0.78), Vector3(width + 1.5, 2.55, 0.34), false, panel, recess)
	_build_sector_facade(Vector3(min_x - 0.78, 1.08, center.z), Vector3(0.34, 2.35, depth + 1.5), true, panel, recess)

	for corner in [
		Vector3(min_x - 0.72, 1.45, min_z - 0.72),
		Vector3(max_x + 0.72, 1.18, min_z - 0.72),
		Vector3(min_x - 0.72, 1.22, max_z + 0.72),
		Vector3(max_x + 0.72, 0.82, max_z + 0.72),
	]:
		MeshFactory.box(self, corner, Vector3(0.48, corner.y * 2.0, 0.48), steel)
		_add_power_strip(corner + Vector3(0.0, 0.36, 0.25), Vector3(0.12, 0.78, 0.018), COLOR_CORE_CYAN if central_core_theme else COLOR_ARCHIVE_CYAN, 0.08, 2.5)

	# Broken roof rails frame the room but leave its centre open to the cold shaft
	# of light from above.
	MeshFactory.box(self, Vector3(center.x - 1.2, 3.05, min_z - 0.68), Vector3(width - 1.4, 0.18, 0.24), steel)
	MeshFactory.box(self, Vector3(min_x - 0.68, 2.92, center.z - 0.8), Vector3(0.24, 0.18, depth - 1.2), steel)
	MeshFactory.box(self, Vector3(max_x - 0.8, 3.18, min_z - 0.68), Vector3(1.4, 0.16, 0.22), panel)

	# The central power lane is barely alive at boot and becomes the visual reward
	# when the first Lumina Core is seated.
	var power_color := COLOR_CORE_CYAN if central_core_theme else COLOR_ARCHIVE_CYAN
	_add_power_strip(Vector3(center.x, 0.175, center.z - 0.43), Vector3(width * 0.38, 0.016, 0.028), power_color, 0.05, 3.2)
	_add_power_strip(Vector3(center.x, 0.175, center.z + 0.43), Vector3(width * 0.38, 0.016, 0.028), power_color, 0.05, 3.2)
	_add_power_strip(Vector3(center.x, 1.86, min_z - 0.58), Vector3(width * 0.38, 0.035, 0.025), power_color, 0.04, 3.8)

	if RENDER_QUALITY.background_fx_enabled():
		_add_dust_volume(center + Vector3(0, 1.25, 0), Vector3(width * 0.48, 1.2, depth * 0.48))
		_add_light_shaft(Vector3(center.x - 1.2, 1.82, center.z - 0.8), 0.72, COLOR_CORE_CYAN if central_core_theme else Color(0.16, 0.62, 0.90))
	if central_core_theme:
		# A pair of suspended reactor rings establishes the chapter silhouette
		# without consuming a walkable cell. Their low idle emission is lifted by
		# set_sector_powered() when the player restores the network.
		var ring_radius := minf(width, depth) * 0.38
		var cyan_ring_mat := MeshFactory.transparent_mat(Color(0.52, 0.86, 1.0, 0.13), 0.75)
		var violet_ring_mat := MeshFactory.transparent_mat(Color(0.42, 0.35, 0.66, 0.11), 0.55)
		MeshFactory.torus(self, center + Vector3(0, 2.48, 0), ring_radius - 0.045, ring_radius, cyan_ring_mat)
		MeshFactory.torus(self, center + Vector3(0, 2.26, 0), ring_radius * 0.72 - 0.035, ring_radius * 0.72, violet_ring_mat)
		sector_power_materials.append({"material": cyan_ring_mat, "off": 0.75, "on": 3.2})
		sector_power_materials.append({"material": violet_ring_mat, "off": 0.55, "on": 2.4})
	if RENDER_QUALITY.background_fx_enabled():
		_build_distant_structures(center, width, depth, panel, steel, recess)


func _build_distant_structures(center: Vector3, width: float, depth: float, _panel: Material, _steel: Material, _recess: Material) -> void:
	var tower_color := Color(0.09, 0.15, 0.24)
	var tower_recess_color := Color(0.035, 0.065, 0.11)
	var tower_panel_color := Color(0.06, 0.10, 0.17)
	if chapter == 4:
		# Central Core structures recede into the void instead of reading as
		# ordinary archive towers; only their cyan/violet energy lines should
		# remain bright at a distance.
		tower_color = Color(0.018, 0.040, 0.072)
		tower_recess_color = Color(0.005, 0.012, 0.024)
		tower_panel_color = Color(0.032, 0.078, 0.125)
	var tower_mat := MeshFactory.mat(tower_color)
	tower_mat.metallic = 0.65
	tower_mat.roughness = 0.35
	var tower_recess := MeshFactory.mat(tower_recess_color)
	var tower_panel := MeshFactory.mat(tower_panel_color)
	var tower_strip_cyan := COLOR_CORE_CYAN if chapter == 4 else COLOR_ARCHIVE_CYAN
	var tower_strip_amber := COLOR_CORE_AMBER if chapter == 4 else COLOR_ARCHIVE_AMBER

	# Massive foundation pylons anchoring the platform into the deep abyss
	for offset in [
		Vector3(-width * 0.42, -5.0, -depth * 0.42),
		Vector3(width * 0.42, -5.0, -depth * 0.42),
		Vector3(-width * 0.42, -5.0, depth * 0.42),
		Vector3(width * 0.42, -5.0, depth * 0.42)
	]:
		MeshFactory.box(self, center + offset, Vector3(1.6, 9.0, 1.6), tower_mat)
		MeshFactory.box(self, center + offset + Vector3(0, -1.0, 0), Vector3(1.8, 4.0, 1.8), tower_recess)
		_add_static_neon_strip(center + offset + Vector3(0, 1.5, 0.82), Vector3(0.12, 5.0, 0.02), tower_strip_cyan, 2.2)

	# Hanging industrial power conduits connecting platform to the deep void
	for cable_x in [-width * 0.35, 0.0, width * 0.35]:
		MeshFactory.box(self, center + Vector3(cable_x, -4.2, depth * 0.52), Vector3(0.08, 6.5, 0.08), tower_recess)
		MeshFactory.box(self, center + Vector3(cable_x, -4.2, -depth * 0.52), Vector3(0.08, 6.5, 0.08), tower_recess)

	# Distant towering monolithic Data Towers of ancient Asteria
	var towers: Array = [
		{"pos": center + Vector3(width * 1.35, 1.5, -depth * 1.45), "size": Vector3(4.2, 18.0, 3.8), "strip": tower_strip_cyan},
		{"pos": center + Vector3(-width * 1.55, 3.5, -depth * 1.30), "size": Vector3(5.2, 22.0, 4.6), "strip": tower_strip_cyan},
		{"pos": center + Vector3(-width * 1.65, -0.5, depth * 1.35), "size": Vector3(3.8, 14.0, 3.5), "strip": tower_strip_amber},
		{"pos": center + Vector3(width * 1.50, -1.5, depth * 1.40), "size": Vector3(4.6, 16.0, 4.2), "strip": tower_strip_cyan},
		{"pos": center + Vector3(-0.5, 5.5, -depth * 2.10), "size": Vector3(3.2, 26.0, 3.2), "strip": tower_strip_cyan},
		{"pos": center + Vector3(width * 2.1, 1.0, 0.0), "size": Vector3(3.6, 17.0, 3.6), "strip": tower_strip_amber},
		{"pos": center + Vector3(-width * 2.2, 0.5, -0.5), "size": Vector3(3.4, 16.0, 3.4), "strip": tower_strip_cyan}
	]
	for t in towers:
		var t_pos: Vector3 = t["pos"]
		var t_size: Vector3 = t["size"]
		var strip_color: Color = t["strip"]
		MeshFactory.box(self, t_pos, t_size, tower_mat)
		MeshFactory.box(self, t_pos + Vector3(0, 0, 0.05), Vector3(t_size.x * 0.82, t_size.y * 0.94, t_size.z * 1.02), tower_recess)
		MeshFactory.box(self, t_pos + Vector3(0, t_size.y * 0.22, 0.1), Vector3(t_size.x * 0.68, t_size.y * 0.38, t_size.z * 1.04), tower_panel)
		
		# Vertical glowing spine
		var strip_pos := t_pos + Vector3(0, 0, t_size.z * 0.53)
		var strip_size := Vector3(0.14, t_size.y * 0.82, 0.04)
		_add_static_neon_strip(strip_pos, strip_size, strip_color, 2.6)
		
		# Server window array lines
		for row in 3:
			var row_y := t_pos.y + float(row - 1) * 2.5
			_add_static_neon_strip(Vector3(t_pos.x, row_y, t_pos.z + t_size.z * 0.53), Vector3(t_size.x * 0.45, 0.06, 0.04), strip_color, 2.0)
		
		# Top rooftop antenna beacon
		var beacon_pos := t_pos + Vector3(0, t_size.y * 0.5 + 0.35, 0)
		var beacon := MeshFactory.sphere(self, beacon_pos, 0.18, MeshFactory.mat(strip_color, 3.2))
		if beacon:
			var b_light := OmniLight3D.new()
			b_light.position = beacon_pos
			b_light.light_color = strip_color
			b_light.light_energy = 1.2
			b_light.omni_range = 6.0
			add_child(b_light)

	# Deep cosmic abyss: floating stars and stardust
	_add_cosmic_starfield(center)


func _add_cosmic_starfield(center: Vector3) -> void:
	# Layer 1: Floating twinkling cosmic stars in the deep abyss below
	var star_particles := GPUParticles3D.new()
	star_particles.position = center + Vector3(0, -5.5, 0)
	star_particles.amount = 160
	star_particles.lifetime = 14.0
	star_particles.preprocess = 14.0
	star_particles.randomness = 0.85
	var extents := Vector3(35.0, 7.5, 35.0)
	star_particles.visibility_aabb = AABB(-extents, extents * 2.0)
	
	var quad := QuadMesh.new()
	quad.size = Vector2(0.045, 0.045)
	var star_mat := MeshFactory.transparent_mat(Color(1.0, 1.0, 1.0, 0.95), 3.2)
	star_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	quad.material = star_mat
	star_particles.draw_pass_1 = quad
	
	var process_mat := ParticleProcessMaterial.new()
	process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_mat.emission_box_extents = extents
	process_mat.direction = Vector3(0.05, 0.08, 0.05)
	process_mat.spread = 180.0
	process_mat.initial_velocity_min = 0.003
	process_mat.initial_velocity_max = 0.018
	process_mat.gravity = Vector3.ZERO
	process_mat.scale_min = 0.35
	process_mat.scale_max = 1.6
	process_mat.color = Color(0.9, 0.96, 1.0, 0.92)
	star_particles.process_material = process_mat
	add_child(star_particles)
	star_particles.emitting = true

	# Layer 2: Prominent glowing stars with distinct colors (White, Cyan, Warm Gold, Lavender)
	var star_coords: Array = [
		Vector3(-8.5, -1.8, -6.5), Vector3(9.2, -2.5, -7.8), Vector3(-12.0, -3.8, 5.2),
		Vector3(11.5, -2.2, 8.4), Vector3(-4.5, -1.5, 9.5), Vector3(6.8, -4.2, -3.2),
		Vector3(-15.2, -5.5, -10.5), Vector3(14.8, -4.8, -12.0), Vector3(-10.5, -6.2, 14.2),
		Vector3(16.2, -5.8, 11.5), Vector3(0.0, -3.2, -14.0), Vector3(-3.2, -4.5, 16.5),
		Vector3(7.5, -6.8, 15.0), Vector3(-18.0, -4.5, 0.0), Vector3(19.0, -3.8, -2.0),
		Vector3(-6.2, -2.8, -12.5), Vector3(13.0, -6.5, 3.5), Vector3(-14.0, -7.2, -5.5),
		Vector3(3.5, -1.2, 7.8), Vector3(-7.8, -2.0, 3.2), Vector3(5.2, -2.4, -9.5),
		Vector3(-2.0, -8.5, 2.0), Vector3(4.0, -7.5, -4.0), Vector3(-9.0, -9.0, -8.0)
	]
	var star_colors: Array[Color] = [
		Color(1.0, 1.0, 1.0),
		Color(0.55, 0.88, 1.0),
		Color(1.0, 0.85, 0.55),
		Color(0.82, 0.70, 1.0)
	]
	for i in star_coords.size():
		var pos: Vector3 = center + star_coords[i]
		var col: Color = star_colors[i % star_colors.size()]
		var star_sphere := MeshFactory.sphere(self, pos, 0.035 + (i % 3) * 0.015, MeshFactory.mat(col, 4.2))
		if star_sphere and (i % 4 == 0):
			var sl := OmniLight3D.new()
			sl.position = pos
			sl.light_color = col
			sl.light_energy = 0.4
			sl.omni_range = 3.0
			add_child(sl)


func _add_static_neon_strip(position: Vector3, size: Vector3, color: Color, energy := 2.2) -> void:
	var mat := MeshFactory.mat(color, energy)
	MeshFactory.box(self, position, size, mat)





func _build_sector_facade(position: Vector3, size: Vector3, along_z: bool, panel: Material, recess: Material) -> void:
	MeshFactory.box(self, position, size, recess)
	var strip_color := COLOR_CORE_CYAN if chapter == 4 else COLOR_ARCHIVE_CYAN
	var count := 5
	for i in count:
		var t := (float(i) + 0.5) / float(count) - 0.5
		var pos := position
		var module_size: Vector3
		if along_z:
			pos.z += t * (size.z - 0.5)
			module_size = Vector3(size.x + 0.055, size.y * (0.72 if i == 4 else 0.88), (size.z - 0.72) / count)
		else:
			pos.x += t * (size.x - 0.5)
			module_size = Vector3((size.x - 0.72) / count, size.y * (0.70 if i == 0 else 0.88), size.z + 0.055)
		pos.y -= (size.y - module_size.y) * 0.5
		MeshFactory.box(self, pos, module_size, panel)
		if i % 2 == 0:
			var strip_size := Vector3(0.025, module_size.y * 0.52, 0.018)
			var strip_pos := pos
			if along_z:
				strip_pos.x += size.x * 0.52
			else:
				strip_pos.z += size.z * 0.52
			_add_power_strip(strip_pos, strip_size, strip_color, 0.025, 1.35)


func _add_dust_volume(position: Vector3, extents: Vector3) -> void:
	var particles := GPUParticles3D.new()
	particles.position = position
	particles.amount = RENDER_QUALITY.particle_amount(42)
	particles.lifetime = 10.0
	particles.preprocess = 10.0
	particles.randomness = 0.7
	particles.visibility_aabb = AABB(-extents, extents * 2.0)
	var quad := QuadMesh.new()
	quad.size = Vector2(0.028, 0.028)
	var dust_color := Color(0.54, 0.78, 0.86) if chapter == 4 else Color(0.42, 0.70, 0.82)
	var dust_mat := MeshFactory.transparent_mat(Color(dust_color.r, dust_color.g, dust_color.b, 0.23), 0.5)
	dust_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	quad.material = dust_mat
	particles.draw_pass_1 = quad
	var process_mat := ParticleProcessMaterial.new()
	process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_mat.emission_box_extents = extents
	process_mat.direction = Vector3(0.12, 1.0, 0.08)
	process_mat.spread = 32.0
	process_mat.initial_velocity_min = 0.015
	process_mat.initial_velocity_max = 0.055
	process_mat.gravity = Vector3(0, 0.004, 0)
	process_mat.scale_min = 0.45
	process_mat.scale_max = 1.25
	particles.process_material = process_mat
	add_child(particles)
	particles.emitting = true


func _add_light_shaft(position: Vector3, radius: float, color := Color(0.16, 0.62, 0.90)) -> void:
	var shaft := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.22
	mesh.bottom_radius = radius
	mesh.height = 3.6
	mesh.radial_segments = 24
	shaft.mesh = mesh
	shaft.position = position
	shaft.material_override = MeshFactory.transparent_mat(Color(color.r, color.g, color.b, 0.055), 0.7)
	add_child(shaft)


func _build_story_lighting(logic: GameLogic) -> void:
	# Kiro stays legible against the room, while tight cones on Core and Pedestal
	# keep their pools inside one cell. Central Core shifts the key light toward
	# white/cyan so the reactor reads as a live network rather than a warehouse.
	var player_light_color := Color(0.82, 0.94, 1.0) if chapter == 4 else Color(1.0, 0.86, 0.78)
	var block_light_color := COLOR_CORE_CYAN if chapter == 4 else Color(0.68, 0.20, 1.0)
	var slot_light_color := COLOR_CORE_CYAN if chapter == 4 else COLOR_ARCHIVE_CYAN
	_add_spotlight(world_position(logic.player) + Vector3(0, 3.8, 0), player_light_color, 2.4, 6.2, 20.0, RENDER_QUALITY.shadows_enabled(), self)
	if RENDER_QUALITY.is_mobile():
		return
	for cell in logic.blocks.keys():
		_add_spotlight(world_position(cell) + Vector3(0, 3.5, 0), block_light_color, 2.2, 5.4, 17.0, false, _layer_parent(cell))
	for cell in logic.slots.keys():
		_add_spotlight(world_position(cell) + Vector3(0, 3.4, 0), slot_light_color, 2.6, 5.2, 17.0, false, _layer_parent(cell))


func _build_mobile_color_pools(logic: GameLogic, goal_color: Color, plate_color: Color, portal_color: Color, elevator_color: Color, block_color: Color) -> void:
	if not RENDER_QUALITY.mobile_color_pools_enabled():
		return
	var candidates: Array[Dictionary] = []
	for position in logic.slots.keys():
		candidates.append({"position": position, "color": goal_color, "energy": 0.58})
	for position in logic.plates.keys():
		candidates.append({"position": position, "color": plate_color, "energy": 0.46})
	for position in logic.portals.keys():
		candidates.append({"position": position, "color": portal_color, "energy": 0.52})
	for position in logic.elevators.keys():
		candidates.append({"position": position, "color": elevator_color, "energy": 0.48})
	for position in logic.blocks.keys():
		candidates.append({"position": position, "color": block_color, "energy": 0.38})
	for candidate in candidates:
		if _mobile_color_pools_used >= RENDER_QUALITY.mobile_color_pool_budget():
			break
		_add_mobile_color_pool(candidate["position"], candidate["color"], float(candidate["energy"]))


func _add_mobile_color_pool(cell: Vector3i, color: Color, energy: float) -> void:
	var pool := MeshInstance3D.new()
	pool.name = "MobileColorPool%d" % (_mobile_color_pools_used + 1)
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.54
	mesh.bottom_radius = 0.54
	mesh.height = 0.012
	mesh.radial_segments = 12
	pool.mesh = mesh
	var pool_material := MeshFactory.transparent_mat(Color(color.r, color.g, color.b, 0.14), energy)
	pool_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	pool.material_override = pool_material
	pool.position = world_position(cell) + Vector3(0, 0.025, 0)
	pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_layer_parent(cell).add_child(pool)
	_mobile_color_pools_used += 1


func _add_spotlight(position: Vector3, color: Color, energy: float, light_range: float, angle: float, shadows: bool, parent: Node3D = null) -> void:
	var spot := SpotLight3D.new()
	spot.position = position
	spot.rotation_degrees.x = -90.0
	spot.light_color = color
	spot.light_energy = energy
	spot.spot_range = light_range
	spot.spot_angle = angle
	spot.shadow_enabled = shadows and RENDER_QUALITY.shadows_enabled()
	(parent if parent != null else self).add_child(spot)


func _add_sector_lamp(position: Vector3, color: Color, parent: Node3D = null) -> void:
	var node_parent := parent if parent != null else self
	if RENDER_QUALITY.local_lights_enabled():
		var light := OmniLight3D.new()
		light.position = position
		light.light_color = color
		light.light_energy = 0.22
		light.omni_range = 2.6
		light.omni_attenuation = 1.45
		node_parent.add_child(light)
		sector_power_lights.append({"node": light, "off": 0.22, "on": 2.1})
	var lens_mat := MeshFactory.mat(color, 0.25)
	var lens := MeshFactory.sphere(node_parent, position, 0.055, lens_mat)
	lens.scale = Vector3(1.0, 0.55, 1.0)
	sector_power_materials.append({"material": lens_mat, "off": 0.25, "on": 4.0})


func _add_hologram_glow(position: Vector3, color := COLOR_ARCHIVE_CYAN, parent: Node3D = null) -> void:
	var node_parent := parent if parent != null else self
	if RENDER_QUALITY.local_lights_enabled():
		var light := OmniLight3D.new()
		light.position = position
		light.light_color = color
		light.light_energy = 0.28
		light.omni_range = 3.0
		node_parent.add_child(light)
		sector_power_lights.append({"node": light, "off": 0.28, "on": 2.7})
	var holo_mat := MeshFactory.transparent_mat(Color(color.r, color.g, color.b, 0.16), 1.2)
	MeshFactory.cylinder(node_parent, position + Vector3(0, 0.46, 0), 0.22, 0.82, holo_mat)
	for height in [0.12, 0.40, 0.68]:
		MeshFactory.torus(node_parent, position + Vector3(0, height, 0), 0.20, 0.225, holo_mat)
	sector_power_materials.append({"material": holo_mat, "off": 0.35, "on": 3.6})


func _add_power_strip(position: Vector3, size: Vector3, color: Color, off_energy: float, on_energy: float) -> void:
	var mat := MeshFactory.mat(color, off_energy)
	MeshFactory.box(self, position, size, mat)
	sector_power_materials.append({"material": mat, "off": off_energy, "on": on_energy})


func _process(delta: float) -> void:
	_environment_time += delta
	if not _is_sector_powered:
		_flicker_timer += delta
		var flicker := 0.82 + 0.18 * sin(_flicker_timer * 7.5) + (0.22 if fmod(_flicker_timer, 2.4) < 0.08 else 0.0)
		for info in sector_power_lights:
			var light: Light3D = info["node"]
			if is_instance_valid(light):
				light.light_energy = float(info["off"]) * flicker
		for info in sector_power_materials:
			var material: StandardMaterial3D = info["material"]
			if is_instance_valid(material):
				material.emission_energy_multiplier = float(info["off"]) * flicker
	_update_environment_dynamics()


func _dynamic_phase(cell: Vector3i) -> float:
	return fmod(float(cell.x * 17 + cell.y * 29 + cell.z * 41), 31.0) * 0.37


func _make_dynamic_indicator(
		parent: Node3D,
		center: Vector3,
		yaw: float,
		local_position: Vector3,
		size: Vector3,
		color: Color,
		base_emission: float,
		profile: StringName,
		phase: float,
		speed: float,
		amplitude: float,
		mode: StringName = &"pulse") -> void:
	var root := Node3D.new()
	root.name = "EnvironmentDynamic_%s" % str(profile)
	root.position = center
	root.rotation_degrees.y = yaw
	parent.add_child(root)
	var mat := MeshFactory.transparent_mat(Color(color.r, color.g, color.b, 0.72), base_emission)
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	var strip := MeshFactory.box(root, local_position, size, mat)
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	environment_dynamic_materials.append({
		"material": mat,
		"profile": profile,
		"base": base_emission,
		"phase": phase,
		"speed": speed,
		"amplitude": amplitude,
		"mode": mode,
	})


func _register_environment_dynamic(node: Node3D, deco: Dictionary, center: Vector3, yaw: float, cell: Vector3i) -> void:
	var profile := StringName(str(deco.get("dynamic_profile", "")))
	if profile == &"":
		return
	environment_dynamic_profiles.append(profile)
	var phase := float(deco.get("dynamic_phase", _dynamic_phase(cell)))
	match profile:
		&"archive_terminal":
			var speed := float(deco.get("dynamic_speed", 4.2))
			var amplitude := float(deco.get("dynamic_amplitude", 0.62))
			var intensity := float(deco.get("dynamic_intensity", 1.0))
			_make_dynamic_indicator(
				_layer_parent(cell), center, yaw,
				Vector3(0, 0.44, -0.30), Vector3(0.34, 0.025, 0.018),
				COLOR_ARCHIVE_CYAN, 0.72 * intensity, profile, phase, speed, amplitude, &"flicker")
		&"archive_panel":
			var speed := float(deco.get("dynamic_speed", 2.4))
			var amplitude := float(deco.get("dynamic_amplitude", 0.48))
			var intensity := float(deco.get("dynamic_intensity", 1.0))
			_make_dynamic_indicator(
				_layer_parent(cell), center, yaw,
				Vector3(0, 0.25, -0.17), Vector3(0.24, 0.020, 0.016),
				COLOR_ARCHIVE_CYAN, 0.44 * intensity, profile, phase, speed, amplitude, &"flicker")
		&"foundry_conveyor":
			environment_dynamic_nodes.append({
				"node": node,
				"base_position": node.position,
				"base_rotation": node.rotation,
				"mode": &"vibrate",
				"axis": Vector3(1, 0, 0),
				"amplitude": float(deco.get("dynamic_amplitude", 0.007)),
				"speed": float(deco.get("dynamic_speed", 7.2)),
				"phase": phase,
			})
		&"foundry_furnace", &"foundry_machine_heat":
			var speed := float(deco.get("dynamic_speed", 1.75))
			var amplitude := float(deco.get("dynamic_amplitude", 0.72))
			var intensity := float(deco.get("dynamic_intensity", 1.0))
			_make_dynamic_indicator(
				_layer_parent(cell), center, yaw,
				Vector3(0, 0.43, -0.35), Vector3(0.34, 0.050, 0.020),
				COLOR_FOUNDRY_ORANGE, 0.82 * intensity, profile, phase, speed, amplitude)
			_make_dynamic_indicator(
				_layer_parent(cell), center, yaw,
				Vector3(0, 0.66, -0.30), Vector3(0.22, 0.030, 0.018),
				Color(1.0, 0.58, 0.12), 0.55 * intensity, profile, phase + 0.65, speed, amplitude * 0.81)
		&"sanctuary_sway":
			environment_dynamic_nodes.append({
				"node": node,
				"base_position": node.position,
				"base_rotation": node.rotation,
				"mode": &"sway",
				"axis": Vector3(0.55, 0.0, 1.0).normalized(),
				"amplitude": deg_to_rad(float(deco.get("dynamic_amplitude", 1.35))),
				"speed": float(deco.get("dynamic_speed", 0.72)),
				"phase": phase,
			})
		&"sanctuary_water":
			_configure_dynamic_water(node, deco)
		&"core_cabinet_pulse":
			var speed := float(deco.get("dynamic_speed", 1.18))
			var amplitude := float(deco.get("dynamic_amplitude", 0.52))
			var intensity := float(deco.get("dynamic_intensity", 1.0))
			_make_dynamic_indicator(
				_layer_parent(cell), center, yaw,
				Vector3(0, 0.31, -0.265), Vector3(0.46, 0.018, 0.014),
				COLOR_CORE_TEAL, 0.48 * intensity, profile, phase, speed, amplitude)
		&"core_trim_pulse":
			var speed := float(deco.get("dynamic_speed", 1.18))
			var amplitude := float(deco.get("dynamic_amplitude", 0.68))
			var intensity := float(deco.get("dynamic_intensity", 1.0))
			_make_dynamic_indicator(
				_layer_parent(cell), center, yaw,
				Vector3(0, 0.15, -0.12), Vector3(0.62, 0.018, 0.014),
				COLOR_CORE_CYAN, 0.62 * intensity, profile, phase, speed, amplitude)


func _configure_dynamic_water(node: Node, deco: Dictionary) -> void:
	var speed := float(deco.get("dynamic_speed", 0.58))
	var amplitude := float(deco.get("dynamic_amplitude", 0.012))
	if RENDER_QUALITY.is_mobile():
		amplitude *= 0.72
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			for surface in mi.mesh.get_surface_count():
				var active := mi.get_active_material(surface)
				if active is ShaderMaterial and (active as ShaderMaterial).shader == load(WATER_SHADER_PATH):
					var mat := active as ShaderMaterial
					mat.set_shader_parameter("wave_speed", speed)
					mat.set_shader_parameter("wave_amplitude", amplitude)
					if not environment_dynamic_water_materials.has(mat):
						environment_dynamic_water_materials.append(mat)
	for child in node.get_children():
		_configure_dynamic_water(child, deco)


func _update_environment_dynamics() -> void:
	var motion_scale := RENDER_QUALITY.environment_motion_scale()
	for info in environment_dynamic_nodes:
		var node: Node3D = info["node"]
		if not is_instance_valid(node):
			continue
		var phase := float(info["phase"])
		var speed := float(info["speed"])
		var amount := sin(_environment_time * speed + phase) * float(info["amplitude"]) * motion_scale
		var base_position: Vector3 = info["base_position"]
		var base_rotation: Vector3 = info["base_rotation"]
		var axis: Vector3 = info["axis"]
		match StringName(info["mode"]):
			&"vibrate":
				node.position = base_position + axis * amount
				node.rotation = base_rotation
			&"sway":
				node.position = base_position
				node.rotation = base_rotation + axis * amount
	for info in environment_dynamic_materials:
		var material: StandardMaterial3D = info["material"]
		if not is_instance_valid(material):
			continue
		var phase := float(info["phase"])
		var speed := float(info["speed"])
		var wave := 0.5 + 0.5 * sin(_environment_time * speed + phase)
		if StringName(info["mode"]) == &"flicker":
			var drop := 0.18 if fmod(_environment_time + phase, 3.15) < 0.07 else 1.0
			wave = clampf((0.34 + wave * 0.66) * drop, 0.08, 1.0)
		var emission_scale := RENDER_QUALITY.environment_emission_scale()
		material.emission_energy_multiplier = float(info["base"]) * (1.0 + wave * float(info["amplitude"])) * emission_scale


func set_sector_powered(powered: bool, immediate := false) -> void:
	_is_sector_powered = powered
	for info in sector_power_lights:
		var light: Light3D = info["node"]
		if not is_instance_valid(light):
			continue
		var target: float = float(info["on"] if powered else info["off"])
		if immediate:
			light.light_energy = target
		else:
			create_tween().tween_property(light, "light_energy", target, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for info in sector_power_materials:
		var material: StandardMaterial3D = info["material"]
		if not is_instance_valid(material):
			continue
		var target: float = float(info["on"] if powered else info["off"])
		if immediate:
			material.emission_energy_multiplier = target
		else:
			create_tween().tween_property(material, "emission_energy_multiplier", target, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)




func _board_bounds(logic: GameLogic) -> Dictionary:
	var min_x := INF
	var max_x := -INF
	var min_z := INF
	var max_z := -INF
	for cell in logic.floors.keys():
		min_x = minf(min_x, float(cell.x))
		max_x = maxf(max_x, float(cell.x))
		min_z = minf(min_z, float(cell.z))
		max_z = maxf(max_z, float(cell.z))
	return {"min_x": min_x, "max_x": max_x, "min_z": min_z, "max_z": max_z}


func set_bridge_rails_retracted(cell: Vector3i, direction: Vector3i, retracted: bool, animated := true) -> void:
	if not bridge_rail_nodes.has(cell):
		return
	var rail: Node3D = bridge_rail_nodes[cell]
	if bridge_rail_tweens.has(cell):
		var old_tween: Tween = bridge_rail_tweens[cell]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
		bridge_rail_tweens.erase(cell)
	var target_y := -0.20 if retracted else 0.0
	var target_rotation_y := 90.0 if abs(direction.x) > abs(direction.z) else 0.0
	if not animated or GameState.reduced_motion:
		rail.position.y = target_y
		rail.rotation_degrees.y = target_rotation_y
		return
	var tween := create_tween().set_parallel(true)
	bridge_rail_tweens[cell] = tween
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(rail, "position:y", target_y, 0.15)
	tween.tween_property(rail, "rotation_degrees:y", target_rotation_y, 0.15)
	tween.finished.connect(func() -> void:
		if bridge_rail_tweens.get(cell) == tween:
			bridge_rail_tweens.erase(cell)
	)


func reset_bridge_rails(animated := false) -> void:
	for cell in bridge_rail_nodes.keys():
		set_bridge_rails_retracted(cell, Vector3i(0, 0, 1), false, animated)


func set_bridges_open(open: bool, animated := false) -> void:
	reset_bridge_rails(false)
	for bridge_node in bridge_nodes.values():
		bridge_node.visible = true
		var target_rotation := Vector3.ZERO if open else Vector3(-82.0, 0.0, 0.0)
		var target_scale := Vector3.ONE if open else Vector3(1.0, 0.86, 1.0)
		if not animated:
			bridge_node.rotation_degrees = target_rotation
			bridge_node.scale = target_scale
			continue
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(bridge_node, "rotation_degrees", target_rotation, 0.48)
		tween.tween_property(bridge_node, "scale", target_scale, 0.48)


func _build_hint_marker() -> void:
	hint_marker = Node3D.new()
	hint_marker.name = "HintMarker"
	hint_marker.visible = false
	add_child(hint_marker)
	var marker_mat := MeshFactory.transparent_mat(Color(1.0, 0.78, 0.12, 0.86), 3.2)
	MeshFactory.torus(hint_marker, Vector3(0, 0.10, 0), 0.32, 0.43, marker_mat)
	MeshFactory.cylinder(hint_marker, Vector3(0, 0.075, 0), 0.045, 0.025, marker_mat)
	if RENDER_QUALITY.local_lights_enabled():
		var marker_light := OmniLight3D.new()
		marker_light.light_color = Color(1.0, 0.66, 0.10)
		marker_light.light_energy = 0.65
		marker_light.omni_range = 1.35
		marker_light.position = Vector3(0, 0.18, 0)
		hint_marker.add_child(marker_light)


func set_hint_cell(cell: Vector3i, active := true) -> void:
	if hint_marker == null:
		return
	if _hint_marker_tween and _hint_marker_tween.is_valid():
		_hint_marker_tween.kill()
	_hint_marker_tween = null
	if not active:
		hint_marker.visible = false
		return
	hint_marker.position = world_position(cell)
	hint_marker.visible = true
	hint_marker.scale = Vector3.ONE
	_hint_marker_tween = create_tween().set_loops()
	_hint_marker_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_hint_marker_tween.tween_property(hint_marker, "scale", Vector3(1.14, 1.0, 1.14), 0.55)
	_hint_marker_tween.tween_property(hint_marker, "scale", Vector3.ONE, 0.55)


func set_energy_progress(progress: int) -> void:
	for position in energy_nodes.keys():
		var energy_node: Node3D = energy_nodes[position]
		var floor_progress := progress
		var node_index := _logic.energy_nodes.find(position) if _logic != null else 0
		if _logic != null and _logic.sequential_floors:
			floor_progress = _logic.energy_progress_for_floor(position.y)
			node_index = _logic.energy_nodes_on_floor(position.y).find(position)
		energy_node.scale = Vector3.ONE if node_index < floor_progress else Vector3.ONE * 0.78
		var number := energy_node.get_node_or_null("NodeNumber") as Label3D
		if number:
			number.modulate = Color(0.25, 1.0, 0.65) if node_index < floor_progress else (Color(1.0, 0.82, 0.25) if node_index == floor_progress else Color(0.42, 0.50, 0.60))
	var total := energy_nodes.size()
	var ratio := 0.0 if total <= 0 else clampf(float(progress) / float(total), 0.0, 1.0)
	for mat in energy_cable_materials:
		if mat:
			mat.set_shader_parameter("is_active", progress > 0)
			mat.set_shader_parameter("activity_progress", ratio)


func _platform_edge(logic: GameLogic, v: Vector3i, direction: Vector3i) -> bool:
	var neighbor := v + direction
	return not logic.floors.has(neighbor) or logic.walls.has(neighbor)


func _asset(path: String) -> Variant:
	if _asset_cache.has(path):
		return _asset_cache[path]
	var scene := load(path) as PackedScene
	_asset_cache[path] = scene
	return scene


func _spawn(
		parent: Node3D,
		path: String,
		center: Vector3,
		floor_y: float,
		scale := 1.0,
		dim_until_powered := true,
		apply_chapter_material := false) -> Node3D:
	# Baked assets are centred on their footprint and stand on y = 0, authored for
	# the kit's 2-unit cell. One uniform ASSET_SCALE keeps every module in
	# proportion; per-asset width normalisation would stretch thin, tall pieces.
	var scene: Variant = _asset(path)
	if scene == null:
		return null
	var model := (scene as PackedScene).instantiate() as Node3D
	model.scale = Vector3.ONE * (ASSET_SCALE * scale)
	model.position = Vector3(center.x, floor_y, center.z)
	parent.add_child(model)
	if apply_chapter_material:
		MATERIAL_PROFILES.apply(model, chapter)
	# Scenery goes dark until the sector is powered, but pieces the player has to
	# read to solve the puzzle stay lit regardless of the story state.
	if dim_until_powered:
		_register_mesh_emissives(model)
	return model


func _register_mesh_emissives(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh:
			for i in mi.mesh.get_surface_count():
				var mat := mi.get_active_material(i)
				if mat is StandardMaterial3D and (mat as StandardMaterial3D).emission_enabled:
					var dup := mat.duplicate() as StandardMaterial3D
					mi.set_surface_override_material(i, dup)
					var orig: float = dup.emission_energy_multiplier
					sector_power_materials.append({"material": dup, "off": 0.05, "on": maxf(orig, 2.5)})
					dup.emission_energy_multiplier = 0.05
	for child in node.get_children():
		_register_mesh_emissives(child)




func _build_block(parent: Node3D, pos: Vector3, base_mat: Material, accent_mat: Material) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	# `pos` already contains the gameplay floor height. The authored model must use
	# a floor-relative local offset; subtracting `pos.y` here used to cancel the
	# floor elevation and put every upper-floor Core back at Floor 1 height.
	var model_local_y := FLOOR_TOP_Y - world_position(Vector3i.ZERO).y - BLOCK_ROOT_HEIGHT
	var core := _spawn(root, ENERGY_CORE_PATH, Vector3.ZERO, model_local_y, 1.0, false)
	if core != null:
		core.name = "EnergyCoreModel"
	if core == null:
		MeshFactory.box(root, Vector3.ZERO, Vector3(0.80, 0.80, 0.80), base_mat)
		MeshFactory.box(root, Vector3(0, 0.415, 0), Vector3(0.56, 0.035, 0.56), accent_mat)
		MeshFactory.box(root, Vector3(0, -0.415, 0), Vector3(0.56, 0.035, 0.56), accent_mat)
		MeshFactory.box(root, Vector3(0, 0, -0.405), Vector3(0.60, 0.035, 0.025), accent_mat)
		MeshFactory.box(root, Vector3(0, 0, 0.405), Vector3(0.60, 0.035, 0.025), accent_mat)
	# A persistent ground ring distinguishes movable Cores from scenery. This is
	# deliberately geometry-only (no extra light) so it stays cheap on Android.
	MeshFactory.torus(root, Vector3(0, -0.405, 0), 0.34, 0.43, accent_mat)
	if RENDER_QUALITY.local_lights_enabled():
		var core_light := OmniLight3D.new()
		core_light.light_color = COLOR_BLOCK_EDGE
		core_light.light_energy = 0.75
		core_light.omni_range = 1.8
		core_light.position = Vector3(0, 0.1, 0)
		root.add_child(core_light)
	return root


func _build_door(parent: Node3D, pos: Vector3, base_mat: Material, accent_mat: Material) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	MeshFactory.box(root, Vector3.ZERO, Vector3(0.88, 1.08, 0.22), base_mat)
	MeshFactory.box(root, Vector3(0, 0, -0.125), Vector3(0.58, 0.72, 0.035), accent_mat)
	MeshFactory.box(root, Vector3(0, 0.42, -0.145), Vector3(0.72, 0.055, 0.025), accent_mat)
	return root


var kiro_glow_materials: Array[StandardMaterial3D] = []


func _collect_kiro_glow_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh:
			for i in mi.mesh.get_surface_count():
				var mat := mi.get_active_material(i)
				if mat is StandardMaterial3D:
					var dup := mat.duplicate() as StandardMaterial3D
					mi.set_surface_override_material(i, dup)
					var mat_name: String = dup.resource_name.to_lower()
					var is_glow := "glow" in mat_name or "cyan" in mat_name or dup.emission_enabled
					if is_glow:
						kiro_glow_materials.append(dup)
	for child in node.get_children():
		_collect_kiro_glow_materials(child)


func set_kiro_powered(powered: bool, immediate := false) -> void:
	for mat in kiro_glow_materials:
		if not is_instance_valid(mat):
			continue
		if immediate:
			mat.emission_enabled = powered
			mat.emission_energy_multiplier = 3.5 if powered else 0.0
			mat.albedo_color = Color(0.12, 0.92, 1.0) if powered else Color(0.04, 0.06, 0.08)
		else:
			if powered:
				mat.emission_enabled = true
				var tw := create_tween()
				tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tw.tween_property(mat, "emission_energy_multiplier", 3.5, 0.45)
				tw.parallel().tween_property(mat, "albedo_color", Color(0.12, 0.92, 1.0), 0.45)
			else:
				mat.emission_energy_multiplier = 0.0
				mat.albedo_color = Color(0.04, 0.06, 0.08)


func _build_player(parent: Node3D, pos: Vector3, player_mat: Material, accent_mat: Material) -> Node3D:
	var kiro_scene := load(KIRO_MODEL_PATH) as PackedScene
	if kiro_scene:
		var model := kiro_scene.instantiate() as Node3D
		model.name = "Kiro_K7"
		player_visual_offset = Vector3(0, KIRO_MODEL_FLOOR_OFFSET, 0)
		model.position = pos + player_visual_offset
		model.scale = Vector3.ONE * KIRO_MODEL_SCALE
		parent.add_child(model)
		kiro_glow_materials.clear()
		_collect_kiro_glow_materials(model)
		set_kiro_powered(true, true)
		player_animation = _find_animation_player(model)
		play_player_animation(&"Idle")
		_add_player_ground_ring(model)
		return model
	return _build_player_procedural(parent, pos, player_mat, accent_mat)


func _add_player_ground_ring(model: Node3D) -> void:
	# Kiro is small and dark against the floor. A ring at his feet gives the local
	# contrast the silhouette alone does not. Sizes are divided by the model scale
	# because the ring rides inside the scaled model.
	var ring_mat := MeshFactory.mat(COLOR_PLAYER, 2.6)
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.albedo_color = Color(COLOR_PLAYER.r, COLOR_PLAYER.g, COLOR_PLAYER.b, 0.55)
	var inv := 1.0 / KIRO_MODEL_SCALE
	MeshFactory.torus(model, Vector3(0, 0.03 * inv, 0), 0.30 * inv, 0.38 * inv, ring_mat)



func play_player_animation(clip: StringName) -> void:
	if not player_animation or not player_animation.has_animation(clip):
		return
	if clip == _current_clip and player_animation.is_playing():
		return
	var animation := player_animation.get_animation(clip)
	animation.loop_mode = Animation.LOOP_LINEAR if clip == &"Idle" or clip == &"Walk" or clip == &"Victory" else Animation.LOOP_NONE
	player_animation.play(clip)
	_current_clip = clip


func play_oneshot(clip: StringName) -> void:
	# Play a non-looping clip, then settle back to Idle.
	if not player_animation or not player_animation.has_animation(clip):
		return
	play_player_animation(clip)
	await player_animation.animation_finished
	play_player_animation(&"Idle")


func play_boot_awakening() -> void:
	if not player_node:
		return
	if player_animation and player_animation.has_animation(&"Power_On"):
		play_player_animation(&"Power_On")
	else:
		var initial_y: float = player_node.position.y
		player_node.position.y -= 0.12
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(player_node, "position:y", initial_y, 0.75)
		play_player_animation(&"Idle")




func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null


func _build_player_procedural(parent: Node3D, pos: Vector3, player_mat: Material, accent_mat: Material) -> Node3D:
	player_visual_offset = Vector3.ZERO
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	MeshFactory.box(root, Vector3(-0.13, -0.23, 0), Vector3(0.15, 0.28, 0.16), player_mat)
	MeshFactory.box(root, Vector3(0.13, -0.23, 0), Vector3(0.15, 0.28, 0.16), player_mat)
	MeshFactory.box(root, Vector3(0, 0.02, 0), Vector3(0.52, 0.44, 0.34), player_mat)
	MeshFactory.box(root, Vector3(0, 0.05, 0.18), Vector3(0.16, 0.16, 0.02), accent_mat)
	MeshFactory.box(root, Vector3(-0.34, 0.02, 0), Vector3(0.12, 0.34, 0.14), player_mat)
	MeshFactory.box(root, Vector3(0.34, 0.02, 0), Vector3(0.12, 0.34, 0.14), player_mat)
	MeshFactory.box(root, Vector3(0, 0.28, 0), Vector3(0.16, 0.08, 0.16), accent_mat)
	MeshFactory.box(root, Vector3(0, 0.42, 0), Vector3(0.36, 0.30, 0.30), player_mat)
	MeshFactory.box(root, Vector3(-0.08, 0.44, 0.16), Vector3(0.08, 0.08, 0.03), accent_mat)
	MeshFactory.box(root, Vector3(0.08, 0.44, 0.16), Vector3(0.08, 0.08, 0.03), accent_mat)
	MeshFactory.cylinder(root, Vector3(0, 0.66, 0), 0.02, 0.14, accent_mat)
	MeshFactory.sphere(root, Vector3(0, 0.75, 0), 0.05, accent_mat)
	return root


func world_position(v: Vector3i) -> Vector3:
	return Vector3(v.x, 0.04 + v.y * 1.15, v.z)


func _floor_surface_y(v: Vector3i) -> float:
	# Baked gameplay props use FLOOR_TOP_Y on Floor 1. Preserve that authored
	# offset while adding the runtime elevation of higher puzzle floors.
	return world_position(v).y + (FLOOR_TOP_Y - world_position(Vector3i.ZERO).y)


func player_position(v: Vector3i, blocks: Dictionary) -> Vector3:
	var offset := Vector3(-0.27, 0.42, 0.27) if blocks.has(v) else Vector3(0, 0.42, 0)
	return world_position(v) + offset


func player_target(v: Vector3i, blocks: Dictionary) -> Vector3:
	return player_position(v, blocks) + player_visual_offset


func face_player(dir: Vector3i) -> void:
	# Kiro's animation-library GLB front faces +Z in Godot (Blender front -Y maps
	# to +Z on export);
	# yaw so that +Z forward points along dir, turning along the shortest arc.
	if not player_node or (dir.x == 0 and dir.z == 0):
		return
	var target := atan2(float(dir.x), float(dir.z))
	var current: float = player_node.rotation.y
	var next := current + angle_difference(current, target)
	if _turn_tween and _turn_tween.is_valid():
		_turn_tween.kill()
	_turn_tween = player_node.create_tween()
	_turn_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_turn_tween.tween_property(player_node, "rotation:y", next, 0.09)


func door_position(v: Vector3i, open: bool) -> Vector3:
	return world_position(v) + Vector3(0, -0.58 if open else 0.58, 0)


var _eva_hologram_node: Node3D = null
var _eva_bob_tween: Tween = null
var _eva_hologram_material: ShaderMaterial = null
var _elias_hologram_node: Node3D = null
var _elias_bob_tween: Tween = null


func spawn_eva_hologram(world_pos: Vector3, look_at_target: Vector3 = Vector3.ZERO, stage := 4) -> Node3D:
	dismiss_eva_hologram(true)
	var eva_scene := load(EVA_MODEL_PATH) as PackedScene
	if not eva_scene:
		return null
	var eva := eva_scene.instantiate() as Node3D
	eva.name = "EVA_Hologram"
	eva.position = world_pos + Vector3(0, 0.28, 0)
	eva.scale = Vector3(0.01, 0.01, 0.01)
	
	# Face towards Kiro
	if look_at_target != Vector3.ZERO:
		var dir := look_at_target - world_pos
		if dir.x != 0.0 or dir.z != 0.0:
			eva.rotation.y = atan2(dir.x, dir.z)
	
	# Apply Hologram Shader with balanced emission
	var h_shader := load(HOLOGRAM_SHADER_PATH) as Shader
	if h_shader:
		var h_mat := ShaderMaterial.new()
		h_mat.shader = h_shader
		_eva_hologram_material = h_mat
		_apply_hologram_material(eva, h_mat)
	
	# Soft holographic glow light
	if RENDER_QUALITY.local_lights_enabled():
		var holo_light := OmniLight3D.new()
		holo_light.light_color = Color(0.3, 0.85, 1.0)
		holo_light.light_energy = 0.9
		holo_light.omni_range = 1.8
		holo_light.position = Vector3(0, 0.15, 0)
		eva.add_child(holo_light)
	
	add_child(eva)
	_eva_hologram_node = eva
	_configure_eva_hologram(stage)

	# Compact hologram scale (proportional to Kiro and core). Lower stages are
	# intentionally incomplete/weak so Level 14 can rebuild EVA node by node.
	var target_scale := Vector3.ONE * _eva_stage_scale(stage)
	var enter_tw := create_tween().set_parallel(true)
	enter_tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	enter_tw.tween_property(eva, "scale", target_scale, 0.5)
	enter_tw.tween_property(eva, "position:y", world_pos.y + 0.36, 0.5)
	
	# Gentle hover bobbing loop
	_eva_bob_tween = create_tween().set_loops()
	_eva_bob_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_eva_bob_tween.tween_property(eva, "position:y", world_pos.y + 0.40, 1.2)
	_eva_bob_tween.tween_property(eva, "position:y", world_pos.y + 0.34, 1.2)
	
	return eva


func set_eva_hologram_stage(stage: int, world_pos: Vector3, look_at_target: Vector3 = Vector3.ZERO) -> Node3D:
	stage = clampi(stage, 0, 4)
	if stage <= 0:
		dismiss_eva_hologram()
		return null
	if _eva_hologram_node == null or not is_instance_valid(_eva_hologram_node):
		return spawn_eva_hologram(world_pos, look_at_target, stage)
	if look_at_target != Vector3.ZERO:
		var dir := look_at_target - world_pos
		if dir.x != 0.0 or dir.z != 0.0:
			_eva_hologram_node.rotation.y = atan2(dir.x, dir.z)
	_configure_eva_hologram(stage)
	var target_scale := Vector3.ONE * _eva_stage_scale(stage)
	create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(
		_eva_hologram_node, "scale", target_scale, 0.32)
	return _eva_hologram_node


func _eva_stage_scale(stage: int) -> float:
	match clampi(stage, 1, 4):
		1:
			return 0.09
		2:
			return 0.12
		3:
			return 0.15
		_:
			return 0.18


func _configure_eva_hologram(stage: int) -> void:
	if _eva_hologram_material == null:
		return
	var alpha: float = float([0.0, 0.22, 0.38, 0.58, 0.76][clampi(stage, 0, 4)])
	var emission: float = float([0.0, 0.85, 1.05, 1.30, 1.60][clampi(stage, 0, 4)])
	var glitch: float = float([0.0, 0.34, 0.24, 0.14, 0.06][clampi(stage, 0, 4)])
	_eva_hologram_material.set_shader_parameter("hologram_color", Color(0.18, 0.75, 1.0, alpha))
	_eva_hologram_material.set_shader_parameter("rim_color", Color(0.78, 0.35, 1.0, minf(1.0, alpha + 0.18)))
	_eva_hologram_material.set_shader_parameter("emission_energy", emission)
	_eva_hologram_material.set_shader_parameter("scanline_frequency", 100.0 - float(stage) * 2.5)
	_eva_hologram_material.set_shader_parameter("flicker_amount", 0.18 - float(stage) * 0.025)
	_eva_hologram_material.set_shader_parameter("glitch_strength", glitch)


func _build_energy_cables(logic: GameLogic) -> void:
	if logic.energy_nodes.size() < 2:
		return
	var shader := load(ENERGY_CABLE_SHADER_PATH) as Shader
	var by_floor := {}
	for cell in logic.energy_nodes:
		if not by_floor.has(cell.y):
			by_floor[cell.y] = []
		by_floor[cell.y].append(cell)
	for floor in by_floor.keys():
		var nodes: Array = by_floor[floor]
		for i in range(nodes.size() - 1):
			var a: Vector3i = nodes[i]
			var b: Vector3i = nodes[i + 1]
			var start := world_position(a) + Vector3(0, 0.18, 0)
			var finish := world_position(b) + Vector3(0, 0.18, 0)
			var mid := (start + finish) * 0.5
			var cable := _spawn(_layer_parent(a), ENERGY_CABLE_PATH, mid, mid.y, 0.85, false, false)
			if cable == null:
				continue
			var delta := finish - start
			if delta.length_squared() > 0.001:
				cable.look_at(finish, Vector3.UP)
				var span := maxf(delta.length() / 2.0, 0.35)
				cable.scale = Vector3(ASSET_SCALE * 0.7, ASSET_SCALE * 0.7, ASSET_SCALE * span)
			if shader:
				var mat := ShaderMaterial.new()
				mat.shader = shader
				mat.set_shader_parameter("is_active", false)
				mat.set_shader_parameter("activity_progress", 0.0)
				_apply_hologram_material(cable, mat)
				energy_cable_materials.append(mat)


func _apply_water_shader(node: Node3D, ice_mode := false) -> void:
	var shader := load(WATER_SHADER_PATH) as Shader
	if shader == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("is_ice_mode", 1.0 if ice_mode else 0.0)
	_apply_water_material(node, mat, ice_mode)


func _apply_water_material(node: Node, mat: ShaderMaterial, apply_all_surfaces := false) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			for surface in mi.mesh.get_surface_count():
				var source := mi.get_active_material(surface)
				if apply_all_surfaces or (source != null and "water" in source.resource_name.to_lower()):
					mi.set_surface_override_material(surface, mat)
	for child in node.get_children():
		_apply_water_material(child, mat, apply_all_surfaces)


func place_memory_fragment(cell: Vector3i) -> void:
	if fragment_node != null and is_instance_valid(fragment_node):
		fragment_node.queue_free()
	var pos := world_position(cell) + Vector3(0, 0.42, 0)
	fragment_node = _spawn(_layer_parent(cell), FRAGMENT_MODEL_PATH, pos, pos.y, 1.15, false, false)
	if fragment_node == null:
		return
	var shader := load(FRAGMENT_SHADER_PATH) as Shader
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		_apply_hologram_material(fragment_node, mat)


func collect_memory_fragment() -> Vector3:
	if fragment_node == null or not is_instance_valid(fragment_node):
		return Vector3.ZERO
	var pos := fragment_node.global_position
	fragment_node.queue_free()
	fragment_node = null
	return pos


func spawn_elias_hologram(world_pos: Vector3, look_at_target: Vector3 = Vector3.ZERO) -> Node3D:
	dismiss_elias_hologram(true)
	var scene := load(ELIAS_MODEL_PATH) as PackedScene
	if scene == null:
		return null
	var elias := scene.instantiate() as Node3D
	elias.name = "EliasHologram"
	elias.position = world_pos + Vector3(0, 0.36, 0)
	elias.scale = Vector3.ONE * 0.01
	if look_at_target != Vector3.ZERO:
		var dir := look_at_target - world_pos
		if dir.x != 0.0 or dir.z != 0.0:
			elias.rotation.y = atan2(dir.x, dir.z)
	var shader := load(HOLOGRAM_SHADER_PATH) as Shader
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("hologram_color", Color(1.0, 0.62, 0.18, 0.72))
		mat.set_shader_parameter("rim_color", Color(1.0, 0.85, 0.40, 0.95))
		mat.set_shader_parameter("emission_energy", 1.4)
		mat.set_shader_parameter("scanline_frequency", 70.0)
		mat.set_shader_parameter("glitch_strength", 0.08)
		_apply_hologram_material(elias, mat)
	add_child(elias)
	_elias_hologram_node = elias
	var enter := create_tween().set_parallel(true)
	enter.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	enter.tween_property(elias, "scale", Vector3.ONE * 0.16, 0.45)
	enter.tween_property(elias, "position:y", world_pos.y + 0.42, 0.45)
	_elias_bob_tween = create_tween().set_loops()
	_elias_bob_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_elias_bob_tween.tween_property(elias, "position:y", world_pos.y + 0.46, 1.35)
	_elias_bob_tween.tween_property(elias, "position:y", world_pos.y + 0.39, 1.35)
	return elias


func _apply_hologram_material(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		mi.material_override = mat
	for child in node.get_children():
		_apply_hologram_material(child, mat)


func dismiss_eva_hologram(immediate: bool = false) -> void:
	if _eva_bob_tween and _eva_bob_tween.is_valid():
		_eva_bob_tween.kill()
		_eva_bob_tween = null
	if not _eva_hologram_node or not is_instance_valid(_eva_hologram_node):
		_eva_hologram_node = null
		return
	var target_node := _eva_hologram_node
	_eva_hologram_node = null
	if immediate:
		target_node.queue_free()
		return
	var tw := create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(target_node, "scale", Vector3(0.01, 0.8, 0.01), 0.4)
	tw.tween_property(target_node, "position:y", target_node.position.y - 0.2, 0.4)
	tw.finished.connect(func() -> void:
		if is_instance_valid(target_node):
			target_node.queue_free()
	)


func dismiss_elias_hologram(immediate: bool = false) -> void:
	if _elias_bob_tween and _elias_bob_tween.is_valid():
		_elias_bob_tween.kill()
		_elias_bob_tween = null
	if not _elias_hologram_node or not is_instance_valid(_elias_hologram_node):
		_elias_hologram_node = null
		return
	var target_node := _elias_hologram_node
	_elias_hologram_node = null
	if immediate:
		target_node.queue_free()
		return
	var tw := create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(target_node, "scale", Vector3(0.01, 0.8, 0.01), 0.38)
	tw.tween_property(target_node, "position:y", target_node.position.y - 0.18, 0.38)
	tw.finished.connect(func() -> void:
		if is_instance_valid(target_node):
			target_node.queue_free()
	)
