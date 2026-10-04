# Hoàn thiện asset sau refactor

Yêu cầu: thực hiện các nâng cấp đã đề xuất trên kiến trúc refactor hiện tại.

- Core/Pedestal: chất liệu và socket/ring rõ hơn, giảm phần ánh sáng che hình học.
- Foundry: bevel và chi tiết cơ khí cho Furnace, Press, Machine Unit; giữ các part được animate.
- Landmark: Data Vault, Shrine, Reactor, Judgement Engine có silhouette và chi tiết chức năng riêng.
- Vật liệu: phân biệt kim loại/đá/kính/cao su; chi tiết nằm trong footprint hiện hữu, không thay gameplay.
- Biến thể nhỏ: tán cây/plant/debris có variation xác định theo vị trí; tối đa một biển sector mỗi tầng, gắn vào tường hiện hữu.
- Dùng BoardDecorations/ModuleMotion/VFX theo ownership sau refactor; bake lại clip, MeshLibrary và kiểm tra renderer/gameplay.

Trạng thái: hoàn thành 2026-10-02. Nâng cấp 9 GLB và 4 biển sector; 18 clip bake lại; variation và giảm Core glow áp dụng trong các owner sau refactor. 13 nhóm kiểm tra đạt; đã review studio và gameplay. Chi tiết: `docs/ASSET_POLISH.md`. Không commit/push trong phạm vi này.
