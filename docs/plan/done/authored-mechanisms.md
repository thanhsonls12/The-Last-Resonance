# Model cơ chế trong gameplay

Phạm vi: dùng GLB Elevator, Door và Bridge hiện có trong gameplay; giữ state/tween/Undo của kiến trúc refactor. Không bake thêm asset hoặc thêm props khác.

- Cửa: khung đứng yên, panel đi theo root mở/đóng hiện tại; giữ material trạng thái.
- Cầu: deck dùng GLB, rails tách vào rail root hiện tại để rút/xoay.
- Thang: station và cabin di chuyển dùng GLB; giữ label, nguồn, camera và chuyển tầng tuần tự.
- Kiểm tra model được instance, phần chuyển động, interaction/elevator regression và camera thực.

Trạng thái: hoàn thành 2026-10-02. Ba GLB đã dùng trong gameplay, panel/frame và deck/rails tách theo state hiện có, thang có model station/cabin. Kiểm tra và camera review đạt; hướng dẫn `docs/AUTHORED_MECHANISMS.md`.
