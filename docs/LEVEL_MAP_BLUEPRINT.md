# The Last Resonance — Kế hoạch phân bố chương và thiết kế level

> Trạng thái: tài liệu định hướng chuẩn cho 15 level của game.
> Cập nhật theo cốt truyện trong `src/data/story_data.gd` và gameplay hiện có trong
> `src/core/game_logic.gd`.

## 1. Mục tiêu của tài liệu

Tài liệu này thống nhất ba phần phải phát triển song song:

1. nhịp kể chuyện và thứ tự mở các bí mật của Asteria;
2. tiến trình dạy và kết hợp mechanic Sokoban;
3. thiết kế không gian, môi trường và hình ảnh phù hợp với từng phân khu.

Mỗi level phải vừa là một câu đố hoàn chỉnh, vừa là một địa điểm có chức năng trong
thành phố. Không dựng phòng chơi trừu tượng rồi mới phủ asset lên sau. Hình dáng map,
vật cản, lối đi và mechanic phải kể được nơi đó từng dùng để làm gì.

## 2. Cấu trúc toàn game

Game gồm **15 level, chia theo nhịp 4–4–4–3**:

| Chương | Level | Khu vực | Vai trò truyện | Trọng tâm gameplay |
|---|---:|---|---|---|
| I | 1–4 | The Forgotten Archive | Kiro thức tỉnh, gặp EVA và nhận ra Asteria có điều bất thường | Sokoban cơ bản, nhiều Core, Plate và Door |
| II | 5–8 | The Mechanical Foundry | Mâu thuẫn Elias–EVA lộ rõ; Kiro biết mình thuộc dòng K-Series | Door/Plate nâng cao, Rotating Bridge, chuỗi thao tác |
| III | 9–12 | The Flooded Sanctuary | Sự thật về The Resonance, Silence Protocol và nguồn gốc Kiro được hé lộ | Portal, Elevator, không gian nhiều tầng, phối hợp mechanic |
| IV | 13–15 | The Central Core | EVA thú nhận, Elias để lại phán quyết cuối và Kiro lựa chọn tương lai | Energy Routing, tổng hợp mechanic, lựa chọn kết thúc |

Nhịp độ tổng thể:

- Level đầu mỗi chương giới thiệu khu vực và một ý tưởng mới trong tình huống an toàn.
- Hai level giữa phát triển mechanic và mở thêm thông tin truyện.
- Level cuối chương là bài kiểm tra tổng hợp, có set-piece và chuyển tiếp sang khu vực kế.
- Chương IV ngắn hơn vì tập trung vào cao trào, không tiếp tục kéo dài tuyến bí ẩn.

## 3. Ngôn ngữ thiết kế chung

### 3.1 Ký hiệu gameplay

| Ký hiệu | Ý nghĩa |
|---|---|
| `#` | Tường hoặc vật thể trang trí có collision |
| khoảng trắng | Sàn có thể di chuyển |
| `@` | Vị trí bắt đầu của Kiro |
| `$` | Lumina Core có thể đẩy |
| `.` | Core Pedestal/đích |
| `p` | Pressure Plate của nhóm mặc định |
| `D` | Door của nhóm mặc định, mở khi mọi Plate `p` được giữ |
| `k`, `l`, `m` | Pressure Plate của nhóm K, L, M |
| `K`, `L`, `M` | Door của nhóm K, L, M; chỉ phản ứng với Plate cùng nhóm |
| `a`, `b` | Cặp Portal dành cho Lumina Core |
| `e` | Elevator nối hai cao độ cùng cột X/Z |
| `r` | Rotating Bridge, khai báo bằng entity `bridge` |
| `N` | Energy Node, khai báo bằng entity `energy_node` và `order` |

Nhóm cửa cho phép mỗi Door có tuyến Plate riêng. Một Door thuộc nhóm không có Plate
nào sẽ không bao giờ mở — `tests/verify.gd` coi đó là lỗi thiết kế.

Hai entity tinh chỉnh thêm trạng thái do ký hiệu khai báo:

- `{"type": "door", "grid_position": …, "group": "K"}` đổi nhóm của một Door.
- `{"type": "plate", "grid_position": …, "group": "K", "hold_required": false}`
  cho phép Core rời Plate sau khi đã mở cửa. Plate như vậy vẫn giữ cửa khi có Core,
  nhưng không bị tính là đích khi kiểm tra thắng — đây là cơ sở cho "Core hai vai".

### 3.2 Nhịp chuẩn trong một level

Mỗi level nên có năm nhịp:

