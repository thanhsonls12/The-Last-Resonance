# Bộ vật thể dựng map theo chương

**23 loại** chapter-prop (15 roster + 8 identity nhỏ) + 5 landmark GLB riêng. MeshLibrary toàn project: **79** item. Scenery không collision.

![Cùng tỷ lệ](CHAPTER_PROPS_PREVIEW.png)

## Danh mục

| Chương | `type` trong LevelData | Vật thể | Vị trí sử dụng gợi ý |
| --- | --- | --- | --- |
| I | `archive_access_panel_broken` | Bảng truy cập hỏng | Wall cell nội thất; tạo cảm giác kho dữ liệu bị bỏ quên |
| I | `archive_storage_tray_low` | Khay lưu trữ thấp | Mép phòng/ô chặn thấp, không che Core |
| II | `foundry_furnace` | Lò nung | Cuối phòng, sau đường đi |
| II | `foundry_press` | Máy ép | Hai bên dây chuyền |
| II | `foundry_gear` | Bánh răng nằm | Bãi phế liệu hoặc bệ máy |
| II | `foundry_pipe_valve` | Ống và van | Sát tường công nghiệp |
| II | `foundry_lamp` | Đèn nhà máy | Mép phòng |
| II | `foundry_maintenance_box` | Hộp bảo trì | Góc bảo trì, cạnh máy chính |
| II | `foundry_pipe_support` | Giá đỡ ống | Điểm neo cho tuyến ống modular |
| III | `sanctuary_water_pool` | Bể nước và quả cầu | Điểm nhấn khu vực nước |
| III | `sanctuary_shrine` | Bệ thờ và tinh thể | Cuối trục nhìn |
| III | `sanctuary_tree` | Cây | Ngoài mép đường chơi |
| III | `sanctuary_vine_arch` | Vòm có dây leo | Hậu cảnh; không phải cửa đi qua |
| III | `sanctuary_rocks` | Cụm đá | Bờ khu vực ngập |
| III | `sanctuary_broken_plinth_low` | Trụ/bệ gãy thấp | Mép bờ hoặc foreground thấp |
| III | `sanctuary_bank_root` | Rễ bám bờ | Khe đá/bờ nước, không bò qua tuyến đẩy Core |
| IV | `core_reactor` | Lõi và bốn trụ | Điểm nhấn trung tâm hoặc cuối phòng |
| IV | `core_generator` | Máy phát | Hai bên phòng lõi |
| IV | `core_wall` | Tường có đường sáng | Biên phòng |
| IV | `core_hologram_dais` | Bệ hologram | Khu vực dữ liệu/EVA |
| IV | `core_portal_frame` | Khung cổng năng lượng | Hậu cảnh; không tự dịch chuyển nhân vật |
| IV | `core_data_cabinet_low` | Tủ dữ liệu thấp | Mép phòng lõi, nhịp hình học chính xác |
| IV | `core_light_trim` | Nẹp dẫn sáng thấp | Viền kiến trúc; emission phụ, không thay Energy Node |

Chương I vẫn tái sử dụng bộ Archive hiện có cho props lớn, nhưng Đợt B bổ sung hai silhouette nhỏ riêng để Chapter I không chỉ dựa vào asset generic. Các tên cốt truyện cũ như `sanctuary_pool` và `judgement_engine` vẫn giữ cách ánh xạ hiện tại.

## Dùng trong Godot

- `scenes/editor/chapter_props_gallery.tscn` vẫn là gallery của 15 props roster gốc. Cụm Đợt B được xem trong `scenes/editor/modular_map_showcase.tscn`, nơi mỗi chapter ghép landmark/prop lớn với hai identity prop nhỏ.
- Đặt map: mở `scenes/editor/gridmap_level_editor.tscn`; tìm item có tiền tố `Prop_` trong MeshLibrary. Mốc 51 item của đợt props đầu đã được thay thế bởi thư viện hiện tại 79 item.
- MeshLibrary hiện có 79 item tổng cộng; installer giữ nguyên ID cũ khi thêm 8 props B.
- GridMap export/import nhận biết đủ 23 chapter-prop type và giữ yaw khi xoay quanh trục Y theo bước 90 độ.
- Runtime dùng catalog chung `src/data/chapter_props.gd`; BoardView đọc các loại mới từ `LevelData.decorations`.

