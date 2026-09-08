# Âm thanh môi trường

**Đã gắn.** Loop chương + loop chi tiết (nhỏ hơn). Plate dùng clip Press/Release riêng. Không đổi puzzle.

| Chapter | Base loop | Detail loop | Detail level |
| --- | --- | --- | ---: |
| I — Archive | `AMB_Archive_Base_Loop` | `AMB_Electrical_Hum_Loop` | -24 dB |
| II — Foundry | `AMB_Foundry_Base_Loop` | `AMB_Machinery_Distant_Loop` | -21 dB |
| III — Sanctuary | `AMB_Sanctuary_Base_Loop` | `AMB_Water_Current_Loop` | -22 dB |
| IV — Central Core | `AMB_Core_Reactor_Loop` | `AMB_Electrical_Hum_Loop` | -25 dB |

Pressure plates now use the authored `SFX_PressurePlate_Press` and `SFX_PressurePlate_Release` clips instead of pitching the Core insert sound. The detail player follows the same Music bus, settings and mute state as the base ambience; it is stopped/restarted together with the base loop.

## Verification

```powershell
godot --headless --path . tests/verify_audio_profiles.tscn
```

This pass reuses existing WAV files, adds no new asset files, and does not alter level routes, entity positions or puzzle rules.
