extends Node3D

const QUALITY = preload("res://src/data/render_quality.gd")
const PALETTES := {
	1: [Color("182735"), Color("253a49"), Color("0c1520"), Color("376777"), Color("101e2b")],
	2: [Color("30251e"), Color("47372b"), Color("160f0c"), Color("82572e"), Color("211a16")],
	3: [Color("243630"), Color("374941"), Color("101e19"), Color("365d55"), Color("132d31")],
	4: [Color("142530"), Color("253b48"), Color("09131c"), Color("416d80"), Color("10202c")],
}
var _boxes: Dictionary = {}
var _pipes: Array[Transform3D] = []
var _materials: Array[StandardMaterial3D] = []
var _accent: StandardMaterial3D
var _pulse := -1.0
var _chapter := 1
var _water_material: ShaderMaterial
var _water_time := 0.0
var _water_size := Vector2.ZERO
var _ripples: Array[Vector4] = [Vector4(0, 0, -10, 0), Vector4(0, 0, -10, 0), Vector4(0, 0, -10, 0)]
var _next_ripple := 0


func react_to_step(world: Vector3) -> void:
	if not _water_material or GameState.reduced_motion or world.y > .5:
		return
	var local := Vector2(world.x - position.x, world.z - position.z)
	var hx := (_water_size.x - 14) * .5
	var hz := (_water_size.y - 14) * .5
	if minf(hx - absf(local.x), hz - absf(local.y)) > 1.6:
		return
	if hx - absf(local.x) < hz - absf(local.y):
		local.x = (1.0 if local.x >= 0 else -1.0) * (hx + 1.6)
	else:
		local.y = (1.0 if local.y >= 0 else -1.0) * (hz + 1.6)
	_ripples[_next_ripple] = Vector4(local.x, local.y, _water_time, 1)
	_water_material.set_shader_parameter("ripple_%d" % _next_ripple, _ripples[_next_ripple])
	_next_ripple = (_next_ripple + 1) % (2 if QUALITY.is_mobile() else 3)


func build(bounds: Dictionary, chapter := 1) -> void:
	name = "SectorExterior"
	_chapter = chapter
	var width: float = bounds.max_x - bounds.min_x + 1
	var depth: float = bounds.max_z - bounds.min_z + 1
	position = Vector3((bounds.min_x + bounds.max_x) * .5, 0, (bounds.min_z + bounds.max_z) * .5)
	for i in range(5):
		var mat := MeshFactory.mat(PALETTES[chapter][i], .24 if i == 3 else (.14 if i == 1 else .07))
		mat.metallic = .0 if chapter == 3 else .45
		mat.roughness = .82
		if i == 4:
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_materials.append(mat)
		_boxes[i] = []
	_accent = _materials[3]
	_build_supports(width, depth)
	_build_service_walk(width, depth)
	_build_background(width, depth)
	_flush_batches()


func _box(role: int, pos: Vector3, size: Vector3, rotation := Vector3.ZERO) -> void:
	_boxes[role].append(Transform3D(Basis.from_euler(rotation).scaled_local(size), pos))


func _pipe(start: Vector3, end: Vector3, radius: float) -> void:
	var direction := end - start
	var basis := Basis(Quaternion(Vector3.UP, direction.normalized())).scaled_local(Vector3(radius, direction.length(), radius))
	_pipes.append(Transform3D(basis, (start + end) * .5))


