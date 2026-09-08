# Campaign Dressing Pass

Cập nhật: 2026-09-07.

Mục tiêu của dressing pass là đưa A1/A2/B/C vào campaign theo từng màn mà **không đổi puzzle**. `map`, `entities`, `hint_route` và `par_moves` vẫn là nguồn gameplay; scenery chỉ thay cách đọc không gian.

## D1 — Chapter III ✅ kỹ thuật

Chapter III dùng L11 làm representative level đã được kiểm trước. D1 mở rộng ngôn ngữ Sanctuary sang L9/L10/L12 nhưng không copy nguyên `sanctuary_flooded_bank` prefab.

### Level 9 — Giấc mơ chung

Ý đồ: Sanctuary mới bắt đầu lộ diện, còn tương đối khô và mang cảm giác ảo giác hơn là đổ nát hoàn toàn.

- Giữ `sanctuary_pool`, tree, rocks, vine arch và một water edge hiện có.
- Thêm `sanctuary_broken_plinth_low` tại `(5,0,0)`.
- Thêm `sanctuary_bank_root` tại `(8,0,1)` cạnh vùng vine arch.
- Không tăng thêm mặt nước để L9 vẫn nhẹ hơn L10–L12.

### Level 10 — Mạng lưới cộng hưởng

Ý đồ: kiến trúc Sanctuary bị Resonance và thiên nhiên ăn sâu hơn, nhưng Energy Node/altar vẫn là tín hiệu thị giác chính.

- Thêm `sanctuary_broken_plinth_low` tại `(8,0,2)` gần khu altar nhưng không đè Energy Node.
- Thêm `sanctuary_bank_root` tại `(10,0,5)` cạnh cụm rocks ở biên phải.
- Không thêm emission mới cạnh ba Energy Node.

### Level 12 — Dự án K-7

Ý đồ: finale Chapter III không chỉ là Sanctuary khác; nó lộ ra **một phòng nghiên cứu K-7 cũ bị Sanctuary chôn lấp**.

- `elias_testament` vẫn ở `(4,1,0)` và là landmark chính.
- `archive_access_panel_broken` tại `(3,1,0)` và `archive_storage_tray_low` tại `(5,1,0)` kẹp hai bên projector của Elias.
- Hai prop Archive được runtime tint/weather theo Chapter III, tạo cảm giác cơ sở nghiên cứu cũ nằm dưới Sanctuary thay vì quay lại thẩm mỹ Chapter I nguyên bản.
- `sanctuary_bank_root` tại `(8,1,4)` nối vùng railing/shrine bên phải, cho thấy thiên nhiên đang xâm nhập phòng nghiên cứu.

Đây là ngoại lệ có chủ đích cho identity-prop: L12 dùng một phần ngôn ngữ Archive để kể nguồn gốc K-7, nhưng landmark, material profile và phần còn lại của composition vẫn thuộc Chapter III.

## Quy tắc D1

- Tất cả identity prop mới nằm trên ô `#` đã blocked; chúng chỉ thay visual wall.
- Không thêm collision hoặc gameplay trigger.
- Không thay map/entity/route/par.
- Không đặt prop phát sáng cạnh Energy Node/Portal để tránh cạnh tranh affordance.
- L12 multi-floor phải kiểm camera, upper-floor height và Elias hologram sau mỗi thay đổi dressing.

Regression: `tests/verify_campaign_dressing.gd`, `tools/validate_map_decorations.py`, `tools/validate_levels.py`, multi-floor camera và story-hologram tests.

## D2 — Chapter IV ✅ kỹ thuật

Chapter IV dùng L14 làm representative level đã được kiểm trước. D2 tập trung đưa cùng ngôn ngữ kiến trúc chính xác/đang suy kiệt sang L13, đồng thời chỉ thêm accent thấp cho L15 vì topology finale hiện vẫn có khả năng được redesign.

### Level 13 — Những linh hồn đã mất

Ý đồ: đây là lần đầu Kiro bước vào Central Core nên phòng phải đọc như **kho lưu trữ ý thức**, không chỉ là một phòng gameplay có ba Energy Node.

- `soul_archive` tại `(4,0,1)` vẫn là landmark chính.
- Thêm `core_data_cabinet_low` tại `(3,0,0)` và `core_light_trim` tại `(5,0,0)`, tạo nhịp data-wall phía sau Soul Archive mà không chen vào tuyến Core.
- Thêm `kit_wall_low_straight` tại `(4,0,7)` ở foreground. Đây chỉ thay visual tường cao bằng tường thấp để mở tầm nhìn vào phòng; `GameLogic.walls` vẫn giữ nguyên.
- Không thêm emission mới gần ba Energy Node `(3,0,2)`, `(5,0,4)`, `(2,0,5)`.