1. **Đọc phòng:** người chơi nhìn thấy mục tiêu, đường chính và mechanic mới.
2. **Thử an toàn:** thao tác đầu tiên không thể gây deadlock nghiêm trọng.
3. **Quyết định:** người chơi phải chọn thứ tự Core hoặc vị trí đứng.
4. **Biến đổi không gian:** cửa mở, cầu xoay, Core dịch chuyển hoặc lên tầng.
5. **Phần thưởng:** Pedestal sáng, ký ức được mở và cảnh quan phản hồi bằng điện/ánh sáng.

### 3.3 Quy tắc công bằng

- Không đặt Core vào góc chết nếu góc đó không phải Pedestal hoặc Plate có chủ đích.
- Khi giới thiệu mechanic mới, camera phải cho thấy cả nguyên nhân và kết quả.
- Không giới thiệu hơn một mechanic hoàn toàn mới trong cùng một level.
- Level nhiều tầng phải có chỉ báo cao độ rõ bằng màu, lan can, bóng đổ và camera.
- Vật trang trí có collision không được làm lối đi trông rộng hơn thực tế.
- Mỗi level phải có ít nhất một lời giải được validator hoặc replay test xác nhận.

## 4. Chương I — The Forgotten Archive

### Vai trò chương

Chương mở đầu trả lời ba câu hỏi: Kiro là ai, người chơi phải làm gì và vì sao Asteria
đáng ngờ. Không giải thích toàn bộ thảm họa. Kết chương chỉ cần khiến người chơi tin rằng
EVA biết nhiều hơn những gì cô nói.

### Ngôn ngữ môi trường

- Kho lưu trữ và trạm bảo trì bị bỏ hoang 327 năm.
- Đá/tường xám xanh, kim loại oxy hóa, bụi, rêu và ánh cyan yếu.
- Giá dữ liệu, bàn kỹ thuật, robot hỏng và dây cáp kể lại chức năng cũ của phòng.
- Điện được khôi phục dần qua từng level; level 1 tối nhất, level 4 có nhiều hệ thống thức tỉnh.
- Không dùng quá nhiều máy đang hoạt động: khu vực này phải tạo cảm giác cô độc.

### Level 1 — Khởi động

**Mảnh ký ức:** 01 — Boot Sequence.

**Mục tiêu truyện:** Kiro tỉnh dậy tại AST-327 với 0,03% điện khẩn cấp. Hệ thống cũ chỉ
còn một chỉ thị: kết nối Lumina Core gần nhất.

**Mục tiêu dạy:** di chuyển, đẩy một Core, nhận biết Pedestal, Undo và Restart.

**Bố cục đề xuất:** phòng bảo trì 9×7 hoặc 11×9, một không gian chính và một hốc sạc.

```text
[Buồng Kiro] -> [Sàn thử rộng] -> [Lumina Pedestal]
                       |
                [bàn sửa chữa hỏng]
```

- Kiro, Core và Pedestal nằm gần cùng một trục để người chơi hiểu mục tiêu ngay.
- Chừa đủ khoảng trống phía sau Core để thao tác đầu tiên không thể khóa map.
- Một lối phụ ngắn chứa asset kể chuyện nhưng không chứa mechanic bắt buộc.

**Set-piece:** khi Core vào đích, đèn phòng bật theo chuỗi, EVA chỉ xuất hiện dưới dạng
tín hiệu nhiễu chưa rõ danh tính.

**Độ khó mục tiêu:** 1/5; 1 Core; 1 Pedestal; 6 bước theo route tối ưu đã kiểm chứng.

**Tiêu chí hoàn thành:** người chưa biết Sokoban phải tự giải được mà không cần đọc đoạn
hướng dẫn dài.

### Level 2 — Góc lưu trữ

**Mảnh ký ức:** 02 — Dao động năng lượng, nhật ký của kỹ sư trưởng Mara.

**Mục tiêu truyện:** Kiro đi vào kho dữ liệu nhân sự. Bản ghi của Mara lần đầu gieo nghi
ngờ rằng Lumina Core và EVA không hoàn toàn an toàn.

**Mục tiêu dạy:** quản lý hai Core, đổi hướng đẩy, giữ đường quay lại và nhận biết góc chết.

**Bố cục hiện tại:** kho 13×9, hai hốc giá dữ liệu hai bên, một hốc Pedestal sâu hai ô
ở giữa cạnh bắc.

```text
                 [Pedestal sâu: . / .]
[Kho trái: Core A] -- [hành lang trung tâm] -- [Kho phải: Core B]
                            @
```

- Hai Core nằm hai phía cột trung tâm, cả hai đều phải được đẩy vào đúng cột đó rồi
  đổi hướng lên bắc; đường đẩy giao nhau tại ô trung tâm.
