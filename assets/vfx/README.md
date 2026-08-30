# Godot VFX

The Unity VFX prefabs are represented by native Godot nodes in
`src/view/vfx_manager.gd` rather than copied as Unity `.prefab` files.

Implemented gameplay effects:

- persistent Core glow and Portal rings;
- footstep dust and blocked-move sparks;
- push impact;
- Core/Goal activation;
- door unlock;
- portal and elevator bursts;
- bridge feedback;
- level-complete burst.

The effects use `GPUParticles3D`, `TorusMesh`, `SphereMesh`, emissive
`StandardMaterial3D`, and tweens, so they remain compatible with the project's
mobile renderer without external textures.
