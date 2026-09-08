class_name GameLogic
extends RefCounted

## Plate glyph -> door group. "p" keeps the legacy shared group so older maps
## behave the same; k/l/m address one door group each.
const PLATE_GLYPHS := {"p": "", "k": "K", "l": "L", "m": "M"}
## Door glyph -> door group. A door only reacts to plates of its own group.
const DOOR_GLYPHS := {"D": "", "K": "K", "L": "L", "M": "M"}
const DECORATION_WALL_TYPES := [
	"data_rack", "archive_shelf", "workbench", "crate", "machine",
	"broken_robot", "broken_wall", "broken_pillar", "rock", "door_frame",
	"archive_lock_node", "foundry_line", "k_series_mold", "bridge_console",
	"reactor_switch",
]

var level_name := ""
var walls := {}
var floors := {}
var slots := {}
## Vector3i -> door group String.
var plates := {}
## Plate positions that do NOT have to stay covered to win. A Core may hold
## such a plate to pass a door, then leave it for a Pedestal.
var plate_hold_required := {}
## Vector3i -> door group String.
var doors := {}
var portals := {}
var portal_links := {}
var elevators := {}
var elevator_links := {}
var bridges := {}
## Solid console/decor cell next to which Kiro may change the bridge state.
var bridge_controls := {}
var bridge_open := true
var energy_nodes: Array = []
var energy_progress := 0
var blocks := {}
var player := Vector3i.ZERO
var won := false
var moves := 0
var pushes := 0
var history: Array = []


func load_map(p_name: String, lines: Array) -> void:
	_reset_state(p_name)
	_parse_rows(lines, 0)
	_build_portal_links()
	_build_elevator_links()


func _reset_state(p_name: String) -> void:
	level_name = p_name
	walls.clear()
	floors.clear()
	slots.clear()
	plates.clear()
	plate_hold_required.clear()
	doors.clear()
	portals.clear()
	portal_links.clear()
	elevators.clear()
	elevator_links.clear()
	bridges.clear()
	bridge_controls.clear()
	bridge_open = true
	energy_nodes.clear()
	energy_progress = 0
	blocks.clear()
	player = Vector3i.ZERO
	history.clear()
	won = false
	moves = 0
	pushes = 0



func load_level(data: LevelData) -> void:
	if data.maps.is_empty():
		load_map(data.title, data.map)
	else:
		load_maps(data.title, data.maps)
	_apply_entities(data.entities)
	for deco in data.decorations:
		if deco is Dictionary and deco.get("grid_position", null) is Vector3i:
			var type: String = str(deco.get("type", ""))
			if type in DECORATION_WALL_TYPES:
				walls[deco["grid_position"]] = true



func load_maps(p_name: String, encoded_layers: Array) -> void:
	_reset_state(p_name)
	for y in encoded_layers.size():
		var layer: String = encoded_layers[y]
		_parse_rows(layer.split("\n"), y)
	_build_portal_links()
	_build_elevator_links()


func _parse_rows(lines: Array, y: int) -> void:
	for z in lines.size():
		var row: String = lines[z]
		for x in row.length():
			var v := Vector3i(x, y, z)
			var glyph: String = row[x]
			if PLATE_GLYPHS.has(glyph):
				floors[v] = true
				plates[v] = PLATE_GLYPHS[glyph]
				plate_hold_required[v] = true
				continue
			if DOOR_GLYPHS.has(glyph):
				floors[v] = true
				doors[v] = DOOR_GLYPHS[glyph]
				continue
			match glyph:
				"#":
					walls[v] = true
					floors[v] = true
				" ":
					floors[v] = true
				".":
					floors[v] = true
					slots[v] = true
				"a", "b":
					floors[v] = true
					portals[v] = glyph
				"e":
					floors[v] = true
					elevators[v] = true
				"r":
					floors[v] = true
				"$":
					floors[v] = true
					blocks[v] = true
				"*":
					floors[v] = true
					blocks[v] = true
					slots[v] = true
				"@":
					floors[v] = true
					player = v
				"+":
					floors[v] = true
					player = v
					slots[v] = true


func _build_portal_links() -> void:
	var positions: Array = portals.keys()
	if positions.size() != 2:
		return
	portal_links[positions[0]] = positions[1]
	portal_links[positions[1]] = positions[0]


