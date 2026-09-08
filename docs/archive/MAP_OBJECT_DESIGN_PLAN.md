# Kế hoạch tiếp theo: vật thể thiết kế map

Đợt căn chỉnh truyện tiếp nối: L2 sửa điểm phát thoại; L10/L15 đổi puzzle; L14 thành nhịp lắng; năm landmark có model riêng. Xem [NARRATIVE_MAP_ALIGNMENT.md](NARRATIVE_MAP_ALIGNMENT.md) và blueprint hiện hành. Những dòng “không đổi puzzle” bên dưới mô tả phạm vi các đợt asset trước đó.

Cập nhật: 2026-09-07. Trạng thái: **A1, A2, B, C và campaign dressing D1–D4 đã tích hợp; pilot gameplay đã được kiểm bằng renderer thật; Environment Dynamics E2 đã phủ đủ 15 level**.

## 1. Điểm xuất phát

- Đã có **23 chapter props** (15 roster + 8 identity props Đợt B) trong [CHAPTER_MAP_PROPS.md] và **20 mảnh modular** (A1+A2) trong [MODULAR_MAP_KIT.md]; MeshLibrary hiện có **79 item**.
- Đã có [pilot L2/L6/L11/L14](ASSET_PILOT.md), [bố trí bổ sung Sanctuary/Core](MAP_COMPOSITION_PASS.md) và [profile vật liệu theo chương](../CHAPTER_MATERIAL_PASS.md).
- Pilot L2/L6/L11/L14 đã được capture bằng scene gameplay thật ở camera runtime với Vulkan `Forward Mobile`; headless vẫn chỉ dùng regression, không dùng làm bằng chứng bố cục. Chưa có số đo Android thật.

Mục tiêu đợt tiếp theo: ghép phòng ít phải chỉnh tay, nhận ra chức năng không gian qua hình dáng, và giữ đường đi/Core/đích rõ ở kích thước màn hình chơi thật.

## 2. Quy tắc thiết kế

1. Mỗi màn giữ một landmark cốt truyện chính; props phụ hỗ trợ landmark, không tạo thêm nhiều tâm chú ý ngang nhau.
2. Ba lớp bố cục: mép sàn thấp ở phía gần camera; vật thể vừa ở hai bên; máy/cây/tường cao ở hậu cảnh. Nếu camera đổi hướng, kiểm tra lại mọi hướng được hỗ trợ.
3. Props trang trí không dùng cùng dấu hiệu nhận diện với Plate, Portal, Energy Node hoặc Core. Khung cổng scenery không có mặt xoáy/sáng như Portal hoạt động; cáp trang trí không giả đường nối trạng thái puzzle.
4. Không mở rộng map hoặc đổi route/par để chứa đồ trang trí. Vật thể lớn phải vừa vùng biên hiện có; nếu không vừa, chọn biến thể nhỏ hoặc bỏ.
5. Footprint tính theo hình học sau scale/yaw, không chỉ ô neo. Props không tự tạo collision; dữ liệu puzzle quyết định ô bị chặn.
6. Tái sử dụng profile vật liệu hiện có. Chỉ thêm mesh khi hình dáng hoặc khả năng ghép có nhu cầu rõ; đổi màu đơn thuần dùng profile.

## 3. Đợt A — hoàn thiện mảnh ghép nền

Ba mảnh A1 và ba mảnh A2 đã được blockout và tích hợp vào catalog, MeshLibrary và scene showcase. A2 tại các pilot L2/L6/L11/L14 đã được kiểm trong gameplay capture; việc tái sử dụng ở level khác vẫn giữ nguyên yêu cầu kiểm footprint/camera theo từng bố cục.

Các tên là ID dự kiến. Kích thước tính bằng ô game và là mục tiêu thiết kế, cần đo lại sau khi tạo model.

| Ưu tiên | Vật thể mới | Kích thước mục tiêu | Lý do và vị trí thử |
| --- | --- | --- | --- |
| A1 | `kit_floor_inner_corner` — góc lõm mép sàn | 1×1 | Khép nền chữ L; thử ở biên sàn, không che ô đi |
| A1 | `kit_floor_end_reverse` — đầu bịt đối hướng | Cùng chuẩn mép sàn hiện có | Kết thúc mép cùng cạnh, giảm nhu cầu bù offset thủ công |
| A1 | `kit_rail_end_reverse` — đầu lan can đối hướng | Cùng chuẩn lan can hiện có | Ghép đầu còn lại trên cùng cạnh; thử L2/L14 |
| A2 ✅ | `kit_wall_low_straight` — tường thấp | 0,96×0,19; cao ~0,37 | Đã tích hợp; pilot L2/L11 |
| A2 ✅ | `kit_wall_low_corner` — góc tường thấp | ~0,92×0,88; cao ~0,37 | Đã tích hợp; pilot L6 |
| A2 ✅ | `kit_wall_low_end` — đầu tường thấp | ~0,51×0,24; cao ~0,37 | Đã tích hợp; pilot L14 tầng 2 |

