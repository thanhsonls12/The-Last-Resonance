# Kiểm kê asset — đợt 1

Ngày kiểm kê: 2026-09-05. Phạm vi: thư viện hiện có và tham chiếu trong dự án The Last Resonance.

Cập nhật sau kiểm kê: đã bổ sung 15 GLB chương II–IV và tích hợp catalog/editor; xem [CHAPTER_MAP_PROPS.md](../CHAPTER_MAP_PROPS.md). Các con số bên dưới là mốc trước đợt bổ sung; danh mục tự động phản ánh lần chạy bộ quét gần nhất.

## Kết quả

Đã kiểm kê **239 file asset, 90,54 MiB** trên đĩa, không tính metadata import, UID, README và file ẩn.

| Phân loại tĩnh | Số file | Ý nghĩa |
| --- | ---: | --- |
| Có tham chiếu trong dự án | 104 | Có khai báo trong mã, resource hoặc cấu hình; chưa chứng minh xuất hiện trong một lượt chơi |
| Khớp đường dẫn động | 3 | Ba ảnh ending khớp `ending_%s_cg.jpg` |
| Chỉ thấy trong công cụ/test | 40 | Phục vụ biên tập hoặc pipeline; không coi là file thừa |
| Chưa tìm thấy tham chiếu | 92 | Danh sách cần đánh giá tiếp, không phải danh sách xóa |

Không phát hiện đường dẫn asset literal bị thiếu trong phạm vi bộ quét hỗ trợ. Không có file trùng hoàn toàn theo SHA-256. Các bản cùng tên ở thư mục gốc và `baked/` có thể khác dữ liệu, tỷ lệ hoặc bố cục; không thay thế qua lại chỉ dựa vào tên.

Danh mục từng file: [ASSET_INVENTORY.md](../ASSET_INVENTORY.md). Bằng chứng đường dẫn/dòng, kích thước và hash: [ASSET_INVENTORY.json](../ASSET_INVENTORY.json).

## Phát hiện và việc cần làm tiếp

| Nhóm | Bằng chứng hiện tại | Hành động đề xuất |
| --- | --- | --- |
| SFX | 80 WAV; 27 có tham chiếu dự án, 53 chưa tìm thấy. `play_plate()` đang dùng âm Core với pitch khác nhau | Nghe và nối `SFX_PressurePlate_Press/Release`, sau đó Elevator Loop/Stop và Portal Activate/Reject vào sự kiện phù hợp |
| Ambience | 10 WAV; 4 có tham chiếu, 6 chưa tìm thấy. Tổng 43,49 MiB | Nghe sáu loop phụ trước khi đặt làm mới; đo bộ nhớ/tải màn trước khi đổi định dạng hoặc cách nạp |
| Voice | 11 file, gồm 8 MP3 có tham chiếu và 3 WAV chưa tìm thấy | So sánh nội dung WAV/MP3; giữ các bản WAV như ứng viên nguồn, chưa kết luận là bản thử |
| Model | 44 GLB trong `baked/`; pipeline tách vật thể từ roster trình bày | Giữ riêng nguồn xuất, roster và bản dùng cho bàn chơi; đối chiếu pivot/tỷ lệ khi tích hợp |
| Props kể chuyện | `archive_lock_node`, `k_series_mold`, `soul_archive`, `sanctuary_pool`, `eva_conduit`, `judgement_engine` dùng lại model chung trong `board_view.gd` | Đợt model mới chọn một vật thể chủ đạo mỗi chương; hiện chưa tạo model |
| Portrait | Bốn avatar vuông hiện có và được tham chiếu; README còn nhắc các dialogue card v3 và bản thử không thấy trong thư mục | Cập nhật tài liệu portrait khi chốt nguồn artwork; không đưa các card vắng mặt vào danh sách asset hiện có |
| Tài liệu audio | README ghi 76 SFX, thư mục thực tế có 80 | Cập nhật README trong đợt tích hợp âm thanh |
| VFX | Hiệu ứng được tạo bằng Godot trong `src/view/vfx_manager.gd` | Đánh giá hiệu ứng trong game; thư mục VFX không có texture không đồng nghĩa thiếu hiệu ứng |

## Nguồn và giấy phép

Chưa tìm thấy tài liệu LICENSE/COPYING/OFL đi kèm trong phạm vi kho dự án đã kiểm tra. Trạng thái giấy phép là **chưa xác minh**, không phải kết luận không có quyền sử dụng. Không suy ra giấy phép từ tên file hay tên font.

| Nhóm | Bằng chứng nguồn trong repo | Thông tin còn thiếu |
| --- | --- | --- |
| Model/material | `assets/models/README.md`, `tools/convert_blend_assets.py` mô tả xuất từ Blender; `tools/bake_asset_library.py` có manifest tách roster | File Blender nguồn, tác giả/nhà cung cấp, điều khoản sử dụng và bản ghi nguồn cho từng bộ |
| SFX/ambience | `assets/audio/README.md` ghi chuyển từ dự án Unity Sokoban | Nguồn gốc thư viện trước khi chuyển, giấy phép, yêu cầu credit |
| Voice | `tools/gen_tts.ps1` có lệnh tạo `voice_ch1_eva_intro_msg.wav` qua System.Speech, chọn Zira/David | Nguồn tám MP3 và hai WAV còn lại; điều khoản phân phối đầu ra của công cụ/giọng đã dùng |
| UI/icon/portrait/ending | Có file và mô tả bố cục/palette trong README | File nguồn, tác giả hoặc lịch sử tạo ảnh, điều khoản/credit |
| Font | Bảy TTF: Chakra Petch, Rajdhani, Share Tech Mono | Gói tải gốc và văn bản giấy phép khớp phiên bản |
| Shader/VFX | Có mã nguồn trong dự án | Thông tin tác giả/nguồn và giấy phép của phần được tái sử dụng, nếu có |

Khi thu thập nguồn, bổ sung một sổ nguồn có các trường: đường dẫn hoặc nhóm asset, tác giả, nguồn, phiên bản/ngày tải, giấy phép, bằng chứng, yêu cầu credit, bản nguồn và bản export tương ứng.

## Tiêu chí khép lại đợt kiểm kê

- [x] Danh mục toàn bộ file hiện có, kích thước và hash.
- [x] Phân loại tham chiếu dự án, công cụ/test và chưa tìm thấy.
- [x] Kiểm tra đường dẫn literal thiếu và file trùng hoàn toàn.
- [x] Ghi nhận nguồn có bằng chứng và các khoảng trống giấy phép.
- [x] Xác định danh sách ưu tiên tích hợp tiếp theo.
- [ ] Xác nhận chất lượng nghe/nhìn, scale/pivot và độ rõ trong game — thuộc đợt đánh giá/tích hợp tiếp theo.
- [ ] Bổ sung chứng từ nguồn/giấy phép từ thư viện gốc — cần dữ liệu ngoài repo hiện tại.

## Chạy lại

```powershell
python tools/audit_assets.py
```

Lệnh chỉ tạo lại hai file `docs/ASSET_INVENTORY.md` và `docs/ASSET_INVENTORY.json`. Báo cáo nhận xét này được cập nhật thủ công khi có thay đổi.

Bộ quét nhận diện đường dẫn literal, phép nối hằng đường dẫn như `BAKED + "Floor-Tile.glb"` và ứng viên mẫu `%s`. Không phân tích khả năng thực thi, dependency nhúng trong GLB hay mọi biểu thức tạo đường dẫn. Không dùng kết quả để tự động xóa asset. Dung lượng file nguồn không đại diện RAM/VRAM hoặc dung lượng APK.
