# Nhiều tầng

> L11, L12, L14: puzzle **tuần tự**. Xong tầng đang chơi → thang mở → lên một lần.
> Core / portal / node **không** sang tầng kia. Undo = cả lượt thang.

## Luồng tuần tự đang áp dụng

1. Khi ở tầng 1, chỉ geometry, Core, mục tiêu và tương tác của tầng 1 được
   hiển thị. Tầng 2 chỉ để lộ underside, cột đỡ và trục thang gần elevator để
   gợi chiều cao mà không che ô puzzle.
2. Đặt đủ Core, giữ đủ plate và kích hoạt các Energy Node của tầng 1 sẽ chốt
   trạng thái tầng này, làm sáng vòng thang và hiện chỉ dẫn đi tới thang máy.
3. Bước vào elevator đã mở chạy animation cabin/camera đi lên, đổi khung hình
   sang tầng 2, rồi mới mở input và puzzle tầng 2.
4. Không thể gọi thang sớm, đi xuống lại, hay đẩy Core vào thang. Undo vẫn coi
   lượt bước vào elevator là một move nguyên tử và khôi phục tầng trước đó.

`LevelData.sequential_floors` bật quy tắc này. Level 11, 12 và 14 dùng cờ đó;
mỗi layer có Core/mục tiêu riêng, portal (nếu có) hoạt động trong chính layer.

Tài liệu này là hợp đồng thiết kế cho các level hai tầng của `The Last Resonance`.
Mục tiêu là mở rộng không gian theo chiều cao mà vẫn giữ puzzle Sokoban dễ đọc,
đặc biệt trên màn hình Android.

## Phạm vi

- Level 1–10: một tầng.
- Level 11: level đầu tiên dạy Elevator.
- Level 12: tổng hợp Portal + Elevator + Door.
- Level 14: Central Core — một Core/Pedestal mỗi tầng, Portal tầng dưới,
  bốn Energy Node tầng trên, Elevator tuần tự.
- Level 13 và 15 giữ một tầng để nhịp dạy và màn phán quyết không bị ngắt bởi
  chuyển camera.

## Quy tắc topology

Board framing giữ FOV 48° ở landscape và nới tối đa 62° ở portrait hẹp, để cùng một map không bị cắt mép trên Android.

- Dùng `LevelData.maps` với đúng hai layer cho Level 11, 12 hoặc 14.
- Mỗi layer tối đa 11×9; mục tiêu thường 9×7.
- Mỗi Elevator là một cặp ký hiệu `e` ở cùng X/Z nhưng khác Y.
- Kiro bắt đầu trên sàn thường, không spawn trên `e`.
- Không đặt hoặc đẩy Core qua `e` trong `sequential_floors`; Elevator là tuyến
  chuyển tầng của Kiro sau khi puzzle tầng hiện tại đã hoàn tất.
- Hai layer phải có chức năng và landmark khác nhau: ví dụ gian thánh đường ở
  tầng 1, ban công nghi lễ ở tầng 2.
- Camera phải cho người chơi đọc được điểm vào Elevator, điểm ra và mục tiêu của
  tầng kế tiếp trước khi cam kết bước vào.

## Chuyển tầng

Elevator chuyển tầng trong cùng gameplay scene, không phải chuyển sang scene mới.
Khi Kiro bước vào `e`:

1. khóa input trong thời gian animation;
2. phát âm thanh/VFX đi lên hoặc đi xuống;
3. đưa camera và focus sang layer đích;
4. hiện nhãn `TẦNG 1` hoặc `TẦNG 2` trong HUD;
5. giữ nguyên Core, cửa, plate, bridge và lịch sử Undo.

Gợi ý vẫn đánh dấu đúng ô ở tầng hiện tại. Nếu Kiro chỉ đi lệch bằng các bước đi
thường, hệ thống tìm đường ngắn quay lại một trạng thái của route đã kiểm chứng rồi
tiếp tục gợi ý từng bước. Nếu người chơi đã đẩy Core/xoay cầu làm thay đổi trạng thái
puzzle, hệ thống yêu cầu Hoàn tác thay vì trỏ thẳng vào ô đích bằng một route sai.

Tap-to-move không tự đi xuyên qua `e`. Tap trực tiếp đúng ô Elevator đã mở là
lệnh rõ ràng để Kiro tự đi tới cạnh thang và bước vào; tap một ô khác vẫn không
được phép lấy Elevator làm đường đi tắt.
Một lần Undo phải trả lại toàn bộ thao tác chuyển tầng như một move nguyên tử.

## Nhịp Level 11

- Tầng 1: đọc phòng, thấy Elevator bị khóa hoặc chưa cấp điện.
- Tầng 1: giải một mục tiêu ngắn để mở tuyến Elevator.
- Chuyển lên tầng 2: camera xác nhận không gian mới và một mục tiêu rõ ràng.
- Tầng 2: hoàn thành mục tiêu, nhận ký ức 11 và quay về nếu puzzle yêu cầu.
- Par mục tiêu 55–70; không thêm hành lang chỉ để tăng số bước.

## Nhịp Level 12

- Portal được ôn lại trước khi người chơi phải dùng Elevator.
- Một cửa giới hạn tuyến Kiro hoặc Core, nhưng không giới thiệu thêm mechanic mới.
- Thứ tự Core ở tầng 1 phải được giải đúng trước khi cam kết đi Elevator; sau
  khi lên tầng 2 không quay xuống, đúng với `sequential_floors`.
- Par mục tiêu 70–90; mỗi layer ≤ 11×8.

## Nhịp Level 14

- Tầng 1: một Core, Pedestal, Portal; tầng 2: một Core, Pedestal, bốn Energy
  Node. Không Plate. Mỗi tầng hoàn tất trước khi thang mở.
- Elevator cùng cột X/Z; route tối ưu 28 bước (nhịp lắng, không đỉnh độ khó).

## Nghiệm thu

Smoke test framing: `tests/verify_multifloor_camera.tscn` khởi chạy Level 11–12, chuyển focus từng tầng và kiểm tra camera center, FOV/framing cùng landmark Elevator/goal/energy còn nằm trong viewport.

- Solver xử lý đúng Y và tìm route tối ưu.
- `tests/verify.gd` replay được route có bước Elevator.
- Không có teleport bất ngờ khi tap một ô khác tầng.
- Camera không che khuất Elevator, mục tiêu hoặc Core sau khi chuyển tầng.
- Undo/Restart khôi phục đúng layer, vị trí Kiro và toàn bộ trạng thái puzzle.
- Playtest Android xác nhận nút, chữ tầng và âm thanh đọc được trong portrait lẫn landscape.
- Nút Gợi ý hoạt động theo ba cấp và không tăng số bước thật hay thay đổi par. Mỗi
  hành động mới được tiết lộ cộng một điểm `hint_penalty` vào `score_moves`, vì vậy
  có thể ảnh hưởng số sao; mở lại cùng thông tin không bị tính phí lần nữa và Undo
  không hoàn phí. Trạng thái này được lưu trong record hoàn thành.
