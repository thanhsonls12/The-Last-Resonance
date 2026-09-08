# Render mobile

**Đã có tier Android** (`src/data/render_quality.gd`). Chưa đo FPS máy thật.

Board gameplay từng vẽ cùng lúc: vỏ nền, hạt sao/bụi, cột sáng, đèn tháp xa, nhiều Omni/Spot, shadow directional, glow. Tier mobile **giữ** sàn/tường/deco/entity/puzzle, và:

- bỏ sao / bụi / cột sáng nền;
- bỏ tháp xa và đèn beacon;
- tắt Omni + shadow; giữ 1 key light không shadow;
- tối đa 3 mesh phát sáng màu trên landmark;
- tắt glow/fog;
- VFX one-shot ~42% hạt;
- weathering 16×16.

Bù màu rẻ: nâng nhẹ ambient/key/fill, exposure 1.10 — vẫn tách chương, không glow.

Desktop không đổi. Test: `tests/verify_mobile_render_budget.tscn`. Không đổi map/collision/par. FPS máy thật: ⏳.