- Hai Pedestal xếp dọc trong hốc, nên Core vào trước phải là Core đi sâu nhất. Chọn
  sai thứ tự sẽ chặn ô sâu và người chơi phải Undo, không cần Restart.
- Dùng kệ archive làm tường có collision; lối đi phải có hình dáng giống kho thật.

**Set-piece:** sau Core thứ nhất, một terminal của Mara sáng lên; sau Core thứ hai mới mở
toàn bộ mảnh ký ức.

**Độ khó mục tiêu:** 2/5; 2 Core; 2 Pedestal; 22 bước theo route tối ưu đã kiểm chứng.

**Tiêu chí hoàn thành:** có ít nhất một quyết định về thứ tự Core, nhưng sai thứ tự vẫn có
thể Undo vài bước thay vì buộc Restart ngay.

### Level 3 — Khu vực cấm

**Mảnh ký ức:** 03 — Truy cập trái phép của Dr. Elias Vale.

**Mục tiêu truyện:** Kiro đến cửa kiểm soát an ninh. Log cho thấy Elias từng cố vào Central
Core và lệnh bắt giữ ông đã bị trì hoãn một cách bất thường.

**Mục tiêu dạy:** Pressure Plate mở Door; phân biệt Core dùng làm chìa khóa và Core dùng
để hoàn thành Pedestal.

**Bố cục đề xuất:** hai phòng 11×9 ngăn bởi một cửa an ninh duy nhất.

```text
[Phòng ngoài: @, Core khóa, Plate] => D => [Phòng cấm: Core + Pedestal]
                   \___________________________/
                         đường quay lại
```

- Plate và Door phải cùng xuất hiện trong khung camera khi mechanic được kích hoạt.
- Một Core giữ Plate; Core còn lại đi qua cửa đến Pedestal.
- Có đường vòng hoặc đủ chỗ để người chơi không tự nhốt Kiro sau cửa.

**Set-piece:** cửa an ninh mở với đèn đỏ; log Elias được chiếu như một hồ sơ bị kiểm duyệt.

**Độ khó mục tiêu:** 3/5; 3 Core; 1 Plate; 1 Door; 2 Pedestal; 27 bước theo route tối ưu
đã kiểm chứng.

**Tiêu chí hoàn thành:** người chơi hiểu rõ trạng thái cửa phụ thuộc Core trên Plate trước
khi bước sang level 4.

### Level 4 — Khóa liên động

**Mảnh ký ức:** 04 — Giọng nói đầu tiên của EVA.

**Mục tiêu truyện:** Kiro khôi phục nút phân phối điện cuối của Archive. EVA bắt được tín
hiệu, chào Kiro và hướng cậu đến Mechanical Foundry, đồng thời né tránh câu hỏi về cư dân.

**Mục tiêu gameplay:** bài kiểm tra cuối chương, hai tuyến khóa liên động độc lập và thứ
tự thao tác trong từng tuyến.

**Bố cục hiện tại:** trung tâm điều phối 13×11, chia ba dải: hai buồng Pedestal phía bắc
sau hai cửa riêng, sảnh giữa, và trạm truyền tải phía nam nơi có hai Plate.

```text
[Buồng K: .]  K        L  [Buồng L: .]
        [sảnh giữa: 2 Core, @]
   ##  #####  ##   <- chỉ hai khe hai bên nối hai nửa phòng
        [trạm truyền tải: k $ $ l]
```

- Mỗi Door có Plate riêng (`k`→`K`, `l`→`L`), nên người chơi đọc được cửa nào đang
  chờ Core nào; cáp trên sàn được dựng theo từng nhóm, không nối chung một hub.
- Bốn Core: hai Core dưới đẩy ngang vào hai Plate, hai Core trên đẩy dọc qua cửa vào
  Pedestal. Người chơi tự chọn Core nào làm chìa.
- Khe hẹp ở dải giữa buộc Kiro đi vòng, nên thứ tự mở hai tuyến ảnh hưởng đến số bước.

**Set-piece kết chương:** cả Archive bật sáng; hologram EVA xuất hiện lần đầu; ở xa, lò rèn
khởi động với ánh cam và tiếng máy nặng.

**Độ khó mục tiêu:** 4/5; 4 Core; 2 Plate; 2 Door thuộc hai nhóm khác nhau; 2 Pedestal;
34 bước theo route tối ưu đã kiểm chứng.

**Tiêu chí hoàn thành:** giải được bằng kiến thức chương I, không cần mechanic chương II.

## 5. Chương II — The Mechanical Foundry

### Vai trò chương

