# The Last Resonance audio

The WAV library was transferred from the Unity Sokoban project and is kept in
two runtime groups:

- `ambience/` — 10 chapter and environmental loops.
- `sfx/` — 84 player, puzzle, VFX, and UI effects.

`music/` holds six tracks: three menu/gameplay/ending beds plus three
chapter-scoped tracks (`BGM_Candlepower`, `BGM_Divider`, `BGM_Kaleetan_Full`).
`voice/` holds the Chapter I spoken lines.

`src/data/audio_catalog.gd` is the asset registry — it maps every gameplay key
to an imported clip, plus the chapter → music and chapter → ambience tables.
`src/view/audio_manager.gd` owns playback lifecycle: buses, fading, one-shot
rotation, looping and settings. Chapters 2–4 have no recorded voice yet, so
those lines fall back to `play_voice_blip()`; see
`docs/AUDIO_ENVIRONMENT_PASS.md` for the current wiring.
