# Kế hoạch refactor theo chức năng — The Last Resonance

Ngày lập: 2026-10-02. Trạng thái: **hoàn tất refactor code và nghiệm thu headless**. Phạm vi: cấu trúc code, giữ nguyên gameplay, nội dung 15 màn và hình ảnh hiện tại. Playtest Android thật vẫn là bước thủ công trước khi nộp.

Mục tiêu: tách trách nhiệm theo chức năng → dễ tìm code, sửa và kiểm thử → có đầu việc và bằng chứng rõ ràng để theo dõi, viết báo cáo cuối kỳ.

## 1. Căn cứ và giới hạn khảo sát

Khảo sát bắt đầu trên working tree đang phát triển, không phải một release tag. RF-00 đã xử lý assertion audio cũ, chốt baseline xanh và từ đó mỗi lát cắt đều được chạy regression trước khi tiếp tục. Working tree vẫn chứa nhiều thay đổi presentation/asset từ các pass trước nên commit cuối cần được nhóm có chủ đích.

| Điểm quan sát | Ý nghĩa đối với kế hoạch |
| --- | --- |
| `src/game/main.gd`: 1.286 dòng; chứa khởi tạo scene, hint recovery, tap/pathfinding, bước đi, elevator, win và môi trường | Ưu tiên tách các luồng có đầu vào/đầu ra riêng; không chỉ chuyển hàm sang file mới |
| `src/view/board_view.gd`: 2.109 dòng; dựng board, decoration, shell, lighting, nhân vật và trạng thái tương tác | Tách phần dựng tĩnh khỏi phần cập nhật/animation runtime |
| `src/view/game_hud.gd`: 1.041 dòng; thống kê, nút điều khiển, pause, accessibility và responsive layout | Tách component UI theo chức năng, giữ API cập nhật HUD |
| Đã có `LevelFlow`, `HintManager`, `GameCoordinator`, `StoryDirector`, `GameplayInput` | Mở rộng ranh giới hiện có; tránh tạo manager song song cùng trách nhiệm |
| `GameLogic` là `RefCounted`; `ScoreRules` và `ProgressStore` đã riêng | Giữ luật chơi độc lập với Node, UI, âm thanh và animation |
| `main.gd` có nhiều `await`, trạng thái busy và token phiên; hint checkpoint còn nằm trong main | Kiểm tra quyền sở hữu trạng thái và hủy thao tác khi restart/chuyển màn |
| Có `tools/run_tests.py`, các verify theo chức năng và validator Python | Tận dụng kiểm thử hiện có; thêm test hành vi ở ranh giới thay đổi còn thiếu |

Số dòng chỉ là chỉ báo nơi cần đọc kỹ, không phải tiêu chí chất lượng hay mục tiêu giảm dòng. Các điểm trên là quan sát cấu trúc, chưa khẳng định có lỗi runtime.

## 2. Ranh giới chức năng đích

Luồng chính: input → điều phối hành động → luật chơi → kết quả → cập nhật board/HUD/audio → sự kiện truyện → hoàn thành màn/lưu tiến độ. `main.gd` giữ việc tạo đối tượng, nối signal và gọi lifecycle.

| Nhóm | Sở hữu | Không sở hữu |
| --- | --- | --- |
| Luật chơi | Board state, move/push, cửa, cầu, portal, elevator, energy, undo, thắng | Tween, Node hiển thị, save và UI |
| Phiên và hành động | Thứ tự hành động, busy, token phiên, tap/autowalk, hủy thao tác | Quy tắc puzzle, truyện và dựng mesh |
| Gợi ý | Route, checkpoint, đồng bộ cursor, recovery, nội dung kết quả gợi ý | Tự di chuyển người chơi hoặc cộng bước thật |
| Hiển thị board | Dựng scene, vật liệu, actor, animation, decoration, sector shell và hiệu ứng cục bộ gắn với board | Quyết định thắng/thua, ghi save hoặc sở hữu WorldEnvironment toàn scene |
| Truyện và chiến dịch | Trigger truyện, chapter intro, fragment, chuỗi kết thúc | Thực thi luật di chuyển |
| UI | Thống kê, điều khiển, pause, menu/settings/codex, accessibility | Thay đổi trực tiếp board state |
| Âm thanh và môi trường | BGM, ambience, SFX, WorldEnvironment, DirectionalLight toàn scene, chapter lighting/power và render quality | Quyết định tiến độ chiến dịch hoặc dựng hình học board |
| Dữ liệu và tiến độ | Level resources, catalog, điểm/sao, save/load/migration | Chạy animation |