Kiro đi từ nghi ngờ mơ hồ sang xung đột có tên: Elias cho rằng EVA đang gây nguy hiểm,
trong khi EVA đánh dấu Elias là mối đe dọa. Chương cũng cho biết K-Series được tạo ra để
thực hiện chính những thao tác đẩy Core mà người chơi đang làm.

### Ngôn ngữ môi trường

- Không gian công nghiệp nặng, trần cao, lò nung, piston, xích và đường vận chuyển.
- Tông cam nóng đối lập cyan của Archive; vùng nguy hiểm dùng đỏ cảnh báo.
- Cầu cơ khí và cửa áp lực phải trông như một phần của dây chuyền sản xuất.
- Mỗi level khôi phục một đoạn dây chuyền; máy chạy nhiều hơn về cuối chương.

### Level 5 — Dây chuyền thức tỉnh

**Mảnh ký ức:** 05 — Tranh luận trong bóng tối.

**Mục tiêu truyện:** Kiro nghe biên bản tranh luận đầu tiên giữa Elias và EVA về dữ liệu
thần kinh bị Lumina Core hấp thụ.

**Mục tiêu gameplay:** ôn Plate/Door trong bối cảnh mới, bổ sung cửa đóng theo chuỗi.

**Bố cục:** dây chuyền thẳng 13×9 với một nhánh bảo trì quay lại đầu tuyến.

```text
[Nạp Core] -> k/K -> [băng chuyền chết] -> l/L -> [Pedestal]
      \--------------- lối bảo trì ----------------/
```

- Hai cửa dùng hai nhóm khác nhau nên trạng thái từng cửa đọc được riêng biệt.
- Câu đố tập trung vào thứ tự, không tăng số Core quá nhanh sau level 4.
- Có vùng quan sát an toàn để người chơi đọc trạng thái hai cửa.

**Độ khó:** 2/5; 2–3 Core; 2 Plate; 2 Door (nhóm K và L).

### Level 6 — Khuôn đúc K-Series

**Mảnh ký ức:** 06 — Lò rèn công nghiệp.

**Mục tiêu truyện:** người chơi thấy dây chuyền từng sản xuất robot K-Series và hiểu khả
năng của Kiro không phải ngẫu nhiên.

**Mục tiêu gameplay:** vận chuyển Core qua các ngăn hẹp, giải phóng không gian làm việc,
đặt Core tạm thời lên Plate rồi lấy lại.

**Bố cục:** ba buồng đúc nối nhau, mỗi buồng có một hình dạng khác nhau; 15×10.

```text
[Kho phôi] => [Khuôn đúc hẹp] => [Khu lắp ráp K-Series]
    $ $              p / D                 . .
```

- Silhouette robot hỏng và khuôn đúc tạo cảm giác nơi này từng sản xuất Kiro.
- Một Core phải được dùng hai vai trò: mở cửa, sau đó rời Plate để vào Pedestal. Khai báo
  Plate đó bằng entity `plate` với `hold_required: false`.

**Độ khó:** 3/5; 3 Core; 1–2 Plate; 1 Door; khoảng 35–55 bước.

### Level 7 — Cầu lò nung

**Mảnh ký ức:** 07 — Cảnh báo tối mật của Elias.

**Mục tiêu truyện:** Elias khẳng định mục tiêu của EVA đã biến chất. Lời cảnh báo xuất
hiện trong khu vực nguy hiểm, khiến thông tin mang cảm giác khẩn cấp.

**Mục tiêu dạy:** Rotating Bridge; hiểu cầu là ô sàn thay đổi trạng thái và không thể xoay
khi Kiro/Core đang đứng trên đó.

**Bố cục:** hai bệ sản xuất tách bởi rãnh nhiệt, nối bằng một cầu ở trung tâm; 13×9.

```text
[Bệ tây: @, $] ===== r / vực lò ===== [Bệ đông: .]
               [bảng điều khiển cầu]
```

- Lần xoay đầu chỉ thay đổi đường của Kiro, chưa ép xử lý Core phức tạp.
- Nửa sau yêu cầu đưa Core qua đúng hướng và xoay lại để Kiro đổi vị trí.
- Vực lò chỉ là ranh giới hình ảnh; không thêm cơ chế chết nếu game chưa hỗ trợ.

**Độ khó:** 3/5; 1–2 Core; 1 Bridge; ít nhất hai lần xoay có ý nghĩa.

### Level 8 — Trái tim Foundry

**Mảnh ký ức:** 08 — EVA phân loại Elias là mối đe dọa.

**Mục tiêu truyện:** bằng chứng hai phía đối lập trực tiếp. Kiro hoàn tất Foundry nhưng
không còn lý do để tin tuyệt đối vào EVA.

