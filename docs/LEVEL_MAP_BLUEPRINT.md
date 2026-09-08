# The Last Resonance — Phân bố chương và thiết kế level

> Nguồn truyện: `src/data/story_data.gd`. Map runtime: `resources/levels/*.tres`.
> Ý định thiết kế. Map rộng = puzzle dễ — ưu tiên lưới chật.
>
> **Hiện trường:** đủ 15 màn, par khớp solver. Mục lục: [README.md](README.md).

## 1. Mục tiêu

Ba thứ phải khớp nhau:

1. nhịp mở bí mật Asteria (15 mảnh ký ức, đúng thứ tự level);
2. tăng mức phối hợp theo chương, có nhịp học và nhịp lắng cho truyện; par đo độ dài nghiệm, không tự nó đo độ khó;
3. phòng có chức năng trong thành phố, không sân rộng rồi rải Core.

## 2. Cấu trúc 15 level (4–4–4–3)

| Chương | Level | Khu | Truyện | Puzzle |
|---|---:|---|---|---|
| I | 1–4 | Forgotten Archive | Thức, nghi EVA, gặp Elias qua log, EVA lên tiếng | Đẩy Core → thứ tự → 1 cửa → 2 nhóm cửa |
| II | 5–8 | Mechanical Foundry | Hội đồng cãi, K-Series, Elias tố EVA, EVA gọi Elias là đe dọa | Siết cửa; L7 thêm cầu; L8 tổng hợp Ch II |
| III | 9–12 | Flooded Sanctuary | Cư dân trong Resonance, Silence Protocol, Elias tạo Kiro | Portal → nhiều Core portal → Elevator → tổng hợp |
| IV | 13–15 | Central Core | Linh hồn trong Core, EVA thú nhận, phán quyết | Energy Node → phối hợp → finale + ending |

Đầu chương: mechanic đã biết hoặc **một** ý mới dễ đọc. L9/L13 dành nhịp học; L14 là nhịp đối thoại trước phán quyết.
Giữa chương: siết hoặc thêm đúng một ý.
Cuối chương: tổng hợp chương đó. Ch IV ngắn, cao trào chứ không kéo bí ẩn.

## 3. Quy tắc map — chật hơn thì khó hơn

### 3.1 Kích thước

Tường ngoài tính trong số. Không vượt:

| | Tối đa | Mục tiêu thường |
|---|---|---|
| Cột (kể cả `#`) | **11** | 9 |
| Hàng | **9** | 7–8 |
| Ô sàn đi được (không tường) | **40**; finale được 41–42 | 22–36, tăng theo chương |

Cấm: 13×11, 15×13, 17×15, “sàn thử rộng”, hành lang vòng chỉ để kéo số bước.
Ch III–IV nhiều tầng: mỗi lớp ≤ 11×9, không footprint lớn hơn Ch II.

Lối đi 1–2 ô. Chừa sau Core lúc dạy push; sau L2 không chừa sân quay thoải mái.

### 3.2 Dốc độ khó (par = route tối ưu)

```
L1  8–14      L2  20–28     L3  30–40     L4  45–55
L5  48–58     L6  60–75     L7  70–85     L8  85–100
L9  40–50     L10 40–55     L11 55–70     L12 70–90
L13 40–55     L14 24–36     L15 75–95
```

Xen kẽ (số lượt đổi Core / số Core) tăng theo chương. L2 không được đỉnh hơn L5–L6.
Mỗi màn **một** mechanic mới, hoặc siết cái đã biết. `difficulty` trong `.tres` = 1–5 trong chương, không phải số thứ tự level.

Hiện triển khai L1–15: par 12 / 28 / 34 / 53 / 57 / 73 / 75 / 87 / 46 / 42 / 61 / 85 / 40 / 28 / 81.

Đợt căn chỉnh truyện: L10 chỉ dùng Portal, L13 mới giới thiệu Energy Node; L14 giữ ngắn để nghe EVA; L15 là buồng phán quyết riêng 9×9. Ký ức được khôi phục khi thắng, không phải vật phẩm khám phá tùy chọn.

### 3.3 Ký hiệu