## 3. Các gói công việc

Tên module mới dưới đây là đề xuất; chỉ tạo khi trích xuất được trách nhiệm độc lập. Mỗi gói có thể chia thành nhiều thay đổi nhỏ và nghiệm thu riêng.

| ID | Chức năng / phạm vi file | Công việc và đầu ra | Tiêu chí nghiệm thu | Phụ thuộc / mức công |
| --- | --- | --- | --- | --- |
| RF-00 | Baseline và kiểm thử: `tools/run_tests.py`, `tests/`, working tree | Phân loại thay đổi đang dở; chốt snapshot có thể phục hồi; ghi phiên bản Godot, kết quả test, ảnh/video các luồng chuẩn và số liệu tải/render; sửa các assertion cũ không còn phản ánh hành vi hiện tại trước khi lấy baseline | Baseline phải xanh trước RF-01; phân biệt lỗi có sẵn với lỗi refactor; có danh sách test và baseline được lưu | Đầu tiên / nhỏ–vừa |
| RF-01 | Gợi ý: `main.gd`, `hint_manager.gd` | Đưa checkpoint, đồng bộ cursor và recovery về module hint; tách tính kết quả khỏi gọi HUD/board; giữ phí gợi ý và route hiện tại | Hint đúng sau đi lệch route, undo, restart và đổi tầng; phí không tăng bước thật hoặc sửa par | RF-00 / vừa |
| RF-02 | Input và thực thi hành động: `main.gd`, `input_controller.gd`, `game_coordinator.gd`, `level_flow.gd` | Tách theo ba lát cắt: **RF-02A Navigation** (tap/pathfinding/autowalk), **RF-02B Action execution** (single-step, push, bridge, elevator sequencing), **RF-02C Lifecycle/session** (busy, token phiên, hủy thao tác cũ). Không tạo một controller mới lại phụ thuộc toàn bộ HUD/board/audio/story. Main chỉ nhận request, gọi subsystem và nối kết quả | Keyboard/touch cùng hành vi; restart, rời scene và chuyển màn không để thao tác phiên cũ cập nhật scene mới; pause/undo đúng quy ước hiện tại; mỗi lát cắt nghiệm thu độc lập trước khi sang lát tiếp theo | RF-00, RF-01, RF-07A / lớn |
| RF-03 | Board và render cục bộ: `board_view.gd`, `mesh_factory.gd`, `module_motion.gd`, các catalog | Tách lần lượt **BoardGeometry**, **GameplayObjectView**, **BoardDecoration** và **BoardEnvironment** khi ranh giới thực tế đủ rõ; sector shell, local gameplay lights và environment dynamics gắn trực tiếp với board thuộc RF-03. Giữ `BoardView` làm facade/API công khai; quy định cache, cleanup, material instance và tween ownership | 15 màn giữ placement/palette; cửa/cầu/portal/elevator/energy/fragment cập nhật đúng; không tích lũy node hoặc tween sau reload; `main.gd` không truy cập xuyên qua component con của `BoardView` | RF-00; tích hợp với RF-02 / lớn |
| RF-04 | HUD và màn UI: `game_hud.gd`, `src/ui/`, `scenes/ui/` | Tách bảng thống kê, controls, pause/win thành component; **ưu tiên scene composition (`.tscn`) cho component có lifecycle/UI độc lập** thay vì chuyển nguyên procedural UI sang một `HudBuilder`; gom style/accessibility chỉ khi có code trùng thực tế; kiểm tra main menu/settings/codex | Signal không nối lặp; nhãn/nút/layout giữ hành vi; pause, next/restart, text scale và tương phản dùng được ở viewport nhỏ; component scene có API rõ và không buộc `GameHud` biết chi tiết node bên trong | RF-00, RF-02 / vừa–lớn |
| RF-05 | Truyện và chiến dịch: `story_director.gd`, `main.gd`, `ending_cutscene.gd`, `story_data.gd` | Chốt ownership trigger và trình tự intro/post-step/win/ending; đưa phần điều phối truyện còn sót khỏi main; tách tra cứu trigger nếu cần | Event chạy đúng một lần theo quy ước; L7/L11/L13–15, fragment, codex và các lựa chọn ending giữ hành vi; hủy phiên không treo chờ dialogue | RF-02, RF-03, RF-04 / vừa |
| RF-06 | Âm thanh và môi trường toàn scene: `audio_manager.gd`, `vfx_manager.gd`, `void_environment.gd`, môi trường trong main | Tách cấu hình asset âm thanh khỏi playback; tách **WorldEnvironment, DirectionalLight, chapter lighting/power toàn scene** khỏi controller; giữ manager công khai hiện có; quy định dừng loop/tween khi rời màn. Không nhận lại sector shell/local board lighting đã thuộc RF-03 | BGM/ambience/SFX, elevator loop, mute/volume đúng; mobile giữ render budget; không nhân đôi player/light sau chuyển scene; chỉ còn một owner cho từng nhóm lighting/power | RF-02, RF-03 / vừa |
| RF-07 | Luật chơi, dữ liệu và lưu tiến độ: `game_logic.gd`, `game_state.gd`, `progress_store.gd`, `score_rules.gd`, `level_data.gd`, `levels.gd` | Chia thành **RF-07A Contract audit**: đọc/chốt hợp đồng `MoveResult`, snapshot, signal `LevelFlow`, settings/progress mà RF-02/RF-05 phụ thuộc; và **RF-07B Optional structural cleanup**: chỉ tách parser/mechanics hoặc state khi có lợi ích rõ. Giữ format save và level resources | RF-07A hoàn tất trước RF-02; 15 màn giải được, par không đổi; undo phục hồi đủ trạng thái; điểm/sao/phí, unlock, backup/migration giữ tương thích | RF-00; RF-07A trước RF-02/RF-05, RF-07B có thể làm sau / vừa–lớn |
| RF-08 | Tooling, tài liệu và báo cáo: `tools/`, `src/tools/`, `tests/`, `docs/` | Chuẩn hóa lệnh chạy test và nhóm theo chức năng; phân biệt capture/generator với regression; cập nhật sơ đồ module, hướng dẫn và bảng kết quả | Người khác chạy được checks; mọi gói Done có bằng chứng; báo cáo nêu được trước/sau, hạn chế và phần chưa nghiệm thu | Xuyên suốt, kết thúc sau RF-01–07 / vừa |

