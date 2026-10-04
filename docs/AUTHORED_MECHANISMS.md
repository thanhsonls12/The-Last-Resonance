# Door, Bridge và Elevator trong gameplay

Áp dụng 2026-10-02 trong BoardGameplayObjects sau refactor. Ba GLB hiện có trong `assets/models/baked/` đã được dùng trực tiếp; không bake thêm model hoặc thay luật puzzle.

- Door: model panel và lock/line đi theo root mở/đóng hiện có. Pillar/inset/top beam tách sang frame đứng yên. Material trạng thái vẫn dùng tín hiệu door/plate hiện tại.
- Bridge: deck Blender xoay về trục Z mặc định của gameplay. Bốn rail/glow part được đưa vào rail root để giữ tween rút/xoay và Undo.
- Elevator: station có sàn/rail/arrow Blender; glow/arrow gắn vào material locked/unlocked. Cabin cùng model đi theo tween chuyển tầng hiện tại. Station model ẩn trong lúc cabin đi qua rồi hiện lại; label không chồng nhãn kiến trúc.

Thang có tại L11/L12/L14; cầu tại L7/L8/L15; cửa tại các màn có Door/Plate. Chuyển tầng, camera, lock, tap-to-move và undo giữ API facade hiện có.

Kiểm tra: authored-model wiring, interaction, camera, campaign surface và sequential elevator runtime đạt. Mobile giữ model, không thêm light/particle. Đã render L5/L7/L11 (hai tầng) bằng camera gameplay; ảnh ở `.codex_qa/campaign_surfaces/`.
