class_name ChapterVisuals
extends Resource

## Per-chapter lighting profile for the gameplay scene. Chapter 1 is the cold
## archive, chapter 2 the warm foundry, and chapter 3 the teal Flooded Sanctuary.
## Loaded by src/game/main.gd.

@export var background: Color = Color(0.002, 0.003, 0.006)
@export var ambient: Color = Color(0.14, 0.20, 0.31)
@export var fog: Color = Color(0.04, 0.08, 0.14)
@export var fog_awake: Color = Color(0.08, 0.16, 0.26)
@export var key: Color = Color(0.52, 0.74, 0.98)
@export var fill: Color = Color(0.58, 0.22, 0.34)
@export var wash: Color = Color(0.38, 0.54, 0.76)
## (unpowered, powered) ranges for each light/env channel, lifted by power_level.
@export var ambient_range: Vector2 = Vector2(0.20, 0.42)
@export var fog_energy_range: Vector2 = Vector2(0.40, 0.70)
@export var key_range: Vector2 = Vector2(0.38, 0.68)
@export var fill_range: Vector2 = Vector2(0.12, 0.24)
@export var wash_range: Vector2 = Vector2(0.22, 0.42)
## (ambient, key, fill) energies the sector tweens to on win.
@export var powered: Vector3 = Vector3(0.92, 1.72, 0.48)
