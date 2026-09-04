class_name GameCoordinator
extends RefCounted

## Manages play session identity and busy gating for async gameplay flows.
## Prevents stale coroutines from mutating state after restart/next level.
## Does not own visuals or logic; just the session token and busy flag.

signal busy_changed(busy: bool)
signal session_advanced(play_id: int)

var busy: bool = false
var play_id: int = 0


func new_session() -> int:
	play_id += 1
	session_advanced.emit(play_id)
	return play_id


func set_busy(value: bool) -> void:
	if busy == value:
		return
	busy = value
	busy_changed.emit(busy)


func is_current(pid: int) -> bool:
	return pid == play_id


func begin_operation() -> int:
	var pid := play_id
	set_busy(true)
	return pid


func end_operation(pid: int) -> bool:
	if not is_current(pid):
		return false
	set_busy(false)
	return true


func guard(pid: int) -> bool:
	return is_current(pid)


func reset() -> void:
	busy = false
	play_id = 0