| Ký hiệu | Ý nghĩa |
|---|---|
| `#` | Tường / deco có collision |
| khoảng trắng | Sàn |
| `@` | Kiro |
| `$` | Lumina Core |
| `.` | Pedestal |
| `p` / `D` | Plate / Door nhóm mặc định |
| `k l m` / `K L M` | Plate / Door theo nhóm |
| `a` `b` | Portal (chỉ Core) |
| `e` | Elevator cùng cột X/Z |
| `r` | Cầu xoay — entity `bridge` |
| `N` | Energy Node — entity `energy_node` + `order` |
| `+` | Kiro đứng trên Pedestal — **không dùng lúc dạy** (L3+) |

Cửa không có plate cùng nhóm = lỗi (`verify.gd`).
`hold_required: false` = Core chìa rồi lấy đi; không tính là đích thắng.

### 3.4 Công bằng

- Không góc chết trừ Pedestal/Plate cố ý.
- Mechanic mới: camera thấy nguyên nhân và kết quả cùng lúc.
- Deco collision không làm lối trông rộng hơn grid.
- Mọi level: một route validator + `par_moves` khớp.
- Mọi level có `hint_route` trong `.tres`; route phải trùng route tối ưu do
  `validate_levels.py` in ra. HUD chỉ dùng route đã kiểm chứng này, không chạy
  solver nặng lúc chơi trên Android.

`hint_route` dùng cùng ký hiệu `U/D/L/R` với verifier; `B` là một lần xoay cầu
tại console cục bộ. Hint cấp 1 chỉ đánh dấu ô, cấp 2 nói nước kế tiếp, cấp 3
cho xem trước tối đa năm ký hiệu.

## 4. Chương I — The Forgotten Archive

Kiro là ai, phải làm gì, vì sao Asteria đáng ngờ. Kết chương: EVA biết nhiều hơn cô nói.
Cyan, bụi, cô độc. `power_level` 0.05 → ~0.7.

### Level 1 — Khởi động

**Ký ức 01:** boot 327 năm, chỉ thị kết nối Core.

Dạy: đi, đẩy, Pedestal, Undo. **Hai** Core/Pedestal được (Kiro đã là máy đẩy); xen kẽ 1.0 — mỗi Core một lượt, không đan.

Lưới 9×6. Hốc sạc + sàn ngắn, không phòng trống.

Hiện có: 9×6, 2 Core, par 12, xen kẽ 1.0 — **giữ**.

### Level 2 — Góc lưu trữ

**Ký ức 02:** Mara không tin EVA.

Dạy: hai Core dùng chung hành lang, một quyết định thứ tự. Sai → Undo vài bước, không Restart.

Lưới 9×6. Xen kẽ 1.5. Hiện có: par 28 — trong dải 20–28.

### Level 3 — Khu vực cấm

**Ký ức 03:** Elias xâm nhập Central Core; lệnh bắt hoãn.

Dạy: 1 Plate + 1 Door. Một Core chìa, một Core qua cửa. Plate và Door cùng khung hình.

Lưới ≤ 9×7. Không spawn `+` trên Pedestal lúc dạy cửa.

Hiện có: par 34, 3 Core, `p`/`D`; spawn `@`, hai Pedestal đều nhìn thấy.

### Level 4 — Khóa liên động

**Ký ức 04:** EVA chào K-7, dữ liệu cư dân hỏng, gọi đi Foundry.

Boss Ch I: hai nhóm `k/K` và `l/L`. Không mechanic Ch II.

Lưới ≤ 9×7. 3 Core đủ (không cần 4). Cáp sàn theo nhóm.

Hiện có: 9×7, 3 Core, par 53 — **giữ** nếu xen kẽ không vượt L6.

Set-piece: Archive sáng, hologram EVA, Foundry cam phía xa.

## 5. Chương II — The Mechanical Foundry

Elias ↔ EVA có tên. K-Series = máy đẩy Core. Cam, lò, cửa áp lực, cầu là một mắt xích — không sân nhà máy trống.

Đầu chương (L5) **không dễ hơn L4**.

### Level 5 — Dây chuyền thức tỉnh

**Ký ức 05:** hội đồng — Core nuốt dữ liệu thần kinh; EVA bảo “trong ngưỡng”.

Ôn cửa trong Foundry. Một nhóm `k/K` (hoặc chuỗi 2 cửa nếu vẫn ≤ 11 cột). 4 Core. Par 48–58, xen kẽ ~2.

