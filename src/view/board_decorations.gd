class_name BoardDecorations
extends RefCounted

const BAKED := "res://assets/models/baked/"
const FLOOR_TOP_Y := 0.154
const WATER_SHADER_PATH := "res://assets/shaders/ice_water_sanctuary.gdshader"

const CHAPTER_PROPS = preload("res://src/data/chapter_props.gd")
const MODULAR_PROPS = preload("res://src/data/modular_props.gd")
const MAP_EXPANSION = preload("res://src/data/map_expansion.gd")
const SECTOR_SIGNS := {
	1: "res://assets/models/signage/sector_1.glb",
	2: "res://assets/models/signage/sector_2.glb",
	3: "res://assets/models/signage/sector_3.glb",
	4: "res://assets/models/signage/sector_4.glb",
}

const COLOR_ARCHIVE_CYAN := Color(0.10, 0.82, 1.0)
const COLOR_ARCHIVE_AMBER := Color(1.0, 0.30, 0.08)
const COLOR_FOUNDRY_ORANGE := Color(1.0, 0.32, 0.055)
const COLOR_CORE_CYAN := Color(0.72, 0.94, 1.0)
const COLOR_CORE_VIOLET := Color(0.42, 0.35, 0.66)
const COLOR_CORE_AMBER := Color(1.0, 0.64, 0.22)

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
	"sanctuary_pool": {"path": BAKED + "Sanctuary-Pool.glb"},
	"resonance_altar": {"path": BAKED + "Archive-Plinth.glb"},
	"silence_reliquary": {"path": BAKED + "Narrative-silence_reliquary.glb"},
	"elias_testament": {"path": BAKED + "Narrative-elias_testament.glb"},
	"eva_conduit": {"path": BAKED + "Narrative-eva_conduit.glb"},
	"judgement_engine": {"path": BAKED + "Narrative-judgement_engine.glb"},
}

var nodes: Array = []


func reset() -> void:
	nodes.clear()


func build(
		decorations: Array,
		chapter: int,
		spawn: Callable,
		world_position: Callable,
		layer_parent: Callable,
		environment_dynamics: RefCounted,
		lighting: RefCounted) -> void:
	nodes.clear()
	if not spawn.is_valid() or not world_position.is_valid() or not layer_parent.is_valid():
		return
	var signed_floors := {}
	for decoration in decorations:
		if not decoration is Dictionary:
			continue
		var kind := str(decoration.get("type", ""))
		if not DECOR_ASSETS.has(kind) \
				and not CHAPTER_PROPS.ASSETS.has(kind) \
				and not MODULAR_PROPS.ASSETS.has(kind) \
				and not MAP_EXPANSION.ASSETS.has(kind):
			continue
		var cell: Variant = decoration.get("grid_position", null)
		if not cell is Vector3i:
			continue
		var spec: Dictionary = DECOR_ASSETS.get(kind, {})
		if CHAPTER_PROPS.ASSETS.has(kind):
			spec = {"path": CHAPTER_PROPS.ASSETS[kind]}
		elif MODULAR_PROPS.ASSETS.has(kind):
			spec = {"path": MODULAR_PROPS.ASSETS[kind]}
		elif MAP_EXPANSION.ASSETS.has(kind):
			spec = {"path": MAP_EXPANSION.ASSETS[kind]}
		var floor_skin := bool(decoration.get("surface_skin", false)) and MAP_EXPANSION.FLOOR_SKINS.has(kind)
		if floor_skin:
			spec = {"path": MAP_EXPANSION.FLOOR_SKINS[kind]}
		var base_position: Vector3 = world_position.call(cell)
		var center := base_position + Vector3(
			float(decoration.get("offset_x", 0.0)),
			float(decoration.get("offset_y", 0.0)),
			float(decoration.get("offset_z", 0.0)))
		var floor_y := center.y if floor_skin else FLOOR_TOP_Y + center.y - float((world_position.call(Vector3i.ZERO) as Vector3).y)
		var parent := layer_parent.call(cell) as Node3D
		var node: Node3D = spawn.call(
			parent,
			str(spec["path"]),
			center,
			floor_y,
			float(decoration.get("scale", 1.0)),
			not (floor_skin or kind.ends_with("wall_variant")),
			not MAP_EXPANSION.ASSETS.has(kind))
		if node == null:
			continue
		var yaw := float(decoration.get("yaw", 0.0))
		if yaw != 0.0:
			node.rotate_y(deg_to_rad(yaw))
		_apply_variation(node, kind, cell)
		if kind in GameLogic.DECORATION_WALL_TYPES:
			var original_position := node.position
			_fit_solid_footprint(node, base_position)
			center += node.position - original_position
		if kind.ends_with("wall_variant") and not signed_floors.has(cell.y):
			_attach_sector_sign(node, chapter)
			signed_floors[cell.y] = true
		nodes.append(node)
		if kind.begins_with("kit_water") or kind in ["sanctuary_water_pool", "sanctuary_pool"]:
			_apply_water_shader(node)
		environment_dynamics.register(node, decoration, center, yaw, cell, parent)
		if kind == "lamp":
			lighting.add_sector_lamp(
				parent,
				center + Vector3(0, 0.78, 0),
				COLOR_FOUNDRY_ORANGE if chapter == 2 else (COLOR_CORE_AMBER if chapter == 4 else COLOR_ARCHIVE_AMBER))
		elif kind in ["holo", "terminal", "archive_lock_node", "bridge_console", "reactor_switch", "resonance_altar", "silence_reliquary", "elias_testament", "soul_archive", "eva_conduit", "judgement_engine"]:
			var glow_color := COLOR_CORE_CYAN if chapter == 4 else COLOR_ARCHIVE_CYAN
			if chapter == 4 and kind in ["soul_archive", "eva_conduit"]:
				glow_color = COLOR_CORE_VIOLET
			elif chapter == 4 and kind == "judgement_engine":
				glow_color = COLOR_CORE_AMBER
			lighting.add_hologram_glow(parent, center + Vector3(0, 0.48, 0), glow_color)


