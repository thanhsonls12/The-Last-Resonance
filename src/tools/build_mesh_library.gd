@tool
extends EditorScript

# Run this script in Godot Editor:
# Open this script in Script Editor -> File -> Run (or Ctrl+Shift+X)
# It scans all 3D assets and creates 'res://resources/mesh_libraries/echo_mesh_library.tres'

const OUTPUT_PATH := "res://resources/mesh_libraries/echo_mesh_library.tres"

const CATALOG: Array[Dictionary] = [
	# Architecture
	{"name": "Floor_Tile", "path": "res://assets/models/environments/modular_kit/Architecture/Floor-Tile.glb", "scale": 1.0, "offset": Vector3(0, 0, 0), "solid": false},
	{"name": "Pillar_Wall", "path": "res://assets/models/environments/modular_kit/Architecture/Pillar.glb", "scale": 0.92, "offset": Vector3(0, 0.14, 0), "solid": true},
	{"name": "Wall_Module", "path": "res://assets/models/environments/modular_kit/Architecture/Wall-Module.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": true},
	{"name": "Corner_Wall", "path": "res://assets/models/environments/modular_kit/Architecture/Corner-Wall.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": true},
	{"name": "Door_Frame", "path": "res://assets/models/environments/modular_kit/Architecture/Door-Frame.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": true},
	{"name": "Platform_Module", "path": "res://assets/models/environments/modular_kit/Architecture/Platform-Module.glb", "scale": 1.0, "offset": Vector3(0, 0, 0), "solid": false},
	{"name": "Railing_Module", "path": "res://assets/models/environments/modular_kit/Architecture/Railing-Module.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": true},
	{"name": "Stair_Module", "path": "res://assets/models/environments/modular_kit/Architecture/Stair-Module.glb", "scale": 1.0, "offset": Vector3(0, 0, 0), "solid": false},
	
	# Gameplay Mechanics
	{"name": "Core_Pedestal", "path": "res://assets/models/gameplay/Core/Core-Pedestal.glb", "scale": 0.96, "offset": Vector3(0, 0.14, 0), "solid": false},
	{"name": "Energy_Core", "path": "res://assets/models/gameplay/Core/Energy-Core.glb", "scale": 0.80, "offset": Vector3(0, 0.45, 0), "solid": true},
	{"name": "Memory_Fragment", "path": "res://assets/models/gameplay/Core/Memory-Fragment.glb", "scale": 0.85, "offset": Vector3(0, 0.35, 0), "solid": false},
	{"name": "Pressure_Plate", "path": "res://assets/models/gameplay/Mechanisms/Pressure-Plate.glb", "scale": 1.0, "offset": Vector3(0, 0.08, 0), "solid": false},
	{"name": "Door", "path": "res://assets/models/gameplay/Mechanisms/Door.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": true},
	{"name": "Bridge", "path": "res://assets/models/gameplay/Mechanisms/Bridge.glb", "scale": 1.0, "offset": Vector3(0, 0.08, 0), "solid": false},
	{"name": "Portal", "path": "res://assets/models/gameplay/Mechanisms/Portal.glb", "scale": 1.0, "offset": Vector3(0, 0.08, 0), "solid": false},
	{"name": "Elevator", "path": "res://assets/models/gameplay/Mechanisms/Elevator.glb", "scale": 1.0, "offset": Vector3(0, 0.08, 0), "solid": false},
	{"name": "Conveyor", "path": "res://assets/models/gameplay/Mechanisms/Conveyor.glb", "scale": 1.0, "offset": Vector3(0, 0.08, 0), "solid": false},
	{"name": "Switch", "path": "res://assets/models/gameplay/Interaction/Switch.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": true},
	{"name": "Terminal", "path": "res://assets/models/gameplay/Interaction/Terminal.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": true},
	
	# Archive & Tech Props
	{"name": "Data_Storage_Rack", "path": "res://assets/models/props/Archive_Tech/Data-Storage-Rack.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": true},
	{"name": "Archive_Shelf", "path": "res://assets/models/props/Archive_Tech/Archive-Shelf.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": true},
	{"name": "Archive_Workbench", "path": "res://assets/models/props/Archive_Tech/Archive-Workbench.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": true},
	{"name": "Hologram_Projector", "path": "res://assets/models/props/Archive_Tech/Hologram-Projector.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": false},
	
	# Industrial Props
	{"name": "Cargo_Crate", "path": "res://assets/models/props/Industrial/Cargo-Crate.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": true},
	{"name": "Machine_Unit", "path": "res://assets/models/props/Industrial/Machine-Unit.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": true},
	{"name": "Pipe_Cluster", "path": "res://assets/models/props/Industrial/Pipe-Cluster.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": false},
	{"name": "Cable_Coil", "path": "res://assets/models/props/Industrial/Cable-Coil.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": false},
	{"name": "SciFi_Lamp", "path": "res://assets/models/props/Industrial/SciFi-Lamp.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": true},
	
	# Ruins & Nature
	{"name": "Broken_Wall", "path": "res://assets/models/environments/modular_kit/Ruins/Broken-Wall.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": true},
	{"name": "Broken_Pillar", "path": "res://assets/models/environments/modular_kit/Ruins/Broken-Pillar.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": true},
	{"name": "Broken_Robot", "path": "res://assets/models/props/Ruins/Broken-Robot.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": true},
	{"name": "Debris_Pile", "path": "res://assets/models/props/Ruins/Debris-Pile.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": false},
	{"name": "Rubble_Patch", "path": "res://assets/models/environments/modular_kit/Ruins/Rubble-Patch.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": false},
	{"name": "Moss_Patch", "path": "res://assets/models/props/Nature/Moss-Patch.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": false},
	{"name": "Plant_Cluster", "path": "res://assets/models/props/Nature/Plant-Cluster.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": false},
	{"name": "Rock_Cluster", "path": "res://assets/models/props/Nature/Rock-Cluster.glb", "scale": 1.0, "offset": Vector3(0, 0.14, 0), "solid": true},
]


