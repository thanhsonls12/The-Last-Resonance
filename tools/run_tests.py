"""Run the whole The Last Resonance headless test suite with one command.

Discovers tests instead of listing them, so a new tests/verify_*.gd is picked up
automatically. Two kinds exist in this project:

  * ``extends SceneTree`` scripts, run with ``--headless -s tests/x.gd``, which
    only need the autoloads resolved.
  * Node scenes (``tests/x.tscn``), run by opening the scene, used whenever the
    test needs the real scene tree, viewport or a built board.

Every test quits with its own exit code, so pass/fail is read from the process
status and not scraped out of stdout.

Usage:
    python tools/run_tests.py
    python tools/run_tests.py -t verify verify_interactions
    python tools/run_tests.py -g gameplay ui
    GODOT_BIN=/opt/godot/godot python tools/run_tests.py
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TESTS = ROOT / "tests"

# Per-test wall-clock budget. Board-heavy scenes are the slow ones.
DEFAULT_TIMEOUT = 180

# Capture scenes render preview images for the docs; they are authoring tools,
# not assertions, and they need a real GPU.
SKIP_PATTERNS = ("capture",)

# Tests that read `--level=N` from OS.get_cmdline_user_args(). Run bare, they
# open whatever GameState.current_level the local save file holds, so the result
# depends on the developer's progress. Run each one once per level instead.
LEVEL_ARG_TESTS = {
    "asset_pilot_runtime": (2, 6, 11, 14),
}

TEST_GROUPS: dict[str, set[str]] = {
    "gameplay": {
        "verify",
        "verify_action_execution",
        "verify_game_coordinator",
        "verify_hint_recovery",
        "verify_interactions",
        "verify_multifloor_camera",
        "verify_player_navigation",
        "verify_sequential_elevator_runtime",
    },
    "ui": {
        "verify_hud_components",
        "verify_interactions",
    },
    "narrative": {
        "verify_narrative_events",
        "verify_story_holograms",
    },
    "render": {
        "asset_pilot_runtime",
        "verify_campaign_dressing",
        "verify_campaign_surfaces",
        "verify_chapter_props",
        "verify_environment_dynamics",
        "verify_map_clusters",
        "verify_map_expansion",
        "verify_material_profiles",
        "verify_mobile_render_budget",
        "verify_modular_kit",
        "verify_modular_runtime",
        "verify_module_motion",
    },
    "audio": {
        "verify_audio_profiles",
    },
}

WINDOWS_FALLBACK = Path(
    r"D:\Fifa\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
)


def find_godot() -> str:
    override = os.environ.get("GODOT_BIN")
    if override:
        if not Path(override).exists():
            sys.exit(f"GODOT_BIN points at a missing file: {override}")
        return override
    for name in ("godot", "godot4", "godot-headless"):
        found = shutil.which(name)
        if found:
            return found
    if WINDOWS_FALLBACK.exists():
        # The console build is the only Windows binary that writes stdout.
        return str(WINDOWS_FALLBACK)
    sys.exit(
        "Could not find a Godot binary. Install one, or set GODOT_BIN, e.g.\n"
        "  set GODOT_BIN=D:\\path\\to\\Godot_v4.x-stable_win64_console.exe\n"
        "  export GODOT_BIN=/usr/local/bin/godot"
    )


def is_scene_test(script: Path) -> bool:
    return script.with_suffix(".tscn").exists()


def discover(only: list[str]) -> list[Path]:
    if not TESTS.is_dir():
        sys.exit(f"No tests directory at {TESTS}")
    scripts = []
    for script in sorted(TESTS.glob("*.gd")):
        stem = script.stem
        if any(pattern in stem for pattern in SKIP_PATTERNS):
            continue
        if only and stem not in only:
            continue
        scripts.append(script)
    if not scripts:
        sys.exit("No tests matched. Check the -t names you passed.")
    return scripts


def selected_tests(only: list[str], groups: list[str]) -> list[str]:
    if not only and not groups:
        return []
    selected = set(only)
    for group in groups:
        selected.update(TEST_GROUPS[group])
    return sorted(selected)


def jobs_for(script: Path) -> list[tuple[Path, int | None]]:
    """Expand one script into the invocations it needs."""
    levels = LEVEL_ARG_TESTS.get(script.stem)
    if levels:
        return [(script, level) for level in levels]
    return [(script, None)]


def build_command(godot: str, script: Path, level: int | None) -> list[str]:
    target = (
        f"res://tests/{script.stem}.tscn"
        if is_scene_test(script)
        else f"res://tests/{script.name}"
    )
    command = [godot, "--headless", "--path", str(ROOT)]
    if not is_scene_test(script):
        command += ["-s", target]
    else:
        command.append(target)
    if level is not None:
        # Everything after `--` reaches OS.get_cmdline_user_args().
        command += ["--", f"--level={level}"]
    return command


def run_one(godot: str, script: Path, level: int | None, timeout: int) -> tuple[bool, str]:
    command = build_command(godot, script, level)
    try:
        completed = subprocess.run(
            command,
            cwd=ROOT,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout,
        )
    except subprocess.TimeoutExpired as error:
        output = b"".join((error.stdout or b"", error.stderr or b""))
        return False, f"TIMEOUT after {timeout}s\n" + output.decode("utf-8", errors="replace")
    output = (completed.stdout or "") + (completed.stderr or "")
    return completed.returncode == 0, output


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "-t",
        "--test",
        nargs="*",
        default=[],
        metavar="NAME",
        help="run only these test stems (without the .gd extension)",
    )
    parser.add_argument(
        "-g",
        "--group",
        nargs="*",
        default=[],
        choices=sorted(TEST_GROUPS),
        help="run named regression groups; combines with -t and deduplicates tests",
    )
    parser.add_argument(
        "--timeout", type=int, default=DEFAULT_TIMEOUT, help="seconds per test"
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="print output of passing tests too"
    )
    args = parser.parse_args()

    godot = find_godot()
    scripts = discover(selected_tests(args.test, args.group))
    jobs = [job for script in scripts for job in jobs_for(script)]
    print(f"Godot: {godot}")
    print(f"Running {len(jobs)} test(s)\n")

    failures: list[tuple[str, str]] = []
    for script, level in jobs:
        kind = "scene" if is_scene_test(script) else "script"
        label = script.stem if level is None else f"{script.stem}[L{level:02d}]"
        print(f"  [{kind:6}] {label} ... ", end="", flush=True)
        passed, output = run_one(godot, script, level, args.timeout)
        print("PASS" if passed else "FAIL")
        if not passed:
            failures.append((label, output))
            print(output.rstrip(), flush=True)
        elif args.verbose:
            print(output)

    print()
    if failures:
        for name, output in failures:
            print(f"===== FAILED: {name} =====")
            print(output.rstrip())
            print()
        print(f"RESULT: {len(failures)}/{len(jobs)} test(s) FAILED")
        return 1
    print(f"RESULT: ALL {len(jobs)} TEST(S) PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
