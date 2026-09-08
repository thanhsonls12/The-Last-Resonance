extends SceneTree

## Phase C: build four editable, editor-only map-composition clusters.
## These scenes never change puzzle data. They are placement references/prefabs
## for a level designer, with metadata that records footprint and safe-facing
## information. Landmark/story objects remain outside these reusable clusters.

const KIT = preload("res://src/data/modular_props.gd")
const PROPS = preload("res://src/data/chapter_props.gd")
const MATERIAL_PROFILES = preload("res://src/data/chapter_material_profiles.gd")
const OUTPUT_DIR := "res://scenes/editor/map_clusters"
const CATALOG_PATH := "res://docs/MAP_CLUSTER_CATALOG.json"

const CLUSTERS := {
	"archive_storage_bay": {
		"chapter": 1,
		"display_name": "Archive — Powered Storage Bay",
		"footprint": Vector2i(3, 3),
		"outward_face": "south",
		"blocked_cells": [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)],
		"walkable_cells": [Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)],
		"components": [
			{"type": "Archive-Bookshelf", "position": Vector3(0, 0, -1), "yaw": 0.0},
			{"type": "archive_access_panel_broken", "position": Vector3(-1, 0, -1), "yaw": 0.0},
			{"type": "archive_storage_tray_low", "position": Vector3(1, 0, -1), "yaw": 0.0},
		],
		"notes": "Back-wall storage rhythm; damaged access panel beside a surviving powered bay.",
	},
	"foundry_maintenance_corner": {
		"chapter": 2,
		"display_name": "Foundry — Maintenance Corner",
		"footprint": Vector2i(3, 3),
		"outward_face": "south",
		"blocked_cells": [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0)],
		"walkable_cells": [Vector2i(0, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)],
		"components": [
			{"type": "foundry_press", "position": Vector3(-1, 0, -1), "yaw": 0.0},
			{"type": "kit_pipe_end", "position": Vector3(0, 0, -1), "yaw": 180.0},
			{"type": "kit_pipe_straight", "position": Vector3(1, 0, -1), "yaw": 0.0},
			{"type": "foundry_pipe_support", "position": Vector3(1, 0, 0), "yaw": 90.0},
			{"type": "foundry_maintenance_box", "position": Vector3(-1, 0, 0), "yaw": 180.0},
		],
		"notes": "One heavy machine, a short terminated pipe run, and a low maintenance pocket.",
	},
	"sanctuary_flooded_bank": {
		"chapter": 3,
		"display_name": "Sanctuary — Flooded Bank",
		"footprint": Vector2i(3, 3),
		"outward_face": "south",
		"blocked_cells": [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0)],
		"walkable_cells": [Vector2i(0, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)],
		"components": [
			{"type": "sanctuary_rocks", "position": Vector3(-1, 0, -1), "yaw": 15.0},
			{"type": "kit_water_corner", "position": Vector3(0, 0, -1), "yaw": 0.0},
			{"type": "kit_water_edge", "position": Vector3(1, 0, -1), "yaw": 0.0},
			{"type": "sanctuary_broken_plinth_low", "position": Vector3(-1, 0, 0), "yaw": -8.0},
			{"type": "sanctuary_bank_root", "position": Vector3(1, 0, 0), "yaw": -90.0},
		],
		"notes": "Asymmetric flooded edge with eroded stone, broken plinth and roots kept off the Core route.",
	},
	"core_data_wall": {
		"chapter": 4,
		"display_name": "Central Core — Data Wall",
		"footprint": Vector2i(3, 3),
		"outward_face": "south",
		"blocked_cells": [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)],
		"walkable_cells": [Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)],
		"components": [
			{"type": "core_data_cabinet_low", "position": Vector3(-1, 0, -1), "yaw": 0.0},
			{"type": "core_wall", "position": Vector3(0, 0, -0.75), "yaw": 0.0},
			{"type": "core_light_trim", "position": Vector3(1, 0, -1), "yaw": 0.0},
		],
		"notes": "Precise data-wall rhythm; secondary emission stays below Energy Node/Portal prominence.",
	},
}


func own(node: Node, parent: Node) -> void:
	parent.add_child(node)
	node.owner = parent if parent.owner == null else parent.owner


func asset_path(kind: String) -> String:
	if KIT.ASSETS.has(kind):
		return KIT.ASSETS[kind]
	if PROPS.ASSETS.has(kind):
		return PROPS.ASSETS[kind]
	return "res://assets/models/baked/%s.glb" % kind


func add_component(parent: Node3D, component: Dictionary, scene_owner: Node) -> void:
	var kind := str(component.type)
	var path := asset_path(kind)
	var packed := load(path) as PackedScene
	assert(packed != null, "Missing cluster component: %s (%s)" % [kind, path])
	var instance := packed.instantiate() as Node3D
	instance.name = kind.replace("-", "_")
	instance.position = component.position
	instance.rotation_degrees.y = float(component.get("yaw", 0.0))
	instance.scale = Vector3.ONE * 0.5
	parent.add_child(instance)
	instance.owner = scene_owner


