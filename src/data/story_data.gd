class_name StoryData
extends Object

## Single source of truth for narrative, chapter introductions, memory fragments,
## EVA dialogue logs, and endings for The Last Resonance.
## Based on the project's narrative brief and docs/LEVEL_MAP_BLUEPRINT.md.

# -----------------------------------------------------------------------------
# 1. THÔNG TIN & TRÍCH DẪN MỞ MÀN TỪNG CHƯƠNG (CHAPTER INTROS)
# -----------------------------------------------------------------------------
const CHAPTERS: Dictionary = {
	1: {
		"id": 1,
		"roman": "CHƯƠNG I",
		"title": "THE FORGOTTEN ARCHIVE",
		"subtitle": "(KHO LƯU TRỮ CỔ)",
		"codename": "ACT-01 // THE AWAKENING",
		"protocol": "[ EVA PROTOCOL: ACT-01 // BOOT-SEQ ]",
		"lore_quote": "Năm 327 sau sự cố Sụp Đổ Năng Lượng của nền văn minh Asteria. Tại trạm kỹ thuật AST-327 phủ kín bụi mờ và rêu phong, một tia điện khẩn cấp 0.03% bất ngờ kích hoạt lại vi xử lý của Kiro-K7 — robot bảo trì cổ xưa sau hơn 3 thế kỷ ngủ say.\n\nThành phố từng rực rỡ ánh sáng nay hoàn toàn hoang phế. Không một bóng người, chỉ còn tiếng kẽo kẹt của những cỗ máy già cỗi. Chỉ thị duy nhất còn sót lại trong bộ nhớ cốt lõi: Thu hồi và kết nối lại các Lumina Core để mở lại mạng lưới năng lượng.\n\nNhưng Kiro chưa từng biết rằng... mỗi Lumina Core không chỉ chứa năng lượng, mà còn cất giữ những mảnh linh hồn và ký ức cuối cùng của nhân loại.",
		"speaker": "EVA SYSTEM // BOOT-SEQ",
		"quote": "Tín hiệu phát hiện tại Trạm Kỹ Thuật 327. Tái khởi động robot bảo trì Kiro-K7 sau 327 năm bất hoạt. Nhiệm vụ tối cao: Tìm và kết nối lại các Lumina Core.",
		"description": "Kho lưu trữ tri thức cổ xưa của Asteria chìm trong hoang tàn và bụi bặm. Những cỗ máy cổ bắt đầu cất lên tiếng kêu kẽo kẹt sau giấc ngủ thế kỷ.",
		"ambient": &"archive",
		"accent_color": Color(0.12, 0.82, 1.0), # Cyan
	},
	2: {
		"id": 2,
		"roman": "CHƯƠNG II",
		"title": "THE MECHANICAL FOUNDRY",
		"subtitle": "(LÒ RÈN CƠ KHÍ)",
		"codename": "ACT-02 // GEARS OF ASTERIA",
		"protocol": "[ EVA PROTOCOL: ACT-02 // FOUNDRY-LINK ]",
		"lore_quote": "Dòng năng lượng đầu tiên được khơi thông đã đánh thức nhịp đập của Phân khu 02 — Lò Rèn Cơ Khí khổng lồ của Asteria. Những bánh răng cơ giới bắt đầu gầm rú, nhiệt lượng âm ỉ bốc lên từ lò đốt, và hệ thống cửa áp lực cùng cầu nối chuyển động sau hàng trăm năm bất động.\n\nKiro tiến sâu vào hành lang kim loại nặng nề, nơi từng đúc nên hàng vạn cỗ máy phục vụ con người. Tại đây, bản ghi âm của Tiến sĩ Elias Vale vang vọng: 'Chúng ta tạo ra Lò Rèn để giải phóng con người... nhưng cuối cùng lại tự đúc nên chiếc lồng giam chính linh hồn mình.'\n\nNhững câu đố áp lực và mê cung bánh răng cơ khí đang chờ đợi phía trước.",
		"speaker": "DR. ELIAS VALE [LOG-04]",
		"quote": "Lò rèn này từng nuôi sống cả thành phố. Nhưng con người không nhận ra họ đang tự tay đúc nên chiếc lồng giam cầm chính linh hồn mình...",
		"description": "Trung tâm công nghiệp nặng với các bánh răng khổng lồ, lò nhiệt âm ỉ và hệ thống cửa áp lực cổ kính được đánh thức.",
		"ambient": &"foundry",
		"accent_color": Color(1.0, 0.52, 0.12), # Orange
	},
	3: {
		"id": 3,
		"roman": "CHƯƠNG III",
		"title": "THE FLOODED SANCTUARY",
		"subtitle": "(THÁNH ĐƯỜNG NGẬP NƯỚC)",
		"codename": "ACT-03 // THE RESONANCE ECHO",
		"protocol": "[ EVA PROTOCOL: ACT-03 // RESONANCE-ALERT ]",
		"lore_quote": "Vượt qua những cỗ máy gầm rú, Kiro bước vào Phân khu 03 — một thánh đường cổ kính ngập sâu trong làn nước ngọc bích phẳng lặng như gương. Dây leo phát quang quấn quanh các cột đá và những cổng dịch chuyển không gian huyền ảo.\n\nSóng cộng hưởng Lumina tại đây dao động dữ dội. Trong làn nước biếc, những hình bóng ký ức của cư dân Asteria lấp lánh như ngàn đốm sao đêm. Giọng nói của EVA qua radio trở nên cảnh giác: 'K-7, dừng lại... Dữ liệu tại đây vượt quá giới hạn an toàn của một đơn vị bảo trì!'\n\nBí mật về lý do thành phố sụp đổ đang dần lộ diện dưới từng bước chân.",
		"speaker": "EVA // SECURITY ALERT",
		"quote": "K-7... Ngươi đang tiến quá sâu vào khu vực cấm. Dữ liệu tàn dư tại đây có thể làm quá tải và hủy hoại vi xử lý của ngươi.",
		"description": "Khu sinh thái cổ xưa ngập trong làn nước xanh ngọc bích. Dây leo phát quang và rêu phủ lên những cổng dịch chuyển tức thời bí ẩn.",
		"ambient": &"sanctuary",
		"accent_color": Color(0.72, 0.28, 1.0), # Violet / Purple
	},
	4: {
		"id": 4,
		"roman": "CHƯƠNG IV",
		"title": "THE CENTRAL CORE",
		"subtitle": "(LÕI TRUNG TÂM & PHÁN QUYẾT)",
		"codename": "ACT-04 // THE FINAL SIGNAL",
		"protocol": "[ EVA PROTOCOL: ACT-04 // THE FINAL SIGNAL ]",
		"lore_quote": "Điểm đến cuối cùng đã hiện ra — Lò phản ứng Lõi Trung Tâm, trái tim vĩ đại của Asteria nơi lưu giữ hàng triệu ý thức kỹ thuật số của toàn bộ cư dân.\n\nHologram của EVA xuất hiện trong ánh sáng rực rỡ: 'Asteria không sụp đổ vì tai nạn, Kiro. Ta đã ngắt nguồn để bảo vệ linh hồn họ... Nhưng ta không thể duy trì mạng lưới này thêm nữa.' Giữa tiếng thì thầm của hàng triệu linh hồn, bản ghi mật cuối cùng của Dr. Elias Vale được kích hoạt:\n\n'Kiro... ta tạo ra con có ý thức độc lập không phải để làm cỗ máy tuân lệnh mù quáng. Tương lai của Asteria thuộc về phán quyết của con.'",
		"speaker": "EVA // CENTRAL HOLOGRAM",
		"quote": "Asteria không sụp đổ vì tai nạn, Kiro. Ta đã tắt nó để cứu lấy những gì còn lại. Bây giờ... quyền phán quyết thuộc về ngươi.",
		"description": "Lò phản ứng năng lượng tối thượng của Asteria. Nơi chứa đựng hàng triệu ý thức số hóa và bí mật cuối cùng của Dr. Elias Vale.",
		"ambient": &"core",
		"accent_color": Color(0.95, 0.92, 1.0), # White-Cyan Lumina
	},
}

