# Module map động

Yêu cầu chủ dự án: toàn bộ module tham gia dựng map chuyển sang động ở nơi phù hợp; sàn/tường và cấu trúc không cần chuyển động được giữ cố định. Chọn hiệu ứng đẹp, theo bản sắc từng chương.

- Kiểm kê scenery đang dùng và phân loại cơ khí / điện / hữu cơ / nước / năng lượng / kết cấu tĩnh.
- Tạo clip Blender thật cho con lăn, piston, bánh răng, vòng năng lượng, hologram và tán cây; giữ pivot/root và kích thước nghỉ của GLB hiện hữu.
- Godot tự gắn hiệu ứng phù hợp vào model trong campaign: tia lửa ở mối hỏng, hơi nước ở van/ống, màn hình quét, tín hiệu và ánh sáng nguồn. Không cần sửa layout LevelData.
- Tái sử dụng hiệu ứng gameplay cửa, plate, cầu, thang, portal; bổ sung trạng thái Energy Node. Không đổi luật puzzle, vị trí ô, route hoặc par.
- Đặt controller dưới model/tầng; tắt khi tầng ẩn và dừng theo pause. Giảm hạt/âm trên mobile, không thêm đèn động.
- Nghiệm thu clip sau import, chuyển động thật theo thời gian, coverage catalog, cleanup, tầng ẩn, power/Undo, mobile và regression; review video/gallery và campaign.

Trạng thái: hoàn thành 2026-10-02. Đã kiểm kê 71 scenery type (41 dynamic, 30 static), bake 18 GLB/nguồn Blender, gắn vào campaign, thêm bàn áp lực theo trạng thái và Node lens shader. Đã qua 15 nhóm regression và các lần kiểm tra lại sau sửa; renderer Vulkan thật kiểm shader, cleanup và ảnh gameplay. Gallery Blender/Godot và GIF preview đã tạo. Hướng dẫn: `docs/MODULE_MOTION.md`; Android thật còn cần benchmark.
