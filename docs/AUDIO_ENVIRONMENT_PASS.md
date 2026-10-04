# Âm thanh môi trường và nhạc theo chương

**Đã gắn.** Loop chương + loop chi tiết (nhỏ hơn). Plate dùng clip Press/Release riêng. Không đổi puzzle.

| Chapter | Base loop | Detail loop | Detail level | Accent loop |
| --- | --- | --- | ---: | --- |
| I — Archive | `AMB_Archive_Base_Loop` | `AMB_Electrical_Hum_Loop` | -24 dB | `AMB_Wind_Corridor_Loop` |
| II — Foundry | `AMB_Foundry_Base_Loop` | `AMB_Machinery_Distant_Loop` | -21 dB | `AMB_Foundry_Furnace_Loop` |
| III — Sanctuary | `AMB_Sanctuary_Base_Loop` | `AMB_Water_Current_Loop` | -22 dB | `AMB_Water_Drip_Loop` |
| IV — Central Core | `AMB_Core_Reactor_Loop` | `AMB_Electrical_Hum_Loop` | -25 dB | `AMB_Wind_Corridor_Loop` |

Pressure plates use the authored `SFX_PressurePlate_Press` and `SFX_PressurePlate_Release` clips. The detail player follows the same Music bus, settings and mute state as the base ambience; it is stopped/restarted together with the base loop.

## Nhạc nền theo chương

`AudioCatalog.CHAPTER_BGM` ánh xạ chương → track, `EchoAudioManager.set_bgm_for_chapter()`
chọn nhạc khi nạp màn. Bốn chương dùng bốn track khác nhau nên tiến trình chiến dịch
nghe được, thay vì lặp một loop cho cả 15 màn.

| Chapter | Track |
| --- | --- |
| I — Archive | `BGM_Candlepower.ogg` |
| II — Foundry | `bgm_gameplay_main.ogg` |
| III — Sanctuary | `BGM_Divider.ogg` |
| IV — Central Core | `BGM_Kaleetan_Full.ogg` |

Menu và ending dùng `EchoAudioManager.create_scene_bgm()`, thay cho việc mỗi scene tự
tạo `AudioStreamPlayer` riêng. Ba scene đó trước đây phát nhạc **không loop** (`.ogg`
import với `loop=false`) nên nhạc tắt sau một lượt; nay `_looped_bgm()` bật loop lúc
chạy và duplicate stream, không sửa resource đã import.

## SFX gameplay

Catalog đăng ký đầy đủ clip đã có trên đĩa. Các clip trước đây bỏ không nay được nối:

| Ngữ cảnh | Clip |
| --- | --- |
| Bắt đầu màn | `SFX_Level_Start` |
| Core vào đích | `SFX_Goal_Lock` |
| Cửa khóa | `SFX_Door_Locked` |
| Portal | `SFX_Portal_Charge` |
| Plate / công tắc | `SFX_Switch_Toggle_On` / `_Off` |
| Terminal | `SFX_Terminal_On` / `SFX_Terminal_Error` |
| Feedback người chơi | `SFX_Player_Push_Start`, `_Turn`, `_Interact`, `_Success_Beep` |
| UI | `SFX_UI_Back`, `SFX_UI_Resume` |

`SFX_Level_Fail` **cố ý không dùng**: game không có trạng thái thua, người chơi Undo
hoặc Restart. `&"ui_focus"` trước đây được `memory_codex.gd` gọi nhưng thiếu trong
catalog (im lặng, không phát gì); nay đã ánh xạ tới `SFX_UI_Hover`.

Không có trạng thái thua nên không cần âm thất bại; các cơ chế conveyor/checkpoint/
debris cũng chưa có trong campaign nên helper đã có sẵn nhưng chưa gọi.

## Verification

```powershell
godot --headless --path . tests/verify_audio_profiles.tscn
```

Test kiểm tra: ambience theo chương + accent 4/4 chương, 24 SFX mới đăng ký, 4 track
nhạc chương phân biệt, loop được bật lúc chạy và resource import không bị sửa.

Pass này tái sử dụng file WAV/OGG đã có, không thêm asset mới, và không đổi route,
vị trí entity hay luật puzzle.