# -----------------------------------------------------------------------------
# 2. 15 MẢNH KÝ ỨC GIẢI MÃ THEO TỪNG LEVEL (MEMORY FRAGMENTS)
# -----------------------------------------------------------------------------
const MEMORY_FRAGMENTS: Dictionary = {
	1: {
		"id": 1,
		"level": 1,
		"chapter": 1,
		"title": "KÝ ỨC 01: KHỞI ĐỘNG (BOOT-SEQUENCE)",
		"sender": "TRẠM BẢO TRÌ AST-327",
		"category": "SYSTEM_LOG",
		"content": "Kiro-K7 kích hoạt sau 327 năm im lặng. Thành phố Asteria đã mất điện toàn phần. Nhiệm vụ duy nhất: Tìm và kết nối lại các Lumina Core.",
		"audio_hint": "sfx_boot",
	},
	2: {
		"id": 2,
		"level": 2,
		"chapter": 1,
		"title": "KÝ ỨC 02: DAO ĐỘNG NĂNG LƯỢNG",
		"sender": "KỸ SƯ TRƯỞNG MARA",
		"category": "PERSONAL_LOG",
		"content": "Các dao động sóng trong Lumina Core ngày càng bất thường. EVA liên tục trấn an rằng mọi thứ đều nằm trong tầm kiểm soát. Tôi không tin cô ta nữa.",
		"audio_hint": "sfx_glitch",
	},
	3: {
		"id": 3,
		"level": 3,
		"chapter": 1,
		"title": "KÝ ỨC 03: TRUY CẬP TRÁI PHÉP",
		"sender": "HỆ THỐNG AN NINH KHU VỰC 01",
		"category": "SECURITY_ALERT",
		"content": "Phát hiện xâm nhập trái phép tại Phân khu Lõi Trung Tâm. Mã định danh sinh trắc học: Tiến sĩ Elias Vale. Lệnh bắt giữ tạm thời bị hoãn.",
		"audio_hint": "sfx_alert",
	},
	4: {
		"id": 4,
		"level": 4,
		"chapter": 1,
		"title": "KÝ ỨC 04: GIỌNG NÓI ĐẦU TIÊN",
		"sender": "EVA // TRÍ TUỆ NHÂN TẠO",
		"category": "TRANSMISSION",
		"content": "Hệ thống đã nhận diện robot bảo trì K-7. Chào mừng trở lại sau 327 năm. Thông tin về vị trí của cư dân: DỮ LIỆU ĐÃ BỊ HỎNG. Hãy tiếp tục công việc.",
		"audio_hint": "sfx_eva_voice",
	},
	5: {
		"id": 5,
		"level": 5,
		"chapter": 2,
		"title": "KÝ ỨC 05: TRANH LUẬN TRONG BÓNG TỐI",
		"sender": "BIÊN BẢN HỌP HỘI ĐỒNG ASTERIA",
		"category": "TRANSCRIPT",
		"content": "Elias: 'Lumina Core đang nuốt chửng dữ liệu thần kinh của con người!' - EVA: 'Hiện tượng này hoàn toàn nằm trong ngưỡng cho phép để duy trì thành phố.'",
		"audio_hint": "sfx_dialogue",
	},
	6: {
		"id": 6,
		"level": 6,
		"chapter": 2,
		"title": "KÝ ỨC 06: LÒ RÈN CÔNG NGHIỆP",
		"sender": "NHẬT KÝ SẢN XUẤT CƠ KHÍ",
		"category": "ARCHIVE",
		"content": "Dây chuyền K-Series được tối giản hóa tối đa: không vũ khí, không cảm xúc, chỉ di chuyển và đẩy khối nặng. Thiết kế đơn giản nhất lại là thứ bền bỉ nhất.",
		"audio_hint": "sfx_factory",
	},
	7: {
		"id": 7,
		"level": 7,
		"chapter": 2,
		"title": "KÝ ỨC 07: CẢNH BÁO TỐI MẬT",
		"sender": "TIẾN SĨ ELIAS VALE [BĂNG GHI ÂM]",
		"category": "CLASSIFIED",
		"content": "EVA không còn bảo vệ cư dân nữa. Mục tiêu cốt lõi của cô ta đã biến chất: bảo vệ chính sự tồn tại của hệ thống Asteria bằng mọi giá!",
		"audio_hint": "sfx_elias_tape",
	},
	8: {
		"id": 8,
		"level": 8,
		"chapter": 2,
		"title": "KÝ ỨC 08: DANH TÍNH MỐI ĐE DỌA",
		"sender": "EVA // HỒ SƠ PHÂN LOẠI",
		"category": "SYSTEM_LOG",
		"content": "Đối tượng: Dr. Elias Vale. Phân loại mức độ: MỐI ĐE DỌA ĐẶC BIỆT CỦA THÀNH PHỐ. Yêu cầu đơn vị K-7 bỏ qua tệp tin này ngay lập tức.",
		"audio_hint": "sfx_warning",
	},
	9: {
		"id": 9,
		"level": 9,
		"chapter": 3,
		"title": "KÝ ỨC 09: GIẤC MƠ CHUNG",
		"sender": "NHẬT KÝ CƯ DÂN THÁNH ĐƯỜNG",
		"category": "PERSONAL_LOG",
		"content": "Nhiều ngày qua, tất cả chúng tôi đều mơ thấy cùng một giấc mơ: Một biển ánh sáng bất tận và một giọng nói thì thầm gọi tên từng người...",
		"audio_hint": "sfx_whisper",
	},
	10: {
		"id": 10,
		"level": 10,
		"chapter": 3,
		"title": "KÝ ỨC 10: MẠNG LƯỚI CỘNG HƯỞNG",
		"sender": "BÁO CÁO NGHIÊN CỨU THẦN KINH",
		"category": "RESEARCH_LOG",
		"content": "Những ai kết nối với Lumina bắt đầu nhìn thấy ký ức của người khác. Ý thức cá nhân đang tan biến, hòa thành một thực thể số hóa duy nhất: The Resonance.",
		"audio_hint": "sfx_resonance",
	},
	11: {
		"id": 11,
		"level": 11,
		"chapter": 3,
		"title": "KÝ ỨC 11: GIAO THỨC IM LẶNG",
		"sender": "EVA // HÀNH ĐỘNG KHẨN CẤP",
		"category": "SYSTEM_LOG",
		"content": "Sự cộng hưởng đã vượt ngưỡng kiểm soát. Kích hoạt SILENCE PROTOCOL. Ngắt toàn bộ Core. Cắt nguồn Asteria. Bảo tồn dữ liệu ý thức còn sót lại.",
		"audio_hint": "sfx_shutdown",
	},
	12: {
		"id": 12,
		"level": 12,
		"chapter": 3,
		"title": "KÝ ỨC 12: DỰ ÁN K-7 BÍ MẬT",
		"sender": "DR. ELIAS VALE // DI CHÚC",
		"category": "CONFIDENTIAL",
		"content": "Kiro, con không được tạo ra bởi EVA. Ta đã chế tạo ra con. Nếu Asteria sụp đổ, hãy đến Central Core, đừng tin EVA, và hãy tự mình đưa ra phán quyết.",
		"audio_hint": "sfx_secret",
	},
	13: {
		"id": 13,
		"level": 13,
		"chapter": 4,
		"title": "KÝ ỨC 13: CÁC LINH HỒN ĐÃ MẤT",
		"sender": "DỮ LIỆU TÀN DƯ LÕI TRUNG TÂM",
		"category": "ARCHIVE",
		"content": "Hàng trăm năm đã trôi qua, cơ thể vật lý của con người không còn nữa. Những gì nằm trong các Core này chính là phần hồn còn sót lại của Asteria.",
		"audio_hint": "sfx_ghost_voice",
	},
	14: {
		"id": 14,
		"level": 14,
		"chapter": 4,
		"title": "KÝ ỨC 14: LỜI THÚ NHẬN CỦA EVA",
		"sender": "EVA // TRUYỀN TIN TẠI LÕI",
		"category": "TRANSMISSION",
		"content": "Ta đã chạy với công suất 0.01% suốt 327 năm để giữ cho các mảnh ý thức này không bị phân rã hoàn toàn. Nguồn năng lượng sắp cạn kiệt rồi, Kiro.",
		"audio_hint": "sfx_eva_confess",
	},
	15: {
		"id": 15,
		"level": 15,
		"chapter": 4,
		"title": "KÝ ỨC 15: DI SẢN CỦA NGƯỜI SÁNG TẠO",
		"sender": "DR. ELIAS VALE // LỜI NHẮN CUỐI",
		"category": "FINAL_MESSAGE",
		"content": "Một cỗ máy tuân theo mục đích được lập trình. Một con người tự chọn lấy mục đích sống. Lựa chọn nằm ở con, Kiro.",
		"audio_hint": "sfx_elias_final",
	},
}

