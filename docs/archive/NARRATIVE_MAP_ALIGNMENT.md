# Căn chỉnh map và cốt truyện

Đợt 2026-09-07. Nguồn hiện hành: resources/levels và StoryData; đây là bản ghi thay đổi, không phải đề xuất chưa triển khai.

## Các thay đổi

| Màn/phần | Hành vi sau chỉnh sửa |
| --- | --- |
| Mở đầu | Chương I chỉ gợi tín hiệu nhiễu; chưa tiết lộ Core chứa linh hồn. Intro IV đặt câu hỏi để L13/L14 tự trả lời. |
| L2 | Terminal Mara ở (6,0,1), sát lối vận chuyển Core; crate chuyển về (5,0,0), data rack ở (6,0,0). Route 28 bước đi qua điểm kích hoạt, thoại phát một lần. |
| L4 | Tên ký ức đổi thành “Dữ liệu bị che giấu”; EVA đã liên lạc từ L1. |
| L10 | Bỏ ba Energy Node; bệ phía bắc chuyển về (2,0,2). Hai Core và Portal, par 42. |
| L13 | Màn đầu có Energy Node; giọng nói cá nhân phát khi đồng bộ, xác nhận bản chất Core. |
| L14 | Giữ hai tầng và par 28; difficulty 2 phản ánh nhịp lắng. Bốn Node tầng trên dành cho bốn nhịp thú nhận, sau thắng là lời bàn giao. |
| L15 | Map riêng 9×9, 40 ô đi được, par 81; ba Core cho hai Pedestal và Plate giữ cửa. Không còn dùng lại bố cục hoặc route L8. |

L15 có hai không gian chức năng: khoang cấp nguồn ở phía nam và buồng phán quyết ở phía bắc. Node 1–3 buộc xử lý đường vận chuyển trong khoang dưới, Node 4 ở phía sau cửa. Console cầu nằm ở (2,0,5); cầu tại (3,0,4) và cửa K tại (3,0,3) tạo tuyến bàn giao. Plate (7,0,6) phải giữ Core tới khi kết thúc. Khôi phục tuyến chỉ mở quyền lựa chọn; không đồng nghĩa Kiro đã chọn RESTORE.

## Landmark

Năm GLB mới thay hình của các type truyện cũ trong BoardView; không đổi type hoặc tạo cơ chế mới. Mỗi footprint nguồn 0,82×0,82 ô, cao tối đa 0,58 ô; scale riêng của decoration vẫn được áp dụng.

| Type | Hình dáng |
| --- | --- |
| `silence_reliquary` | Thanh dẫn tách rời và dao cách ly mở — ngắt nguồn có chủ đích |
| `elias_testament` | Hộp bản ghi niêm phong trong đầu đọc — lời nhắn cá nhân |
| `soul_archive` | Ba khoang bản ghi độc lập — những cá nhân còn sót lại |
| `eva_conduit` | Giếng chiếu mở với bốn đầu cấp — bốn nhịp khôi phục EVA |
| `judgement_engine` | Bàn bàn giao với ba đầu nối chưa chọn — quyền quyết định |

Nguồn: `tools/build_narrative_landmarks.py`. Bounds: [NARRATIVE_LANDMARK_BOUNDS.json](../NARRATIVE_LANDMARK_BOUNDS.json). Scene xem chung: `scenes/editor/narrative_landmarks.tscn`, tạo lại bằng `tools/build_narrative_gallery.gd`. Đây là thay thế visual của type truyện hiện có; catalog chapter props và số item MeshLibrary không tăng trong đợt này.

![Năm landmark truyện](../NARRATIVE_LANDMARK_PREVIEW.png)

## Ending và ký ức

Giữ việc khôi phục ký ức khi thắng và dữ liệu save hiện có. Điều kiện 15/15 thể hiện đầy đủ hiểu biết sau campaign, không phải nhiệm vụ tìm vật phẩm ẩn. Bỏ nhãn TRUE ENDING.

- RESTORE: ý thức sống độc lập, có quyền rời mạng; đổi lại cần tiếp tục cấp nguồn và bảo trì.
- RELEASE: Kiro tự quyết định ngắt nguồn vĩnh viễn, không chỉ thi hành ý muốn Elias.
- PRESERVE: ý thức ngủ trong kho độc lập, thành phố dừng; giữ khả năng hồi sinh nhưng chưa có cuộc sống/giao tiếp hiện tại. Kiro nhận trách nhiệm bảo tồn.

