# Ngoại cảnh sector

Ngoại cảnh được tạo theo kích thước map, áp dụng cho cả 15 màn. Hành lang bảo trì, lan can, dầm đỡ, cột và đường ống nằm dưới sàn chơi. Vật liệu nền tối hơn gameplay để robot, đường đi và các tín hiệu tương tác giữ độ rõ.

| Chương | Bối cảnh |
|---|---|
| Archive | Kho dữ liệu thấp, khung chứa và đường bảo trì xanh thép |
| Foundry | Máy công nghiệp, ống dẫn lớn, chân đế và ánh đồng |
| Sanctuary | Bể nền xanh tối, cột đổ, đá và rễ |
| Central Core | Vòng reactor thấp, trụ kỹ thuật và ánh xanh lạnh |

`src/view/sector_exterior.gd` sở hữu ngoại cảnh; `BoardView` chỉ khởi tạo và truyền bounds/chapter. Thuộc tính `void_environment` được giữ để lời gọi `resonate()` của gameplay tiếp tục hoạt động. Renderer void cũ không còn được khởi tạo. Các sao, beacon và dải neon xa ngẫu nhiên đã được bỏ khỏi `BoardEnvironment`; shell gần và hiệu ứng trong phòng được giữ.

Geometry dùng sáu MultiMesh theo vật liệu, thêm hai vòng ở Core. Bounds được tính từ transform và mesh để culling đúng cả với thanh/ống xoay. Không thêm light, particle, collision; mobile giảm số đoạn vòng. Resonance chỉ tăng nhẹ emission trong một nhịp, tôn trọng Reduced Motion.

Kiểm tra: `verify_sector_exterior`, `verify_mobile_render_budget`, `verify_campaign_surfaces`, `verify_environment_dynamics`, `verify_module_motion`, `verify_multifloor_camera`, `verify_interactions` đều PASS. Kiểm tra mobile là profile mô phỏng, chưa đo trên thiết bị Android thật.

Ảnh gameplay đại diện: [SECTOR_EXTERIOR_PREVIEW.jpg](SECTOR_EXTERIOR_PREVIEW.jpg).