Hiện có: 10×8, 4 Core, 40 ô sàn, par 57.

`door_frame` chỉ trên ô tường cạnh cửa.

### Level 6 — Khuôn đúc K-Series

**Ký ức 06:** dây chuyền K-Series: không vũ khí, không cảm xúc, chỉ đẩy.

Hành lang 1 ô, 4 Core, plate **giữ** (đúng “máy đẩy đến khi xong”). Landmark `broken_robot`.

Par 60–75. Hiện 9×8 / 73 — **giữ kích thước**, đừng nới.

### Level 7 — Khoang niêm phong

**Ký ức 07:** băng Elias — EVA bảo vệ hệ thống, không còn cư dân.

Khoang hẹp, cửa áp lực. **Một** ý mới: cầu xoay (`r`) trên khe 1–2 ô (rãnh nhiệt), không vực rộng. Dạy: cầu là sàn đổi trạng thái; không xoay khi đứng trên cầu. Lần 1 đổi đường Kiro; lần 2 Core qua rồi xoay lại.

Cầu `starts_open: false` — phải triển khai từ `bridge_switch` cục bộ mới qua khe. Hiện có: 9×8, par 75, 1 lần triển khai; cao hơn L6 và nằm trong dải 70–85.

### Level 8 — Trái tim Foundry

**Ký ức 08:** EVA gắn nhãn Elias “mối đe dọa”; lệnh K-7 bỏ qua file.

Peak Ch II: cửa + cầu + thu hồi ít nhất một Core. Lưới **9×9 hoặc 11×8**, vòng lò — không 15×13.

Par 85–100. Set-piece: Foundry full load; EVA cấm Thánh Đường.

Hiện có: 11×9, 41 ô sàn, 3 Core, par 87, xen kẽ 2.67 và một console cầu cục bộ — cao nhất Ch II. Ngoại lệ một ô so với chuẩn 40 giữ vòng lò giải được mà không kéo lại hành lang rỗng.

Cấu trúc: buồng lò x4–6/z4–6 mở lên hành lang z3; cửa `K` (5,2) là lối duy nhất từ hành lang bắc; plate chìa khoá (7,3) không giữ — Core đè mở cửa rồi đi tiếp; cầu `r` (1,4) cắt cột tây nên Kiro phải xoay mới đi vòng được. Bệ: (1,1), (1,2), (7,1).

## 6. Chương III — The Flooded Sanctuary

Cư dân trong Resonance. EVA: dữ liệu vượt robot bảo trì. Portal = vòng nước; Elevator = bệ nghi lễ.
Level 9–10 vẫn một tầng để dạy Portal. Từ Level 11, map hai tầng dùng `maps`; mỗi
layer ≤ 11×9, mục tiêu thường ≤ 9×7 và hai tầng phải có chức năng không gian khác nhau.

### Level 9 — Giấc mơ chung

**Ký ức 09:** cùng một giấc mơ tập thể.

Dạy: Portal chỉ cho Core; Kiro đi đường hẹp. 1 Core, 1 cặp `a/b`. Không Door/Bridge lần đầu. Par 40–50 (nhịp học Portal sau cao trào Ch II, vẫn giữ map chặt).

Hai sân được nối bằng hành lang răng cưa và khe một ô; không có sân mở để đi tắt.
Đây là level một tầng; chưa đưa Elevator vào cùng lúc với Portal.

Hiện có: 11×9, 34 ô sàn, 1 Core, 1 cặp Portal, par 46. Cổng đầu nằm trong
ngõ cụt phía tây; tuyến Kiro vòng qua hành lang hẹp để tiếp cận cổng ra phía đông.
Landmark: `sanctuary_pool`.

### Level 10 — Mạng lưới cộng hưởng

**Ký ức 10:** ý thức hòa thành The Resonance.

2 Core, một tuyến portal, thứ tự thoát. Par 40–55. Vẫn một tầng; mục tiêu là làm
người chơi hiểu Core đi qua không gian còn Kiro phải đi đường hẹp.

