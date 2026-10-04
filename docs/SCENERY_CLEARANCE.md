# Vật thể và lối đi

Lỗi: một số vật thể đặc chỉ được render trên ô vẫn cho phép đi; một số mesh bất đối xứng hoặc có offset lấn sang ô bên cạnh. Map 11 có cây tầng trên và bờ nước tầng dưới thuộc trường hợp này.

Đã chuyển 21 decoration ở L2, L6, L9–L14 sang ô tường có sẵn, giữ nguyên bản đồ puzzle, entities, hint route và par. `GameLogic.DECORATION_WALL_TYPES` và solver Python nhận biết cây, máy, lan can, ống, bờ nước cùng các prop đặc khác. Sàn, mặt nước phẳng và portal vẫn cho đi theo luật hiện tại.

`BoardDecorations` đo bounds sau yaw, scale và biến thể, đặt tâm footprint vào ô bị chặn và giới hạn chiều ngang ở 0.88 ô. Chiều cao giữ nguyên; vị trí hiệu ứng đi theo prop đã chỉnh. Phần khoảng trống còn lại dành cho thân robot ở ô sát bên.

Sửa bổ sung L9: `sanctuary_pool` dùng model Portal có đế/khung đặc, nên phải thuộc nhóm solid. Chuyển từ (2,0,1) sang ô tường (2,0,0). Hai portal gameplay ở glyph a/b giữ nguyên. Regression riêng kiểm tra pool nằm trên ô chặn và cả hai portal còn tồn tại; replay 15 màn và kiểm tra mesh clearance đều PASS.

Kiểm tra `verify_scenery_clearance` đo mesh thực của toàn campaign: prop đặc nằm trên ô tường có sẵn, logic chặn ô đó, mesh nằm trong footprint. `verify` phát lại đường giải cả 15 màn thành công. Các kiểm tra placement, interaction, navigation, floor/elevator, camera, modular assets, surfaces, dynamics, module motion và mobile profile đã chạy đạt. Đã render lại tám màn thay đổi và hai tầng L11 sau chỉnh cuối.