RF-07 không mặc định viết lại toàn bộ `GameLogic`: bản hiện tại đã độc lập với scene. **RF-07A là bắt buộc trước RF-02**, còn RF-07B chỉ thực hiện khi có lợi ích được chứng minh. Mục tiêu là làm rõ contract trước khi di chuyển orchestration, không đổi luật chơi chỉ để giảm số dòng.

### 3.1. Ranh giới triển khai bắt buộc

- **RF-03 vs RF-06:** mọi geometry, decoration, local light, local power material và dynamics sinh ra như một phần của board thuộc RF-03; `WorldEnvironment`, DirectionalLight và chapter/global power orchestration thuộc RF-06.
- **RF-02:** không tạo một `PlayerMovementController` mới rồi truyền vào toàn bộ `BoardView`, HUD, Audio, VFX và Story. Navigation/action execution phát kết quả hoặc trả dữ liệu; lớp điều phối cập nhật presentation qua API công khai.
- **RF-04:** nếu một phần UI có cấu trúc node/lifecycle riêng như pause hoặc win panel, ưu tiên scene `.tscn` + controller tương ứng. Chỉ dùng builder khi UI thật sự được sinh động theo dữ liệu và không phù hợp để author bằng scene.
- **BoardView facade:** `main.gd` tiếp tục gọi API như `set_active_floor`, `set_lock_state`, `set_energy_progress`; không truy cập kiểu `board_view.environment.lighting...` hoặc component nội bộ tương đương.

## 4. Thứ tự và mốc bàn giao

Chưa có deadline, số người hoặc thời lượng kỳ học; dùng mốc đầu ra thay cho cam kết số tuần. Khi có lịch, ước lượng lại sau RF-00 và gói đầu tiên.

