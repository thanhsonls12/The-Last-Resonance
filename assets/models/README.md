# Game-ready 3D assets

The Blender output library has been converted to GLB and distributed by asset
role so Godot can import and use it directly:

- `animations/` — character animation-library GLBs.
- `characters/` — Kiro, EVA, and Dr. Elias character GLBs.
- `environments/chapters/` — chapter asset rosters.
- `environments/modular_kit/` — modular architecture and ruins pieces.
- `props/` — decorative archive, industrial, nature, and ruins props.
- `gameplay/` — core, interaction, and mechanism objects.
- `../materials/Material_Texture_Library.glb` — material-library preview scene.

The runtime character is `res://assets/models/animations/Kiro_K7/Kiro_K7_Animation_Library.glb`,
using the Kiro animation-library export as the primary model. The standalone
character GLB remains available as a non-runtime export. The rigged character remains available as
`res://assets/models/characters/Kiro_K7_rigged.glb` for a future animated
variant.

To repeat the export with the same layout:

```text
blender --background --python tools/convert_blend_assets.py -- <source-root> <project-root>
```
