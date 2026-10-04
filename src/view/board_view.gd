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
const MODULE_MOTION = preload("res://src/view/module_motion.gd")
const BOARD_LIGHTING = preload("res://src/view/board_lighting.gd")
const BOARD_ENVIRONMENT = preload("res://src/view/board_environment.gd")
const BOARD_ACTORS = preload("res://src/view/board_actors.gd")
const BOARD_DECORATIONS = preload("res://src/view/board_decorations.gd")
const BOARD_GAMEPLAY_OBJECTS = preload("res://src/view/board_gameplay_objects.gd")
const BOARD_GEOMETRY = preload("res://src/view/board_geometry.gd")
const ENVIRONMENT_DYNAMICS = preload("res://src/view/environment_dynamics.gd")
const MATERIAL_PROFILES = preload("res://src/data/chapter_material_profiles.gd")
const RENDER_QUALITY = preload("res://src/data/render_quality.gd")
# The Blender modular kit is authored on a 2-unit cell; gameplay uses 1 unit.
const ASSET_SCALE := 0.5
const FLOOR_TOP_Y := 0.154
## Compatibility aliases for tools/tests that inspect BoardView's public asset paths.
const FLOOR_TILE_PATH := BOARD_GEOMETRY.FLOOR_TILE_PATH
const DECOR_ASSETS = BOARD_DECORATIONS.DECOR_ASSETS

static var _asset_cache: Dictionary = {}
var _lighting = BOARD_LIGHTING.new()
var _environment = BOARD_ENVIRONMENT.new()
var _actors = BOARD_ACTORS.new()
var _decorations = BOARD_DECORATIONS.new()
var _gameplay_objects = BOARD_GAMEPLAY_OBJECTS.new()
var _geometry = BOARD_GEOMETRY.new()
var decor_nodes: Array:
	get: return _decorations.nodes
## LevelData.power_level of the level currently built. 0 = emergency power only.
var power_level: float = 0.0
## Controls the material and architectural palette used for the current sector.
var chapter: int = 1
## Stable palette identifier used by diagnostics and UI/theme integrations.
var palette_name: StringName = &"archive"


var player_node: Node3D:
	get: return _actors.player_node
var player_animation: AnimationPlayer:
	get: return _actors.player_animation
var player_visual_offset: Vector3:
	get: return _actors.player_visual_offset
var _eva_hologram_node: Node3D:
	get: return _actors.eva_hologram_node
var _eva_hologram_material: ShaderMaterial:
	get: return _actors.eva_hologram_material
var _elias_hologram_node: Node3D:
	get: return _actors.elias_hologram_node
var block_nodes: Dictionary:
	get: return _gameplay_objects.block_nodes
var plate_nodes: Dictionary:
	get: return _gameplay_objects.plate_nodes
var plate_status_materials: Dictionary:
	get: return _gameplay_objects.plate_status_materials
var plate_status_lights: Dictionary:
	get: return _gameplay_objects.plate_status_lights
var door_nodes: Dictionary:
	get: return _gameplay_objects.door_nodes
var door_status_lights: Dictionary:
	get: return _gameplay_objects.door_status_lights
## Door position -> its own edge material, so two doors in different states never
## share one colour.
var door_status_materials: Dictionary:
	get: return _gameplay_objects.door_status_materials
## Door group -> cable material for that group's plate/door trace.
var lock_cable_materials: Dictionary:
	get: return _gameplay_objects.lock_cable_materials
var lock_cable_material: StandardMaterial3D:
	get: return _gameplay_objects.lock_cable_material
	set(value): _gameplay_objects.lock_cable_material = value
var portal_nodes: Dictionary:
	get: return _gameplay_objects.portal_nodes
var elevator_nodes: Dictionary:
	get: return _gameplay_objects.elevator_nodes
var elevator_status_materials: Dictionary:
	get: return _gameplay_objects.elevator_status_materials
var elevator_status_labels: Dictionary:
	get: return _gameplay_objects.elevator_status_labels
var bridge_nodes: Dictionary:
	get: return _gameplay_objects.bridge_nodes
var bridge_rail_nodes: Dictionary:
	get: return _gameplay_objects.bridge_rail_nodes
var bridge_rail_tweens: Dictionary:
	get: return _gameplay_objects.bridge_rail_tweens
var energy_nodes: Dictionary:
	get: return _gameplay_objects.energy_nodes
var energy_cable_materials: Array[ShaderMaterial]:
	get: return _gameplay_objects.energy_cable_materials
var plate_motion_nodes: Dictionary:
	get: return _gameplay_objects.plate_motion_nodes
var fragment_node: Node3D:
	get: return _gameplay_objects.fragment_node
## Gameplay geometry is grouped per floor so a sequential level never lets an
## upper floor cover the current Sokoban board.
var layer_roots: Dictionary:
	get: return _geometry.layer_roots
var floor_preview_roots: Dictionary:
	get: return _geometry.floor_preview_roots
