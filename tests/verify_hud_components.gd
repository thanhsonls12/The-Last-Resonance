extends Node

var failures := 0


func _ready() -> void:
	var hud: Variant = GameHud.new()
	add_child(hud)
	await get_tree().process_frame

	_check(hud.status != null and hud.controls != null, "HUD status/controls components are composed")
	_check(hud.win_panel != null and hud.pause_panel != null, "HUD modal components are composed")

	var counts := {"undo": 0, "restart": 0, "resume": 0, "next": 0}
	hud.undo_requested.connect(func() -> void: counts.undo += 1)
	hud.restart_requested.connect(func() -> void: counts.restart += 1)
	hud.resume_requested.connect(func() -> void: counts.resume += 1)
	hud.next_level_requested.connect(func() -> void: counts.next += 1)

	hud.controls.undo_button.pressed.emit()
	_check(counts.undo == 1, "Undo signal is forwarded exactly once")

	hud.set_paused(true)
	_check(hud.pause_panel.visible, "Pause component becomes visible")
	hud.pause_panel.resume_button.pressed.emit()
	_check(counts.resume == 1, "Resume signal is forwarded exactly once")
	hud.set_paused(false)
	_check(not hud.pause_panel.visible, "Pause component hides on resume")

	hud.show_win("Test", 12, 2, 12, 12, "Tiếp", "DONE", 0, {"stars": 3, "perfect": true})
	_check(hud.win_panel.visible, "Win component becomes visible")
	_check(hud.win_panel.stars_label.visible and "★★★" not in hud.win_panel.stars_label.text, "Win result owns star presentation")
	hud.win_panel.next_button.pressed.emit()
	_check(counts.next == 1 and not hud.win_panel.visible, "Next-level action hides win panel and emits once")

	hud.set_bridge_available(true)
	hud.controls.layout(Vector2(640, 480), true)
	_check(hud.controls.bridge_button.visible, "Compact controls keep available bridge action visible")
	_check(hud.controls.undo_button.custom_minimum_size.x >= 72.0, "Compact control buttons keep touch-safe width")

	hud.status.apply_accessibility(true)
	_check(hud.status.level_label.label_settings.outline_size >= 9, "High contrast strengthens status label outline")
	hud.status.apply_accessibility(false)
	_check(hud.status.level_label.label_settings.outline_size == 8, "Accessibility reset restores status defaults")

	hud.queue_free()
	print("HUD components: %s" % ("PASS" if failures == 0 else "FAIL"))
	get_tree().quit(0 if failures == 0 else 1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		print("FAIL: " + message)