1. **M0 — Có baseline xanh:** RF-00; xử lý các assertion cũ, chạy full suite thành công rồi mới chốt baseline; lập danh sách kết quả move, signal, trường snapshot và dependency mà RF-02 dùng.
2. **M1 — Hoàn thành lát cắt nhỏ:** RF-01; chứng minh có thể chuyển trách nhiệm mà không đổi hành vi.
3. **M2 — Luồng gameplay rõ:** RF-07A → RF-02A Navigation → RF-02B Action execution → RF-02C Lifecycle/session → kiểm thử tích hợp hint/input/undo/elevator.
4. **M3 — View và UI rõ:** RF-03 theo từng phần, sau đó RF-04; giữ API trung gian ổn định để kiểm thử sau mỗi lần tách.
5. **M4 — Chiến dịch hoàn chỉnh:** RF-05, RF-06 và RF-07B nếu còn cần; kiểm tra từ start menu đến ending và tải lại save.
6. **M5 — Nghiệm thu cuối kỳ:** RF-08; toàn bộ regression, visual review desktop và playtest Android thật nếu có thiết bị.

Ưu tiên khi thời gian hạn chế: RF-00 → RF-01 → RF-07A → RF-02A/02B/02C → phần decoration/asset của RF-03 → RF-08. Những phần chưa làm ghi là Deferred và nêu lý do; không báo cáo toàn bộ refactor đã hoàn thành.

## 5. Rủi ro luồng và cách kiểm chứng

| Thành phần khảo sát luồng | Kết luận phục vụ triển khai |
| --- | --- |
| Luồng mục tiêu | Nhận một hành động, áp dụng luật, trình diễn kết quả và kết thúc thao tác trong đúng phiên |
| Luồng mong muốn | Một đầu mối sở hữu lifecycle; state thay đổi qua luật chơi; view phản ánh kết quả |
| Luồng thực tế | Main vẫn nối input, logic, hint, tween, audio, story và win qua nhiều hàm/await |
| Điểm cần kiểm tra | Hủy giữa autowalk/elevator/dialogue, restart khi animation đang chạy, chuyển tầng rồi undo; chưa kết luận có bug |
| Cơ chế bảo vệ hiện có | Busy, kiểm tra pause/won, token phiên và reset gesture/story; phải hiểu mục đích trước khi di chuyển hoặc bỏ |
| Vấn đề cấu trúc | Nhiều trách nhiệm nằm ở main; checkpoint hint và các trạng thái trình diễn khó theo dõi cùng lifecycle |
| Thiết kế đề xuất | Coordinator sở hữu phiên; navigation/action execution có ranh giới riêng; hint sở hữu checkpoint; `BoardView` là facade; view/UI nhận kết quả qua API rõ |
| Kiểm chứng nhanh nhất | Hoàn thành RF-01, sau đó thử một luồng move → undo → hint → restart trước khi mở rộng |

Giữ nguyên code hiện tại có lợi thế ít rủi ro trước kỳ nộp. Tách quá nhiều lớp có thể làm việc lần theo code khó hơn và tăng kết nối chéo. Vì vậy, dừng việc tách khi module mới chỉ chuyển tiếp lời gọi hoặc vẫn cần truy cập toàn bộ main; thu nhỏ phạm vi để có ít nhất một lát cắt hoàn chỉnh và kiểm chứng được. Việc đổi NodePath/API cũng ảnh hưởng test, scene và tool capture: cập nhật cùng gói thay đổi.

## 6. Kiểm thử theo chức năng

