# Kiến trúc sau functional refactor

Ngày nghiệm thu: **2026-10-02**. Phạm vi refactor: cấu trúc code và ownership; không đổi luật puzzle, nội dung 15 màn hoặc par.

## 1. Vấn đề trước refactor

Ba file lớn ban đầu chứa nhiều trách nhiệm chồng nhau:

- `src/game/main.gd`: khoảng **1.288 dòng**, vừa điều phối scene vừa chứa hint recovery, tap/pathfinding, action result, elevator, story và global environment.
- `src/view/board_view.gd`: khoảng **2.110 dòng**, vừa dựng board/gameplay object vừa dựng environment, lighting, actor, decoration và runtime dynamics.
- `src/view/game_hud.gd`: khoảng **1.041 dòng**, vừa giữ API HUD vừa tự dựng toàn bộ status, controls, pause/win modal và responsive/accessibility styling.

Vấn đề chính không phải số dòng, mà là ownership khó xác định: một thay đổi nhỏ có thể chạm gameplay, presentation và lifecycle trong cùng file.

## 2. Kiến trúc sau refactor

Luồng gameplay hiện tại:

```text
GameplayInput / HUD
        |
        v
     main.gd  -----------------------------+
        |                                  |
        +--> PlayerNavigation              +--> StoryDirector
        +--> ActionExecution               +--> LevelFlow
        +--> GameCoordinator               +--> SceneEnvironmentController
        +--> HintManager                   +--> EchoAudioManager
        |
        v
     GameLogic
        |
        v
     BoardView (facade)
        |
        +--> BoardGeometry
        +--> BoardGameplayObjects
        +--> BoardDecorations
        +--> BoardActors
        +--> BoardLighting
        +--> BoardEnvironment
        +--> EnvironmentDynamics
```

HUD hiện là facade scene-composition:

```text
GameHud
  +--> HudStatusPanel
  +--> HudControls
  +--> HudPausePanel (.tscn)
  +--> HudWinPanel   (.tscn)
  +--> HudStyle
```

Audio và environment:

```text
AudioCatalog                = asset/config registry
EchoAudioManager            = playback + buses + loops
SceneEnvironmentController  = WorldEnvironment + directional lights
BoardLighting               = board-local lights/material power only
```

Nhờ đó global lighting không còn trộn với board-local lighting.

## 3. Ownership chính

| Module | Sở hữu | Không sở hữu |
| --- | --- | --- |
| `GameLogic` | state puzzle, move/push, door/bridge/elevator/energy, undo/win | Node, tween, HUD, audio |
| `PlayerNavigation` | tap target, pathfinding, approach/elevator plan | mutation gameplay |
| `ActionExecution` | gọi action domain và chuẩn hóa presentation plan | Board/HUD/audio/story |
| `GameCoordinator` | busy + session token, stale async guard | puzzle rule |
| `HintManager` | route/checkpoint/resync/recovery/penalty | UI/tự di chuyển |
| `StoryDirector` | trigger dialogue, chapter intro, story hologram, win skit | score/save |
| `LevelFlow` | current level data + logic instance + complete current run | presentation |
| `BoardView` | facade presentation công khai | luật puzzle |
| `SceneEnvironmentController` | global environment/directional lights/power/blackout | board geometry |
| `GameHud` | facade API/signals HUD | node detail của component |

## 4. Kết quả định lượng hỗ trợ báo cáo

Số dòng chỉ dùng như chỉ báo phụ:

| File | Trước | Sau refactor | Hiện tại (2026-10-02) |
| --- | ---: | ---: | ---: |
| `main.gd` | ~1.288 | **816** | **835** |
| `board_view.gd` | ~2.110 | **581** tại checkpoint RF-03 | **609** |
| `game_hud.gd` | ~1.041 | **157** | **173** |

Cột "Hiện tại" cao hơn checkpoint vì các pass hình ảnh, âm thanh và phòng thử sau
refactor bổ sung code vào facade và module — ranh giới sở hữu vẫn giữ nguyên.
Giá trị chính là giảm coupling và có owner rõ cho state/lifecycle/presentation, không phải đạt một số dòng mục tiêu.

## 5. Regression và validator

Chạy toàn bộ:

```powershell
python tools/run_tests.py
python tools/validate_levels.py
python tools/validate_map_decorations.py
```

Chạy theo nhóm:

```powershell
python tools/run_tests.py -g gameplay
python tools/run_tests.py -g ui
python tools/run_tests.py -g narrative
python tools/run_tests.py -g render
python tools/run_tests.py -g audio
```

Có thể kết hợp nhóm và test cụ thể; runner tự loại trùng:

```powershell
python tools/run_tests.py -g gameplay narrative -t verify_audio_profiles
```

Capture/generator không phải regression gate và vẫn được loại khỏi auto-discovery theo quy ước của `tools/run_tests.py`.

## 6. Bằng chứng nghiệm thu hiện tại

- Full Godot regression: **35/35 PASS** (xác nhận 2026-10-02 sau các pass asset,
  audio và phòng thử; 4 lần chạy `asset_pilot_runtime` tính theo level).
- Solver: **15/15 màn solvable; optimal = par**.
- Placement validator: **930 decorations / 15 màn**, bounded, entity-safe, landmark-backed.
- Asset audit: **329 file**, không có literal reference bị thiếu.
- Headless editor load được dùng để bắt parse/import errors.
- `.gitattributes` đã pin `*.gd/.tscn/.tres/.import/...` về LF; các file cũ được
  renormalize một lần nên working tree không còn diff CRLF giả.
- RF-07B được **Deferred có chủ đích**: `GameLogic` đã là `RefCounted` độc lập scene, chưa có lợi ích đủ rõ để tách parser/mechanics/state thêm.

## 7. Hạn chế còn lại

Headless regression không thay thế visual/audio review thực tế. Trước báo cáo/nộp cuối cùng vẫn nên chạy demo desktop và playtest Android thật cho touch target, focus, FPS, nhiệt, RAM, loading và audio mix.
