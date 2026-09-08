# Nâng cấp: ổn định gameplay và input

## Đã triển khai

- Lưu tiến độ qua file tạm, flush trước khi thay thế; giữ bản `.bak` hợp lệ.
- Khi save chính hỏng, đọc bản dự phòng; dùng file tạm nếu không còn bản chính/dự phòng hợp lệ.
- Kiểm tra kiểu dữ liệu record trước khi tải, chặn hoàn thành chỉ số màn ngoài danh mục.
- Hủy hội thoại/intro khi đổi phiên; kiểm tra phiên sau các đoạn chờ để callback cũ không tác động màn mới.
- Hủy tween chuyển tầng khi đặt lại camera; hủy tween cấp điện khi tải lại màn.
- Nhận touch trực tiếp, bỏ chuột giả lập của touch, theo dõi một ngón tay, hủy gesture khi mất focus/pause/restart.
- Bổ sung phím thay thế còn thiếu mà không xóa cấu hình action hiện có.
- Replay + Undo từng nước và Restart toàn bộ 15 màn; kiểm tra phục hồi save và khóa phiên.

## Chạy kiểm tra

Từ thư mục dự án, dùng đường dẫn Godot trên máy hoặc `godot` nếu đã có trong PATH:

```powershell
godot --headless --path . -s tests/verify.gd
godot --headless --path . tests/verify_interactions.tscn
```

Bộ interaction phải chạy bằng scene để Godot thiết lập autoload trước khi biên dịch các thành phần UI/audio.
Fixture phục hồi save dùng tên riêng và được xóa sau kiểm tra, không ghi đè `progress.json`.

## Còn lại trong lộ trình

- Playtest Android thật: chạm HUD, vuốt/kéo, thay đổi focus và cỡ màn hình; chưa xác nhận chất lượng cảm giác điều khiển bằng test headless.
- Kiểm tra hình ảnh/camera màn 11–12, xử lý tầng che khuất và điểm đến Elevator.
- Đo FPS, bộ nhớ và tải màn trên thiết bị mục tiêu trước khi tối ưu mesh, đèn, VFX.
- Cân bằng độ khó và cảm giác điều khiển sau khi có bản Android thực tế.
- Playtest thực tế tuyến 13–15 trên Android và cân bằng cảm giác điều khiển/ánh sáng.

## UX đã triển khai tiếp theo

- Settings có âm lượng theo nhóm, rung phản hồi, giảm chuyển động và tương phản cao.
- HUD gameplay tự thu gọn theo chiều rộng màn hình; nút hành động giữ vùng chạm lớn và tránh chồng lấp.
- Âm thanh được tách bus Master/Music/SFX để slider tác động ngay trong runtime.

Đợt này không thay đổi thiết kế các màn hiện có hoặc tuyên bố toàn bộ lộ trình đã hoàn thành.
