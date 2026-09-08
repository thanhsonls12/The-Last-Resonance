extends Node

const RENDER_QUALITY = preload("res://src/data/render_quality.gd")
const EXPECTED_CAMPAIGN_PROFILES := {
	0: [&"archive_panel"],
	1: [&"archive_terminal", &"archive_panel"],
	2: [&"archive_panel"],
	3: [&"archive_panel"],
	4: [&"foundry_conveyor", &"foundry_machine_heat"],
	5: [&"foundry_conveyor", &"foundry_machine_heat"],
	6: [&"foundry_machine_heat"],
	7: [&"foundry_conveyor", &"foundry_furnace"],
	8: [&"sanctuary_water"],
	9: [&"sanctuary_water"],
	10: [&"sanctuary_water", &"sanctuary_sway"],
	11: [&"sanctuary_water", &"sanctuary_sway"],
	12: [&"core_trim_pulse"],
	13: [&"core_cabinet_pulse", &"core_trim_pulse"],
	14: [&"core_trim_pulse"],
}
var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func profile_set(values: Array[StringName]) -> Dictionary:
	var result := {}
	for value in values:
		result[value] = true
	return result


func count_nodes_of_type(root: Node, type_name: StringName) -> int:
	var count := 0
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node.is_class(type_name):
			count += 1
		for child in node.get_children():
			stack.append(child)
	return count


func dynamic_base_for_profile(board: BoardView, profile: StringName) -> float:
	var result := 0.0
	for info in board.environment_dynamic_materials:
		if StringName(info.get("profile", &"")) == profile:
			result = maxf(result, float(info.get("base", 0.0)))
	return result


func build_board(level_index: int) -> BoardView:
	var data: LevelData = Levels.get_data(level_index)
	var logic := GameLogic.new()
	logic.load_level(data)
	var board := BoardView.new()
	board.chapter = data.chapter
	board.power_level = data.power_level
	add_child(board)
	board.build(logic, data.decorations)
	board.set_process(false)
	return board