| Nhóm | Kiểm thử hiện có cần chạy | Kiểm tra bổ sung khi ranh giới thay đổi |
| --- | --- | --- |
| Luật/dữ liệu/save | `verify`, `tools/validate_levels.py` | Save cũ, backup bị hỏng, chấm sao/phí hint, snapshot sau undo |
| Input và tầng | `verify_interactions`, `verify_multifloor_camera`, `verify_sequential_elevator_runtime` | Hủy autowalk/elevator khi restart/rời scene; keyboard và tap cùng kết quả |
| Hint | `verify_hint_recovery` | Đi lệch route → undo → restart → đổi tầng |
| Truyện | `verify_narrative_events`, `verify_story_holograms` | Thứ tự trigger, event một lần, hủy dialogue và ending |
| Render/map | `verify_modular_runtime`, `verify_modular_kit`, `verify_map_clusters`, `verify_map_expansion`, `verify_module_motion`, `verify_chapter_props`, `verify_campaign_dressing`, `verify_campaign_surfaces`, `verify_material_profiles` | So ảnh cùng level/camera; reload nhiều lần; `tools/validate_map_decorations.py`, `tools/audit_assets.py` |
| Audio/môi trường | `verify_audio_profiles`, `verify_environment_dynamics`, `verify_mobile_render_budget` | Nghe thực tế, dừng loop, mute/volume, FPS/RAM/tải màn trên cùng thiết bị; xác nhận test so **hành vi/thuộc tính stream** thay vì object identity nếu manager chủ động duplicate stream để bật loop |
| UI | Các test tích hợp liên quan | Menu → game → pause → settings → codex → win; viewport nhỏ, text scale, tương phản |

Chạy test chọn lọc bằng `python tools/run_tests.py -t verify_hint_recovery` (thay tên theo gói). Chạy toàn bộ bằng `python tools/run_tests.py` ở M0/M5 và sau thay đổi tích hợp rộng. Đọc nội dung test để xác nhận coverage, không suy từ tên rằng mọi tình huống đã được kiểm tra. Test mới phải kiểm hành vi hoặc lỗi hồi quy thực tế, không chỉ xác nhận file/class vừa được tạo.

Android export preflight dùng `tools/validate_android_export.py` khi tạo lại APK. Headless PASS không thay thế việc nghe âm thanh, xem animation và chơi trên Android thật.

**Baseline/refactor checkpoint 2026-10-02:** assertion audio cũ đã được sửa theo hành vi `_looped(source)` thay vì object identity. RF-01 chuyển checkpoint/resync/recovery/fallback hint vào `HintManager`; RF-07A chốt contract `GameLogic.try_move()` mà không đổi domain. RF-02 hoàn tất `PlayerNavigation`, `ActionExecution` và lifecycle/session qua `GameCoordinator`. RF-03 tách board-local presentation thành `BoardGeometry`, `BoardGameplayObjects`, `BoardDecorations`, `BoardActors`, `BoardLighting`, `EnvironmentDynamics` và `BoardEnvironment`. RF-04 chuyển HUD sang scene composition (`HudStatusPanel`, `HudControls`, `HudPausePanel`, `HudWinPanel`) với `GameHud` làm facade. RF-05 gom các trigger narrative còn sót vào `StoryDirector` và dùng `LevelFlow.complete_current()` làm owner completion record. RF-06 tách global environment/power/blackout vào `SceneEnvironmentController` và asset registry âm thanh vào `AudioCatalog`, trong khi `EchoAudioManager` giữ playback lifecycle. `BoardView` giảm **~2110 → 609 dòng**, `main.gd` **~1288 → 835**, `game_hud.gd` **~1041 → 173** mà không đổi luật puzzle. Full suite gần nhất **35/35 PASS**; solver xác nhận **15/15 màn solvable và optimal = par**, placement validator xác nhận **930 decoration** hợp lệ trên 15 màn, asset audit **329 file**. Số dòng hiện tại cao hơn checkpoint RF-03/04/06 vì các pass hình ảnh, âm thanh và phòng thử sau refactor bổ sung code trong cùng ranh giới sở hữu.

## 7. Bảng theo dõi

Trạng thái: Todo → In progress → Review → Done; Blocked cần lý do; Deferred cần quyết định phạm vi. Done chỉ khi code, checks liên quan và bằng chứng đều hoàn tất.

