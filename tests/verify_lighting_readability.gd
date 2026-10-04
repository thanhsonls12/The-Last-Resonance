extends Node

const QUALITY = preload("res://src/data/render_quality.gd")
var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func _ready() -> void:
	var original_reduced_motion := GameState.reduced_motion
	for mobile in [false, true]:
		QUALITY.set_mobile_override(mobile)
		var lighting := SceneEnvironmentController.new()
		add_child(lighting)
		for chapter in range(1, 5):
			lighting.apply_chapter(chapter, 0.0)
			var color: Color = lighting.key_light.light_color
			check(maxf(color.r, maxf(color.g, color.b)) - minf(color.r, minf(color.g, color.b)) < .18, "Main light retains neutral material colors")
			check(lighting.key_light.light_energy >= .499, "Unpowered puzzle keeps readable key lighting")
			check(lighting.wash_light.light_energy < lighting.key_light.light_energy * .4, "Chapter wash remains a secondary accent")
			lighting.power_up(chapter)
			lighting._power_tween.custom_step(1.1)
			check(is_equal_approx(lighting.environment.ambient_light_energy, .38 * QUALITY.ambient_boost()), "Power-up retains mobile quality boost")
			check(lighting.key_light.light_energy < 1.5, "Power-up avoids blowing out the floor")
		check(lighting.environment.glow_bloom < .03 and lighting.environment.glow_hdr_threshold >= 1.5, "Bloom isolates bright effects")
		check(lighting.key_light.shadow_enabled == not mobile, "Only desktop key light casts shadows")
		check(not lighting.fill_light.shadow_enabled and not lighting.wash_light.shadow_enabled, "Fill and wash add no shadow passes")
		lighting.free()
		var data := Levels.get_data(10)
		var logic := GameLogic.new()
		logic.load_level(data)
		var board := BoardView.new()
		board.chapter = data.chapter
		add_child(board)
		board.build(logic, data.decorations)
		if not mobile:
			for block in board.block_nodes.values():
				var spot: Array[Node] = block.find_children("*", "SpotLight3D", false, false)
				check(spot.size() == 1, "Core spotlight follows the pushed object and inherits floor visibility")
		board.set_process(false)
		board.set_sector_powered(true, true)
		board.player_node.position = Vector3(3, 1.57, 3)
		board._lighting.process_power(.1)
		check(board._lighting._player_light.position.is_equal_approx(board.player_node.position + Vector3(0, 3.1, 0)), "Player light follows movement and elevator height after power-up")
		check(not board._lighting._player_light.shadow_enabled, "Player light avoids a second shadow map")
		board.set_sector_powered(false, true)
		GameState.reduced_motion = true
		board._lighting.process_power(.5)
		for info in board._lighting._power_lights:
			check(is_equal_approx(info.node.light_energy, info.off), "Reduced Motion disables lamp breathing")
		GameState.reduced_motion = original_reduced_motion
		board.free()
	QUALITY.set_mobile_override(null)
	print("Lighting readability checks: ", failures, " failures")
	get_tree().quit(1 if failures else 0)