### Level 14 — Lời thú nhận của EVA

Không thêm dressing trong D2. L14 đã là representative level của Chapter IV với `core_data_cabinet_low`, `core_light_trim`, low-wall, rail/floor modular và EVA Conduit. Giữ nguyên composition để tránh over-dress màn confession.

### Level 15 — Phán quyết

Ý đồ: chỉ nối tiếp ngôn ngữ Central Core ở biên phòng, không khóa art vào topology finale hiện tại.

> Ghi chú lịch sử: các tọa độ D2 bên dưới mô tả topology L15 trước đợt narrative redesign. Topology hiện hành là map 9×9/par 81 trong `level_15.tres`; placement hiện tại và visual review xem [VISUAL_POLISH_PASS.md](../VISUAL_POLISH_PASS.md).

- Thêm `core_data_cabinet_low` tại `(9,0,5)`.
- Thêm `core_light_trim` tại `(9,0,6)`.
- Cả hai quay `-90°` về phía phòng và nằm trên wall cell biên phải.
- Không đặt thêm scenery quanh `judgement_engine` `(5,0,7)` hoặc cụm Energy Node/bridge control. Khu vực phán quyết trung tâm được giữ thoáng cho EVA + Elias hologram và ending choice.

## Quy tắc D2

- L13 nhận composition chính; L14 giữ nguyên; L15 chỉ nhận hai accent thấp.
- Identity prop và low-wall mới đều nằm trên `#` authoritative.
- Không thay map/entity/route/par.
- Không thêm ánh sáng phụ cạnh Energy Node hoặc Judgement Engine.
- D2 không được coi là lý do giữ topology L15 hiện tại; finale puzzle vẫn có thể redesign độc lập.

Regression: `tests/verify_campaign_dressing.gd`, decoration validator, 15-level solver/verifier, multi-floor camera, story holograms và mobile render budget.

## D3 — Chapter II ✅ kỹ thuật

Chapter II dùng L6 làm representative level đã được kiểm trước. D3 không copy `foundry_maintenance_corner` nguyên dạng mà chia ba màn còn lại thành ba công năng hình ảnh khác nhau: dây chuyền sản xuất, khoang niêm phong và trái tim lò phản ứng.

### Level 5 — Dây chuyền thức tỉnh

Ý đồ: đây là khu sản xuất vừa bắt đầu sống lại, nên cần đọc như **production line** chứ chưa phải phòng bảo trì nặng như L6.

- Thêm `foundry_press` tại `(8,0,0)`, scale `0.75`, ở hậu cảnh phía phải.
- Thêm `foundry_pipe_support` tại `(4,0,1)` để tạo điểm neo kỹ thuật giữa các khối dây chuyền.
- Thêm `kit_wall_low_straight` tại `(7,0,7)` ở foreground để mở tầm nhìn vào tuyến chơi thay vì giữ wall cao toàn bộ.
- Không thay `foundry_line`, conveyor hoặc machine hiện có; các phần đó vẫn là nhịp chính của phòng.

### Level 6 — Khuôn đúc K-Series

Không thêm dressing mới trong D3. L6 tiếp tục là representative Foundry với machine/conveyor, modular pipe, pipe support, maintenance box và low-wall corner. Furnace accent representative trước đây đã được thay bằng modular floor corner trong refinement sau D3; environment heat pulse hiện gắn vào machine thay vì khôi phục prop cũ.

### Level 7 — Khoang niêm phong

Ý đồ: không gian phải đọc **kín, nặng và cơ khí hơn**, hỗ trợ bridge/lockdown thay vì trông như một production room khác.

- Thêm `foundry_gear` tại `(2,0,0)`, scale `0.8`; gear thấp nên tạo texture cơ khí ở hậu cảnh mà không thành landmark.
- Thêm `foundry_pipe_valve` tại `(8,0,3)`, scale `0.82`, nối nhịp wall phải giữa machine và data rack.
- Thêm `kit_wall_low_straight` tại `(5,0,7)` ở foreground; gameplay wall vẫn authoritative.
- Bridge console `(8,0,1)` và bridge route vẫn giữ khoảng đọc rõ.

### Level 8 — Trái tim Foundry

Ý đồ: đây là **reactor heart**, vì vậy dressing tập trung vào nhiệt/áp lực hệ thống chứ không lặp hộp bảo trì của L6.

- Thêm `foundry_furnace` tại `(4,0,0)`, scale `0.78`, ở hậu cảnh trung tâm.
- Thêm `foundry_pipe_valve` tại `(9,0,4)`, scale `0.82`, trên biên phải.
- Thêm `kit_wall_low_straight` tại `(5,0,8)` ở foreground.
- Không đặt thêm prop quanh `reactor_switch` `(4,0,2)`, khu bridge/plate hoặc vị trí EVA xuất hiện khi lockdown mở.

