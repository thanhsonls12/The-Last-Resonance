# Ngoại cảnh sector

Yêu cầu: ngoại cảnh đẹp và dễ quan sát, có kết cấu dưới sàn, tầng bảo trì và kiến trúc xa theo bốn chương.

- Thay các mảnh nổi/star/neon ngẫu nhiên bằng kiến trúc cố định, không thêm collision/light.
- Giữ ngoại cảnh thấp hơn sàn; batching mesh theo vật liệu để giới hạn draw calls trên mobile.
- Archive: storage shaft; Foundry: pipe/furnace structures; Sanctuary: water basin/ruins/roots; Core: reactor rings/service architecture.
- Giữ API resonate, giảm nhịp pulse nền và ánh sáng shell. Kiểm tra camera, nhiều tầng, mobile và ảnh bốn chương.

Trạng thái: hoàn thành, 2026-10-02. Sáu MultiMesh, tối đa hai reactor rings, không thêm light/particle/collision. Bảy bộ kiểm tra liên quan PASS; ảnh render 15 màn/18 tầng đã kiểm tra. Chi tiết: [SECTOR_EXTERIOR.md](../../SECTOR_EXTERIOR.md).