Ví dụ thêm vào danh sách `decorations` của một level:

```gdscript
{ "type": "foundry_furnace", "grid_position": Vector3i(3, 0, 0), "yaw": 90.0, "scale": 1.0 }
```

Chọn tọa độ thực sự nằm ở phần trang trí của map. Ví dụ trên chỉ minh họa cú pháp, không phải tọa độ an toàn cho mọi level.

## Tỷ lệ, footprint và va chạm

- GLB dùng tỷ lệ gốc của kit; BoardView và MeshLibrary cùng áp dụng hệ số `0.5`. `scale = 1.0` trong decoration nghĩa là dùng tỷ lệ chuẩn này.
- Pivot X/Z ở giữa footprint, đáy ở Y = 0; đặt lên mặt sàn cao `0.154` trong game.
- Xem kích thước 15 props roster tại [CHAPTER_PROPS_BOUNDS.json](CHAPTER_PROPS_BOUNDS.json). Tám identity prop B dùng [CHAPTER_IDENTITY_PROPS_BOUNDS.json](CHAPTER_IDENTITY_PROPS_BOUNDS.json), gồm bounds, triangles, surfaces và source generator.
- Đây là vật thể trang trí: không tự thêm luật puzzle, collision hoặc nguồn sáng động. Material phát sáng được giữ lại.
- Khi xuất từ GridMap, ô neo của loại mới được đặt thành `#` để không trở thành ô đi bộ xuyên qua đồ vật. Trong LevelData viết tay, người dựng map phải đặt địa hình chặn phù hợp.
- Một số mẫu rộng hơn một ô: bánh răng, bể nước, cây, lõi, khung cổng. Cần chừa khoảng trống hoặc địa hình chặn quanh footprint, đặc biệt khi xoay. Bộ xuất hiện chỉ giữ ô neo, không tự khóa mọi ô model phủ lên.
- Không đặt cây/lò/tường cao phía trước ô cần đọc. Vòm và khung cổng trong bộ này là scenery, không thay cho Portal gameplay.

GridMap sync hiện có giới hạn từ trước: không phải công cụ round-trip đầy đủ cho campaign nhiều tầng và toàn bộ dữ liệu puzzle. Dùng bản sao level khi thử bố cục; chưa dùng export này để ghi đè màn chiến dịch hoàn chỉnh.

## Pipeline và kiểm tra

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --python tools/bake_chapter_props.py -- 'D:/GodotProjects/The Last Resonance'
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --python tools/build_chapter_identity_props.py -- 'D:/GodotProjects/The Last Resonance'
godot --headless --path . --editor --import
godot --headless --path . -s tools/install_chapter_props.gd
godot --headless --path . -s tests/verify_chapter_props.gd
```

`bake_chapter_props.py` tạo lại 15 props roster. `build_chapter_identity_props.py` tạo riêng 8 props Đợt B. Installer cập nhật/thêm item theo tên và giữ ID hiện có.

Đã kiểm tra import, pivot/footprint, triangle budget, đủ surface/material khi ghép MeshLibrary, vòng xuất–nhập type/vị trí/yaw, runtime spawn ở L2/L6/L11/L14 và nghiệm của 15 màn hiện tại. Identity props đã được kiểm bằng camera gameplay trong campaign visual-polish; Android thật vẫn cần đo trước khi gọi mobile art-final.

## Phần cần nâng cấp tiếp

Ảnh thực tế cho thấy bộ mẫu hiện ở mức hình khối low-poly đơn giản. Đủ dùng để thử bố cục và tạo khác biệt cơ bản giữa các chương; cần thêm chi tiết/vật liệu nếu muốn nâng chất lượng mỹ thuật.

Đợt A/B/C và campaign dressing D1–D4 đều đã triển khai. Visual review đủ 15 level nằm tại [VISUAL_POLISH_PASS.md](VISUAL_POLISH_PASS.md). Phần còn lại của asset pass là benchmark Android thật và chỉ bổ sung chi tiết/model khi capture hoặc playtest chỉ ra thiếu hụt cụ thể.
