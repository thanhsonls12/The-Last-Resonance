# The Last Resonance

**Trạng thái (2026-10-02):** campaign đã có **15 level**, 4 chương và 3 nhánh kết
thúc. Refactor theo chức năng đã hoàn tất: `main.gd`, `board_view.gd` và `game_hud.gd`
được tách thành các module sở hữu rõ trách nhiệm (navigation, action execution,
hint, board geometry/decoration/actor/lighting, HUD scene composition, audio catalog,
scene environment) mà không đổi luật puzzle hay par. Các pass hình ảnh và âm thanh
đã áp dụng lên kiến trúc mới: kit dựng map bổ sung, sàn/tường theo chương, module
animation bake từ Blender, hoàn thiện Core/Foundry/landmark, ngoại cảnh sector, ánh
sáng dễ quan sát, nước chương 3, nhạc theo chương và phòng thử **Phòng Vọng Âm**.
Mọi thay đổi được xác nhận bằng **35/35 regression headless**, solver **15/15 màn
solvable và optimal = par**, placement **930 decoration** trên 15 màn, và asset audit
**329 file** không thiếu tham chiếu. APK debug đã qua preflight ở checkpoint trước
nhưng **chưa chạy lại sau refactor**.

Chưa có benchmark FPS, nhiệt, RAM hoặc cảm giác chạm trên thiết bị Android thật;
headless PASS không thay thế nghe nhạc, xem animation và chơi trên máy thật.

Game giải đố Sokoban 3D/isometric phong cách sci-fi, xây dựng bằng **Godot 4.7** và
**GDScript**. Người chơi điều khiển robot Kiro đẩy các Lumina Core trong trạm Asteria,
khám phá các lớp ký ức và quyết định số phận thành phố.

![Logo](assets/ui/logo_header_horizontal.jpg)

Tài liệu chi tiết: [docs/README.md](docs/README.md).

---

## Trải nghiệm & điều khiển cảm ứng (Mobile / Android)

Trò chơi hỗ trợ thao tác chạm và vuốt trên Android:

- **Chạm vào ô (Tap-to-Move):** chạm ô hợp lệ để Kiro đi hoặc đẩy Core.
- **Vuốt ngắn:** thực hiện một bước theo hướng camera.
- **Kéo giữ:** xoay góc nhìn yaw; trên PC dùng `Q`/`E` để xoay camera 90°.
- **Hoàn tác (`undo.svg`):** lùi lại một nước đi.
- **Chơi lại (`restart.svg`):** đặt level về trạng thái ban đầu.
- **Xoay cầu (`bridge.svg`):** kích hoạt cầu khi đứng cạnh console tương ứng.
- **Gợi ý:** hiển thị theo 3 cấp bằng `hint_route`; không tăng số bước thật/par nhưng
  hành động được tiết lộ sẽ cộng phí vào điểm tính sao.
- **Tạm dừng (`pause.svg`):** mở tùy chọn âm thanh, accessibility hoặc về menu.

Khi puzzle lệch khỏi đường gợi ý, HUD chỉ hướng phục hồi hoặc đề nghị Undo. Trên
Godot Editor/PC: `WASD` di chuyển, `Z` undo, `R` restart, `H` gợi ý.

---

## Chiến dịch hiện tại

| Chương | Level | Khu vực | Trọng tâm | Par |
| --- | ---: | --- | --- | --- |
| I — Archive | 1–4 | Forgotten Archive | Đẩy Core, thứ tự, cửa | 12 · 28 · 34 · 53 |
| II — Foundry | 5–8 | Mechanical Foundry | Cửa, cầu xoay, puzzle tổng hợp | 57 · 73 · 75 · 87 |
| III — Sanctuary | 9–12 | Flooded Sanctuary | Portal, Elevator, nhiều tầng | 46 · 42 · 61 · 85 |
| IV — Core | 13–15 | Central Core | Energy Node, phối hợp, phán quyết | 40 · 28 · 81 |

Level 11, 12 và 14 dùng hai tầng với Elevator một chiều: phải hoàn thành tầng hiện
tại trước khi lên tầng tiếp theo. Core không đi qua Elevator; Undo hoàn tác trọn thao
tác chuyển tầng.