func _build_supports(width: float, depth: float) -> void:
	for x in [-width * .34, 0.0, width * .34]:
		_box(0, Vector3(x, -1.02, 0), Vector3(.28, .24, depth + .25))
		for z in [-depth * .32, depth * .32]:
			_box(0, Vector3(x, -2.12, z), Vector3(.38, 2.45, .38))
			_box(1, Vector3(x, -1.02, z), Vector3(.62, .16, .62))
			_box(2, Vector3(x, -3.27, z), Vector3(.78, .18, .78))
			_pipe(Vector3(x - .55, -2.65, z), Vector3(x + .55, -1.18, z), .035)
	for z in [-depth * .28, depth * .28]:
		_box(0, Vector3(0, -1.18, z), Vector3(width + .15, .22, .24))
	for x in [-width * .22, width * .22]:
		_pipe(Vector3(x, -1.1, depth * .46), Vector3(x, -3.65, depth * .46), .038)
		_pipe(Vector3(x, -3.65, depth * .46), Vector3(x + .35, -4.05, depth * .46), .038)


func _build_service_walk(width: float, depth: float) -> void:
	var hx := width * .5 + .92
	var hz := depth * .5 + .92
	for x in [-hx, hx]:
		_box(1, Vector3(x, -1.03, 0), Vector3(.82, .18, depth + 2.7))
		_box(2, Vector3(x, -1.14, 0), Vector3(.88, .07, depth + 2.7))
		var outside: float = x + signf(x) * .33
		_box(0, Vector3(outside, -.47, 0), Vector3(.06, .07, depth + 2.7))
		for z in range(-int(depth * .5) - 1, int(depth * .5) + 2, 2):
			_box(0, Vector3(outside, -.74, z), Vector3(.07, .59, .07))
			_box(2, Vector3(x, -.927, z), Vector3(.66, .016, .18))
	for z in [-hz, hz]:
		_box(1, Vector3(0, -1.03, z), Vector3(width + 1.02, .18, .82))
		_box(0, Vector3(0, -.47, z + signf(z) * .33), Vector3(width + 1.02, .07, .06))
		for x in range(-int(width * .5), int(width * .5) + 1, 2):
			_box(0, Vector3(x, -.74, z + signf(z) * .33), Vector3(.07, .59, .07))
	for x in [-hx, hx]:
		for z in [-hz, hz]:
			_box(0, Vector3(x, -2.65, z), Vector3(.24, 1.8, .24))
			_box(3, Vector3(x, -.87, z), Vector3(.19, .016, .10))
	_pipe(Vector3(-hx, -2.25, hz), Vector3(hx, -2.25, hz), .12 if _chapter == 2 else .07)
	_pipe(Vector3(hx, -2.25, -hz), Vector3(hx, -2.25, hz), .12 if _chapter == 2 else .07)


func _build_background(width: float, depth: float) -> void:
	var hz := depth * .5 + 3.0
	if _chapter == 3:
		_build_water_basin(width, depth)
		for i in range(5):
			var x := (i - 2) * 2.1
			_box(0, Vector3(x, -2.8, -hz), Vector3(.55, 2.8, .65))
			_box(1, Vector3(x, -1.35, -hz), Vector3(.85, .14, .83))
			_box(1, Vector3(x, -3.1, hz + .6), Vector3(1.5, .20, 1.0), Vector3(0, (i % 3) * .25, 0))
			_pipe(Vector3(x, -1.45, -hz), Vector3(x + .3, -2.6, -hz + .5), .09)
			_pipe(Vector3(x + .3, -2.6, -hz + .5), Vector3(x + .65, -3.66, -hz + .95), .075)
		_box(1, Vector3(0, -1.7, -hz), Vector3(9.1, .27, .64))
	elif _chapter == 4:
		for radius in [minf(width, depth) * .5 + 2.6, minf(width, depth) * .5 + 3.6]:
			var ring := MeshInstance3D.new()
			var mesh := TorusMesh.new()
			mesh.inner_radius = radius - .12
			mesh.outer_radius = radius
			mesh.rings = 48 if not QUALITY.is_mobile() else 32
			mesh.ring_segments = 6
			ring.mesh = mesh
			ring.material_override = _materials[1]
			ring.position.y = -3.85
			ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(ring)
		for i in range(6):
			var angle := i * TAU / 6.0
			var pos := Vector3(cos(angle) * (width * .5 + 3), -2.7, sin(angle) * (depth * .5 + 3))
			_box(0, pos, Vector3(.8, 3.8, .8))
			_box(3, pos + Vector3(0, .45, .41), Vector3(.08, 1.6, .018))
	else:
		for i in range(3):
			var x := (i - 1) * width * .30
			_box(4, Vector3(x, -2.85, -hz), Vector3(width * .24, 3.5, 1.20))
			for row in range(3):
				_box(1, Vector3(x, -3.8 + row * 1.0, -hz + .66), Vector3(width * .23, .09, .18))
				for slot in range(3):
					_box(0, Vector3(x + (slot - 1) * width * .062, -3.35 + row * 1.0, -hz + .65), Vector3(width * .045, .66, .10))
			_box(3, Vector3(x, -1.55, -hz + .73), Vector3(.16, .05, .012))
		if _chapter == 2:
			for i in range(3):
				var x := (i - 1) * width * .28
				_pipe(Vector3(x, -3.45, hz), Vector3(x, -1.35, hz), .28)
				_pipe(Vector3(x, -1.35, hz), Vector3(x + .65, -1.35, hz), .19)
				_box(0, Vector3(x, -3.6, hz), Vector3(1.0, .2, 1.0))
				_box(3, Vector3(x, -2.9, hz + .30), Vector3(.35, .12, .02))
	_box(4, Vector3(0, -5.3, 0), Vector3(width + 15, .12, depth + 15))


