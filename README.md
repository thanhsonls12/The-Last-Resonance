# The Last Resonance

> **Trạng thái**: Chương I (Forgotten Archive) hoàn chỉnh với 4 level gameplay, hệ thống hội thoại, ký ức (Memory Codex), giao diện HUD tích hợp icon SVG, hiệu ứng Hologram EVA 3D và 3 phân nhánh kết thúc (Endings).

Game giải đố Sokoban 3D/Isometric phong cách Sci-Fi xây dựng trên **Godot 4.7** và **GDScript**. Trò chơi kết hợp giữa cơ chế giải đố logic chuẩn xác (deterministic) và không khí khám phá trạm không gian/khu tàng thư cổ hoang tàn Asteria.

---

## 📱 Trải nghiệm & Điều khiển Cảm ứng (Mobile / Android)

Trò chơi được thiết kế tối ưu hóa 100% cho thao tác chạm và vuốt trên màn hình cảm ứng Android:

* **Chạm vào ô (Tap-to-Move)**: Chạm vào bất kỳ ô hợp lệ nào trên mặt sàn để robot Kiro tự động di chuyển hoặc đẩy khối Core.
* **Vuốt màn hình (Swipe Gesture)**: Vuốt ngang sang trái / phải để xoay góc nhìn camera 90°, giúp quan sát toàn cảnh 3D và các góc khuất của câu đố.
* **Hệ thống nút bấm HUD cảm ứng**:
  * **Hoàn tác (`undo.svg`)**: Lùi lại một bước đi trước đó.
  * **Chơi lại (`restart.svg`)**: Đặt lại màn chơi về trạng thái ban đầu.
  * **Xoay cầu (`bridge.svg`)**: Kích hoạt cơ chế xoay cầu khi đứng tại vị trí điều khiển.
  * **Tạm dừng (`pause.svg`)**: Mở bảng tùy chọn, bật/tắt nhanh âm thanh hoặc thoát về menu.

*(Dành cho lập trình viên khi test nhanh trên máy tính trong Godot Editor: Có thể dùng `WASD` để đi, `Q`/`E` xoay camera, `Z` undo, `R` restart).*

---

## 🧩 Cấu trúc Hệ thống & Tính năng

### 1. Gameplay & Core Logic
* **`src/core/game_logic.gd`**: Engine xử lý luật Sokoban deterministic, quản lý ngăn xếp Undo/Redo, cửa khóa liên động (interlocking gates), cầu xoay, cổng dịch chuyển, thang máy và điều kiện hoàn thành.
* **`src/core/game_state.gd`**: Autoload toàn cục lưu trữ tiến độ mở khóa màn chơi, số bước kỷ lục, mảnh ký ức thu thập và cấu hình âm thanh/độ nhạy.
* **`src/data/levels.gd` & `src/data/level_data.gd`**: Hệ thống định nghĩa dữ liệu màn chơi độc lập thông qua các file Resource `.tres`.

### 2. Giao diện (UI / UX)
* **Start Menu (`scenes/ui/start_menu.tscn`)**: Menu chính phong cách Sci-Fi với nền artwork Asteria, hỗ trợ tiếp tục nhanh, chọn màn, đọc ký ức, cài đặt và thoát.
* **Level Select (`scenes/ui/menu.tscn`)**: Danh sách màn chơi trực quan kèm thông tin độ khó, kỷ lục số bước đẩy.
* **In-Game HUD (`src/view/game_hud.gd`)**: Giao diện trong màn chơi hiển thị tiến độ khóa liên động, bước đi, mảnh ký ức; tích hợp đầy đủ bộ icon SVG cho các nút Hoàn tác, Chơi lại, Xoay cầu, Menu, Tạm dừng, Âm thanh và Modal Chiến thắng.
* **Dialogue Box (`scenes/ui/dialogue_box.tscn`)**: Khung hội thoại tương tác giữa Kiro, EVA và Dr. Elias Vale với hiệu ứng typewriter, avatar 2D, âm bleep và glitch.
* **Memory Codex (`scenes/ui/memory_codex.tscn`)**: Kho lưu trữ bản thảo ký ức để người chơi đọc lại các lore/mẩu truyện đã thu thập.
* **Ending Cutscene (`scenes/ui/ending_cutscene.tscn`)**: Cảnh kết cốt truyện với 3 phân nhánh kết thúc (Preserve, Release, Restore).

### 3. Đồ họa 3D & Nhân vật
* **Kiro-K7 (`Kiro_K7_Animation_Library.glb`)**: Robot nhân vật chính có gắn xương (rig) và thư viện chuyển động, phản hồi phát sáng khi đẩy năng lượng.
* **EVA (`EVA_v5.glb`)**: Trí tuệ nhân tạo AI Hologram 3D xuất hiện trực tiếp trên bàn chơi khi có hội thoại/gợi ý kèm Hologram Shader (`assets/shaders/hologram_eva.gdshader`).
* **Hiệu ứng & Âm thanh**: `vfx_manager.gd` (bụi di chuyển, tia lửa, hào quang chiến thắng) và `audio_manager.gd` (hệ thống âm thanh ambience đa kênh theo từng chương và bộ SFX cơ chế).

### 4. Công cụ Biên tập & Kiểm thử (Tools)
* **GridMap Level Editor (`scenes/editor/gridmap_level_editor.tscn`)**: Bộ công cụ thiết kế màn chơi trực quan trong Godot Editor.
* **Headless Test (`tests/verify.gd`)**: Script kiểm tra tự động replay lời giải của cả 4 level để xác minh tính toàn vẹn của logic game.

---

## 📁 Sơ đồ Cây Thư mục

```text
The Last Resonance/
├── assets/
│   ├── audio/              # Nhạc nền Ambience và bộ hiệu ứng SFX
│   ├── icons/              # Icon game và icon xuất bản Android
│   ├── materials/          # Shader và vật liệu PBR
│   ├── models/             # 3D Model: characters, animations, modular kit, props
│   ├── shaders/            # Shader Hologram EVA, glitch, v.v.
│   └── ui/                 # Avatar nhân vật, icon SVG và background art
├── resources/
│   └── levels/             # Resource dữ liệu .tres của các level
├── scenes/
│   ├── editor/             # Scene công cụ Level Editor
│   ├── game/               # Scene Gameplay chính và Ending Cutscene
│   └── ui/                 # Các scene Menu, HUD, Settings, Dialogue, Codex
├── src/
│   ├── core/               # GameLogic, GameState (Luật chơi & Save)
│   ├── data/               # Cấu trúc dữ liệu Level & Story
│   ├── game/               # Bộ điều khiển vòng đời màn chơi
│   ├── tools/              # GridMap Sync & MeshLibrary Builder
│   ├── ui/                 # Mã nguồn điều khiển các màn hình UI
│   └── view/               # BoardView, CameraController, GameHud, VFX & Audio
├── tests/
│   └── verify.gd           # Headless Verification Test
└── tools/                  # Các Python script hỗ trợ bake asset, rig model, validate
```

---

## 📱 Xuất bản Android

Dự án đã được cấu hình sẵn export preset cho Android:
1. Cấu hình Android SDK / JDK trong cài đặt Godot Editor.
2. Xuất bản thông qua menu `Project -> Export...` với preset `Android`.
3. File APK xuất ra tại: `build/TheLastResonance-debug.apk`.
