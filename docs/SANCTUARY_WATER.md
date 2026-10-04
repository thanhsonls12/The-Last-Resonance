# Mặt nước Sanctuary

Chương 3 (L9–L12) có mặt nước thật dưới nền và quanh hành lang bảo trì. Một PlaneMesh ở y=-1.48 dùng shader `sanctuary_basin.gdshader`: sóng nhẹ, gợn nhỏ trôi, sắc nước sâu/nông và phản sáng thủ tục. Mép xa tối dần. Không dùng screen reflection, không thêm light/particle/collision. Mobile giảm subdivision; đồng hồ shader ngừng khi pause hoặc Reduced Motion.

`SectorExterior` sở hữu mặt nước và thời gian chuyển động. Nước luôn dưới nền giải đố và các tầng cao. Gameplay không thay đổi.

Landmark `sanctuary_pool` tại L9 dùng `Sanctuary-Pool.glb`, thay model Portal trước đây. Shader nước dạng lỏng chỉ gắn vào material Water Blue; Ancient Stone và Energy Cyan được giữ. Bỏ cylinder hologram chồng lên hồ. Hồ vẫn nằm tại ô tường (2,0,0), footprint giữ trong ô chặn; hai portal gameplay không đổi.

Đã render bốn màn/sáu tầng Sanctuary. Replay cả 15 màn, scenery clearance, water/basin, environment dynamics, module motion, mobile budget và camera nhiều tầng đều PASS. Kiểm tra mobile là quality profile, chưa benchmark Android thật. Ảnh: [SANCTUARY_WATER_PREVIEW.jpg](SANCTUARY_WATER_PREVIEW.jpg).