func portal_destination(v: Vector3i) -> Vector3i:
	return portal_links.get(v, Vector3i(999999, 999999, 999999))


func _build_elevator_links() -> void:
	var grouped := {}
	for position in elevators.keys():
		var column := Vector2i(position.x, position.z)
		if not grouped.has(column):
			grouped[column] = []
		grouped[column].append(position)
	for column in grouped.keys():
		var positions: Array = grouped[column]
		if positions.size() != 2:
			continue
		elevator_links[positions[0]] = positions[1]
		elevator_links[positions[1]] = positions[0]


func elevator_destination(v: Vector3i) -> Vector3i:
	return elevator_links.get(v, Vector3i(999999, 999999, 999999))


func _apply_entities(entities: Array) -> void:
	var ordered_energy_nodes: Array = []
	for raw_entity in entities:
		if not raw_entity is Dictionary:
			continue
		var entity: Dictionary = raw_entity
		var position: Variant = entity.get("grid_position", null)
		if not position is Vector3i:
			continue
		match str(entity.get("type", "")):
			"bridge":
				bridges[position] = true
				if entity.has("starts_open"):
					bridge_open = bool(entity["starts_open"])
			"bridge_switch":
				bridge_controls[position] = true
			"plate":
				# Refines a glyph-declared plate: regroup it, or let a Core leave it.
				floors[position] = true
				plates[position] = str(entity.get("group", plates.get(position, "")))
				plate_hold_required[position] = bool(entity.get("hold_required", true))
			"door":
				floors[position] = true
				doors[position] = str(entity.get("group", doors.get(position, "")))
			"energy_node":
				ordered_energy_nodes.append({
					"order": int(entity.get("order", ordered_energy_nodes.size() + 1)),
					"position": position,
				})
	ordered_energy_nodes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["order"]) < int(b["order"])
	)
	for entry in ordered_energy_nodes:
		energy_nodes.append(entry["position"])


func has_bridges() -> bool:
	return not bridges.is_empty()


func bridge_control_available() -> bool:
	if bridges.is_empty():
		return false
	var controls: Array = bridge_controls.keys()
	# Backward-compatible fallback for prototype maps without a console entity.
	if controls.is_empty():
		controls = bridges.keys()
	for control_position in controls:
		var offset: Vector3i = control_position - player
		if absi(offset.x) + absi(offset.y) + absi(offset.z) == 1:
			return true
	return false


func rotate_bridge() -> Dictionary:
	if not bridge_control_available():
		return {}
	for bridge_position in bridges.keys():
		if player == bridge_position or blocks.has(bridge_position):
			return {}
	history.append(_snapshot())
	bridge_open = not bridge_open
	moves += 1
	won = _check_won()
	return {"bridge_open": bridge_open}


## A door opens only when every plate of its own group carries a Core.
func door_open(v: Vector3i) -> bool:
	if not doors.has(v):
		return true
	var group: String = doors[v]
	var group_plates := plates_in_group(group)
	if group_plates.is_empty():
		return false
	for plate in group_plates:
		if not blocks.has(plate):
			return false
	return true


func plates_in_group(group: String) -> Array:
	var result: Array = []
	for plate in plates.keys():
		if plates[plate] == group:
			result.append(plate)
	return result


func doors_in_group(group: String) -> Array:
	var result: Array = []
	for door in doors.keys():
		if doors[door] == group:
			result.append(door)
	return result


## Snapshot used so a single move resolves against one consistent door state.
func door_state() -> Dictionary:
	var state := {}
	for door in doors.keys():
		state[door] = door_open(door)
	return state


## True only when every door on the map is open. HUD summary and legacy callers.
func doors_open() -> bool:
	if doors.is_empty():
		return true
	for door in doors.keys():
		if not door_open(door):
			return false
	return true


## Cores needed to finish: every Pedestal plus every plate that must stay held.
func required_target_count() -> int:
	var required_plates := 0
	for plate in plates.keys():
		if plate_hold_required.get(plate, true):
			required_plates += 1
	var total := slots.size() + required_plates
	return total if total > 0 else blocks.size()


## Count of Cores currently in position (on goal slots or held plates)
func placed_core_count() -> int:
	var count := 0
	for b in blocks.keys():
		if slots.has(b) or (plates.has(b) and plate_hold_required.get(b, true)):
			count += 1
	return count


