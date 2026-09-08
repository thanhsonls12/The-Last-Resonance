# Cụm dựng map — editor prefab

**Xong.** Bốn cụm 3×3 (mỗi chương một). Không phải entity gameplay; không tự sửa `LevelData` / collision / par. Campaign dressing đã dùng ngôn ngữ này (không copy nguyên prefab).

## Danh mục

| Chapter | Scene | Footprint | Hướng ra đường chơi | Thành phần |
| --- | --- | ---: | --- | --- |
| I — Archive | `scenes/editor/map_clusters/archive_storage_bay.tscn` | 3×3 | South | Bookshelf + access panel hỏng + storage tray thấp |
| II — Foundry | `scenes/editor/map_clusters/foundry_maintenance_corner.tscn` | 3×3 | South | Press + pipe end/straight + pipe support + maintenance box |
| III — Sanctuary | `scenes/editor/map_clusters/sanctuary_flooded_bank.tscn` | 3×3 | South | Rocks + water edge/corner + broken plinth + bank root |
| IV — Central Core | `scenes/editor/map_clusters/core_data_wall.tscn` | 3×3 | South | Core wall + data cabinet thấp + light trim |

Xem cả bốn cùng lúc tại `scenes/editor/map_cluster_gallery.tscn`.

## Metadata placement

Mỗi root scene lưu trực tiếp metadata:

- `cluster_id`
- `chapter`
- `display_name`
- `footprint_cells`
- `outward_face`
- `blocked_cells`
- `walkable_cells`
- `geometry_checked_yaws`
- `measured_bounds_position`
- `measured_bounds_size`
- `visual_camera_review`
- `notes`

Catalog máy đọc được sinh tại `docs/MAP_CLUSTER_CATALOG.json`.

Quy ước local grid của cluster: origin ở tâm footprint, `-Z` là phía sau scenery và `+Z` là phía đường chơi mặc định. South edge (`z = +1`) luôn được giữ trống trong bốn prefab hiện tại.

`blocked_cells` là vùng mà level nhận cluster phải **đã** đánh dấu `#` hoặc scenery-only. `walkable_cells` là vùng cluster cho phép tuyến chơi đi qua. Prefab không tự biến các vùng này thành collision hay floor.

## Cách dùng

1. Mở scene cluster phù hợp hoặc `map_cluster_gallery.tscn`.
2. Instance/copy cluster vào scene bố trí thử, xoay cả root theo bước 90° nếu cần.
3. Dùng metadata để đối chiếu wall/walkable region của level đích.
4. Chuyển từng component cần giữ thành `LevelData.decorations` hoặc bố trí thủ công; **không** export cluster nguyên khối để ghi đè campaign nhiều tầng.
5. Kiểm tra camera gameplay và toàn bộ tuyến Core đi qua trước khi mở rộng sang level khác.

Landmark cốt truyện như EVA conduit, Elias testament, judgement engine, soul archive hoặc portal gameplay không nằm trong cluster. Chúng phải được bố trí riêng theo narrative/gameplay của từng level.

## Bounds hiện tại

Bounds chính xác nằm trong `MAP_CLUSTER_CATALOG.json`. Tóm tắt X×Z:

- Archive: khoảng `2.75 × 0.46`
- Foundry: `3.00 × 1.61`
- Sanctuary: khoảng `3.02 × 1.88` — rock rotation dùng tolerance 0.02 ô ở biên X
- Central Core: khoảng `2.81 × 0.68`

Mọi cluster khai báo footprint 3×3. Automated geometry check ghi bốn yaw `0/90/180/270`; đây là kiểm tra kích thước/metadata, **không phải bằng chứng không che khuất ở camera gameplay**. `visual_camera_review` vẫn là `pending` cho tới khi xem trực tiếp trong cửa sổ render.

## Pipeline và kiểm tra

```powershell
godot --headless --path . -s tools/build_map_clusters.gd
godot --headless --path . -s tests/verify_map_clusters.gd
```

`verify_map_clusters.gd` khóa các điều kiện: đủ bốn chapter, 3–5 component mỗi cluster, metadata khớp catalog, blocked/walkable không chồng nhau, south approach trống, không có `CollisionObject3D`, component vẫn là scene instance chỉnh được và bounds không vượt footprint khai báo.

Các prefab/editor tool được loại khỏi Android export qua `scenes/editor/*` và `src/tools/*`.