Đợt A đã đủ 6 mesh mới. Low-wall A2 thay visual tường cao tại chính ô `#` nhưng không thay `GameLogic.walls`, vì vậy không tạo lối đi mới. Không thêm cầu thang hoặc đường dốc trang trí nối hai tầng vì dễ gợi ý một lối đi chưa được gameplay hỗ trợ.

## 4. Đợt B — hình dáng riêng cho từng chương

Mỗi chương đã có một cụm thử trong `modular_map_showcase.tscn`. Landmark/prop lớn tái sử dụng asset hiện có; mỗi chapter bổ sung đúng hai identity prop nhỏ để tăng silhouette riêng mà không tạo thêm tâm chú ý ngang landmark.

| Chương | Cụm thiết kế | Hình dáng và câu chuyện | Phạm vi đặt |
| --- | --- | --- | --- |
| I — Archive ✅ | `data_rack` + `archive_access_panel_broken` + `archive_storage_tray_low` | Nhịp đứng đều, khe cyan mảnh, khoang/khay bị bỏ quên | Đã đặt thử L2 |
| II — Foundry ✅ | lò/press + `foundry_maintenance_box` + `foundry_pipe_support` | Khối nặng, chân đế/khớp nối rõ; góc bảo trì gắn với tuyến ống | Đã đặt thử L6 |
| III — Sanctuary ✅ | bờ nước/đá + `sanctuary_broken_plinth_low` + `sanctuary_bank_root` | Đá nước ăn mòn, silhouette bất đối xứng, rễ bám bờ | Đã đặt thử L11, gồm cả tầng trên |
| IV — Central Core ✅ | `core_wall` + `core_data_cabinet_low` + `core_light_trim` | Hình học chính xác, nẹp sáng phụ thấp hơn gameplay signal | Đã đặt thử L14 tầng 2 |

Mục tiêu cho props phụ mới: footprint không quá 1×1 ô; cao khoảng 0,2–0,45 ô nếu ở phía gần camera. Đây là ngưỡng khởi đầu để thử hình, không bảo đảm không che khuất. Đồ lớn dùng bounds đo thực tế và đặt riêng từng màn.

## 5. Đợt C — cụm đặt map có thể tái sử dụng ✅

Đã tạo bốn scene mẫu có thể chỉnh trong editor, mỗi scene gồm một vật thể chính và 2–4 chi tiết phụ. Catalog và hướng dẫn chi tiết nằm tại [MAP_CLUSTERS.md](../MAP_CLUSTERS.md) và `../MAP_CLUSTER_CATALOG.json`:

- Archive: `archive_storage_bay.tscn` — kho lưu trữ còn nguồn cạnh khoang hỏng.
- Foundry: `foundry_maintenance_corner.tscn` — press, tuyến ống ngắn và góc bảo trì.
- Sanctuary: `sanctuary_flooded_bank.tscn` — bờ nước, trụ gãy, đá và rễ.
- Central Core: `core_data_wall.tscn` — mảng tường dữ liệu, thiết bị thấp và nẹp sáng.

Mỗi root scene đã ghi footprint, bounds đo thật, hướng ra đường chơi, `blocked_cells`, `walkable_cells` và bốn yaw đã kiểm tra hình học. `visual_camera_review` cố ý để `pending`: headless test không thay thế kiểm tra che khuất bằng mắt. Chỉ tái sử dụng cụm nền; landmark cốt truyện vẫn bố trí riêng cho từng level. Không rải cụm tự động lên campaign trước khi kiểm tra camera/footprint.

## 6. Chuẩn bàn giao asset