func _ready() -> void:
	RENDER_QUALITY.set_mobile_override(false)

	# E2 is intentionally authored level by level. Lock the unique profile set so
	# later dressing edits cannot silently make a gameplay/story prop dynamic or
	# flatten every room into the same animation density.
	for level_index in EXPECTED_CAMPAIGN_PROFILES:
		var campaign_board := build_board(level_index)
		var actual_profiles := profile_set(campaign_board.environment_dynamic_profiles)
		var expected_profiles: Array = EXPECTED_CAMPAIGN_PROFILES[level_index]
		check(actual_profiles.size() == expected_profiles.size(), "L%d keeps its reviewed E2 profile density" % (level_index + 1))
		for expected_profile in expected_profiles:
			check(actual_profiles.has(expected_profile), "L%d keeps environment profile %s" % [level_index + 1, str(expected_profile)])
		check(count_nodes_of_type(campaign_board, &"CollisionObject3D") == 0, "L%d environment dynamics add no collision objects" % (level_index + 1))
		campaign_board.free()

	var archive := build_board(1)
	var archive_profiles := profile_set(archive.environment_dynamic_profiles)
	check(archive_profiles.has(&"archive_terminal"), "L2 enables Archive terminal flicker")
	check(archive_profiles.has(&"archive_panel"), "L2 enables Archive damaged-panel flicker")
	check(archive.environment_dynamic_materials.size() == 2, "L2 uses exactly two cheap emissive dynamics")
	check(count_nodes_of_type(archive, &"CollisionObject3D") == 0, "L2 dynamics add no collision objects")
	var archive_mat: StandardMaterial3D = archive.environment_dynamic_materials[0]["material"]
	archive._environment_time = 0.0
	archive._update_environment_dynamics()
	var archive_emission_a := archive_mat.emission_energy_multiplier
	archive._environment_time = 0.61
	archive._update_environment_dynamics()
	var archive_emission_b := archive_mat.emission_energy_multiplier
	check(not is_equal_approx(archive_emission_a, archive_emission_b), "Archive dynamic emission changes over time")
	var tutorial_archive := build_board(0)
	check(dynamic_base_for_profile(tutorial_archive, &"archive_panel") < dynamic_base_for_profile(archive, &"archive_panel"), "L1 tutorial panel stays dimmer than L2 representative panel")
	tutorial_archive.free()
	archive.free()

	var foundry := build_board(5)
	var foundry_profiles := profile_set(foundry.environment_dynamic_profiles)
	check(foundry_profiles.has(&"foundry_conveyor"), "L6 enables conveyor vibration")
	check(foundry_profiles.has(&"foundry_machine_heat"), "L6 enables machine heat pulse")
	check(foundry.environment_dynamic_nodes.size() == 1, "L6 animates only the authored conveyor transform")
	check(foundry.environment_dynamic_materials.size() == 2, "L6 machine heat uses two low-poly emissive strips")
	check(count_nodes_of_type(foundry, &"CollisionObject3D") == 0, "L6 dynamics add no collision objects")
	var conveyor_info: Dictionary = foundry.environment_dynamic_nodes[0]
	var conveyor: Node3D = conveyor_info["node"]
	foundry._environment_time = 0.0
	foundry._update_environment_dynamics()
	var conveyor_a := conveyor.position
	foundry._environment_time = 0.27
	foundry._update_environment_dynamics()
	var conveyor_b := conveyor.position
	check(conveyor_a.distance_to(conveyor_b) > 0.0001, "Foundry conveyor actually moves")
	var sealed_foundry := build_board(6)
	check(dynamic_base_for_profile(sealed_foundry, &"foundry_machine_heat") < dynamic_base_for_profile(foundry, &"foundry_machine_heat"), "L7 sealed chamber heat stays weaker than L6 representative heat")
	sealed_foundry.free()
	foundry.free()

	var sanctuary := build_board(10)
	var sanctuary_profiles := profile_set(sanctuary.environment_dynamic_profiles)
	check(sanctuary_profiles.has(&"sanctuary_water"), "L11 enables Sanctuary water flow")
	check(sanctuary_profiles.has(&"sanctuary_sway"), "L11 enables subtle vegetation sway")
	check(sanctuary.environment_dynamic_water_materials.size() >= 3, "L11 configures all authored water pieces")
	var water_mat: ShaderMaterial = sanctuary.environment_dynamic_water_materials[0]
	var wave_speed := float(water_mat.get_shader_parameter("wave_speed"))
	var wave_amplitude := float(water_mat.get_shader_parameter("wave_amplitude"))
	check(wave_speed >= 0.50 and wave_speed <= 0.70, "L11 water speed stays in the calm Sanctuary range")
	check(wave_amplitude > 0.0 and wave_amplitude <= 0.013, "L11 water displacement stays subtle")
	check(sanctuary.environment_dynamic_nodes.size() == 1, "L11 only CPU-animates the authored vegetation prop")
	check(count_nodes_of_type(sanctuary, &"CollisionObject3D") == 0, "L11 dynamics add no collision objects")
	check(sanctuary.layer_roots.has(1) and not (sanctuary.layer_roots[1] as Node3D).visible, "L11 hidden upper floor stays hidden")
	var sanctuary_sway_node: Node3D = sanctuary.environment_dynamic_nodes[0]["node"]
	check(not sanctuary_sway_node.is_visible_in_tree(), "L11 upper-floor sway target inherits hidden floor visibility")
	sanctuary.free()

	var core := build_board(13)
	var core_profiles := profile_set(core.environment_dynamic_profiles)
	check(core_profiles.has(&"core_cabinet_pulse"), "L14 enables data-cabinet pulse")
	check(core_profiles.has(&"core_trim_pulse"), "L14 enables light-trim pulse")
	check(core.environment_dynamic_profiles.size() == 2, "L14 registers only the two authored environment profiles")
	check(core.environment_dynamic_nodes.is_empty(), "L14 does not transform-animate gameplay or story objects")
	check(core.environment_dynamic_materials.size() == 2, "L14 uses two sequenced emissive strips")
	check(core.energy_nodes.size() == 4, "L14 keeps all four gameplay Energy Nodes separate from environment dynamics")
	check(core._eva_hologram_node == null, "L14 environment dynamics do not spawn EVA as scenery")
	check(count_nodes_of_type(core, &"CollisionObject3D") == 0, "L14 dynamics add no collision objects")
	var core_a: Dictionary = core.environment_dynamic_materials[0]
	var core_b: Dictionary = core.environment_dynamic_materials[1]
	check(not is_equal_approx(float(core_a.phase), float(core_b.phase)), "L14 pulse strips use different phases")
	var entry_core := build_board(12)
	var finale_core := build_board(14)
	check(dynamic_base_for_profile(entry_core, &"core_trim_pulse") < dynamic_base_for_profile(core, &"core_trim_pulse"), "L13 pulse stays weaker than L14 representative pulse")
	check(dynamic_base_for_profile(finale_core, &"core_trim_pulse") < dynamic_base_for_profile(core, &"core_trim_pulse"), "L15 finale pulse stays weaker than L14 representative pulse")
	entry_core.free()
	finale_core.free()
	core.free()

	# Android keeps the authored motion but scales it down and must not gain any
	# expensive lights or particles from this presentation pass.
	RENDER_QUALITY.set_mobile_override(true)
	var mobile_core := build_board(13)
	check(is_equal_approx(RENDER_QUALITY.environment_motion_scale(), 0.62), "mobile environment motion scale is deterministic")
	check(is_equal_approx(RENDER_QUALITY.environment_emission_scale(), 0.72), "mobile environment emission scale is deterministic")
	check(profile_set(mobile_core.environment_dynamic_profiles).has(&"core_trim_pulse"), "mobile keeps Central Core dynamics enabled")
	check(count_nodes_of_type(mobile_core, &"GPUParticles3D") == 0, "environment dynamics add no mobile particles")
	check(count_nodes_of_type(mobile_core, &"Light3D") <= 1, "environment dynamics add no mobile realtime accent lights")
	check(count_nodes_of_type(mobile_core, &"CollisionObject3D") == 0, "environment dynamics add no mobile collision objects")
	mobile_core.free()
	RENDER_QUALITY.set_mobile_override(null)

	print("Environment dynamics checks: ", failures, " failures")
	get_tree().quit(1 if failures else 0)
