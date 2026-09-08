# Export Android

**Trạng thái 2026-09-08:** preflight PASS với APK debug arm64 tại
`build/TheLastResonance-debug.apk` (63.010.089 byte, 777 entry). Đây là kiểm tra gói
build; chưa phải chứng nhận hiệu năng hay UX trên thiết bị thật.

Preset **arm64**, renderer mobile, fallback Compatibility.

APK không đóng: `docs/`, `tests/`, `tools/`, `scenes/editor/`, `src/tools/`, `.codex_qa/`.

```powershell
godot --headless --path . --export-debug Android build/TheLastResonance-debug.apk
python tools/validate_android_export.py
```

Validator kiểm tra preset, lib arm64, PCK, manifest, zip và việc không nhét folder
QA. Mỗi lần export lại APK phải chạy lại validator; kết quả trên không thay playtest
máy thật.

## Còn phải làm trên máy

- Chạm HUD, vuốt, đổi focus, đổi cỡ màn.
- FPS, RAM, thời gian load trước khi cắt mesh/đèn/VFX.
- Camera / che khuất L11–L12 và điểm ra thang.
- L13–L15: cảm giác điều khiển + ánh sáng.
