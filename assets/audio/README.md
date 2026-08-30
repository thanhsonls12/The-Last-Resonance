# The Last Resonance audio

The WAV library was transferred from the Unity Sokoban project and is kept in
two runtime groups:

- `ambience/` — 10 chapter and environmental loops.
- `sfx/` — 76 player, puzzle, VFX, and UI effects.

`src/view/audio_manager.gd` maps the gameplay events to the imported clips and
selects the chapter ambience from `LevelData.chapter`.