func _fit_solid_footprint(node: Node3D, center: Vector3) -> void:
	var bounds := AABB()
	var initialized := false
	var parent_inverse := (node.get_parent() as Node3D).global_transform.affine_inverse()
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		if mesh.mesh == null:
			continue
		var mesh_bounds: AABB = (parent_inverse * mesh.global_transform) * mesh.mesh.get_aabb()
		bounds = bounds.merge(mesh_bounds) if initialized else mesh_bounds
		initialized = true
	if not initialized:
		return
	# Leave clearance for Kiro's body on either side of the blocked cell.
	var fit := minf(1.0, .88 / maxf(bounds.size.x, bounds.size.z))
	node.scale.x *= fit
	node.scale.z *= fit
	var footprint_center := bounds.get_center()
	node.position.x = center.x + (node.position.x - footprint_center.x) * fit
	node.position.z = center.z + (node.position.z - footprint_center.z) * fit


func _apply_variation(node: Node3D, kind: String, cell: Vector3i) -> void:
	if kind not in ["plant", "sanctuary_tree", "debris", "rubble", "archive_access_panel_broken"]:
		return
	var variant := posmod(cell.x * 17 + cell.z * 31 + cell.y * 7, 3)
	node.set_meta("asset_variation", variant)
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		var name_text := String(mesh.name).to_lower()
		if kind in ["plant", "sanctuary_tree"] and (name_text.contains("leaf") or name_text.contains("canopy")):
			mesh.scale.x *= [1.0, .90, .78][variant]
			mesh.scale.z *= [.88, 1.0, .92][variant]
		elif kind in ["debris", "rubble"]:
			mesh.scale.y *= [1.0, .80, .65][variant]
		elif kind == "archive_access_panel_broken":
			mesh.scale.x *= [1.0, .92, .84][variant]


func _attach_sector_sign(node: Node3D, chapter: int) -> void:
	var sign := (load(SECTOR_SIGNS[chapter]) as PackedScene).instantiate() as Node3D
	sign.name = "SectorSign"
	sign.position = Vector3(0, .01, .24)
	node.add_child(sign)


func _apply_water_shader(node: Node3D, ice_mode := false) -> void:
	var shader := load(WATER_SHADER_PATH) as Shader
	if shader == null:
		return
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("is_ice_mode", 1.0 if ice_mode else 0.0)
	_apply_water_material(node, material, ice_mode)


func _apply_water_material(node: Node, material: ShaderMaterial, apply_all_surfaces := false) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			for surface in mesh_instance.mesh.get_surface_count():
				var source := mesh_instance.get_active_material(surface)
				if apply_all_surfaces or (source != null and "water" in source.resource_name.to_lower()):
					mesh_instance.set_surface_override_material(surface, material)
	for child in node.get_children():
		_apply_water_material(child, material, apply_all_surfaces)
