# Ánh sáng dễ quan sát

Áp dụng cho bốn chương và toàn bộ 15 màn. Ánh sáng chính gần trắng, chiếu chéo từ trên với góc dốc hơn để bóng ngắn. Màu chương nằm ở wash yếu, vật liệu và đèn cục bộ: xanh thép Archive, đồng Foundry, xanh Sanctuary, xanh lạnh Core.

Tinh chỉnh theo yêu cầu cảm giác bí ẩn: giảm ambient, key và fill phủ toàn phòng; ambient mang sắc chương, ngoại cảnh giảm emission. Giữ nguyên đèn theo robot/core và tín hiệu tương tác. Các vùng tối có chiều sâu hơn trong khi ánh chính vẫn đủ để đọc ô sàn. Cấp điện nâng sáng vừa phải. Đã render lại bốn chương và chạy lại readability/mobile budget sau tinh chỉnh.

`resources/visuals/chapter_*.tres` sở hữu màu và mức ánh sáng khi phòng tối/sáng. `SceneEnvironmentController` giảm fog và bloom, tạo một nguồn bóng chính mềm; fill/wash không đổ bóng. Khi cấp điện, độ sáng tăng vừa phải và giữ hệ số chất lượng mobile.

`BoardLighting` cho đèn robot theo vị trí hiện tại, kể cả sau cấp điện và lên tầng. Spotlight core là con của core nên theo thao tác đẩy. Vùng sáng từ cửa, đế và core được thu gọn; emission của đèn trang trí, hologram và dải sáng khi cấp điện được giới hạn. Đèn nền thở nhẹ, chậm và đứng yên khi bật Reduced Motion. `SectorExterior` tăng ánh tự phát nhẹ ở vật liệu hành lang và kết cấu để rõ hơn mà không thêm light.

Đã kiểm tra render 15 màn/18 tầng, cùng trạng thái cấp điện tại L5/L11/L13. Kiểm tra ánh sáng theo vật thể, ánh sáng cấp điện, Reduced Motion, interaction, authored mechanisms, environment dynamics, module motion, scenery clearance, camera, game coordinator và mobile budget đều đạt. Không thay đổi luật giải đố. Mobile được kiểm tra bằng quality profile, chưa benchmark thiết bị Android thật.

Ảnh bốn chương: [LIGHTING_PREVIEW.jpg](LIGHTING_PREVIEW.jpg).
