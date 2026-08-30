class_name LevelData
extends Resource

## Data-only representation of a playable level.
## The current ASCII catalogue is converted through from_dict() while the
## project migrates toward editable .tres resources.

@export var id := 0
@export var title := ""
@export var chapter := 1
@export var difficulty := 1
## Length of the best route verified by tests/verify.gd or tools/validate_levels.py.
## Not a proof of optimality; a shorter verified route lowers this number.
@export var par_moves := 0
## 0.0 = emergency power only, 1.0 = the sector is awake. Drives the unpowered
## light baseline so a chapter can brighten level by level.
@export_range(0.0, 1.0) var power_level := 0.0
## Decoration type that makes this room recognisable on sight. Checked by tests.
@export var landmark := ""
@export var map: Array[String] = []
@export var maps: Array[String] = []
@export var entities: Array = []
@export var decorations: Array = []
@export var memory_fragment := ""


static func from_dict(index: int, source: Dictionary) -> LevelData:
	var data := LevelData.new()
	data.id = index
	data.title = str(source.get("name", "Level %d" % (index + 1)))
	data.chapter = int(source.get("chapter", index / 5 + 1))
	data.difficulty = int(source.get("difficulty", mini(data.chapter + 1, 5)))
	data.par_moves = int(source.get("par_moves", 0))
	data.power_level = float(source.get("power_level", 0.0))
	data.landmark = str(source.get("landmark", ""))
	data.memory_fragment = str(source.get("memory_fragment", ""))
	for row in source.get("map", []):
		data.map.append(str(row))
	for layer in source.get("maps", []):
		data.maps.append(str(layer))
	var source_entities: Variant = source.get("entities", [])
	data.entities = source_entities if source_entities is Array else []
	var source_decorations: Variant = source.get("decorations", [])
	data.decorations = source_decorations if source_decorations is Array else []
	return data
