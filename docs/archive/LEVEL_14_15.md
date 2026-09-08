# Level 14–15 — Central Core

Hai màn cuối tạo nhịp đối thoại rồi phán quyết: L14 ngắn để nghe EVA; L15 có
buồng bàn giao riêng. Cập nhật 2026-09-07; xem [NARRATIVE_MAP_ALIGNMENT.md](NARRATIVE_MAP_ALIGNMENT.md).

## Level 14 — Lời thú nhận của EVA

- Hai layer 11×7, một Core và một Pedestal mỗi tầng; không có Plate.
- Portal ở tầng dưới, bốn Energy Node thẳng hàng ở tầng trên; Elevator nối hai tầng tuần tự.
- Route tối ưu: 28 bước. Đây là nhịp lắng có chủ đích, không phải đỉnh độ khó.
- Landmark `eva_conduit` dùng giếng chiếu với bốn đầu cấp. Mỗi Node khôi phục
  một phần hologram và một đoạn thoại; lời thú nhận cuối phát sau thắng.

## Level 15 — Phán quyết

- Một layer 9×9, 40 ô đi được, ba Core, hai Pedestal và một Plate giữ nguồn.
- Node 1–3 nằm trong khoang cấp nguồn phía nam. Cầu (3,4) và cửa K (3,3)
  dẫn tới Node 4 và hai đích phía bắc. Console tại (2,5), Plate giữ tại (7,6).
- Route tối ưu: 81 bước; cầu được triển khai một lần. Test xác nhận route
  sử dụng cầu, thay đổi cửa và kích hoạt đủ Node; map/route khác L8.
- Landmark `judgement_engine`; hoàn thành trao Ký ức 15 rồi nút “Màn tiếp theo”
  chuyển sang `ending_cutscene.tscn`.

RESTORE duy trì cuộc sống số và cần nguồn điện; RELEASE ngắt nguồn vĩnh viễn;
PRESERVE giữ ý thức ngủ trong kho độc lập chờ hồi sinh. Điều kiện 15/15 bản ghi
là hoàn thành hiểu biết trong campaign; không gọi PRESERVE là TRUE ENDING.

Kiểm tra từ thư mục dự án:

```powershell
py -3 tools/validate_levels.py
godot --headless --path . -s tests/verify.gd
godot --headless --path . tests/verify_interactions.tscn
```
