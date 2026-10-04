extends Node3D
## Presentation only: bounded geometry, no lights or collision bodies.
const QUALITY = preload("res://src/data/render_quality.gd")
const MIST = preload("res://assets/shaders/void_mist.gdshader")
var _pieces: Array[Node3D] = []
var _bases: Array[Vector3] = []
var _mist: ShaderMaterial
var _stone: StandardMaterial3D
var _time := 0.0
var _pulse := -1.0
var _dust: MultiMeshInstance3D


func build(bounds: Dictionary) -> void:
	name = "VoidEnvironment"
	var width: float = bounds["max_x"] - bounds["min_x"] + 1.0
	var depth: float = bounds["max_z"] - bounds["min_z"] + 1.0
	position = Vector3((bounds["min_x"] + bounds["max_x"]) * 0.5, -1.8,
		(bounds["min_z"] + bounds["max_z"]) * 0.5)
	_stone = MeshFactory.mat(Color(0.028, 0.052, 0.075), 0.15)
	var trim := MeshFactory.mat(Color(0.055, 0.20, 0.25), 0.35)
	var count := 4 if QUALITY.is_mobile() else 7
	for i in count:
		var angle := float(i) * TAU / float(count) + 0.3
		var root := Node3D.new()
		add_child(root)
		root.position = Vector3(cos(angle) * (width * 0.5 + 3.0),
			-0.8 - float(i % 3) * 0.65, sin(angle) * (depth * 0.5 + 3.0))
		root.rotation = Vector3(0.12 * sin(angle), angle, 0.16 * cos(angle))
		_pieces.append(root)
		_bases.append(root.position)
		if i == 2:
			# Broken doorway, with one surviving upright and a fractured lintel.
			MeshFactory.box(root, Vector3(-0.65, 0.65, 0), Vector3(0.22, 1.8, 0.3), _stone)
			MeshFactory.box(root, Vector3(0.12, 1.45, 0), Vector3(1.65, 0.24, 0.3), _stone)
			MeshFactory.box(root, Vector3(0.8, 1.14, 0), Vector3(0.22, 0.7, 0.3), _stone)
			MeshFactory.box(root, Vector3(-0.51, 0.7, 0.16), Vector3(0.025, 1.3, 0.025), trim)
		else:
			MeshFactory.box(root, Vector3.ZERO, Vector3(1.1 + float(i % 2) * 0.5, 0.22, 0.75), _stone)
			MeshFactory.box(root, Vector3(0, 0.12, 0.23), Vector3(0.72, 0.025, 0.035), trim)
		for child in root.get_children():
			(child as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if QUALITY.background_fx_enabled():
		_mist = ShaderMaterial.new()
		_mist.shader = MIST
		var plane := MeshInstance3D.new()
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(width + 19.0, depth + 19.0)
		plane.mesh = mesh
		plane.material_override = _mist
		plane.position.y = -2.5
		plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(plane)
		_dust = MultiMeshInstance3D.new()
		_dust.name = "DistantMemoryDust"
		var motes := MultiMesh.new()
		motes.transform_format = MultiMesh.TRANSFORM_3D
		var mote := SphereMesh.new()
		mote.radius = 0.018
		mote.height = 0.036
		mote.radial_segments = 4
		mote.rings = 2
		mote.material = MeshFactory.mat(Color(0.12, 0.32, 0.40), 0.65)
		motes.mesh = mote
		motes.instance_count = 28
		var rng := RandomNumberGenerator.new()
		rng.seed = 7341
		for i in motes.instance_count:
			var angle := rng.randf_range(0, TAU)
			var offset := Vector3(cos(angle) * (width * 0.5 + rng.randf_range(2.0, 7.0)),
				rng.randf_range(-2.5, 0.0), sin(angle) * (depth * 0.5 + rng.randf_range(2.0, 7.0)))
			motes.set_instance_transform(i, Transform3D(Basis.IDENTITY, offset))
		_dust.multimesh = motes
		_dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_dust)


func resonate() -> void:
	if not GameState.reduced_motion:
		_pulse = 0.0


func _process(delta: float) -> void:
	if GameState.reduced_motion:
		_pulse = -1.0
	else:
		_time += delta * QUALITY.environment_motion_scale()
		if _pulse >= 0.0:
			_pulse += delta * 0.28
			if _pulse > 1.0:
				_pulse = -1.0
	for i in _pieces.size():
		_pieces[i].position = _bases[i]
		if not GameState.reduced_motion:
			_pieces[i].position.y += sin(_time * 0.24 + float(i) * 1.7) * 0.12
	if _mist:
		_mist.set_shader_parameter("clock", _time)
		_mist.set_shader_parameter("pulse", _pulse)
	if _dust:
		_dust.position.y = sin(_time * 0.15) * 0.18
	if _stone:
		_stone.emission_energy_multiplier = 0.15 + (sin(_pulse * PI) * 1.4 if _pulse >= 0.0 else 0.0)