func _build_water_basin(width: float, depth: float) -> void:
	var water := MeshInstance3D.new()
	water.name = "SanctuaryWaterBasin"
	var plane := PlaneMesh.new()
	plane.size = Vector2(width + 14, depth + 14)
	_water_size = plane.size
	plane.subdivide_width = 16 if QUALITY.is_mobile() else 32
	plane.subdivide_depth = plane.subdivide_width
	water.mesh = plane
	water.position.y = -1.48
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_water_material = ShaderMaterial.new()
	_water_material.shader = preload("res://assets/shaders/sanctuary_basin.gdshader")
	_water_material.set_shader_parameter("basin_size", plane.size)
	_water_material.set_shader_parameter("wave_height", .012 if QUALITY.is_mobile() else .018)
	water.material_override = _water_material
	add_child(water)


func _flush_batches() -> void:
	for role in _boxes:
		var transforms: Array = _boxes[role]
		var mesh := BoxMesh.new()
		mesh.size = Vector3.ONE
		mesh.material = _materials[role]
		_add_batch("ExteriorStructure_%d" % role, mesh, transforms)
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1
	cylinder.bottom_radius = 1
	cylinder.height = 1
	cylinder.radial_segments = 10
	cylinder.rings = 1
	cylinder.material = _materials[0]
	_add_batch("ExteriorConduits", cylinder, _pipes)
	_boxes.clear()
	_pipes.clear()


func _add_batch(label: String, mesh: Mesh, transforms: Array) -> void:
	var node := MultiMeshInstance3D.new()
	node.name = label
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = transforms.size()
	var bounds := AABB()
	for i in transforms.size():
		batch.set_instance_transform(i, transforms[i])
		var instance_bounds: AABB = transforms[i] * mesh.get_aabb()
		bounds = instance_bounds if i == 0 else bounds.merge(instance_bounds)
	batch.custom_aabb = bounds
	node.multimesh = batch
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)


func resonate() -> void:
	if not GameState.reduced_motion:
		_pulse = 0


func _process(delta: float) -> void:
	if _water_material and not GameState.reduced_motion:
		_water_time += delta
		_water_material.set_shader_parameter("water_time", _water_time)
	if _pulse >= 0:
		_pulse += delta * .4
		if _pulse > 1 or GameState.reduced_motion:
			_pulse = -1
	if _accent:
		_accent.emission_energy_multiplier = .24 + (sin(_pulse * PI) * .10 if _pulse >= 0 else 0)
