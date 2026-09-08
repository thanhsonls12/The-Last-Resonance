#!/usr/bin/env python3
"""Validate campaign map decoration placement without changing puzzle data."""

from collections import Counter, defaultdict
from pathlib import Path

from tres_levels import load_levels


KNOWN_MODULAR = {
    "kit_floor_edge", "kit_floor_corner", "kit_floor_inner_corner", "kit_floor_end", "kit_floor_end_reverse",
    "kit_rail_straight", "kit_rail_corner", "kit_rail_end", "kit_rail_end_reverse",
    "kit_wall_low_straight", "kit_wall_low_corner", "kit_wall_low_end",
    "kit_pipe_straight", "kit_pipe_elbow", "kit_pipe_tee", "kit_pipe_end",
    "kit_water_tile", "kit_water_edge", "kit_water_corner", "kit_water_inner_corner",
}
WALL_LOW_MODULAR = {"kit_wall_low_straight", "kit_wall_low_corner", "kit_wall_low_end"}
CHAPTER_IDENTITY_PROPS = {
    "archive_access_panel_broken", "archive_storage_tray_low",
    "foundry_maintenance_box", "foundry_pipe_support",
    "sanctuary_broken_plinth_low", "sanctuary_bank_root",
    "core_data_cabinet_low", "core_light_trim",
}
KNOWN_DYNAMIC_PROFILES = {
    "archive_terminal", "archive_panel",
    "foundry_conveyor", "foundry_furnace", "foundry_machine_heat",
    "sanctuary_sway", "sanctuary_water",
    "core_cabinet_pulse", "core_trim_pulse",
}
DYNAMIC_PROFILE_TYPES = {
    "archive_terminal": {"terminal"},
    "archive_panel": {"archive_access_panel_broken"},
    "foundry_conveyor": {"conveyor"},
    "foundry_furnace": {"foundry_furnace"},
    "foundry_machine_heat": {"machine"},
    "sanctuary_sway": {"plant", "sanctuary_bank_root"},
    "sanctuary_water": {"kit_water_tile", "kit_water_edge", "kit_water_corner", "kit_water_inner_corner"},
    "core_cabinet_pulse": {"core_data_cabinet_low"},
    "core_trim_pulse": {"core_light_trim"},
}
ENTITY_MOUNTED_DECORATIONS = {"bridge_console", "reactor_switch"}


def layers(level):
    return level.get("maps") or ["\n".join(level.get("map", []))]


def map_cells(level):
    result = set()
    bounds = {}
    for y, raw in enumerate(layers(level)):
        rows = raw.splitlines()
        bounds[y] = (max((len(row) for row in rows), default=0), len(rows))
        for z, row in enumerate(rows):
            for x, glyph in enumerate(row):
                if glyph != "#":
                    result.add((x, y, z))
    return result, bounds


def main() -> int:
    failures = []
    chapter_counts = Counter()
    chapter_types = defaultdict(set)
    total = 0
    levels = load_levels()
    for level in levels:
        name = Path(level["path"]).stem
        walkable, bounds = map_cells(level)
        entities = {
            tuple(item.get("grid_position", ()))
            for item in level.get("entities", [])
            if isinstance(item, dict) and isinstance(item.get("grid_position"), tuple)
        }
        seen_landmark = False
        for deco in level.get("decorations", []):
            if not isinstance(deco, dict):
                failures.append(f"{name}: decoration is not a dictionary")
                continue
            kind = str(deco.get("type", ""))
            raw_pos = deco.get("grid_position")
            if not isinstance(raw_pos, tuple) or len(raw_pos) != 3:
                failures.append(f"{name}: {kind} has no Vector3i grid_position")
                continue
            pos = tuple(raw_pos)
            width, height = bounds.get(pos[1], (0, 0))
            if pos[0] < 0 or pos[0] >= width or pos[2] < 0 or pos[2] >= height:
                failures.append(f"{name}: {kind} is outside layer bounds at {pos}")
            if pos in entities and kind not in ENTITY_MOUNTED_DECORATIONS:
                failures.append(f"{name}: {kind} overlaps gameplay entity at {pos}")
            if kind.startswith("kit_"):
                if kind not in KNOWN_MODULAR:
                    failures.append(f"{name}: unknown modular type {kind}")
                if kind in WALL_LOW_MODULAR:
                    if pos in walkable:
                        failures.append(f"{name}: low wall {kind} must stay on an already blocked wall cell {pos}")
                    x, y, z = pos
                    neighbors = {(x + 1, y, z), (x - 1, y, z), (x, y, z + 1), (x, y, z - 1)}
                    if not (neighbors & walkable):
                        failures.append(f"{name}: low wall {kind} has no adjacent playable floor at {pos}")
                elif pos not in walkable:
                    failures.append(f"{name}: modular {kind} is on a wall cell {pos}")
            if kind in CHAPTER_IDENTITY_PROPS and pos in walkable:
                failures.append(f"{name}: chapter identity prop {kind} must replace an already blocked wall cell {pos}")
            profile = deco.get("dynamic_profile")
            if profile is not None and profile not in KNOWN_DYNAMIC_PROFILES:
                failures.append(f"{name}: unknown dynamic_profile {profile!r} on {kind} at {pos}")
            elif profile is not None and kind not in DYNAMIC_PROFILE_TYPES[profile]:
                failures.append(f"{name}: dynamic_profile {profile!r} is not valid for {kind} at {pos}")
            if kind == str(level.get("landmark", "")):
                seen_landmark = True
            chapter = int(level.get("chapter", 0))
            chapter_counts[chapter] += 1
            chapter_types[chapter].add(kind)
            total += 1
        if not seen_landmark:
            failures.append(f"{name}: landmark {level.get('landmark', '')} is not represented")

    print("Campaign decoration placement:")
    for chapter in sorted(chapter_counts):
        print("  Chapter %d: %d decorations, %d unique types" % (
            chapter, chapter_counts[chapter], len(chapter_types[chapter])))
    print("  Total: %d decorations across %d levels" % (total, len(levels)))
    if failures:
        for failure in failures:
            print("FAIL:", failure)
        return 1
    print("RESULT: all decoration positions are bounded, entity-safe and landmark-backed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
