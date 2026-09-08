extends Node

const RENDER_QUALITY = preload("res://src/data/render_quality.gd")
const GAME_SCENE := preload("res://scenes/game/main.tscn")
var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


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


func count_color_pools(root: Node) -> int:
	var count := 0
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node.name.begins_with("MobileColorPool"):
			count += 1
		for child in node.get_children():
			stack.append(child)
	return count


func detail_texture_width(root: Node) -> int:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D and (node as MeshInstance3D).mesh:
			var mesh_instance := node as MeshInstance3D
			for surface in mesh_instance.mesh.get_surface_count():
				var material := mesh_instance.get_active_material(surface)
				if material is StandardMaterial3D and (material as StandardMaterial3D).detail_enabled:
					var detail := (material as StandardMaterial3D).detail_albedo
					if detail != null:
						return detail.get_width()
		for child in node.get_children():
			stack.append(child)
	return 0


func _ready() -> void:
	RENDER_QUALITY.set_mobile_override(true)
	var data: LevelData = Levels.get_data(13)
	var logic := GameLogic.new()
	logic.load_level(data)
	var board := BoardView.new()
	board.chapter = data.chapter
	board.power_level = data.power_level
	add_child(board)
	board.build(logic, data.decorations)
	await get_tree().process_frame

	var light_count := count_nodes_of_type(board, &"Light3D")
	var particle_count := count_nodes_of_type(board, &"GPUParticles3D")
	check(board.decor_nodes.size() == data.decorations.size(), "mobile tier keeps every authored decoration")
	check(light_count <= 1, "mobile tier has no realtime accent lights")
	check(particle_count == 0, "mobile tier removes background particle volumes")
	check(count_color_pools(board) == 3, "mobile tier keeps three cheap color pools")
	check(detail_texture_width(board) == ChapterMaterialProfiles.MOBILE_WEATHERING_SIZE, "mobile tier uses compact material detail")
	check(RENDER_QUALITY.particle_amount(100) == 42, "mobile particle scale is deterministic")
	check(RENDER_QUALITY.mobile_color_pool_budget() == 3, "mobile color-pool budget is deterministic")
	for node in board.get_children():
		if node is Light3D:
			check(not (node as Light3D).shadow_enabled, "mobile board light has shadows disabled")
	board.queue_free()
	await get_tree().process_frame
	var game := GAME_SCENE.instantiate()
	add_child(game)
	for _frame in 8:
		await get_tree().process_frame
	check(game.world_environment != null and not game.world_environment.glow_enabled, "mobile environment disables glow post-processing")
	check(game.world_environment != null and not game.world_environment.fog_enabled, "mobile environment disables fog post-processing")
	check(game.world_environment != null and is_equal_approx(game.world_environment.tonemap_exposure, 1.10), "mobile environment uses the balanced exposure")
	check(game.sector_key_light != null and not game.sector_key_light.shadow_enabled, "mobile environment disables directional shadows")
	game.queue_free()
	await get_tree().process_frame
	RENDER_QUALITY.set_mobile_override(null)
	print("Mobile render budget checks: ", failures, " failures")
	get_tree().quit(1 if failures else 0)
