# Bổ sung kit dựng map

Yêu cầu: bổ sung Energy Node, biến thể sàn/tường bốn chương và chân đỡ/viền thang máy.

- Tạo 13 GLB và một Blender gallery riêng, không ghi đè roster đang mở.
- Giữ tỷ lệ authoring 2×, runtime 0.5; sàn là lớp phủ mỏng, tường thấp cao dưới 0.4 ô, chân đỡ cao 1.14 ô với clearance 0.01 ô cho tầng cách nhau 1.15 ô.
- Đăng ký catalog riêng trong BoardView, MeshLibrary và GridMap sync. Energy Node dùng model mới với feedback gameplay hiện có.
- Không tự thay bố cục hay luật puzzle của campaign. Kiểm tra bounds/import, ghép tầng, round-trip editor và regression liên quan; xem ảnh render.

Trạng thái: hoàn thành 2026-10-01. Đã xuất 13 GLB, lưu gallery Blender riêng, tạo scene Godot, thêm 12 item vào MeshLibrary và dùng Energy Node mới trong runtime. Sáu nhóm regression liên quan đã qua; kiểm tra expansion chạy lại sau chỉnh clearance và đạt. Đã xem ảnh preview và mở gallery mới trong Blender. Hướng dẫn: `docs/MAP_KIT_EXPANSION.md`. Android thật chưa benchmark.
