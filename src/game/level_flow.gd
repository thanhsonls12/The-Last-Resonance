class_name LevelFlow
extends RefCounted

## Owns level data, GameLogic instance, and win/lifecycle state.
## Does NOT own visuals, audio, story, or input.
## Scene controller (main.gd) owns the managers and wires them.

signal level_loaded(data: LevelData)
signal level_won
signal state_changed

var logic: GameLogic
var level_index: int = 0
var decorations: Array = []
var pending_fragment: String = ""

var _data: LevelData = null


func reset() -> void:
	logic = GameLogic.new()
	level_index = 0
	decorations.clear()
	pending_fragment = ""
	_data = null


func load_level(index: int) -> LevelData:
	if Levels.ALL.is_empty() or index < 0 or index >= Levels.ALL.size():
		return null

	level_index = index
	logic = GameLogic.new()

	_data = Levels.get_data(index)
	if _data == null:
		return null

	logic.load_level(_data)
	decorations = _data.decorations if _data.decorations else []
	pending_fragment = _data.memory_fragment if _data else ""

	level_loaded.emit(_data)
	state_changed.emit()
	return _data


func get_data() -> LevelData:
	return _data


func get_title() -> String:
	return logic.level_name if logic else ""


func get_moves() -> int:
	return logic.moves if logic else 0


func get_pushes() -> int:
	return logic.pushes if logic else 0


func is_won() -> bool:
	return logic.won if logic else false


func required_targets() -> int:
	return logic.required_target_count() if logic else 0


func placed_cores() -> int:
	return logic.placed_core_count() if logic else 0


func doors_open() -> bool:
	return logic.doors_open() if logic else true


func bridge_available() -> bool:
	return logic.bridge_control_available() if logic else false


func has_bridges() -> bool:
	return logic.has_bridges() if logic else false


func try_move(dir: Vector3i) -> Dictionary:
	if logic == null:
		return {}
	return logic.try_move(dir)


func rotate_bridge() -> Dictionary:
	if logic == null:
		return {}
	return logic.rotate_bridge()


func undo() -> bool:
	if logic == null:
		return false
	return logic.undo()


func restart() -> void:
	if _data != null and logic != null:
		logic.load_level(_data)
		state_changed.emit()


func get_hint_route() -> String:
	return _data.hint_route if _data else ""


func get_chapter() -> int:
	return _data.chapter if _data else 1


func get_power_level() -> float:
	return _data.power_level if _data else 0.0


func get_memory_fragment() -> String:
	return _data.memory_fragment if _data else ""


func complete_current(moves: int, pushes: int, hints_used: int) -> void:
	if _data == null:
		return
	var memory_collected := not _data.memory_fragment.is_empty()
	GameState.complete_level(level_index, moves, pushes, memory_collected, hints_used)
