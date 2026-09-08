# Environment Dynamics Pass

Cập nhật: 2026-09-07. Trạng thái: **E1 đã kiểm bằng camera gameplay; E2 đã rollout đủ 15 level**.

Mục tiêu của pass này là làm môi trường có nhịp sống mà không thêm gameplay state. Dynamics được opt-in bằng `dynamic_profile` ngay trên từng decoration; BoardView không tự động animate mọi asset cùng loại trong campaign.

## E1 — Representative levels

### L2 — Archive

- `terminal` tại `(6,0,0)` dùng `archive_terminal`: một status strip cyan flicker bất ổn.
- `archive_access_panel_broken` tại `(2,0,3)` dùng `archive_panel`: tín hiệu nhỏ hơn/chậm hơn terminal.
- Không thêm realtime light hoặc particle. Hai strip là geometry emissive nhỏ và độc lập với sector-power material, nên không phá power-restoration tween.

Ngôn ngữ: Archive không “hoạt động bình thường”; nó chỉ còn các tín hiệu cục bộ chập chờn.

### L6 — Foundry

- Conveyor tại `(8,0,1)` dùng `foundry_conveyor`: rung cơ khí biên độ rất nhỏ, chỉ presentation transform.
- `machine` tại `(8,0,7)` dùng `foundry_machine_heat`: hai strip nhiệt cam pulse lệch phase. Profile này thay cho furnace accent cũ sau khi composition L6 được tinh gọn.
- Không animate Core, plate, door hoặc K-Series mold.

Ngôn ngữ: máy nặng vẫn còn rung/nhiệt dư, nhưng puzzle object không bao giờ bị nhầm với scenery động.

### L11 — Flooded Sanctuary

- Ba `kit_water_*` dùng `sanctuary_water`: tận dụng shader `TIME`, chỉnh `wave_speed` khoảng `0.56–0.64` và amplitude `0.011–0.013`.
- `plant` tầng 2 tại `(1,1,4)` dùng `sanctuary_sway`: sway khoảng `1.35°`, chậm.
- Water vẫn GPU procedural; không spawn particle hoặc physics.

Ngôn ngữ: Sanctuary chuyển động liên tục nhưng nhẹ, trái ngược chuyển động máy Foundry.

### L14 — Central Core

- `core_data_cabinet_low` dùng `core_cabinet_pulse`.
- `core_light_trim` dùng `core_trim_pulse` với phase riêng.
- Hai pulse cùng tần số chậm nhưng lệch phase, tạo cảm giác dữ liệu chạy qua kiến trúc thay vì tất cả đèn sáng/tắt đồng thời.
- Không animate Energy Node bằng hệ này; Energy Node và EVA vẫn dùng gameplay/story presentation riêng.

Ngôn ngữ: Central Core còn sống và có thứ tự, không flicker hỗn loạn như Archive.

### Visual review E1

L2/L6/L11/L14 đã được capture bằng scene gameplay thật ở `1280×720`, renderer Vulkan `Forward Mobile`; không dùng headless frame làm bằng chứng bố cục. Các accent động nằm ở scenery/biên phòng, không che Core, Energy Node, EVA hay landmark chính. Sanctuary được kiểm lại sau khi sửa water-material path và renderer không còn báo `material is null`.

## E2 — Campaign rollout

E2 giữ cơ chế opt-in theo từng decoration và cố ý không đồng nhất nhịp giữa các level:

- Chapter I: L1/L3/L4 chỉ dùng một `archive_panel`; L1 chậm và tối hơn L2 để tutorial signal vẫn ưu tiên cao nhất.
- Chapter II: L5 dùng conveyor + machine heat, L7 chỉ có machine heat yếu, L8 dùng conveyor + furnace. L6 vẫn là representative mạnh hơn L7.
- Chapter III: L9/L10 ưu tiên một water target; L12 có water tầng 1 và plant sway tầng 2, tách khỏi Elias. L11 giữ representative water/vegetation pair.
- Chapter IV: L13/L15 chỉ dùng một `core_trim_pulse` yếu; L14 giữ cabinet + trim sequence mạnh hơn để L13 Soul Archive và L15 Judgement Engine không bị tranh chú ý.

Visual review E2 dùng gameplay capture tại L1/L5/L7/L8/L13/L15 và riêng L12 floor 2. Không thấy dynamic accent che gameplay affordance hoặc story landmark trong các điểm kiểm tra này.

## Mobile budget

Dynamics E1 cố ý giữ trên Android nhưng giảm biên độ:

- `environment_motion_scale() = 0.62`
- `environment_emission_scale() = 0.72`
- không thêm `GPUParticles3D`
- không thêm realtime accent `Light3D`
- water shader giảm displacement thêm 28% trên mobile

Do đó visual motion vẫn tồn tại trên Android mà không phá nguyên tắc mobile tier hiện tại.

## Data contract

Các profile hợp lệ hiện tại:

```text
archive_terminal
archive_panel
foundry_conveyor
foundry_furnace
foundry_machine_heat
sanctuary_sway
sanctuary_water
core_cabinet_pulse
core_trim_pulse
```

`tools/validate_map_decorations.py` reject profile không thuộc danh sách trên và reject profile gắn sai loại asset. `dynamic_speed`, `dynamic_amplitude`, `dynamic_phase`, `dynamic_intensity` là override presentation tùy chọn; chúng không được đọc bởi GameLogic.

## Regression

`tests/verify_environment_dynamics.tscn` kiểm:

- đúng unique profile set trên đủ 15 level;
- emissive thực sự thay đổi theo thời gian;
- conveyor thực sự dịch chuyển nhẹ;
- water shader nhận speed/amplitude đã author;
- L14 có pulse lệch phase;
- hierarchy cường độ L1 < L2, L7 < L6, L13/L15 < L14;
- mobile vẫn giữ dynamics nhưng không tăng particle/realtime light.
- dynamics không thêm `CollisionObject3D` trên bất kỳ level nào;
- L11 floor 2 ẩn vẫn ẩn cả sway target;
- L14 giữ Energy Node và EVA ngoài environment-dynamics registry.

## Tiếp theo

E2 đã hoàn tất về authoring, visual review desktop và regression. Hạng mục còn lại là đo frame time/draw calls trên Android thật với cùng thiết bị, độ phân giải và quality preset; desktop/headless không được dùng thay cho số đo thiết bị.
