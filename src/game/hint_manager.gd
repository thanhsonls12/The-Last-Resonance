class_name HintManager
extends RefCounted

## Stateless-ish manager for the 3-tier in-game hint system.
## Owns route, cursor, stage, desync tracking, and hint usage count.
## Main scene provides the route on load, then calls record/undo/advance
## and queries for display state. Hints are offline (pre-verified routes),
## never computed at runtime.

signal hint_changed

var route: String = ""
var cursor: int = 0
var stage: int = 0
var desynced: bool = false
var hints_used: int = 0

var _recorded_actions: Array[String] = []


func reset() -> void:
	route = ""
	cursor = 0
	stage = 0
	desynced = false
	hints_used = 0
	_recorded_actions.clear()
	hint_changed.emit()


func load_route(new_route: String) -> void:
	route = new_route if new_route != null else ""
	cursor = 0
	stage = 0
	desynced = false
	hints_used = 0
	_recorded_actions.clear()
	hint_changed.emit()


func is_available() -> bool:
	return not route.is_empty()


func advance_stage() -> int:
	if route.is_empty():
		return 0
	if stage >= 3:
		stage = 0
	else:
		stage += 1
		hints_used += 1
	hint_changed.emit()
	return stage


func dismiss() -> void:
	stage = 0
	hint_changed.emit()


func record_action(action: String) -> void:
	if action.is_empty() or route.is_empty():
		return
	_recorded_actions.append(action)
	_rebuild_progress()
	hint_changed.emit()


func undo_action() -> void:
	if not _recorded_actions.is_empty():
		_recorded_actions.pop_back()
	_rebuild_progress()
	hint_changed.emit()


func get_display() -> Dictionary:
	# Returns: { stage, text, target, desynced }
	if stage <= 0 or route.is_empty():
		return {"stage": 0, "text": "", "target": Vector3i.ZERO, "desynced": false}

	if desynced or cursor >= route.length():
		return {
			"stage": stage,
			"text": _get_fallback_text(),
			"target": Vector3i.ZERO,  # caller resolves fallback cell
			"desynced": desynced
		}

	var action: String = route[cursor]
	return {
		"stage": stage,
		"text": _get_stage_text(action),
		"target": Vector3i.ZERO,  # caller resolves from action
		"desynced": false
	}


func get_current_action() -> String:
	if desynced or cursor >= route.length() or stage <= 0:
		return ""
	return route[cursor]


func get_preview(max_steps: int = 5) -> String:
	if route.is_empty() or cursor >= route.length():
		return ""
	var end := mini(route.length(), cursor + max_steps)
	var preview := ""
	for i in range(cursor, end):
		if i > cursor:
			preview += " • "
		preview += _action_symbol(route[i])
	return preview


func get_hints_used() -> int:
	return hints_used


func _rebuild_progress() -> void:
	cursor = 0
	desynced = false
	for action in _recorded_actions:
		if desynced:
			break
		if cursor >= route.length() or route[cursor] != action:
			desynced = true
			break
		cursor += 1


func _get_stage_text(action: String) -> String:
	match stage:
		1:
			return "GỢI Ý 1/3 — Hãy hướng tới ô đang phát sáng."
		2:
			return "GỢI Ý 2/3 — Bước kế tiếp theo lưới: %s." % _action_text(action)
		_:
			return "GỢI Ý 3/3 — Chuỗi kế tiếp: %s" % get_preview()
	return ""


func _action_symbol(action: String) -> String:
	match action:
		"U": return "↑"
		"D": return "↓"
		"L": return "←"
		"R": return "→"
		"B": return "CẦU"
	return "•"


func _action_text(action: String) -> String:
	match action:
		"U": return "↑ Lên"
		"D": return "↓ Xuống"
		"L": return "← Trái"
		"R": return "→ Phải"
		"B": return "xoay cầu tại bảng điều khiển"
	return "tiếp tục"


func _get_fallback_text() -> String:
	if desynced:
		return "Đường gợi ý đã lệch khỏi nước đi hiện tại."
	return "Tiếp tục di chuyển và quan sát các ô sáng."
