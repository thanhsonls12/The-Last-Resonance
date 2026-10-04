# Export Android

**Trạng thái 2026-10-02 (sau refactor):** preflight PASS với APK debug arm64 export
lại từ cây mã đã refactor tại `build/TheLastResonance-debug.apk`
(**81.881.736 byte, 949 entry**). Bản export trước refactor là 63.010.089 byte / 777
entry; phần tăng ~18 MB gần đúng 17,39 MB nhạc theo chương mới thêm, đúng như dự kiến.
Đây là kiểm tra gói build; **chưa phải** chứng nhận hiệu năng hay UX trên thiết bị thật.

Preset **arm64**, renderer mobile, fallback Compatibility.

APK không đóng: `docs/`, `tests/`, `tools/`, `scenes/editor/`, `src/tools/`, `.codex_qa/`.

```powershell
godot --headless --path . --export-debug Android build/TheLastResonance-debug.apk
python tools/validate_android_export.py
```

Validator kiểm tra preset, lib arm64, PCK, manifest, zip và việc không nhét folder
QA. Mỗi lần export lại APK phải chạy lại validator; kết quả trên không thay playtest
máy thật.

Export headless cần `JAVA_HOME` trỏ tới JDK 17; Android SDK đọc từ editor settings
(`export/android/android_sdk_path`), không cần biến môi trường `ANDROID_HOME`.

## Còn phải làm trên máy

- Chạm HUD, vuốt, đổi focus, đổi cỡ màn.
- FPS, RAM, thời gian load trước khi cắt mesh/đèn/VFX.
- Camera / che khuất L11–L12 và điểm ra thang.
- L13–L15: cảm giác điều khiển + ánh sáng.