---

## Cấu trúc hệ thống & tính năng

### 1. Gameplay & Core Logic

- `src/core/game_logic.gd`: engine Sokoban deterministic; Undo/Restart; Core,
  Pedestal, Plate/Door, cầu xoay, Portal, Elevator, Energy Node và điều kiện thắng.
- `src/game/player_navigation.gd`, `src/game/action_execution.gd`: tách tap/
  pathfinding và thứ tự thực thi hành động khỏi `main.gd`.
- `src/game/game_coordinator.gd`: sở hữu busy và token phiên, chặn thao tác cũ
  cập nhật scene mới.
- `src/core/game_state.gd`: autoload lưu unlock, thành tích, ký ức, âm lượng,
  haptics, reduced motion, high contrast và phần thưởng Phòng Vọng Âm.
- `src/core/progress_store.gd`: đọc/ghi save có kiểm tra dữ liệu, backup và migration
  từ định dạng cũ.
- `src/core/score_rules.gd`: ngưỡng 1–3 sao, `score_moves`, `hint_penalty` và cờ
  perfect cho từng level.
- `src/data/levels.gd` và `src/data/level_data.gd`: catalogue/schema level; dữ liệu
  map nằm trong các Resource `.tres`.

### 2. Giao diện (UI / UX)

- `scenes/ui/start_menu.tscn`: menu chính, Continue, chọn level, Memory Codex,
  Settings, **Phòng Vọng Âm** và thoát.
- `scenes/ui/menu.tscn`: level select theo chương, par, sao và kỷ lục.
- `src/view/game_hud.gd`: facade API/signal; `HudStatusPanel`, `HudControls`,
  `HudPausePanel` và `HudWinPanel` là scene composition cho từng vùng HUD.
- `scenes/ui/dialogue_box.tscn`: hội thoại Kiro, EVA, Dr. Elias với typewriter,
  avatar, bleep và glitch.
- `scenes/ui/memory_codex.tscn`: đọc lại 15 mảnh ký ức theo chương.
- `scenes/game/ending_cutscene.tscn`: ba ending `PRESERVE`, `RELEASE`, `RESTORE`.
- `scenes/game/tidal_trial.tscn`: phòng thử Phòng Vọng Âm, không nằm trong thứ tự
  15 màn chiến dịch.

### 3. Đồ họa 3D, nhân vật, hiệu ứng & âm thanh

- Kiro-K7: `assets/models/animations/Kiro_K7/Kiro_K7_Animation_Library.glb`.
- EVA: `assets/models/characters/EVA_v5.glb` và
  `assets/shaders/hologram_eva.gdshader`.
- Dr. Elias Vale: `assets/models/characters/Dr-Elias-Vale_v3.glb`.
- Board 3D là facade: `src/view/board_view.gd` uỷ quyền cho `board_geometry.gd`,
  `board_gameplay_objects.gd`, `board_decorations.gd`, `board_actors.gd`,
  `board_lighting.gd` và `board_environment.gd`.
- `src/view/module_motion.gd` và `src/data/module_motion_catalog.gd`: animation
  Blender và FX gắn theo model trong campaign.
- Ngoại cảnh và môi trường: `src/view/sector_exterior.gd`,
  `src/view/scene_environment.gd`, `src/view/environment_dynamics.gd`.
- Hiệu ứng gameplay: `src/view/vfx_manager.gd`; asset/config âm thanh:
  `src/data/audio_catalog.gd`; playback, bus và loop: `src/view/audio_manager.gd`.
- Material/render theo chương và mobile quality: `src/data/chapter_material_profiles.gd`
  và `src/data/render_quality.gd`.

### 4. Công cụ biên tập & kiểm thử

- `scenes/editor/gridmap_level_editor.tscn`: thiết kế level trong Godot Editor.
- `tests/verify.gd`: replay route, schema, par, save, score, Undo/Restart và
  progression của toàn campaign.
- `tools/run_tests.py`: chạy toàn bộ regression, tự phát hiện test và hỗ trợ
  nhóm `-g gameplay ui narrative render audio`.