func _run() -> void:
	print("==================================================")
	print("  [The Last Resonance] Building 3D GridMap MeshLibrary  ")
	print("==================================================")
	
	var dir := DirAccess.open("res://")
	if not dir.dir_exists("res://resources/mesh_libraries"):
		dir.make_dir_recursive("res://resources/mesh_libraries")
	
	var mesh_library := MeshLibrary.new()
	var item_id := 0
	
	for entry in CATALOG:
		var item_name: String = entry["name"]
		var model_path: String = entry["path"]
		
		if not ResourceLoader.exists(model_path):
			print("[-] Missing asset: ", model_path)
			continue
		
		var scene := load(model_path) as PackedScene
		if not scene:
			continue
		
		var instance := scene.instantiate() as Node3D
		var mesh_instance := _find_mesh_instance(instance)
		if not mesh_instance or not mesh_instance.mesh:
			instance.free()
			continue
		
		var mesh: Mesh = mesh_instance.mesh.duplicate()
		var item_transform := Transform3D.IDENTITY
		var scale_factor: float = float(entry.get("scale", 1.0))
		item_transform = item_transform.scaled(Vector3.ONE * scale_factor)
		var offset_pos: Vector3 = entry.get("offset", Vector3.ZERO)
		item_transform.origin = offset_pos
		
		mesh_library.create_item(item_id)
		mesh_library.set_item_name(item_id, item_name)
		mesh_library.set_item_mesh(item_id, mesh)
		mesh_library.set_item_mesh_transform(item_id, item_transform)
		
		# Collision shape for solid items
		if bool(entry.get("solid", false)):
			var shape := BoxShape3D.new()
			shape.size = Vector3(0.96, 0.96, 0.96)
			var shape_tf := Transform3D.IDENTITY
			shape_tf.origin = Vector3(0, 0.48, 0)
			mesh_library.set_item_shapes(item_id, [shape, shape_tf])
		
		print("[+] Item #%02d: %-20s (scale: %.2f)" % [item_id, item_name, scale_factor])
		item_id += 1
		instance.free()
	
	var err := ResourceSaver.save(mesh_library, OUTPUT_PATH)
	if err == OK:
		print("--------------------------------------------------")
		print("[SUCCESS] MeshLibrary generated: ", OUTPUT_PATH)
		print("Total items registered: ", item_id)
		print("==================================================")
	else:
		print("[ERROR] Failed to save MeshLibrary: ", err)


func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _find_mesh_instance(child)
		if found:
			return found
	return null