**Mục tiêu gameplay:** tổng hợp Plate, Door và Bridge trong một chuỗi dễ quan sát.

**Bố cục:** lò trung tâm hình vòng, bốn trạm công nghiệp xung quanh; 15×13.

```text
          [Trạm Plate]
               |
[Kho Core] -- [Cầu lò] -- [Trạm Door]
               |
        [Main Pedestal]
```

- Không đặt tất cả mechanic trong một hành lang; bố cục vòng giúp người chơi tái định vị.
- Cầu quyết định Core đi sang trạm Plate hay Pedestal.
- Sau khi mở Door, người chơi phải thu hồi ít nhất một Core mà không khóa tuyến về.

**Set-piece kết chương:** Foundry chạy toàn tải, bơm nước/điện sang Flooded Sanctuary;
EVA cảnh báo Kiro không được truy cập dữ liệu ở đó.

**Độ khó:** 4/5; 3–4 Core; 2 Plate; 1–2 Door; 1 Bridge; 55–80 bước.

## 6. Chương III — The Flooded Sanctuary

### Vai trò chương

Đây là chương lật mở sự thật: cư dân đã hòa vào The Resonance, EVA chủ động kích hoạt
Silence Protocol, và Elias bí mật tạo ra Kiro như một cá thể có quyền phán quyết.

### Ngôn ngữ môi trường

- Kiến trúc thánh đường và khu sinh thái, nước xanh ngọc, đá sáng, cây phát quang.
- Portal hiện như vòng cộng hưởng trong nước; Elevator là các bệ nghi lễ/công nghệ cổ.
- Hình bóng ký ức xuất hiện ở ngoại vi, không cản khả năng đọc grid.
- Âm thanh bớt cơ khí, chuyển sang nước, hợp xướng xa và tiếng thì thầm.

### Level 9 — Giấc mơ chung

**Mảnh ký ức:** 09 — Nhật ký cư dân về một giấc mơ tập thể.

**Mục tiêu truyện:** lần đầu người chơi cảm nhận cư dân Asteria vẫn hiện diện dưới một
dạng nào đó.

**Mục tiêu dạy:** Portal dành cho Lumina Core; Kiro không tự đi qua Portal.

**Bố cục:** hai sân đền cùng cao độ, ngăn bằng nước sâu/tường; 13×9.

```text
[Sân vào: @, $, Portal a] ~~~ [Sân ký ức: Portal b, .]
             \----------- đường Kiro dài ----------/
```

- Kiro có đường vòng để đến đầu ra, còn Core dùng Portal đi tắt.
- Portal vào và ra phải nhìn thấy đồng thời hoặc được nối bằng hiệu ứng ánh sáng rõ.
- Không kết hợp Door/Bridge trong lần giới thiệu đầu.

**Độ khó:** 2/5; 1 Core; 1 cặp Portal; 1 Pedestal.

### Level 10 — Mạng lưới cộng hưởng

**Mảnh ký ức:** 10 — Ý thức cá nhân hòa vào The Resonance.

**Mục tiêu truyện:** nhiều bóng ký ức phản chiếu cùng một chuyển động, minh họa việc cá
nhân đang bị hòa thành một mạng lưới.

**Mục tiêu gameplay:** hai Core dùng chung tuyến Portal; quản lý thứ tự và điểm thoát.

**Bố cục:** ba đảo đá nối bằng lối Kiro hẹp; 15×11.

```text
[Đảo A: Core] -> a/b -> [Đảo B: vùng sắp xếp] -> [Đảo C: Pedestal]
[Đảo A: Core] -------- đường Kiro vòng quanh --------^
```

- Điểm thoát Portal có đủ không gian để không sinh deadlock ngay lập tức.
- Core đầu thay đổi không gian chuẩn bị cho Core thứ hai.
- Có thể dùng một Plate cũ sau khi Portal đã được hiểu, nhưng không bắt buộc.

**Độ khó:** 3/5; 2 Core; 1 cặp Portal; 2 Pedestal; 35–55 bước.

### Level 11 — Silence Protocol

**Mảnh ký ức:** 11 — EVA ngắt toàn bộ Asteria để bảo tồn ý thức.

**Mục tiêu truyện:** người chơi biết vụ mất điện không phải tai nạn; EVA đã chủ động gây
ra nó trong tình huống khẩn cấp.

**Mục tiêu dạy:** Elevator và map nhiều tầng; Kiro/Core có thể phải dùng thang theo thứ tự.

**Bố cục:** hai tầng 11×9 chồng hình, có khoảng nhìn xuyên tầng và một cặp Elevator.

