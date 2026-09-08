# Level 13 — Những linh hồn đã mất

Mở Chương IV: The Central Core. Độ khó 2/5, một tầng 9×8 với 39 ô đi được.
Một Core phải qua ba nút theo thứ tự rồi về chân đế; par và route đã được solver xác minh là 40 bước.

- Nút 1: (3, 0, 2), buộc Kiro vòng xuống dưới Core để bắt đầu đồng bộ.
- Nút 2: (5, 0, 4), chuyển Core qua sảnh giữa.
- Nút 3: (2, 0, 5), yêu cầu đổi phía đẩy rồi thu hồi Core.
- Chân đế: (6, 0, 5), chỉ hoàn thành khi cả ba nút đã kích hoạt.

Nút chưa đến lượt chặn Core, nhưng Kiro vẫn đi qua được. Nút đã kích hoạt giữ trạng thái khi Core rời đi.
Số vàng chỉ nút hiện tại, xanh chỉ nút hoàn thành, xám chỉ nút chưa đến lượt. Undo khôi phục cả vị trí và tiến độ nút.

Landmark `soul_archive` dùng Hologram Projector có sẵn; ánh sáng trắng/cyan dùng profile Chương IV riêng.
Lần đồng bộ đầu phát lời thoại linh hồn tàn dư. Hoàn thành nhận ký ức 13 và mở tuyến tới Level 14 — Lời thú nhận của EVA.

Kiểm tra: `py -3 tools/level_design/check_l13.py`, bộ `tests/verify.gd`, và scene `tests/verify_interactions.tscn`.