Thông tin đánh đổi xuất hiện ngay trên nút lựa chọn và trong kết truyện. Không thêm lựa chọn giả vào puzzle trước màn ending.

## Kiểm tra

- `python tools/validate_levels.py`: nghiệm tối ưu/par/hint của 15 màn.
- `tests/verify.gd`: replay engine, Undo/Restart, Energy Node không xuất hiện trước L13, finale sử dụng cầu/cửa/bốn Node và khác L8.
- `tests/verify_narrative_events.tscn`: dùng StoryDirector thật với dialogue tự đóng để kiểm tra Mara trên route L2 và bốn lời thú nhận L14 đúng thứ tự, không phát lặp.
- `tests/verify_story_holograms.tscn`: năm model riêng, bounds và hologram L12/L14/L15.
- Validator placement/pilot và `tests/verify_interactions.tscn`: kiểm tra tích hợp.

Par ngắn hơn không tự động là dễ hơn. Dải L10/L14/L15 đã cập nhật trong blueprint theo vai trò mới; không thêm hành lang hoặc Core chỉ để đạt số bước cũ.

## Xác nhận hình ảnh đợt này

Đã render bằng Godot Compatibility với `--rendering-driver opengl3` trên Intel Iris Xe. Headless không dùng để chụp ảnh. Đã xem năm landmark và BoardView/camera thực của L2, L10, L11/L12 tầng trên, L13, L14 tầng trên và L15 ở đầu màn/sau 50 bước.

Ảnh kiểm tra tạo bằng `tests/narrative_map_capture.tscn`; dùng LevelData và replay GameLogic để đến tầng/trạng thái yêu cầu, không tải main scene hay ghi tiến độ. Ảnh không bao gồm HUD/dialogue hoặc hoạt cảnh chuyển tầng. Đây là kiểm tra khung nhìn 1280×720 mặc định, chưa phải mọi góc xoay/màn hình điện thoại.

- L1: thay visual data rack tại (6,0,2) bằng tường thấp (kit_wall_low_straight) để mở thông tầm nhìn vào ô sàn (6,0,1) và bệ đích (7,0,1).
- L2: dời terminal Mara và xóa lan can tại (7,0,2), thay crate tại (6,3), bookshelf tại (6,5) và data rack tại (7,5) bằng tường thấp để mở thoáng bệ đích và toàn bộ hàng z=4.
- L6: thay lò nung lớn tại (7,0,6) ở góc tiền cảnh bằng viền sàn thấp (kit_floor_corner) để không che Kiro ở ô xuất phát.
- L10: thay visual sáu ô tường (x2–7,z3) bằng tường thấp để thấy bệ mới và Core phía bắc.
- L14: thay vách tím core_wall tại (7,1,3) và bỏ railing tại (8,1,3) bằng viền sàn kit_floor_edge để bệ đích Pedestal tầng 2 thông thoáng hoàn toàn.
- L15: thay visual tường tại (2,3), (4,3), (4,5), (6,5) bằng tường thấp; cả bốn Node đọc được trong ảnh đầu màn. Các ô vẫn là tường trong puzzle.
- Ảnh kiểm tra cũ đã xóa khỏi git. Regen: `tests/narrative_map_capture.tscn` → `.codex_qa/visual_polish/` (gitignored). Protocol: [../VISUAL_POLISH_PASS.md](../VISUAL_POLISH_PASS.md).

Các bài solver, replay/Undo/Restart, sự kiện truyện, hologram, interaction và validator placement/pilot đều đạt. Lỗi Sanctuary `material null` về sau được xác định ở water-material path và đã sửa bằng surface override chọn lọc; capture Vulkan `Forward Mobile` hiện chạy sạch lỗi đó. Campaign visual review mới cũng đã kiểm HUD ở aspect landscape khoảng 20:9; hiệu năng/touch trên Android thật vẫn cần làm riêng. Xem [VISUAL_POLISH_PASS.md](../VISUAL_POLISH_PASS.md).