func _append_local_bounds(node: Node3D, parent_transform: Transform3D, state: Array) -> void:
	var local_transform := parent_transform * node.transform
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			var bounds := local_transform * mesh_instance.mesh.get_aabb()
			if not bool(state[0]):
				state[1] = bounds
				state[0] = true
			else:
				state[1] = (state[1] as AABB).merge(bounds)
	for child in node.get_children():
		if child is Node3D:
			_append_local_bounds(child as Node3D, local_transform, state)


func local_bounds(cluster: Node3D) -> AABB:
	var state: Array = [false, AABB()]
	_append_local_bounds(cluster, Transform3D.IDENTITY, state)
	return state[1] as AABB


func vector2i_array_to_json(values: Array) -> Array:
	var result := []
	for value in values:
		result.append([value.x, value.y])
	return result


func build_cluster(cluster_id: String, spec: Dictionary) -> Dictionary:
	var cluster := Node3D.new()
	cluster.name = cluster_id.to_pascal_case()
	var components := Node3D.new()
	components.name = "Components"
	cluster.add_child(components)
	components.owner = cluster
	for component in spec.components:
		add_component(components, component, cluster)
	MATERIAL_PROFILES.apply(cluster, int(spec.chapter), false)

	var bounds := local_bounds(cluster)
	cluster.set_meta("cluster_id", cluster_id)
	cluster.set_meta("chapter", int(spec.chapter))
	cluster.set_meta("display_name", str(spec.display_name))
	cluster.set_meta("footprint_cells", spec.footprint)
	cluster.set_meta("outward_face", str(spec.outward_face))
	cluster.set_meta("blocked_cells", spec.blocked_cells)
	cluster.set_meta("walkable_cells", spec.walkable_cells)
	cluster.set_meta("geometry_checked_yaws", PackedFloat32Array([0.0, 90.0, 180.0, 270.0]))
	cluster.set_meta("visual_camera_review", "pending")
	cluster.set_meta("notes", str(spec.notes))
	cluster.set_meta("measured_bounds_position", bounds.position)
	cluster.set_meta("measured_bounds_size", bounds.size)

	var packed_scene := PackedScene.new()
	assert(packed_scene.pack(cluster) == OK)
	var scene_path := "%s/%s.tscn" % [OUTPUT_DIR, cluster_id]
	assert(ResourceSaver.save(packed_scene, scene_path) == OK)

	var component_types := []
	for component in spec.components:
		component_types.append(str(component.type))
	var record := {
		"id": cluster_id,
		"scene": scene_path,
		"chapter": int(spec.chapter),
		"display_name": str(spec.display_name),
		"footprint_cells": [spec.footprint.x, spec.footprint.y],
		"outward_face": str(spec.outward_face),
		"blocked_cells": vector2i_array_to_json(spec.blocked_cells),
		"walkable_cells": vector2i_array_to_json(spec.walkable_cells),
		"geometry_checked_yaws": [0, 90, 180, 270],
		"visual_camera_review": "pending",
		"measured_bounds_position": [bounds.position.x, bounds.position.y, bounds.position.z],
		"measured_bounds_size": [bounds.size.x, bounds.size.y, bounds.size.z],
		"components": component_types,
		"notes": str(spec.notes),
	}
	cluster.free()
	return record


func build_gallery(catalog: Array) -> void:
	var gallery := Node3D.new()
	gallery.name = "MapClusterGallery"
	for i in catalog.size():
		var entry: Dictionary = catalog[i]
		var scene := load(str(entry.scene)) as PackedScene
		var cluster := scene.instantiate() as Node3D
		cluster.position = Vector3(float(i % 2) * 5.0, 0, float(i / 2) * 5.0)
		gallery.add_child(cluster)
		cluster.owner = gallery
		var label := Label3D.new()
		label.text = str(entry.display_name)
		label.font_size = 42
		label.pixel_size = 0.006
		label.position = cluster.position + Vector3(0, 0.08, 1.75)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		gallery.add_child(label)
		label.owner = gallery
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("101b28")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("c4def0")
	env.environment.ambient_light_energy = 0.55
	gallery.add_child(env)
	env.owner = gallery
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -25, 0)
	light.light_energy = 0.9
	gallery.add_child(light)
	light.owner = gallery
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.0
	camera.look_at_from_position(Vector3(10, 14, 16), Vector3(2.5, 0, 2.5))
	gallery.add_child(camera)
	camera.owner = gallery
	var packed_gallery := PackedScene.new()
	assert(packed_gallery.pack(gallery) == OK)
	assert(ResourceSaver.save(packed_gallery, "res://scenes/editor/map_cluster_gallery.tscn") == OK)
	gallery.free()


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var catalog := []
	for cluster_id in CLUSTERS:
		catalog.append(build_cluster(str(cluster_id), CLUSTERS[cluster_id]))
	var file := FileAccess.open(CATALOG_PATH, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(catalog, "  ") + "\n")
	file.close()
	build_gallery(catalog)
	print("Built %d reusable map clusters + gallery" % catalog.size())
	quit()
