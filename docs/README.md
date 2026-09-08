# Tài liệu — The Last Resonance

Godot 4.7 · 15 màn · 4 chương · tối ưu cảm ứng Android.

**Cập nhật trạng thái:** 2026-09-08.

**Đã xong:** campaign; save có phục hồi/migration; unlock tới ending; chấm sao và
phí gợi ý; kit map; dressing; environment dynamics; visual review desktop; APK debug
qua preflight.

**Còn lại:** playtest máy Android thật (chạm, focus, cỡ màn, FPS, nhiệt, RAM và
thời gian tải). Bốn cluster prefab đã đạt kiểm tra hình học/metadata nhưng vẫn cần
visual camera review trước khi tái sử dụng trong campaign.

![Năm landmark truyện](NARRATIVE_LANDMARK_PREVIEW.png)

## Chiến dịch

| Ch | Màn | Khu | Dạy | Par hiện tại |
| --- | ---: | --- | --- | --- |
| I | 1–4 | Forgotten Archive | Đẩy Core → thứ tự → cửa | 12 / 28 / 34 / 53 |
| II | 5–8 | Mechanical Foundry | Siết cửa; L7 cầu; L8 tổng hợp | 57 / 73 / 75 / 87 |
| III | 9–12 | Flooded Sanctuary | Portal → Elevator → tổng hợp | 46 / 42 / 61 / 85 |
| IV | 13–15 | Central Core | Energy Node → nhịp EVA → phán quyết | 40 / 28 / 81 |

Hai tầng (thang một chiều): **L11, L12, L14**. Spec: [LEVEL_MAP_BLUEPRINT.md](LEVEL_MAP_BLUEPRINT.md) · [MULTI_FLOOR_LEVEL_GUIDE.md](MULTI_FLOOR_LEVEL_GUIDE.md).

## Kit hình

| Bộ | Số | Ảnh | Spec |
| --- | ---: | --- | --- |
| Chapter props + identity | 23 | [preview](CHAPTER_PROPS_PREVIEW.png) | [CHAPTER_MAP_PROPS.md](CHAPTER_MAP_PROPS.md) |
| Modular kit | 20 | [preview](MODULAR_KIT_PREVIEW.png) | [MODULAR_MAP_KIT.md](MODULAR_MAP_KIT.md) |
| Cluster prefab editor | 4 | — | [MAP_CLUSTERS.md](MAP_CLUSTERS.md) |
| Narrative landmarks | 5 | trên | cùng [CHAPTER_MAP_PROPS](CHAPTER_MAP_PROPS.md) |

MeshLibrary: **79** item. Scenery không thêm collision; puzzle do `resources/levels/*.tres`.

![Chapter props](CHAPTER_PROPS_PREVIEW.png)

![Modular kit](MODULAR_KIT_PREVIEW.png)

## Runtime

| Chủ đề | File |
| --- | --- |
| Vật liệu / weathering theo chương | [CHAPTER_MATERIAL_PASS.md](CHAPTER_MATERIAL_PASS.md) |
| Ambience + SFX plate | [AUDIO_ENVIRONMENT_PASS.md](AUDIO_ENVIRONMENT_PASS.md) |
| Visual desktop (đã review 15 màn) | [VISUAL_POLISH_PASS.md](VISUAL_POLISH_PASS.md) |
| Render mobile (bỏ glow/sao/nhiều đèn) | [MOBILE_RENDER_PASS.md](MOBILE_RENDER_PASS.md) |
| Export APK | [ANDROID_EXPORT_PREFLIGHT.md](ANDROID_EXPORT_PREFLIGHT.md) |
| Kiểm kê file | [ASSET_INVENTORY.md](ASSET_INVENTORY.md) |

JSON bake (test đọc): `CHAPTER_IDENTITY_PROPS_BOUNDS.json`, `MODULAR_KIT_BOUNDS.json`, `MAP_CLUSTER_CATALOG.json`.

Save hiện dùng `src/core/progress_store.gd` để kiểm tra dữ liệu, phục hồi bản dự
phòng và migrate tiến độ cũ. `src/core/score_rules.gd` tách riêng ngưỡng 1–3 sao:
phí gợi ý không tăng bước thật hay thay par, nhưng được cộng vào `score_moves`.

## Kiểm tra

Snapshot 2026-09-08 trên Godot 4.7.2:

| Nhóm | Kết quả |
| --- | --- |
| Solver/par `validate_levels.py` | PASS — 15/15 màn giải được, par khớp route tối ưu |
| Godot `tests/verify*.gd` | PASS — 16/16 nhóm regression |
| Placement `validate_map_decorations.py` | PASS — 295 decoration, 15 màn |
| Asset audit `audit_assets.py` | PASS — 287 file, không có literal reference bị thiếu |
| Android `validate_android_export.py` | PASS — APK arm64 63.010.089 byte, 777 entry |

Các lệnh cốt lõi:

Yêu cầu Python 3 và Godot 4.7.x có trong `PATH` dưới tên `godot` (`godot.exe`
trên Windows cũng được PowerShell tự nhận).

```powershell
python tools/validate_levels.py
godot --headless --path . -s tests/verify.gd
godot --headless --path . tests/verify_interactions.tscn
python tools/validate_map_decorations.py
python tools/audit_assets.py
python tools/validate_android_export.py
```

Để chạy toàn bộ regression Godot, mỗi file `tests/verify*.gd` có `.tscn` cùng tên
được chạy bằng scene; các script `extends SceneTree` còn lại chạy với `-s`.

`tools/validate_asset_pilot.py` là validator của roster pilot ban đầu và hiện **không
phải release gate**: nó vẫn đòi ba prop đã được thay trong dressing mới ở L2/L6/L14.
Placement tổng thể hiện được khóa bằng `validate_map_decorations.py` cùng các verify
props, modular kit, material, dynamics và visual review. Chi tiết lịch sử:
[archive/ASSET_PILOT.md](archive/ASSET_PILOT.md).

Capture visual (cần cửa sổ, ghi `.codex_qa/visual_polish/`): `tests/asset_pilot_capture.tscn`, `tests/narrative_map_capture.tscn`.

Pass cũ: [archive/](archive/README.md).