- Các scene `tests/verify_*.tscn`: interaction, multi-floor, audio, material,
  decoration, modular runtime, narrative, HUD, map response, sector exterior,
  scenery clearance, lighting và mobile render budget.
- `tools/`: validator/baker Python và script dựng asset; `src/tools/` là công cụ
  chạy bên trong Godot Editor.

---

## Sơ đồ cây thư mục

```text
The Last Resonance/
├── art/                       # Nguồn authoring Blender cho GLB đã bake
│   ├── animated_modules/      # Clip animation module + originals/ trước khi bake
│   ├── asset_polish/          # Nguồn nâng cấp Core/Foundry/landmark
│   ├── echo_expansion/        # Nguồn model Phòng Vọng Âm
│   └── map_expansion/         # Nguồn kit dựng map bổ sung
├── assets/                    # Model, texture, shader, icon, font, audio và VFX
│   ├── audio/                 # Nhạc nền, ambience, SFX, voice
│   ├── fonts/                 # Font giao diện
│   ├── icons/                 # Icon ứng dụng/Android
│   ├── materials/             # Material dùng lại
│   ├── models/                # Nhân vật, environment, props, modular kit
│   ├── shaders/               # Hologram, module motion và shader môi trường
│   ├── textures/              # Texture đồ họa
│   ├── ui/                    # Logo, background, portrait, HUD art
│   └── vfx/                   # Asset hiệu ứng hình ảnh
├── resources/                 # Dữ liệu Resource tách khỏi code/scene
│   ├── levels/                # Nguồn chuẩn map, entity, par, hint_route
│   ├── mesh_libraries/        # MeshLibrary cho GridMap
│   ├── trials/                # Dữ liệu phòng thử ngoài chiến dịch
│   └── visuals/               # Profile hình ảnh theo chương
├── scenes/                    # Scene Godot chạy trong editor/runtime
│   ├── editor/                # Level editor, gallery, cluster/showcase
│   ├── game/                  # Gameplay chính, ending và phòng thử
│   └── ui/                    # Menu, HUD component, dialogue, codex, settings
├── src/                       # Mã GDScript
│   ├── core/                  # Luật puzzle, save/progress, score
│   ├── data/                  # Schema level, story, props, material, render, audio
│   ├── game/                  # Flow màn, navigation, action, hint, story
│   ├── tools/                 # Tool chạy trong Godot Editor
│   ├── ui/                    # Controller cho giao diện
│   └── view/                  # Board facade + component, camera, HUD, audio, VFX
├── tests/                     # Regression, smoke test runtime, capture QA
├── tools/                     # Validator/baker, runner test và công cụ thiết kế level
├── docs/                      # Tài liệu hiện hành, plan/ và archive các pass cũ
├── .github/workflows/         # CI chạy regression headless trên push/PR
├── project.godot              # Cấu hình dự án, input map, autoload
└── export_presets.cfg         # Preset export Android
```

`resources/levels/level_XX.tres` là nguồn chuẩn của gameplay. `.godot/`, `build/`
và `.codex_qa/` là cache/output/artifact sinh tự động, không phải nơi sửa logic game.
`art/` chứa nguồn Blender tham chiếu, không được Godot import (`.gdignore`).

---

## Xuất bản Android

Yêu cầu Python 3 và Godot 4.7.x có trong `PATH` dưới tên `godot` (`godot.exe` trên
Windows cũng được PowerShell nhận).

1. Cấu hình Android SDK/JDK trong Godot Editor.
2. Chọn `Project → Export → Android` với preset `Android`.
3. APK xuất tại `build/TheLastResonance-debug.apk`.

```powershell
godot --headless --path . --export-debug Android build/TheLastResonance-debug.apk
python tools/validate_android_export.py
```

Preflight kiểm tra preset arm64, PCK, manifest, zip integrity, chữ ký và loại trừ
thư mục development khỏi APK. Đây không thay thế playtest trên thiết bị Android thật.

---

## Kiểm tra nhanh

```powershell
python tools/validate_levels.py
python tools/run_tests.py
python tools/run_tests.py -g gameplay ui
python tools/validate_map_decorations.py
python tools/audit_assets.py
```

Kết quả kiểm thử và hướng dẫn đầy đủ: [docs/README.md](docs/README.md).
