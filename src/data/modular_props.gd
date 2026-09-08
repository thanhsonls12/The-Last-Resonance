@tool
extends RefCounted

## Visual modules. Grid centers stay fixed; +Y is up, -Z is north.
## No collision or puzzle mechanics are introduced by these decorations.
const ASSETS := {
	"kit_floor_edge": "res://assets/models/modular/floor_edge.glb",
	"kit_floor_corner": "res://assets/models/modular/floor_corner.glb",
	"kit_floor_inner_corner": "res://assets/models/modular/floor_inner_corner.glb",
	"kit_floor_end": "res://assets/models/modular/floor_end.glb",
	"kit_floor_end_reverse": "res://assets/models/modular/floor_end_reverse.glb",
	"kit_rail_straight": "res://assets/models/modular/rail_straight.glb",
	"kit_rail_corner": "res://assets/models/modular/rail_corner.glb",
	"kit_rail_end": "res://assets/models/modular/rail_end.glb",
	"kit_rail_end_reverse": "res://assets/models/modular/rail_end_reverse.glb",
	"kit_wall_low_straight": "res://assets/models/modular/wall_low_straight.glb",
	"kit_wall_low_corner": "res://assets/models/modular/wall_low_corner.glb",
	"kit_wall_low_end": "res://assets/models/modular/wall_low_end.glb",
	"kit_pipe_straight": "res://assets/models/modular/pipe_straight.glb",
	"kit_pipe_elbow": "res://assets/models/modular/pipe_elbow.glb",
	"kit_pipe_tee": "res://assets/models/modular/pipe_tee.glb",
	"kit_pipe_end": "res://assets/models/modular/pipe_end.glb",
	"kit_water_tile": "res://assets/models/modular/water_tile.glb",
	"kit_water_edge": "res://assets/models/modular/water_edge.glb",
	"kit_water_corner": "res://assets/models/modular/water_corner.glb",
	"kit_water_inner_corner": "res://assets/models/modular/water_inner_corner.glb",
}


static func decoration_mapping() -> Dictionary:
	var mapping := {}
	for kind in ASSETS:
		mapping["Kit_" + str(kind).trim_prefix("kit_")] = kind
	return mapping


static func add_to_library(library: MeshLibrary) -> void:
	var named_assets := {}
	for kind in ASSETS:
		named_assets[str(kind).trim_prefix("kit_")] = ASSETS[kind]
	preload("res://src/data/chapter_props.gd").add_assets_to_library(library, named_assets, "Kit_")