| ID | Trạng thái | Người phụ trách | Dự kiến / thực tế | Commit hoặc diff | Bằng chứng / trở ngại |
| --- | --- | --- | --- | --- | --- |
| RF-00 | Done | Chưa phân công | Đã thực hiện | Working tree | Baseline xanh; audio test kiểm loop/content thay vì object identity; full suite đã PASS |
| RF-01 | Done | Chưa phân công | Đã thực hiện | Working tree | Hint checkpoint/resync/recovery/fallback thuộc `HintManager`; `verify_hint_recovery` + full suite PASS |
| RF-02 | Done | Chưa phân công | Đã thực hiện | Working tree | `PlayerNavigation` + `ActionExecution` + `GameCoordinator`; `verify_player_navigation`, `verify_action_execution`, `verify_game_coordinator`, interaction/elevator integration và full suite PASS |
| RF-03 | Done | Chưa phân công | Đã thực hiện | Working tree | `BoardGeometry`, `BoardGameplayObjects`, `BoardDecorations`, `BoardActors`, `BoardLighting`, `EnvironmentDynamics`, `BoardEnvironment`; rebuild không tích lũy node registry; render/multifloor/mobile/full suite PASS; `BoardView` vẫn facade |
| RF-04 | Done | Chưa phân công | Đã thực hiện | Working tree | Scene composition cho status/controls/pause/win; `verify_hud_components`, interaction và full suite PASS; `GameHud` còn 157 dòng facade |
| RF-05 | Done | Chưa phân công | Đã thực hiện | Working tree | Trigger `first_core_connected`/L7 bridge nằm trong `StoryDirector`; completion record qua `LevelFlow`; narrative/integration PASS |
| RF-06 | Done | Chưa phân công | Đã thực hiện | Working tree | `SceneEnvironmentController` sở hữu global environment/light/power/blackout; `AudioCatalog` tách config khỏi playback; audio/mobile/elevator/full suite PASS |
| RF-07 | Done | Chưa phân công | RF-07A Done; RF-07B Deferred có chủ đích | Working tree | Contract `try_move`/snapshot đã được audit và dùng bởi RF-02; `GameLogic` đã độc lập scene nên không tách parser/mechanics/state khi chưa có lợi ích cụ thể |
| RF-08 | Done | Chưa phân công | Đã thực hiện | Working tree | `run_tests.py` có test groups; `REFACTOR_ARCHITECTURE.md` ghi kiến trúc/bằng chứng; final 35/35 regression + solver/par + placement + asset audit + headless editor PASS |

Mỗi cập nhật tiến độ ghi: ID, trách nhiệm đã chuyển, checks chạy/kết quả, bằng chứng, việc tiếp theo. Tính tiến độ bằng số gói đã nghiệm thu trên phạm vi đã chốt; nếu dùng trọng số thì chốt trọng số trước triển khai và không coi số dòng giảm là phần trăm hoàn thành.

## 8. Khung báo cáo cuối kỳ

1. **Mục tiêu và phạm vi:** vấn đề ban đầu, baseline/commit, các RF thực hiện và các RF hoãn.
2. **Kiến trúc trước/sau:** sơ đồ module và luồng gameplay; ai sở hữu state, lifecycle, hint và trình diễn.
3. **Kết quả theo chức năng:** mỗi RF có vấn đề → thay đổi → hành vi giữ nguyên → bằng chứng nghiệm thu → hạn chế.
4. **Kiểm thử:** bảng baseline/sau refactor, lỗi sẵn có/lỗi mới, môi trường Godot/thiết bị và đường dẫn log.
5. **Hiệu quả:** main/board/HUD còn những trách nhiệm nào; giảm phụ thuộc chéo hoặc trạng thái trùng ở đâu; so tải màn/FPS/RAM trên cùng cấu hình nếu đã đo.
6. **Demo:** move/push, cửa/cầu, portal/elevator, hint recovery/undo, pause/settings, fragment và ending.
7. **Kết luận:** mục tiêu đạt đến đâu, rủi ro còn lại và hướng tiếp tục có căn cứ.

Mẫu bảng kết quả cuối kỳ:

| Chức năng / RF | Trước refactor | Sau refactor | Kiểm thử và minh chứng | Kết luận |
| --- | --- | --- | --- | --- |
| Gợi ý / RF-01 | Checkpoint/recovery nằm trong main | `HintManager` sở hữu route/checkpoint/resync/recovery | `verify_hint_recovery` + full regression | Đạt |

Bằng chứng nên dùng ID RF trong tên thư mục/file để nối task, diff, log và demo. Khi hoàn tất toàn bộ phạm vi đã chốt, chuyển kế hoạch vào `docs/plan/done/` và cập nhật liên kết mục lục.