var visible_floor: int:
	get: return _geometry.visible_floor
var _logic: GameLogic
## Authored, presentation-only environment motion. Profiles are opt-in from
## LevelData decorations so the effect can be rolled out level by level instead
## of silently animating every reused prop in the campaign.
var _environment_dynamics = ENVIRONMENT_DYNAMICS.new()
var environment_dynamic_profiles: Array[StringName]:
	get: return _environment_dynamics.profiles
var environment_dynamic_nodes: Array[Dictionary]:
	get: return _environment_dynamics.nodes
var environment_dynamic_materials: Array[Dictionary]:
	get: return _environment_dynamics.materials
var environment_dynamic_water_materials: Array[ShaderMaterial]:
	get: return _environment_dynamics.water_materials
var _environment_time: float:
	get: return _environment_dynamics.elapsed_time
	set(value): _environment_dynamics.elapsed_time = value
var hint_marker: Node3D
var drone: EchoCompanionDrone
var void_environment: Node3D
var map_response: Node
var _hint_marker_tween: Tween


func build(logic: GameLogic, decorations := []) -> void:
	_logic = logic
	if _hint_marker_tween and _hint_marker_tween.is_valid():
		_hint_marker_tween.kill()
	_hint_marker_tween = null
	hint_marker = null
	drone = null
	_actors.reset(self)
	for child in get_children():
		child.free()
	_lighting.reset(self)
	_environment_dynamics.reset()
	_gameplay_objects.reset()
	_geometry.reset()
	_decorations.reset()
	map_response = preload("res://src/view/map_response.gd").new()
	add_child(map_response)


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
	_environment.build(self, logic, _board_bounds(logic), chapter, _lighting)
	_geometry.build_base(
		self,
		logic,
		decorations,
		{
			"floor": floor_mat,
			"platform": platform_mat,
			"platform_edge": platform_edge_mat,
			"grid": grid_mat,
			"wall": wall_mat,
			"wall_edge": wall_edge_mat,
		},
		Callable(self, "_spawn"),
		Callable(self, "world_position"),
		Callable(self, "_floor_surface_y"),
		chapter)
	_gameplay_objects.build(
		self,
		logic,
		chapter,
		{
			"slot": slot_mat, "slot_ring": slot_ring_mat,
			"plate": plate_mat, "plate_ring": plate_ring_mat,
			"door": door_mat, "door_edge": door_edge_mat,
			"portal": portal_mat, "portal_ring": portal_ring_mat,
			"elevator": elevator_mat, "elevator_ring": elevator_ring_mat,
			"bridge": bridge_mat, "bridge_ring": bridge_ring_mat,
			"energy": energy_mat, "energy_ring": energy_ring_mat,
			"block": block_mat, "block_edge": block_edge_mat,
		},
		{"goal": goal_color, "plate": plate_color, "door_edge": door_edge_color},
		Callable(self, "_spawn"),
		Callable(self, "world_position"),
		Callable(self, "_floor_surface_y"),
		Callable(self, "_layer_parent"))
	_actors.build_player(self, player_position(logic.player, logic.blocks), player_mat, player_edge_mat)
	_build_decorations(decorations)
	_lighting.build_story_lighting(
		logic,
		chapter,
		Callable(self, "world_position"),
		Callable(self, "_layer_parent"))
	_lighting.build_mobile_color_pools(
		logic,
		goal_color,
		plate_color,
		portal_color,
		elevator_color,
		block_edge_color,
		Callable(self, "world_position"),
		Callable(self, "_layer_parent"))
	_build_floor_previews(logic, platform_edge_color)
	_build_hint_marker()
	drone = EchoCompanionDrone.new()
	add_child(drone)
	if _actors.player_node:
		drone.setup_companion(_actors.player_node)
	set_bridges_open(logic.bridge_open)
	set_energy_progress(logic.energy_progress)
	set_lock_state(logic)
	_lighting.apply_power_baseline(power_level)
	set_sector_powered(false, true)
	void_environment = null
	if not logic.floors.is_empty():
		void_environment = preload("res://src/view/sector_exterior.gd").new()
		add_child(void_environment)
		void_environment.build(_board_bounds(logic), chapter)
	set_active_floor(logic.active_floor, false)


func _create_layer_roots(logic: GameLogic) -> void:
	_geometry.create_layer_roots(self, logic)


func _layer_parent(cell: Vector3i) -> Node3D:
	return _geometry.layer_parent(self, cell)


func set_active_floor(floor: int, animated := false) -> void:
	_geometry.set_active_floor(floor)
	set_elevator_state(_logic, animated)


func set_elevator_state(logic: GameLogic, animated := false) -> void:
	_gameplay_objects.set_elevator_state(logic, visible_floor, animated)


func play_elevator_ride(entry: Vector3i, destination: Vector3i, duration: float) -> void:
	_gameplay_objects.play_elevator_ride(self, entry, destination, duration, Callable(self, "world_position"))


