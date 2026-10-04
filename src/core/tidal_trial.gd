extends RefCounted

const DATA = preload("res://resources/trials/tidal_echo.tres")
const VALVE := Vector3i(3, 0, 6)
const CROSSING := Vector3i(4, 0, 5)
const LEFT_DOCK := Vector3i(3, 0, 2)
const RIGHT_DOCK := Vector3i(5, 0, 2)
const MEMORY := Vector3i(7, 0, 3)
var logic := GameLogic.new()
var high_water := false
var memory_collected := false
var transported := false
var history: Array[Dictionary] = []
var message := "Đẩy Core lên bệ nổi, rồi tới van ở cuối bờ trái."


func _init() -> void:
	reset()


func reset() -> void:
	logic.load_level(DATA)
	high_water = false
	memory_collected = false
	transported = false
	history.clear()
	_apply_water()
	message = "Đẩy Core lên bệ nổi, rồi tới van ở cuối bờ trái."


func can_use_valve() -> bool:
	return absi(logic.player.x - VALVE.x) + absi(logic.player.z - VALVE.z) == 1


func _snapshot() -> Dictionary:
	return {"logic": logic._snapshot(), "high_water": high_water, "memory": memory_collected, "transported": transported}


func move(direction: Vector3i) -> Dictionary:
	if direction.y != 0 or absi(direction.x) + absi(direction.z) != 1:
		return {}
	if logic.blocks.has(logic.player + direction) and logic.player + direction * 2 == CROSSING:
		message = "Đường cạn chỉ chịu được Kiro. Core cần bệ nổi để sang bờ."
		return {}
	var before := _snapshot()
	var result := logic.try_move(direction)
	if result.is_empty():
		return {}
	history.append(before)
	logic.history.clear()
	logic.won = false
	if logic.player == MEMORY:
		memory_collected = true
		message = "Đã tìm thấy ký ức. Đưa Core tới đế để mở màu lõi Ngọc triều."
	return result


func toggle_valve() -> bool:
	if not can_use_valve():
		message = "Tới ô sát van ở cuối bờ trái để điều khiển nước."
		return false
	if not high_water and (logic.player == CROSSING or logic.blocks.has(RIGHT_DOCK)):
		message = "Bến bên kia đang bị chiếm. Dọn bến trước khi nâng nước."
		return false
	history.append(_snapshot())
	high_water = not high_water
	if high_water and logic.blocks.has(LEFT_DOCK):
		logic.blocks.erase(LEFT_DOCK)
		logic.blocks[RIGHT_DOCK] = true
		transported = true
	logic.moves += 1
	_apply_water()
	message = "Core đã sang bờ. Hạ nước để Kiro đi qua đường cạn." if high_water and transported else ("Nước đang cao; đường cạn bị ngập." if high_water else "Đường cạn đã lộ. Sang bờ phải và tìm ký ức.")
	return true


func _apply_water() -> void:
	if high_water:
		logic.walls[CROSSING] = true
	else:
		logic.walls.erase(CROSSING)


func undo() -> bool:
	if history.is_empty():
		return false
	var state: Dictionary = history.pop_back()
	logic.history.append(state.logic)
	logic.undo()
	logic.history.clear()
	high_water = state.high_water
	memory_collected = state.memory
	transported = state.transported
	_apply_water()
	message = "Đã hoàn tác bước và mực nước."
	return true


func solved() -> bool:
	return transported and logic.blocks.has(Vector3i(5, 0, 1))