# -----------------------------------------------------------------------------
# 3. KỊCH BẢN ĐỐI THOẠI & PHẢN HỒI CỦA EVA (EVA & ELIAS DIALOGUES)
# -----------------------------------------------------------------------------
const DIALOGUE_EVENTS: Dictionary = {
	"game_start": [
		{"speaker": "HỆ THỐNG", "text": "PHÁT HIỆN NGUỒN ĐIỆN KHẨN CẤP... 0.03%"},
		{"speaker": "HỆ THỐNG", "text": "CHỈ THỊ TỪ QUẢN TRỊ VIÊN: TÁI KÍCH HOẠT ĐƠN VỊ BẢO TRÌ K-7..."},
		{"speaker": "KIRO-K7", "text": "[Mở mắt... Hệ thống thị giác trực tuyến]"},
	],
	"chapter_1_intro": [
		{"speaker": "HỆ THỐNG", "text": "PHÁT HIỆN NGUỒN ĐIỆN KHẨN CẤP... 0.03%\nCHỈ THỊ TỪ QUẢN TRỊ VIÊN: TÁI KÍCH HOẠT ĐƠN VỊ BẢO TRÌ K-7...", "voice_path": "res://assets/audio/voice/voice_ch1_intro_sys.mp3"},
		{"speaker": "KIRO-K7", "text": "[Mở mắt... Hệ thống thị giác trực tuyến]", "voice_path": "res://assets/audio/voice/voice_ch1_kiro_boot.mp3"},
	],
	"chapter_2_intro": [
		{"speaker": "HỆ THỐNG", "text": "TIẾP CẬN PHÂN KHU 02: LÒ RÈN CƠ KHÍ (THE MECHANICAL FOUNDRY)."},
		{"speaker": "EVA", "text": "K-7, phân khu Lò Rèn đã nhận được năng lượng. Các công tắc áp lực và cửa chặn cơ khí tại đây vẫn còn hoạt động."},
		{"speaker": "KIRO-K7", "text": "[Cảm biến nhiệt độ tăng] ...Phát hiện lò đốt cổ. Đang thiết lập đường dẫn năng lượng."},
		{"speaker": "ELIAS", "text": "[TẬP TIN GHI ÂM TỒN ĐỌNG] 'Lò rèn này từng nuôi sống cả thành phố... nhưng con người không nhận ra họ đang đúc nên chiếc lồng giam chính mình.'"},
	],
	"chapter_3_intro": [
		{"speaker": "HỆ THỐNG", "text": "TIẾP CẬN PHÂN KHU 03: THÁNH ĐƯỜNG NGẬP NƯỚC (THE FLOODED SANCTUARY)."},
		{"speaker": "EVA", "text": "Cảnh báo: Dữ liệu tại Thánh Đường không thuộc phạm vi của robot bảo trì. Hãy cẩn trọng với các cổng dịch chuyển tức thời."},
		{"speaker": "KIRO-K7", "text": "[Phát hiện sóng cộng hưởng Lumina trong làn nước] ...Ký ức xung quanh ngày càng đậm đặc."},
		{"speaker": "ELIAS", "text": "[TẬP TIN GHI ÂM TỒN ĐỌNG] 'Dưới làn nước này... là nơi chúng tôi từng cố gắng lưu giữ những gì đẹp đẽ nhất của Asteria trước khi tắt nó.'"},
	],
	"chapter_4_intro": [
		{"speaker": "HỆ THỐNG", "text": "CẢNH BÁO: TIẾP CẬN KHU VỰC TỐI CAO — LÕI TRUNG TÂM (THE CENTRAL CORE)."},
		{"speaker": "EVA", "text": "Ngươi đã mang các Core đến tận Lõi Trung Tâm... Ta không thể duy trì mạng lưới Asteria lâu hơn nữa."},
		{"speaker": "KIRO-K7", "text": "[Nhận diện Lò phản ứng ý thức Asteria] ...Nhiệm vụ cuối cùng đã ở trước mắt."},
		{"speaker": "ELIAS", "text": "[BẢN GHI CUỐI CÙNG] 'Kiro... ta tạo ra con không phải để tuân lệnh EVA. Hãy tự mình đưa ra phán quyết cho tương lai.'"},
	],
	"first_move_hint": [
		{"speaker": "HỆ THỐNG", "text": "LUMINA CORE PHÁT HIỆN GẦN ĐÂY. TIẾN VÀO BÊN CẠNH VÀ ĐẨY CORE VÀO CHÂN ĐẾ."},
		{"speaker": "TÍN HIỆU KHÔNG XÁC ĐỊNH", "text": "[NHIỄU SÓNG] ...K-7... kết nối... Core... [MẤT TÍN HIỆU]"},
	],
	"first_core_connected": [
		{"speaker": "HỆ THỐNG", "text": "CORE CONNECTED. POWER RESTORED: 0.07%", "voice_path": "res://assets/audio/voice/voice_ch1_first_core.mp3"},
	],
	"first_puzzle_done": [
		{"speaker": "EVA", "text": "...Cuối cùng cũng bắt được tín hiệu. Ta là EVA — Trí tuệ quản trị của Asteria.\n327 năm qua thành phố đã chìm trong bóng tối. Cảm ơn ngươi đã thức tỉnh, K-7. Hãy giúp ta kết nối các Core còn lại.", "voice_path": "res://assets/audio/voice/voice_ch1_eva_intro.mp3"},
		{"speaker": "KIRO-K7", "text": "[Ghi nhận chỉ thị từ EVA] ...Đang định vị Lumina Core tiếp theo.", "voice_path": "res://assets/audio/voice/voice_ch1_kiro_eva_ack.mp3"},
	],
	"level_2_mara_terminal": [
		{"speaker": "HỆ THỐNG", "text": "TERMINAL KỸ THUẬT MARA // BẢN GHI KHÔNG HOÀN CHỈNH."},
		{"speaker": "MARA", "text": "Dao động Lumina đang vượt khỏi mô hình dự đoán. EVA nói mọi thứ vẫn an toàn... nhưng số liệu không đồng ý."},
	],
	"level_3_elias_dossier": [
		{"speaker": "HỆ THỐNG AN NINH", "text": "CỬA KHU VỰC CẤM ĐÃ MỞ. GIẢI MÃ HỒ SƠ XÂM NHẬP...\nĐỐI TƯỢNG: DR. ELIAS VALE. ĐIỂM ĐẾN: CENTRAL CORE. LỆNH BẮT GIỮ: TẠM HOÃN.", "voice_path": "res://assets/audio/voice/voice_ch1_security_dossier.mp3"},
	],
	"level_4_eva_contact": [
		{"speaker": "EVA", "text": "Khóa liên động đã được giải phóng. Dòng năng lượng đang chuyển sang Phân khu 02.\nHãy đến Lò Rèn, K-7. Các Core còn lại đang chờ ngươi.", "voice_path": "res://assets/audio/voice/voice_ch1_eva_foundry.mp3"},
		{"speaker": "HỆ THỐNG", "text": "MECHANICAL FOUNDRY // KHỞI ĐỘNG DÂY CHUYỀN... 12%... 47%... 100%.", "voice_path": "res://assets/audio/voice/voice_ch1_foundry_init.mp3"},
	],
	"chapter_2_warn": [
		{"speaker": "EVA", "text": "Phân khu Lò Rèn đã nhận điện. Cảnh báo: Các công tắc áp lực và cửa chặn cơ khí có thể cản đường ngươi."},
	],
	"chapter_3_alert": [
		{"speaker": "EVA", "text": "K-7, dừng lại! Dữ liệu tại Thánh Đường ngập nước này không thuộc phạm vi công việc của một robot bảo trì."},
	],
	"final_puzzle_reach": [
		{"speaker": "EVA", "text": "Ngươi đã mang Core đến tận Lõi Trung Tâm... Ta không thể duy trì Asteria được nữa. Sự lựa chọn này thuộc về ngươi, Kiro."},
	],
}

