@tool
extends RefCounted

const ENERGY_NODE_PATH := "res://assets/models/map_expansion/energy_node.glb"
const FLOOR_SKINS := {
	"archive_floor_variant": "res://assets/models/map_surfaces/archive_floor_variant.glb",
	"foundry_floor_variant": "res://assets/models/map_surfaces/foundry_floor_variant.glb",
	"sanctuary_floor_variant": "res://assets/models/map_surfaces/sanctuary_floor_variant.glb",
	"core_floor_variant": "res://assets/models/map_surfaces/core_floor_variant.glb",
}
const ASSETS := {
	"archive_floor_variant": "res://assets/models/map_expansion/archive_floor_variant.glb",
	"archive_wall_variant": "res://assets/models/map_expansion/archive_wall_variant.glb",
	"foundry_floor_variant": "res://assets/models/map_expansion/foundry_floor_variant.glb",
	"foundry_wall_variant": "res://assets/models/map_expansion/foundry_wall_variant.glb",
	"sanctuary_floor_variant": "res://assets/models/map_expansion/sanctuary_floor_variant.glb",
	"sanctuary_wall_variant": "res://assets/models/map_expansion/sanctuary_wall_variant.glb",
	"core_floor_variant": "res://assets/models/map_expansion/core_floor_variant.glb",
	"core_wall_variant": "res://assets/models/map_expansion/core_wall_variant.glb",
	"elevator_support_column": "res://assets/models/map_expansion/elevator_support_column.glb",
	"elevator_support_brace": "res://assets/models/map_expansion/elevator_support_brace.glb",
	"elevator_deck_fascia": "res://assets/models/map_expansion/elevator_deck_fascia.glb",
	"elevator_threshold": "res://assets/models/map_expansion/elevator_threshold.glb",
}


static func blocks_anchor(kind: String) -> bool:
	return kind.ends_with("wall_variant") or kind in ["elevator_support_column", "elevator_support_brace"]


static func decoration_mapping() -> Dictionary:
	var mapping := {}
	for kind in ASSETS:
		mapping["Expansion_" + str(kind)] = kind
	return mapping


static func add_to_library(library: MeshLibrary) -> void:
	preload("res://src/data/chapter_props.gd").add_assets_to_library(library, ASSETS, "Expansion_")
