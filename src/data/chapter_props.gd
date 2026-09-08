@tool
extends RefCounted

## Scenery only: no puzzle mechanics or automatic blocked cells.
## GLBs use the existing 2-unit authoring grid; runtime scale is 0.5.
const ASSETS := {
	"archive_access_panel_broken": "res://assets/models/baked/Identity-archive_access_panel_broken.glb",
	"archive_storage_tray_low": "res://assets/models/baked/Identity-archive_storage_tray_low.glb",
	"foundry_furnace": "res://assets/models/baked/Foundry-Furnace.glb",
	"foundry_press": "res://assets/models/baked/Foundry-Press.glb",
	"foundry_gear": "res://assets/models/baked/Foundry-Gear.glb",
	"foundry_pipe_valve": "res://assets/models/baked/Foundry-Pipe-Valve.glb",
	"foundry_lamp": "res://assets/models/baked/Foundry-Lamp.glb",
	"foundry_maintenance_box": "res://assets/models/baked/Identity-foundry_maintenance_box.glb",
	"foundry_pipe_support": "res://assets/models/baked/Identity-foundry_pipe_support.glb",
	"sanctuary_water_pool": "res://assets/models/baked/Sanctuary-Pool.glb",
	"sanctuary_shrine": "res://assets/models/baked/Sanctuary-Shrine.glb",
	"sanctuary_tree": "res://assets/models/baked/Sanctuary-Tree.glb",
	"sanctuary_vine_arch": "res://assets/models/baked/Sanctuary-Vine-Arch.glb",
	"sanctuary_rocks": "res://assets/models/baked/Sanctuary-Rocks.glb",
	"sanctuary_broken_plinth_low": "res://assets/models/baked/Identity-sanctuary_broken_plinth_low.glb",
	"sanctuary_bank_root": "res://assets/models/baked/Identity-sanctuary_bank_root.glb",
	"core_reactor": "res://assets/models/baked/Core-Reactor.glb",
	"core_generator": "res://assets/models/baked/Core-Generator.glb",
	"core_wall": "res://assets/models/baked/Core-Wall.glb",
	"core_hologram_dais": "res://assets/models/baked/Core-Hologram-Dais.glb",
	"core_portal_frame": "res://assets/models/baked/Core-Portal-Frame.glb",
	"core_data_cabinet_low": "res://assets/models/baked/Identity-core_data_cabinet_low.glb",
	"core_light_trim": "res://assets/models/baked/Identity-core_light_trim.glb",
}


static func decoration_mapping() -> Dictionary:
	var mapping := {}
	for kind in ASSETS:
		mapping["Prop_" + kind] = kind
	return mapping


static func append_meshes(node: Node3D, parent_transform: Transform3D, result: ArrayMesh) -> void:
	var local_transform := parent_transform * node.transform
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		if instance.mesh:
			for surface in instance.mesh.get_surface_count():
				var builder := SurfaceTool.new()
				builder.append_from(instance.mesh, surface, local_transform)
				builder.set_material(instance.get_active_material(surface))
				builder.commit(result)
	for child in node.get_children():
		if child is Node3D:
			append_meshes(child, local_transform, result)


static func add_to_library(library: MeshLibrary) -> void:
	add_assets_to_library(library, ASSETS, "Prop_")


static func add_assets_to_library(library: MeshLibrary, assets: Dictionary, prefix: String) -> void:
	var next_id := library.get_last_unused_item_id()
	for kind in assets:
		var item_name := prefix + str(kind)
		var item_id := library.find_item_by_name(item_name)
		if item_id == -1:
			item_id = next_id
			next_id += 1
			library.create_item(item_id)
		var scene := load(assets[kind]) as PackedScene
		assert(scene != null, "Missing chapter prop: " + str(kind))
		var instance := scene.instantiate() as Node3D
		var mesh := ArrayMesh.new()
		append_meshes(instance, Transform3D.IDENTITY, mesh)
		library.set_item_name(item_id, item_name)
		library.set_item_mesh(item_id, mesh)
		library.set_item_mesh_transform(item_id, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.5), Vector3(0, 0.154, 0)))
		instance.free()
