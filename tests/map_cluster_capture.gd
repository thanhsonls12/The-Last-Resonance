extends Node3D

## Renders each map cluster prefab in isolation from a gameplay-like isometric
## camera at all four cardinal yaws, so visual_camera_review can be judged from
## images instead of only from bounds metadata. Authoring tool, not a gate.

const CLUSTERS := [
	"res://scenes/editor/map_clusters/archive_storage_bay.tscn",
	"res://scenes/editor/map_clusters/foundry_maintenance_corner.tscn",
	"res://scenes/editor/map_clusters/sanctuary_flooded_bank.tscn",
	"res://scenes/editor/map_clusters/core_data_wall.tscn",
]

const PITCH := -43.0
const DISTANCE := 9.0
const CAPTURE_DIR := "res://.codex_qa/cluster_review"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	_add_environment()
	for path in CLUSTERS:
		await _capture_cluster(path)
	print("Cluster review images written to ", CAPTURE_DIR)
	get_tree().quit()


func _add_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.0627451, 0.105882354, 0.15686275, 1)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.76862746, 0.87058824, 0.9411765, 1)
	environment.ambient_light_energy = 0.55
	world.environment = environment
	add_child(world)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-42.0, 30.0, 0.0)
	light.light_energy = 0.9
	add_child(light)


func _capture_cluster(scene_path: String) -> void:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		printerr("FAIL: cannot load ", scene_path)
		return
	var cluster := packed.instantiate() as Node3D
	add_child(cluster)
	await get_tree().process_frame

	var cluster_id := str(cluster.get_meta("cluster_id", scene_path.get_file().get_basename()))

	var camera := Camera3D.new()
	camera.fov = 45.0
	add_child(camera)
	camera.make_current()

	for yaw in [0, 90, 180, 270]:
		var yaw_radians := deg_to_rad(float(yaw))
		var pitch_radians := deg_to_rad(PITCH)
		var offset := Vector3(
			sin(yaw_radians) * cos(pitch_radians),
			-sin(pitch_radians),
			cos(yaw_radians) * cos(pitch_radians)
		) * DISTANCE
		camera.position = offset
		camera.look_at(Vector3.ZERO, Vector3.UP)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var output := "%s/%s_yaw%03d.png" % [CAPTURE_DIR, cluster_id, yaw]
		var result := get_viewport().get_texture().get_image().save_png(output)
		if result != OK:
			printerr("FAIL: could not save ", output, " (", result, ")")
		else:
			print("Captured ", output)

	camera.queue_free()
	cluster.queue_free()
	await get_tree().process_frame