func _build_floor_previews(logic: GameLogic, edge_color: Color) -> void:
	_geometry.build_floor_previews(self, logic, edge_color, Callable(self, "world_position"))


func _build_lock_cables(logic: GameLogic) -> void:
	_gameplay_objects.build_lock_cables(
		self,
		logic,
		Callable(self, "_layer_parent"),
		Callable(self, "world_position"))


func set_lock_state(logic: GameLogic) -> void:
	_gameplay_objects.set_lock_state(logic, visible_floor)


func _build_decorations(decorations: Array) -> void:
	_decorations.build(
		decorations,
		chapter,
		Callable(self, "_spawn"),
		Callable(self, "world_position"),
		Callable(self, "_layer_parent"),
		_environment_dynamics,
		_lighting)


func _process(delta: float) -> void:
	_lighting.process_power(delta)
	_environment_dynamics.process(delta)


func _update_environment_dynamics() -> void:
	_environment_dynamics.update()


func set_sector_powered(powered: bool, immediate := false) -> void:
	_lighting.set_powered(powered, immediate)
	if powered and not immediate and is_instance_valid(map_response):
		map_response.start_sector(self)
	elif not powered and is_instance_valid(map_response):
		map_response.cancel_sector(self)


func play_step_weight(pushing: bool, duration: float) -> void:
	_actors.play_step_weight(pushing, duration)


func send_lock_pulse(cell: Vector3i, active: bool) -> void:
	if is_instance_valid(map_response):
		map_response.send_lock_pulse(_gameplay_objects.lock_routes.get(cell, []), _layer_parent(cell), active)


func is_sector_powered() -> bool:
	return _lighting.is_powered()


func _board_bounds(logic: GameLogic) -> Dictionary:
	return _geometry.bounds(logic)


func set_bridge_rails_retracted(cell: Vector3i, direction: Vector3i, retracted: bool, animated := true) -> void:
	_gameplay_objects.set_bridge_rails_retracted(
		self, cell, direction, retracted, animated, GameState.reduced_motion)


func reset_bridge_rails(animated := false) -> void:
	_gameplay_objects.reset_bridge_rails(self, animated, GameState.reduced_motion)


func set_bridges_open(open: bool, animated := false) -> void:
	_gameplay_objects.set_bridges_open(self, open, animated, GameState.reduced_motion)


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
		if is_instance_valid(drone):
			drone.set_hint_focus(Vector3.ZERO, false)
		return
	var target_world_pos := world_position(cell)
	hint_marker.position = target_world_pos
	hint_marker.visible = true
	hint_marker.scale = Vector3.ONE
	if is_instance_valid(drone):
		drone.set_hint_focus(target_world_pos, true)
	_hint_marker_tween = create_tween().set_loops()
	_hint_marker_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_hint_marker_tween.tween_property(hint_marker, "scale", Vector3(1.14, 1.0, 1.14), 0.55)
	_hint_marker_tween.tween_property(hint_marker, "scale", Vector3.ONE, 0.55)


func set_energy_progress(progress: int) -> void:
	_gameplay_objects.set_energy_progress(_logic, progress)


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
		_lighting.register_mesh_emissives(model)
	MODULE_MOTION.attach(model, path, self, chapter)
	return model


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
	_actors.face_player(dir)


func set_kiro_powered(powered: bool, immediate := false) -> void:
	_actors.set_kiro_powered(powered, immediate)


func play_player_animation(clip: StringName) -> void:
	_actors.play_player_animation(clip)


func play_oneshot(clip: StringName) -> void:
	await _actors.play_oneshot(clip)


func play_boot_awakening() -> void:
	_actors.play_boot_awakening()


func spawn_eva_hologram(world_pos: Vector3, look_at_target: Vector3 = Vector3.ZERO, stage := 4) -> Node3D:
	return _actors.spawn_eva_hologram(world_pos, look_at_target, stage)


func set_eva_hologram_stage(stage: int, world_pos: Vector3, look_at_target: Vector3 = Vector3.ZERO) -> Node3D:
	return _actors.set_eva_hologram_stage(stage, world_pos, look_at_target)


func dismiss_eva_hologram(immediate := false) -> void:
	_actors.dismiss_eva_hologram(immediate)


func spawn_elias_hologram(world_pos: Vector3, look_at_target: Vector3 = Vector3.ZERO) -> Node3D:
	return _actors.spawn_elias_hologram(world_pos, look_at_target)


func dismiss_elias_hologram(immediate := false) -> void:
	_actors.dismiss_elias_hologram(immediate)


func door_position(v: Vector3i, open: bool) -> Vector3:
	return _gameplay_objects.door_position(v, open, Callable(self, "world_position"))


func place_memory_fragment(cell: Vector3i) -> void:
	_gameplay_objects.place_memory_fragment(
		cell,
		Callable(self, "_spawn"),
		Callable(self, "world_position"),
		Callable(self, "_layer_parent"))


func collect_memory_fragment() -> Vector3:
	return _gameplay_objects.collect_memory_fragment()