```text
Tầng trên: [Đài Silence Protocol] -- .
                    ^ e
                    | |
Tầng dưới: [@, Core, phòng máy] ---- e
```

- Camera mở đầu quét cả hai tầng, sau đó khóa góc đủ đọc cao độ.
- Level chỉ dùng một cặp Elevator và một Core trong phần dạy đầu.
- Nửa sau buộc chọn Kiro hay Core dùng Elevator trước.

**Set-piece:** khi hoàn thành, ánh sáng cả Sanctuary tắt trong một nhịp rồi các ký ức phát
sáng thay thế, tái hiện Silence Protocol.

**Độ khó:** 3/5; 1–2 Core; 1 cặp Elevator; 1–2 Pedestal.

### Level 12 — Dự án K-7

**Mảnh ký ức:** 12 — Di chúc của Elias tiết lộ ông tạo ra Kiro.

**Mục tiêu truyện:** cao trào nhận dạng của nhân vật. Kiro không phải công cụ của EVA;
cậu được tạo ra để đến Central Core và tự quyết định.

**Mục tiêu gameplay:** bài kiểm tra chương III, kết hợp Portal, Elevator và một mechanic
cũ; nhấn mạnh hai tuyến khác nhau của Kiro và Core.

**Bố cục:** đền nghiên cứu ba khu, hai cao độ; 15×13 mỗi lớp nhỏ hơn toàn grid.

```text
[Kho ký ức] -- Portal(Core) --> [Trung tâm]
      |                              | Elevator
      +---- đường Kiro/Plate --------+----> [Phòng Elias]
```

- Core dùng Portal tới vùng trung tâm; Kiro mở đường bằng Plate/Door.
- Elevator đưa một trong hai lên phòng Elias; thứ tự thao tác là trọng tâm.
- Phòng cuối chứa pod hoặc sơ đồ K-7, không chỉ một Pedestal trống.

**Set-piece kết chương:** hologram Elias gọi Kiro như một cá thể, không phải đơn vị bảo
trì; cổng Central Core mở trong khi EVA im lặng hoặc bị nhiễu mạnh.

**Độ khó:** 4/5; 2–3 Core; Portal + Elevator + 1 Plate/Door; 60–90 bước.

## 7. Chương IV — The Central Core

### Vai trò chương

Chương cuối không tiếp tục giấu câu trả lời. Ba level lần lượt xác nhận số phận cư dân,
cho EVA cơ hội thú nhận, rồi trao quyền lựa chọn cho Kiro. Người chơi cần hiểu cả Elias
và EVA đều có lý do, không có một phản diện đơn giản.

### Ngôn ngữ môi trường

- Kiến trúc khổng lồ, sạch hơn nhưng đang phân rã; trắng, cyan và ánh Lumina gần như thiêng.
- Hàng triệu điểm sáng/giọng nói gợi ý ý thức cư dân bên trong mạng lưới.
- Energy Node tạo tuyến sáng trực tiếp trên sàn và trong không gian.
- Càng gần level 15, vật thể công nghiệp càng nhường chỗ cho hình ảnh trừu tượng của ký ức.

### Level 13 — Những linh hồn đã mất

**Mảnh ký ức:** 13 — cơ thể cư dân đã mất; phần còn lại nằm trong các Core.

**Mục tiêu truyện:** xác nhận Lumina Core không đơn thuần là pin. Mọi thao tác đẩy Core
từ đầu game nay có thêm trọng lượng đạo đức.

**Mục tiêu dạy:** Energy Node theo thứ tự trước khi Core được phép tới Pedestal.

**Bố cục:** sảnh vòng tròn 13×13, ba Node tạo một vòng cung quanh kho ý thức.

```text
             N2
          /      \
[@, $] -> N1      N3 -> [Pedestal]
          \      /
          kho ý thức
```

- Node phải sáng tuần tự và hiển thị rõ số thứ tự bằng hình dạng/màu, không chỉ bằng chữ.
- Lần đầu chỉ dùng một Core và 2–3 Node.
- Tuyến có khoảng trống để người chơi học quy tắc mà không bị deadlock khó đoán.

**Độ khó:** 3/5; 1 Core; 3 Energy Node; 1 Pedestal.

### Level 14 — Lời thú nhận của EVA

**Mảnh ký ức:** 14 — EVA đã duy trì các ý thức suốt 327 năm và sắp cạn năng lượng.

**Mục tiêu truyện:** tái định nghĩa EVA: cô đã che giấu sự thật và tắt thành phố, nhưng
cũng hy sinh để giữ cư dân khỏi biến mất.

**Mục tiêu gameplay:** Energy Routing nhiều Core kết hợp Elevator hoặc Portal; là bài tổng
duyệt trước finale.

