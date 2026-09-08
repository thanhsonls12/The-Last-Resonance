"""Validate the Android preset and an exported APK without requiring an emulator."""

from __future__ import annotations

import argparse
import re
import sys
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def check(condition: bool, message: str, failures: list[str]) -> None:
    if not condition:
        failures.append(message)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--apk",
        type=Path,
        default=ROOT / "build" / "TheLastResonance-debug.apk",
        help="exported APK to inspect",
    )
    args = parser.parse_args()
    apk_path = args.apk if args.apk.is_absolute() else ROOT / args.apk
    failures: list[str] = []
    preset = read(ROOT / "export_presets.cfg")
    project = read(ROOT / "project.godot")

    check('[preset.0]\n' in preset, "Android preset.0 is missing", failures)
    check('name="Android"' in preset and 'platform="Android"' in preset, "preset.0 is not Android", failures)
    check('export_filter="all_resources"' in preset, "Android preset must export all runtime resources", failures)
    exclude_match = re.search(r'exclude_filter="([^"]*)"', preset)
    exclude_filter = exclude_match.group(1) if exclude_match else ""
    for dev_path in ("docs/*", "tests/*", "tools/*", "scenes/editor/*", "src/tools/*", ".codex_qa/*"):
        check(dev_path in exclude_filter, f"Android preset excludes {dev_path}", failures)
    check('architectures/arm64-v8a=true' in preset, "arm64-v8a architecture is enabled", failures)
    for disabled_arch in ("armeabi-v7a", "x86", "x86_64"):
        check(f'architectures/{disabled_arch}=false' in preset, f"{disabled_arch} stays disabled", failures)
    check('package/unique_name="com.example.thelastresonance"' in preset, "Android package id is declared", failures)
    check('renderer/rendering_method="mobile"' in project, "mobile renderer is selected", failures)
    check('renderer/rendering_method.mobile="gl_compatibility"' in project, "mobile renderer fallback is gl_compatibility", failures)

    check(apk_path.is_file(), f"APK not found: {apk_path}", failures)
    apk_size = 0
    entry_count = 0
    if apk_path.is_file():
        apk_size = apk_path.stat().st_size
        try:
            with zipfile.ZipFile(apk_path) as archive:
                entry_count = len(archive.namelist())
                check(archive.testzip() is None, "APK zip integrity is valid", failures)
                names = set(archive.namelist())
                apk_assets = "assets"
                required = {
                    "/".join((apk_assets, "project.binary")),
                    "/".join((apk_assets, "assets.sparsepck")),
                    "/".join((apk_assets, "_cl_")),
                    "lib/arm64-v8a/libgodot_android.so",
                    "AndroidManifest.xml",
                    "META-INF/MANIFEST.MF",
                }
                for entry in sorted(required):
                    check(entry in names, f"APK contains {entry}", failures)
                check(any(name.startswith("META-INF/") and name.endswith(".RSA") for name in names), "APK has a signing certificate", failures)
                check(any(name.startswith("META-INF/") and name.endswith(".SF") for name in names), "APK has a signing signature file", failures)
                for dev_prefix in ("assets/docs/", "assets/tests/", "assets/tools/", "assets/scenes/editor/", "assets/src/tools/"):
                    check(not any(name.startswith(dev_prefix) for name in names), f"APK excludes {dev_prefix}", failures)
        except zipfile.BadZipFile:
            failures.append("APK is not a readable zip archive")

    status = "PASS" if not failures else "FAIL"
    print(f"Android export preflight: {status}")
    print(f"  APK: {apk_path}")
    print(f"  size_bytes: {apk_size}")
    print(f"  zip_entries: {entry_count}")
    if failures:
        for failure in failures:
            print(f"  FAIL: {failure}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