- Một ô game = 1 đơn vị; giữ pipeline GLB 2x và hệ số runtime/editor 0,5 hiện tại.
- Modular giữ pivot ở tâm ô/mặt sàn; props độc lập giữ pivot giữa đáy. Không tự căn giữa hình học các mảnh lệch cạnh.
- Ghi bounds X/Y/Z, vùng chiếm chỗ, hướng mặc định, đầu nối, số tam giác và số surface. Kiểm tra bốn góc yaw 0/90/180/270°.
- Mảnh nối phải cùng cao độ và tiết diện với kit hiện có. Kiểm tra đầu bịt đối hướng không cần offset ngoài quy ước để giữ cùng cạnh.
- Material dùng lại bảng vật liệu/profile; emission phụ thấp hơn dấu hiệu gameplay khi so trong cùng cảnh. Chưa đặt ngân sách polygon/draw call tuyệt đối khi chưa có baseline thiết bị.
- Khi tích hợp mới thêm catalog và MeshLibrary, giữ ID cũ. Nhiều decoration cùng ô dùng LevelData hoặc Node3D riêng: GridMap hiện chỉ giữ một item/cell.
- Không dùng GridMap export ghi đè campaign nhiều tầng; công cụ hiện chưa round-trip đầy đủ dữ liệu đó.

## 7. Thứ tự thực hiện và điều kiện hoàn thành

| Bước | Đầu ra | Điều kiện chuyển bước |
| --- | --- | --- |
| 1. Đánh giá pilot hiện có ✅ | Ảnh L2/L6/L11/L14 ở camera gameplay, gồm tầng cần kiểm | Capture renderer thật đã xác nhận composition pilot; Sanctuary water path cũng đã kiểm sạch renderer |
| 2. Blockout đợt A ✅ | 6 mảnh A1+A2 và scene thử nối | Test bounds/catalog/MeshLibrary/runtime đạt; A2 pilot đã kiểm ở camera gameplay |
| 3. Hoàn thiện một cụm/chương ✅ kỹ thuật | Bốn cụm mẫu + 8 identity props, dùng profile hiện có | Bounds/pivot/triangle/runtime đạt; identity props áp dụng ở pilot đã được kiểm bằng camera gameplay |
| 4. Áp dụng lại vào bốn pilot ✅ kỹ thuật | L2/L6/L11/L14 có 2 identity props/chapter | Không đổi map/entity/route/par; validator và solver đạt |
| 5. Đóng gói Đợt C ✅ kỹ thuật | 4 prefab + gallery + catalog metadata + regression test | Bounds/metadata/runtime editor đạt; visual camera review còn pending |
| 6a. D1 — Chapter III ✅ kỹ thuật | L9/L10/L12 dressing riêng; L12 thành hybrid Sanctuary + K-7 lab | Không đổi puzzle; validator/solver/regression đạt; xem [CAMPAIGN_DRESSING_PASS.md](CAMPAIGN_DRESSING_PASS.md) |
| 6b. D2 — Chapter IV ✅ kỹ thuật | L13 nhận data-wall/low foreground; L14 giữ representative; L15 chỉ 2 accent thấp | Không đổi puzzle; giữ vùng Judgement Engine thoáng; xem [CAMPAIGN_DRESSING_PASS.md](CAMPAIGN_DRESSING_PASS.md) |
| 6c. D3 — Chapter II ✅ kỹ thuật | L5 production line; L6 giữ representative; L7 sealed chamber; L8 reactor heart | Không đổi puzzle; bridge/EVA readability giữ nguyên; xem [CAMPAIGN_DRESSING_PASS.md](CAMPAIGN_DRESSING_PASS.md) |
| 6d. D4 — Chapter I ✅ kỹ thuật | L1 replacement pass; L2 giữ representative; L3 restricted-vault accents; L4 một security-panel accent | Không đổi puzzle; tutorial/EVA readability giữ nguyên; xem [CAMPAIGN_DRESSING_PASS.md](CAMPAIGN_DRESSING_PASS.md) |

Khi có thay đổi asset/runtime, dùng các bài kiểm tra props/modular tương ứng. Khi thay decoration, chạy `tools/validate_map_decorations.py`, `tools/validate_asset_pilot.py` và kiểm tra nghiệm campaign bằng `tools/validate_levels.py`. Validator ô neo không thay thế kiểm tra hình học footprint hoặc ảnh che khuất.

Đánh giá hiệu năng sau tích hợp bằng cùng thiết bị, độ phân giải và thiết lập, so trước/sau về frame time và draw calls. Android thật vẫn là hạng mục cần đo; chưa kết luận đạt chỉ từ desktop/headless.

## 8. Phạm vi đề xuất bắt đầu

D1–D4 đã phủ đủ campaign mà không copy nguyên prefab C hoặc thay puzzle. **Environment Dynamics E1** đã được kiểm bằng gameplay camera trên L2/L6/L11/L14 và **E2 đã rollout đủ 15 level** với profile/density riêng từng màn; xem [ENVIRONMENT_DYNAMICS_PASS.md](ENVIRONMENT_DYNAMICS_PASS.md). Gameplay affordance, story landmark và mobile render budget tiếp tục là giới hạn; Android thật vẫn cần benchmark.
