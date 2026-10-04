class_name ActionExecution
extends RefCounted

## Owns gameplay action execution/normalization for the scene controller.
## It mutates GameLogic through its public action API, then returns a compact
## presentation plan. It never touches BoardView, HUD, audio, VFX, story or
## session state.

const KIND_MOVE := &"move"
const KIND_BRIDGE := &"bridge"


func step(logic: GameLogic, direction: Vector3i) -> Dictionary:
	if logic == null:
		return {}
	var result := logic.try_move(direction)
	if result.is_empty():
		return {}

	var player_from: Vector3i = result.get("player_from", logic.player)
	var player_to: Vector3i = result.get("player_to", logic.player)
	var pushed := bool(result.get("pushed", false))
	var door_transitions: Array[Dictionary] = []
	var door_state_after: Dictionary = result.get("door_state_after", {})
	for raw_position in result.get("doors_changed", []):
		var position: Vector3i = raw_position
		door_transitions.append({
			"position": position,
			"open": bool(door_state_after.get(position, false)),
		})

	var block_transition := {}
	if pushed:
		block_transition = {
			"from": result.get("pushed_from", Vector3i.ZERO),
			"to": result.get("pushed_to", Vector3i.ZERO),
			"teleported": bool(result.get("teleported", false)),
			"elevated": bool(result.get("elevated", false)),
		}

	return {
		"kind": KIND_MOVE,
		"direction": direction,
		"result": result,
		"player_from": player_from,
		"player_to": player_to,
		"bridge_from": logic.bridges.has(player_from),
		"bridge_to": logic.bridges.has(player_to),
		"block_transition": block_transition,
		"door_transitions": door_transitions,
		"floor_transition": bool(result.get("floor_transition", false)),
		"elevator_entry": result.get("elevator_entry", Vector3i.ZERO),
		"floor_completed": bool(result.get("floor_completed", false)),
		"completed_floor": int(result.get("completed_floor", -1)),
		"energy_advanced": bool(result.get("energy_advanced", false)),
	}


func rotate_bridge(logic: GameLogic) -> Dictionary:
	if logic == null:
		return {}
	var result := logic.rotate_bridge()
	if result.is_empty():
		return {}
	return {
		"kind": KIND_BRIDGE,
		"result": result,
		"bridge_open": bool(result.get("bridge_open", logic.bridge_open)),
	}