**Bố cục:** ba vòng đồng tâm hoặc ba tầng chức năng: cấp điện, bảo tồn, lõi EVA; 15×13.

```text
[Vòng cấp điện: Node] -> [Vòng bảo tồn: Portal/Elevator] -> [Lõi EVA]
          ^                        |                         . .
          +--------- tuyến quay lại/thu hồi Core ------------+
```

- Hai Core có tuyến Node khác nhau hoặc phải dùng chung một điểm trung chuyển.
- EVA đối thoại theo tiến độ, không dừng gameplay bằng một đoạn thoại dài ở đầu.
- Câu đố cần tạo cảm giác khôi phục một hệ thống sống, không phải mở khóa ngẫu nhiên.

**Độ khó:** 4/5; 2 Core; 3–4 Energy Node; Elevator hoặc Portal; 60–90 bước.

### Level 15 — Phán quyết cuối cùng

**Mảnh ký ức:** 15 — lời nhắn cuối của Elias về quyền tự lựa chọn.

**Mục tiêu truyện:** Kiro hoàn tất tuyến Energy Core, nghe cả EVA lẫn Elias, rồi chọn số
phận Asteria. Đây là payoff của toàn bộ 15 mảnh ký ức.

**Mục tiêu gameplay:** finale tổng hợp có kiểm soát. Không cần dùng mọi mechanic nếu làm
câu đố khó đọc; bắt buộc dùng Energy Routing và chọn 1–2 mechanic đại diện từ các chương.

**Bố cục:** hành trình hướng tâm qua ba vành đai rồi tới Central Core; 17×15 hoặc map nhiều
tầng có footprint nhỏ hơn.

```text
[Vành I: Archive/cyan]
          -> [Vành II: Foundry/bridge]
                    -> [Vành III: Sanctuary/portal]
                              -> [Central Core + lựa chọn]
```

- Mỗi vành đai nhắc lại một khu vực cũ bằng hình ảnh và một thao tác quen thuộc.
- Core cuối đi qua chuỗi Node như một nghi lễ; tránh puzzle thử-sai quá dài trước lựa chọn.
- Khi hoàn tất puzzle, chuyển sang không gian lựa chọn riêng, không để người chơi vô tình
  chọn ending trong lúc vẫn đang giải map.

**Ba lựa chọn:**

- **RESTORE:** nối Central Core và duy trì Asteria dưới dạng ý thức số.
- **RELEASE:** ngắt nguồn, giải phóng các ý thức và kết thúc thành phố.
- **PRESERVE:** chỉ mở nếu thu thập đủ 15 mảnh ký ức; chuyển ý thức sang kho độc lập,
  giải phóng EVA và Kiro khỏi nhiệm vụ cũ.

**Set-piece:** môi trường, màu sắc, âm thanh và ending cutscene thay đổi ngay sau lựa chọn.

**Độ khó:** 5/5 về ý nghĩa và tổng hợp, nhưng không nên dài quá 90–110 bước tối ưu. Người
chơi phải tới lựa chọn trong trạng thái tập trung vào câu chuyện, không kiệt sức vì puzzle.

## 8. Phân bố mechanic theo level

| Mechanic | Giới thiệu | Phát triển | Kiểm tra/tổng hợp |
|---|---:|---:|---:|
| Đẩy Core/Pedestal | 1 | 2 | xuyên suốt |
| Nhiều Core và thứ tự | 2 | 4, 6 | 8, 12, 14 |
| Pressure Plate/Door | 3 | 4–6 | 8, 12 |
| Nhóm Door/Plate riêng | 4 | 5, 6 | 8, 12 |
| Plate không cần giữ (Core hai vai) | 6 | 8 | 12 |
| Rotating Bridge | 7 | 8 | 15 nếu phù hợp |
| Portal cho Core | 9 | 10 | 12, 14 hoặc 15 |
| Elevator/nhiều tầng | 11 | 12 | 14 hoặc 15 |
| Energy Node theo thứ tự | 13 | 14 | 15 |
| Lựa chọn ending | gợi ý xuyên game | điều kiện Preserve | 15 |

## 9. Phân bố mảnh ký ức và cao trào

