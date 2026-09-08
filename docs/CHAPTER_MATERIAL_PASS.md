# Vật liệu theo chương

**Đã áp dụng** cho mọi model trong `LevelData.decorations`. Mỗi surface `StandardMaterial3D` được duplicate trước khi chỉnh, vì vậy material nguồn trong GLB không bị thay đổi và model dùng ở chương khác không bị nhiễm màu. Profile hiện thêm một detail-albedo procedural (32x32 desktop, 16x16 mobile), tạo các đốm xước/ẩm/rỉ nhẹ mà không cần thêm texture bitmap vào repository.

| Chương | Profile | Định hướng |
| --- | --- | --- |
| I | `archive` | Tint xanh thép nhẹ, metallic trung bình, bề mặt hơi nhám, emission cyan, xước nhẹ |
| II | `foundry` | Tint đồng/đỏ cam, metallic cao, roughness trung bình, emission cam, vết rỉ rõ hơn |
| III | `sanctuary` | Tint xanh teal, metallic thấp hơn, roughness cao hơn, emission nước, đốm ẩm |
| IV | `central_core` | Tint xanh lạnh, metallic cao, roughness thấp, emission cyan/teal, xước rất nhẹ |

Profile chỉ tác động lên model trang trí được spawn từ `decorations`. Floor, wall, Core gameplay, Plate, Door và các material procedural vẫn dùng palette/gameplay state riêng để không làm mất khả năng đọc puzzle. Emission gốc được giữ và pha nhẹ theo accent của chương; hệ thống power/dim tiếp tục điều khiển mức sáng sau đó.

Các profile nằm ở [chapter_material_profiles.gd](../src/data/chapter_material_profiles.gd). BoardView áp dụng chúng trước khi đăng ký material emission theo power level.

## Kiểm tra

```powershell
godot --headless --path . -s tests/verify_material_profiles.gd
godot --headless --path . tests/asset_pilot_runtime.tscn -- --level=2
godot --headless --path . tests/asset_pilot_runtime.tscn -- --level=6
```

Weathering dùng `detail_blend_mode = MULTIPLY` với UV1 của mesh, giữ nguyên màu nền và emission. Desktop dùng texture procedural 32x32; mobile dùng bản 16x16 và giới hạn số surface có detail theo từng profile (8–12 surface/model). Nếu model không có UV1, material vẫn hiển thị màu/tint gốc mà không gây lỗi. Đây là pass màu/vật liệu nhẹ, không đổi mesh, collision, footprint hay dữ liệu puzzle. Cường độ tint/detail cần được đánh giá thêm trên thiết bị Android thật; nếu bề mặt bị gắt, giảm `strength`, `weather_dark` hoặc `mobile_surface_limit` trong profile.