func try_move(dir: Vector3i) -> Dictionary:
	if won:
		return {}
	var doors_before := door_state()
	var doors_were_open := doors_open()
	var target := player + dir
	if _terrain_blocked(target, doors_before):
		return {}
	var pushed := false
	var pushed_from := Vector3i.ZERO
	var block_destination := Vector3i.ZERO
	var teleported := false
	var elevated := false
	# Resolve block push (validation only, no state mutation yet).
	if blocks.has(target):
		var beyond := target + dir
		if _terrain_blocked(beyond, doors_before) or blocks.has(beyond):
			return {}
		block_destination = beyond
		if portal_links.has(beyond):
			var exit: Vector3i = portal_links[beyond]
			if not _can_block_enter(exit, doors_before) or exit == player:
				return {}
			block_destination = exit
			teleported = true
		if elevator_links.has(beyond):
			var exit: Vector3i = elevator_links[beyond]
			if not _can_block_enter(exit, doors_before):
				return {}
			block_destination = exit
			elevated = true
		if not _energy_destination_allowed(block_destination):
			return {}
		pushed = true
		pushed_from = target
	# Resolve player destination (validation only).
	var player_destination := target
	if elevator_links.has(target):
		var player_exit: Vector3i = elevator_links[target]
		if _terrain_blocked(player_exit, doors_before) or blocks.has(player_exit):
			return {}
		player_destination = player_exit
		elevated = true
	# Everything validated; commit the move.
	var energy_before := energy_progress
	history.append(_snapshot())
	if pushed:
		blocks.erase(target)
		blocks[block_destination] = true
		_record_energy_destination(block_destination)
		pushes += 1
	player = player_destination
	moves += 1
	won = _check_won()
	var doors_after := door_state()
	var doors_changed: Array = []
	for door in doors_after.keys():
		if doors_after[door] != doors_before.get(door, false):
			doors_changed.append(door)
	return {
		"pushed": pushed,
		"pushed_from": pushed_from,
		"pushed_to": block_destination if pushed else Vector3i.ZERO,
		"teleported": teleported,
		"elevated": elevated,
		"energy_advanced": energy_progress > energy_before,
		"player_from": target,
		"player_to": player_destination,
		"doors_open_before": doors_were_open,
		"doors_open_after": doors_open(),
		"door_state_before": doors_before,
		"door_state_after": doors_after,
		"doors_changed": doors_changed,
	}


func undo() -> bool:
	if history.is_empty():
		return false
	var s: Dictionary = history.pop_back()
	player = s["player"]
	blocks = s["blocks"]
	moves = s["moves"]
	pushes = s["pushes"]
	bridge_open = s["bridge_open"]
	energy_progress = s["energy_progress"]
	won = false
	return true


func _snapshot() -> Dictionary:
	return {
		"player": player,
		"blocks": blocks.duplicate(),
		"moves": moves,
		"pushes": pushes,
		"bridge_open": bridge_open,
		"energy_progress": energy_progress,
	}


func _can_block_enter(v: Vector3i, doors_before: Dictionary) -> bool:
	return not _terrain_blocked(v, doors_before) \
		and not blocks.has(v) \
		and _energy_destination_allowed(v)


func _terrain_blocked(v: Vector3i, doors_before: Dictionary) -> bool:
	return not floors.has(v) or walls.has(v) \
			or (doors.has(v) and not bool(doors_before.get(v, false))) \
			or (bridges.has(v) and not bridge_open)


func _energy_destination_allowed(v: Vector3i) -> bool:
	if energy_nodes.is_empty():
		return true
	var index := energy_nodes.find(v)
	return index < 0 or index <= energy_progress


func _record_energy_destination(v: Vector3i) -> void:
	if energy_progress >= energy_nodes.size():
		return
	if v == energy_nodes[energy_progress]:
		energy_progress += 1


func _check_won() -> bool:
	if energy_progress < energy_nodes.size():
		return false
	if blocks.is_empty():
		return slots.is_empty() and required_target_count() == 0
	# A Core may rest on any plate, but only Pedestals and held plates count.
	for b in blocks.keys():
		if not slots.has(b) and not plates.has(b):
			return false
	for slot in slots.keys():
		if not blocks.has(slot):
			return false
	for plate in plates.keys():
		if plate_hold_required.get(plate, true) and not blocks.has(plate):
			return false
	return true