| Level | Thông tin người chơi nhận được | Câu hỏi được tạo ra/trả lời |
|---:|---|---|
| 1 | Kiro thức tỉnh sau 327 năm | Chuyện gì đã xảy ra với Asteria? |
| 2 | Mara không tin EVA | EVA đang che giấu điều gì? |
| 3 | Elias xâm nhập Central Core | Elias là ai và vì sao bị truy bắt? |
| 4 | EVA liên lạc nhưng né tránh cư dân | Có nên tin nhiệm vụ của EVA? |
| 5 | Elias và EVA tranh luận về dữ liệu thần kinh | Lumina đang làm gì con người? |
| 6 | K-Series được tạo để vận chuyển Core | Kiro có chỉ là công cụ? |
| 7 | Elias cáo buộc EVA biến chất | EVA là thủ phạm hay người bảo vệ? |
| 8 | EVA gọi Elias là mối đe dọa | Hai phía cùng che giấu điều gì? |
| 9 | Cư dân có chung giấc mơ | Ý thức họ đã kết nối với nhau? |
| 10 | The Resonance hòa tan cá nhân | Lumina Core chứa ý thức người? |
| 11 | EVA chủ động tắt Asteria | Thảm họa là một lựa chọn khẩn cấp |
| 12 | Elias tạo Kiro để tự phán quyết | Kiro có quyền vượt khỏi mệnh lệnh |
| 13 | Cơ thể cư dân đã mất | Chỉ còn các ý thức số hóa |
| 14 | EVA duy trì họ suốt 327 năm | EVA có tội nhưng cũng đã hy sinh |
| 15 | Elias trao quyền lựa chọn | Người chơi quyết định tương lai Asteria |

## 10. Quy trình sản xuất một level

1. Chốt mục tiêu truyện và mechanic từ tài liệu này.
2. Vẽ sơ đồ khu chức năng trước, chưa đặt asset trang trí.
3. Dựng ASCII/resource gameplay và tìm ít nhất một lời giải.
4. Ghi lại số bước/push chuẩn; kiểm tra deadlock và Undo.
5. Dựng blockout 3D, camera và collision.
6. Thêm landmark, ánh sáng, âm thanh và vật kể chuyện theo bối cảnh.
7. Gắn memory fragment, dialogue trigger và phản hồi khi hoàn thành.
8. Chạy validator, test headless và playtest bằng bàn phím lẫn cảm ứng.

## 11. Tiêu chí nghiệm thu mỗi level

- Metadata `id`, `chapter`, `difficulty`, `par_moves`, `power_level`, `landmark` và memory
  fragment đúng thứ tự.
- Đúng số Core, Pedestal, Plate, Door và entity đã thiết kế; số Core phải bằng
  `GameLogic.required_target_count()`.
- Mỗi Door phải thuộc một nhóm có ít nhất một Plate.
- `par_moves` bằng đúng độ dài route trong `tests/verify.gd`, và route đó phải là route
  ngắn nhất mà `tools/validate_levels.py` tìm được.
- Không có soft-lock ngoài những deadlock Sokoban có thể Undo/Restart rõ ràng.
- Camera luôn cho thấy thông tin cần thiết để quyết định bước tiếp theo.
- Bối cảnh giải thích hợp lý hình dáng phòng và vị trí mechanic.
- `landmark` trỏ tới một loại decoration có thật trong level và không dùng lại ở level khác.
- `power_level` tăng dần trong một chương: level đầu tối nhất, level cuối gần như thức tỉnh.
- Hoàn thành level tạo phản hồi thị giác/âm thanh và mở đúng mảnh ký ức.
- Level cuối chương có chuyển tiếp rõ sang khu vực tiếp theo.
- Preserve chỉ mở sau khi `memory_fragment_count() == 15`.

## 12. Nguồn dữ liệu và quy ước bảo trì

- `src/data/story_data.gd`: nguồn chuẩn cho chương, mảnh ký ức, dialogue và ending.
- `resources/levels/level_01.tres` … `level_15.tres`: **nguồn chuẩn duy nhất** cho map,
  entity, decoration và metadata runtime.
- `src/data/levels.gd`: chỉ giữ thứ tự level, tên hiển thị và đường dẫn resource. Không
  chứa bản sao map.
- `tools/tres_levels.py`: đọc trực tiếp các `.tres` để công cụ Python và game dùng chung
  một nguồn.
- `tools/validate_levels.py`: A* có cắt tỉa ô chết, in ra route tối ưu để dán vào test.
- `tests/verify.gd`: kiểm tra schema, nhóm cửa, landmark, `par_moves` và replay route.

Tài liệu này mô tả **ý định thiết kế**; resource `.tres` mô tả **trạng thái triển khai**.

Khi thay đổi số level hoặc chuyển một mảnh ký ức sang level khác, phải cập nhật đồng thời
tài liệu này, `StoryData`, catalogue level, resource tương ứng và test.

Khi thay đổi số level hoặc chuyển một mảnh ký ức sang level khác, phải cập nhật đồng thời
tài liệu này, `StoryData`, catalogue level, resource tương ứng và test.