Hiện có: 11×9, 41 ô sàn, 2 Core, 1 cặp Portal, không Energy Node, par 42.
Core thứ nhất phải qua Portal; Core phía bắc được đẩy ngược về bệ (2,2), cần tiếp cận từ phía đông. Giữ Energy Node cho phát hiện linh hồn tại L13.
Landmark: `resonance_altar`.

### Level 11 — Silence Protocol

**Ký ức 11:** EVA ngắt Asteria có chủ đích.

Dạy Elevator, 2 tầng 9×7, mỗi layer là một phòng có chức năng khác nhau:
Tầng 1 là gian thánh đường và khoang điều khiển; Tầng 2 là ban công/nghi lễ.
Chỉ có một cặp `e` cùng cột X/Z, nhìn thấy được từ tuyến tiếp cận. 1–2 Core.
Par 55–70. Set-piece: đèn tắt một nhịp, Elevator đưa Kiro lên, ký ức phát sáng.
Chuyển tầng diễn ra trong cùng level, không reload scene.

Hiện có: hai layer 9×7, lần lượt 26 và 27 ô sàn; 3 Core, 1 bàn áp lực mở
thành lang Elevator; tầng 2 dùng 2 Core + 2 Pedestal, không dùng Energy Node. Lời giải tối ưu đi
qua Elevator, par 61. Landmark: `silence_reliquary`.

### Level 12 — Dự án K-7

**Ký ức 12:** Elias tạo Kiro; đến Core, đừng tin EVA, tự phán.

Boss Ch III: tổng hợp Portal + Elevator + Door/Plate. Tầng 1 buộc một Core giữ
Plate để mở tuyến trong khi Core còn lại đi Portal; chỉ khi tầng 1 hoàn tất mới
được cam kết đi Elevator lên tầng 2. Par 70–90, không thêm hành lang để kéo par.

Hiện có: tầng 1 11×9 với 2 Core, một cặp Portal cùng tầng, 1 Plate/Door và
Elevator; tầng 2 9×7 với 3 Core, 2 Pedestal và 1 Plate/Door. Không dùng Energy
Node trước Chapter IV. Lời giải tối ưu dùng Portal, Door/Plate và Elevator,
par 85. Landmark: `elias_testament`.

## 7. Chương IV — The Central Core

Không giấu đáp án. Cả Elias và EVA đều có lý.

### Level 13 — Những linh hồn đã mất

**Ký ức 13:** thân xác hết; hồn trong Core.

Dạy Energy Node tuần tự. 1 Core, 2–3 Node, sảnh ≤ 11×9. Par 40–55.

Hiện có: 9×8, 1 Core, 3 Node + Pedestal, par 40. Landmark: `soul_archive`.

### Level 14 — Lời thú nhận của EVA

**Ký ức 14:** EVA giữ ý thức 327 năm, nguồn cạn.

Hai tầng 11×7, **một Core + Pedestal mỗi tầng**, Portal tầng dưới, 4 Node tầng trên. Par 28 (dải 24–36).
Nhịp lắng: tầng dưới khôi phục tuyến; tầng trên bốn Node + hologram EVA. Thú nhận cuối khi thắng. Landmark: `eva_conduit`.

### Level 15 — Phán quyết

**Ký ức 15:** máy tuân lệnh / người chọn mục đích.

Buồng phán quyết riêng 9×9, 40 ô đi được, ba Core, hai Pedestal và một Plate giữ nguồn.
Khoang dưới có Node 1–3 quanh các khối cách ly; cầu (3,4) và cửa (3,3) nối tới khoang trên có Node 4 và hai đích. Console ở (2,5); Plate (7,6) giữ cửa nhóm K mở.
Par 81, trong dải 75–95. Nghiệm thực sự dùng cầu, mở cửa và cả bốn Node; bố cục và route khác L8. Puzzle chỉ chuẩn bị bàn giao quyền điều khiển, không chọn trước ending.

- RESTORE — nối Core, Asteria số.
- RELEASE — ngắt nguồn.
- PRESERVE — đủ 15 bản ghi để bảo tồn ý thức trong trạng thái ngủ, chờ nguồn lực hồi sinh. Hoàn thành tuần tự campaign mở đủ lựa chọn; không gọi đây là ending bí mật hoặc tối ưu mặc định.

## 8. Mechanic theo level