## Quy tắc D3

- L5 = production line; L6 = representative maintenance/mold; L7 = sealed chamber; L8 = reactor heart.
- Prop cao chỉ đặt hậu cảnh/biên; foreground mới chỉ dùng low-wall.
- Không thay map/entity/route/par.
- Không che `bridge_console` L7 hoặc `reactor_switch`/EVA hologram L8.
- D3 chỉ dressing; chuyển động máy, hơi nóng, conveyor animation và audio reactive thuộc environment-dynamics pass riêng.

Regression: `tests/verify_campaign_dressing.gd`, decoration validator, solver/verifier, interaction test, story holograms và mobile render budget.

## D4 — Chapter I ✅ kỹ thuật

Chapter I dùng L2 làm representative Archive. Đây vốn là chapter có mật độ scenery cao nhất, nên D4 ưu tiên **thay prop generic bằng identity prop** và chỉ thêm rất ít object mới. Mục tiêu là tăng tính nhận diện mà không làm tutorial/early-game khó đọc hơn.

### Level 1 — Khởi động

Ý đồ: phòng kích hoạt Kiro vẫn phải là màn sạch và dễ đọc nhất. Không tăng số decoration; chỉ thay hai prop generic bằng asset Archive có ngôn ngữ rõ hơn.

- Thay `workbench` tại `(4,0,2)` bằng `archive_access_panel_broken`, yaw `-90°`. Đây là wall cell nội bộ nên panel đọc như một bảng điều khiển chết cạnh tuyến khởi động.
- Thay `crate` tại `(7,0,5)` bằng `archive_storage_tray_low`.
- Tổng decoration **giữ nguyên 29**.
- `holo` và vùng first-contact vẫn không bị thêm scenery mới xung quanh.

### Level 2 — Góc lưu trữ

Không thêm dressing mới trong D4. L2 giữ vai trò representative Archive với modular floor/rail, low-wall và hai identity prop đã được kiểm trước:

- `archive_access_panel_broken` `(2,0,3)`.
- `archive_storage_tray_low` `(3,0,3)`.
- `kit_wall_low_straight` `(3,0,5)`.

### Level 3 — Khu vực cấm

Ý đồ: nhấn mạnh đây là **restricted data-vault corridor**, không chỉ là kho lưu trữ khác.

- Thêm `archive_access_panel_broken` tại `(5,0,0)`, ở back wall gần data-vault zone nhưng không thay `data_vault` landmark.
- Thêm `archive_storage_tray_low` tại `(2,0,6)` ở biên dưới.
- Không thêm low-wall/emission mới; đường đẩy Core và vùng `p/D` vẫn giữ silhouette rõ.

### Level 4 — Khóa liên động

Ý đồ: đây là interlock/security room nên chỉ cần một accent kỹ thuật mới; không tăng mật độ mạnh trước khi chuyển sang Foundry.

- Thêm `archive_access_panel_broken` tại `(4,0,1)`, yaw `180°`.
- Không thêm storage tray hoặc low-wall mới quanh `archive_lock_node`, các điểm `k/l/K/L` và đường Core.
- EVA first full-hologram beat vẫn giữ khoảng nhìn hiện tại.

## Quy tắc D4

- L1 dùng replacement, không tăng decoration count.
- L2 giữ representative composition nguyên trạng.
- L3 chỉ thêm hai identity prop thấp; L4 chỉ thêm một access panel.
- Không thay map/entity/route/par hoặc landmark.
- Tutorial readability và EVA contact quan trọng hơn mật độ scenery.

Regression: `tests/verify_campaign_dressing.gd`, decoration validator, 15-level solver/verifier, story-hologram test và mobile render budget.

## Environment Dynamics rollout

D1–D4 đã phủ đủ bốn chapter. **Environment Dynamics E1** đã được kiểm bằng gameplay camera trên L2/L6/L11/L14: Archive terminal/flicker, Foundry conveyor/heat, Sanctuary water/vegetation và Central Core pulse sequencing. Chi tiết và regression nằm tại [ENVIRONMENT_DYNAMICS_PASS.md](ENVIRONMENT_DYNAMICS_PASS.md).

**E2 đã rollout đủ 15 level** theo từng decoration thay vì tự động animate mọi prop cùng loại. L1/L7/L13/L15 cố ý yếu hơn representative cùng chapter; L12 floor 2 đã được kiểm riêng để plant sway không tranh Elias. Puzzle data, story hologram, Energy Node và mobile render budget tiếp tục là ranh giới không được vượt qua; benchmark Android thật vẫn còn pending.