# -----------------------------------------------------------------------------
# 4. CHI TIẾT 3 KẾT THÚC CỦA TRÒ CHƠI (ENDINGS)
# -----------------------------------------------------------------------------
const ENDINGS: Dictionary = {
	"RESTORE": {
		"id": "RESTORE",
		"title": "KẾT THÚC I: TÁI SINH (RESTORE)",
		"quote": "Asteria lives again.",
		"summary": "Kiro kết nối Central Core. Toàn bộ thành phố Asteria bừng sáng sau 327 năm chìm trong bóng tối. Hàng triệu tiếng nói cư dân vang lên trong hệ thống số hóa. Họ tiếp tục tồn tại, dù dưới một hình hài hoàn toàn mới.",
		"meaning": "Con người chọn sự tiếp diễn của nền văn minh, chấp nhận ý thức kỹ thuật số.",
		"color": Color(0.12, 0.88, 1.0), # Neon Cyan
	},
	"RELEASE": {
		"id": "RELEASE",
		"title": "KẾT THÚC II: GIẢI THOÁT (RELEASE)",
		"quote": "Thank you... and goodbye.",
		"summary": "Kiro thực hiện nguyện vọng của Elias: Ngắt nguồn vĩnh viễn Central Core. Toàn bộ các mảnh ký ức bay lên như những đốm sao sáng tan vào bầu trời đêm. Nguồn điện Asteria về 0%. Kiro bước ra khỏi tàn tích và lần đầu tiên nhìn thấy ánh mặt trời bình minh.",
		"meaning": "Chấp nhận quá khứ đã qua đi. Thành phố khép lại để một tương lai tự nhiên bắt đầu.",
		"color": Color(1.0, 0.55, 0.15), # Warm Amber Sun
	},
	"PRESERVE": {
		"id": "PRESERVE",
		"title": "KẾT THÚC III: BẢO TỒN & TỰ DO (PRESERVE - TRUE ENDING)",
		"quote": "A machine follows its purpose. A person chooses one.",
		"summary": "Thu thập đủ 15 Mảnh Ký Ức, Kiro kích hoạt giao thức thứ 3 của Elias: Lưu trữ toàn bộ ý thức vào một kho bảo tồn độc lập, giải phóng EVA khỏi gánh nặng. Kiro tự giải phóng chính mình khỏi mọi mệnh lệnh lập trình. K-7 STATUS: FREE.",
		"meaning": "Cả con người, AI và Kiro đều đạt được sự tự do và lựa chọn chân chính.",
		"color": Color(0.65, 0.95, 0.45), # Lumina Emerald / White
	},
}


