# Áp dụng sàn/tường theo chương

Yêu cầu: áp dụng các biến thể sàn/tường mới vào campaign, ưu tiên chất lượng thị giác và đọc puzzle.

- Bake bốn floor skin hoàn chỉnh từ foundation sàn hiện tại và panel mới. Mặt panel ở cao độ gần inset sàn cũ; một mesh, material theo chương. Giữ bản overlay gốc cho editor.
- Chọn các vùng sàn liên tục theo bản sắc chương; chừa mục tiêu, Core lúc spawn, portal/plate/thang/cầu và các entity. Thêm tường thấp mới trên ô chặn trống cạnh đường đi, giữ cột góc và props/landmark hiện hữu.
- Chỉ thêm decoration, không sửa map/maps/entities/hint_route/par. Renderer thay base tile ở cell có `surface_skin`, không vẽ chồng hai sàn.
- Validate dữ liệu, gameplay/đa tầng/FX, cao độ floor skin và camera gameplay từng chương; review ảnh tất cả level/tầng.

Trạng thái: hoàn thành 2026-10-02. Bốn full floor skin đã bake, 293 panel cell và 343 wall cell áp dụng vào 15 level/18 tầng chơi. Đối chiếu puzzle với HEAD và chạy lại idempotence đạt; placement và 11 nhóm regression đạt. Đã review 18 ảnh gameplay. Hướng dẫn: `docs/CAMPAIGN_SURFACES.md`; Android thật chưa benchmark.