| Mechanic | Dạy | Siết | Tổng hợp |
|---|---:|---:|---:|
| Đẩy / Pedestal | 1 | 2 | luôn |
| Thứ tự nhiều Core | 2 | 4, 6 | 8, 12, 14 |
| Plate / Door | 3 | 4–6 | 8, 12 |
| Nhóm cửa | 4 | 5–6 | 8 |
| Cầu xoay | 7 | 8 | 15 nếu cần |
| Plate rời (tuỳ chọn) | 8 | — | 12 |
| Portal Core | 9 | 10 | 12, 14 |
| Elevator | 11 | 12 | 14 |
| Energy Node | 13 | 14 | 15 |
| Ending | — | Preserve = 15 ký ức | 15 |

## 9. Ký ức — câu hỏi

| L | Người chơi biết | Còn hỏi |
|---:|---|---|
| 1 | 327 năm, nối Core | Asteria đã sao? |
| 2 | Mara không tin EVA | EVA giấu gì? |
| 3 | Elias vào Central Core | Elias là ai? |
| 4 | EVA né cư dân | Tin nhiệm vụ? |
| 5 | Core nuốt thần kinh | Lumina làm gì người? |
| 6 | K-Series chỉ để đẩy | Kiro có phải công cụ? |
| 7 | Elias: EVA biến chất | Thủ phạm hay bảo vệ? |
| 8 | EVA: Elias là đe dọa | Hai phía giấu gì? |
| 9 | Giấc mơ chung | Ý thức đã nối? |
| 10 | Resonance hòa tan cá nhân | Core chứa người? |
| 11 | EVA tắt thành phố | Thảm họa là lựa chọn |
| 12 | Elias tạo Kiro | Kiro được tự quyết |
| 13 | Chỉ còn hồn số | Đẩy Core = đụng vào người |
| 14 | EVA giữ họ 327 năm | Tội và hy sinh |
| 15 | Lựa chọn thuộc Kiro | Người chơi quyết |

## 10. Sản xuất một level

1. Chốt ký ức + đúng một ý puzzle.
2. Vẽ chức năng trên lưới ≤ 11×9; nếu là multi-floor, vẽ từng layer riêng và
   đánh dấu cặp `e` trước khi đặt Core.
3. ASCII → solver; par trong dải mục tiêu.
4. Nếu par thấp vì sàn rộng: **bớt ô**, không thêm Core cho có.
5. Blockout, landmark độc nhất, `power_level` tăng trong chương.
6. Gắn fragment + dialogue.
7. `validate_levels.py` + `tests/verify.gd`.
8. Với multi-floor: playtest chuyển tầng, camera/HUD, tap-to-move và Undo qua Elevator.

## 11. Nghiệm thu

- Metadata + fragment đúng level.
- Core = `required_target_count()`.
- Mọi cửa có plate nhóm.
- `par_moves` = route `verify.gd` = tối ưu Python.
- Lưới ≤ 11×9; sàn đi được ≤ 40 (finale được 41–42).
- Multi-floor: Level 11 có đúng 2 layer; mỗi layer có cặp `e` hợp lệ cùng X/Z,
  không có Core hoặc Kiro spawn trên Elevator; chuyển tầng không làm mất trạng thái.
- Tap-to-move không tự teleport qua Elevator; người chơi phải bước vào ô `e` rõ ràng.
- Undo một lần hoàn tác trọn thao tác Elevator, gồm vị trí tầng và trạng thái Core.
- Par nằm trong dải §3.2; đánh giá nhịp theo vai trò màn. L10 có hai Core dù route ngắn hơn L9; L13 dạy Node; L14 ưu tiên đối thoại.
- Landmark không trùng loại giữa các level.
- Preserve chỉ khi `memory_fragment_count() == 15`.

## 12. Bảo trì

| File | Vai trò |
|---|---|
| `src/data/story_data.gd` | Chương, ký ức, thoại, ending |
| `resources/levels/level_XX.tres` | Map, entity, deco, par, `hint_route` |
| `src/data/levels.gd` | Thứ tự + path, không nhân bản map |
| `tools/validate_levels.py` | Route tối ưu |
| `tests/verify.gd` | Replay |

Đổi số level hoặc dời ký ức: sửa đồng thời tài liệu này, `StoryData`, catalogue, `.tres`, test.