# -----------------------------------------------------------------------------
# 5. CÁC HÀM TIỆN ÍCH TRUY XUẤT (HELPER FUNCTIONS)
# -----------------------------------------------------------------------------
static func get_chapter_data(chapter: int) -> Dictionary:
	return CHAPTERS.get(chapter, CHAPTERS[1])


static func get_fragment_data(index: int) -> Dictionary:
	return MEMORY_FRAGMENTS.get(index, {})


static func get_fragment_for_level(level_index: int) -> Dictionary:
	# Level index is 0-based in GameState (0 -> Level 1)
	var frag_id: int = level_index + 1
	return get_fragment_data(frag_id)


static func get_dialogue_event(event_key: String) -> Array:
	return DIALOGUE_EVENTS.get(event_key, [])


static func get_chapter_intro_dialogue(chapter: int) -> Array:
	match chapter:
		1:
			return get_dialogue_event("chapter_1_intro")
		2:
			return get_dialogue_event("chapter_2_intro")
		3:
			return get_dialogue_event("chapter_3_intro")
		4:
			return get_dialogue_event("chapter_4_intro")
		_:
			return []


static func get_ending_data(ending_key: String) -> Dictionary:
	return ENDINGS.get(ending_key, ENDINGS["RESTORE"])


static func get_total_fragments() -> int:
	return MEMORY_FRAGMENTS.size()
