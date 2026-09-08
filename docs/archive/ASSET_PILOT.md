# Pilot tích hợp vật thể vào gameplay

> **Bản ghi lịch sử.** Từ 2026-09-08, `tools/validate_asset_pilot.py` không còn là
> release gate: validator vẫn khóa roster pilot cũ, trong khi dressing/identity pass
> đã thay `kit_rail_end_reverse` ở L2, `foundry_furnace` ở L6 và `core_wall` ở L14.
> Trạng thái hiện hành dùng `tools/validate_map_decorations.py` và các verify props,
> modular, material, dynamics; xem [README hiện hành](../README.md#kiểm-tra).

Đợt này đã đưa bộ vật thể mới vào bốn màn đại diện trong campaign. Các thay đổi chỉ nằm ở `decorations`; không thêm entity, không đổi map ASCII, không đổi route/par và không thêm loại decoration có collision trong `GameLogic`.

| Màn | Mục tiêu quan sát | Vật thể thử |
| --- | --- | --- |
| Level 2 — Góc lưu trữ | Mép sàn, lan can và góc viền trong không gian Archive | `kit_floor_edge`, `kit_rail_straight`, `kit_floor_corner` |
| Level 6 — Khuôn đúc K-Series | Ống nối và một landmark Foundry cạnh biên | `kit_pipe_straight`, `kit_pipe_elbow`, `foundry_furnace` |
| Level 11 — Giao thức im lặng | Hồ nông và bờ ghép ở tầng thấp, trong khi puzzle vẫn có hai tầng | `kit_water_edge`, `kit_water_corner`, `kit_water_tile` |
| Level 14 — Lời thú nhận của EVA | Mép sàn/lan can tầng trên và mảng tường Core | `kit_floor_edge`, `kit_rail_straight`, `core_wall` |

Các ô pilot được chọn đều là ô đi được, không trùng entity puzzle. Vật thể modular chỉ là hình ảnh; ô đi được vẫn do map và `GameLogic` quyết định. Điều này cho phép đánh giá độ che khuất mà không thay đổi nghiệm Sokoban.

## Ảnh render

Pilot ban đầu đã được thay bằng campaign visual review mới. Capture hiện ghi artifact tái tạo được vào `.codex_qa/visual_polish/` thay vì `docs/`:

```powershell
godot --path . --resolution 1280x720 tests/asset_pilot_capture.tscn -- --level=2
godot --path . --resolution 1280x720 tests/asset_pilot_capture.tscn -- --level=6
godot --path . --resolution 1280x720 tests/asset_pilot_capture.tscn -- --level=11
godot --path . --resolution 1280x720 tests/asset_pilot_capture.tscn -- --level=14
```

The capture scene instantiates `scenes/game/main.tscn`, so camera, BoardView, chapter lighting and multi-floor setup are the same runtime paths as gameplay. It hides only the story intro/dialogue overlay for a clean visual check.

Capture renderer thật hiện chạy thành công bằng Vulkan `Forward Mobile` trên Intel Iris Xe. E1/E2 và campaign visual-polish đã được xem trong camera gameplay; xem [VISUAL_POLISH_PASS.md](../VISUAL_POLISH_PASS.md). Headless vẫn chỉ dùng regression, không dùng làm bằng chứng bố cục.

## Kết quả kiểm tra tại thời điểm pilot

```powershell
python tools/validate_asset_pilot.py
python tools/validate_levels.py
godot --headless --path . -s tests/verify.gd
godot --headless --path . tests/verify_interactions.tscn
```

Pilot validator từng kiểm tra bốn màn có đúng nhóm vật thể, mọi ô pilot là ô đi được
và không chồng entity. Sau các pass hình ảnh tiếp theo, roster cụ thể này không còn là
nguồn chuẩn; xem cảnh báo đầu tài liệu. Solver/validator campaign vẫn phải xác nhận 15
màn đạt par. Verifier Godot kiểm tra thêm save, input, undo, multi-floor và interaction.

Runtime headless vẫn khóa đường spawn thật qua `tests/asset_pilot_runtime.tscn`. Lỗi water-material từng tạo `material null` đã được sửa ở BoardView bằng surface override chọn lọc; các capture Sanctuary Vulkan hiện chạy sạch lỗi này.

## Nhận xét sau pilot

Pilot đã hoàn thành vai trò của nó: material profile, campaign dressing, environment dynamics và visual review toàn campaign đều đã được triển khai sau đó. Tài liệu hiện hành cho quyết định hình ảnh là [VISUAL_POLISH_PASS.md](../VISUAL_POLISH_PASS.md); Android hardware benchmark vẫn là bước xác nhận còn thiếu.
