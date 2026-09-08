# Visual — campaign

**Desktop (Vulkan Forward Mobile): xong 15 màn.** Android máy thật: chưa đo.

Scenery không đổi `map` / `entities` / `hint_route` / `par`. Một landmark/màn; emission scenery luôn yếu hơn Core, Pedestal, Portal, Node.

## Ảnh QA

Capture gameplay (`BoardView` + camera + HUD, ẩn dialogue) → `.codex_qa/visual_polish/` (gitignored).

```powershell
# Cửa sổ thật, không headless
godot --path . --resolution 1280x720 tests/asset_pilot_capture.tscn -- --level=2
```

Đã chụp: đầu 15 màn; tầng 2 của L11/L12/L14; L14 EVA stage 4; L15 trước/sau cửa K; L1+L15 cửa sổ ~20:9.

![Landmarks](NARRATIVE_LANDMARK_PREVIEW.png)

## Kết quả

| Màn | Đọc được | Ghi chú pass |
| --- | --- | --- |
| L1–L8 | Tutorial / archive / foundry rõ | Không đổi |
| L9 | Sanctuary khô hơn L10–12 | Dời plinth + root, không thêm deco |
| L10–L12 | Nước / portal / tầng 2 rõ | Không đổi |
| L13 | Node mạnh hơn data-wall | Không đổi |
| L14 | Hai tầng thưa; EVA stage 4 là tâm | Không đổi |
| L15 | Nam = nguồn, bắc = phán quyết | +2 `kit_wall_low_straight` frame engine |

L15 mốc route: cầu bước 3 · Node 1/2/3 bước 5/16/30 · cửa K bước 45 · Node 4 bước 51 · xong 81.

## Checklist

| Hạng | |
| --- | --- |
| 15 màn + multi-floor desktop | ✅ |
| EVA L14, cửa K L15 | ✅ |
| HUD ~20:9 desktop | ✅ |
| Regression puzzle/deco | ✅ |
| Android touch / FPS / RAM | ⏳ |
