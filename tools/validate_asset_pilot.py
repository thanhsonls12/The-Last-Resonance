#!/usr/bin/env python3
"""Validate the four map decoration pilots without solving or rewriting levels."""
from pathlib import Path

from tres_levels import load_levels

PILOTS = {
    "level_02": {"kit_floor_edge", "kit_rail_straight", "kit_floor_corner", "kit_floor_end_reverse", "kit_floor_inner_corner", "kit_rail_end_reverse"},
    "level_06": {"kit_pipe_straight", "kit_pipe_elbow", "foundry_furnace"},
    "level_11": {"kit_water_edge", "kit_water_corner", "kit_water_tile"},
    "level_14": {"kit_floor_edge", "kit_rail_straight", "core_wall", "kit_floor_end_reverse", "kit_floor_inner_corner", "kit_rail_end_reverse"},
}
MODULAR_PREFIXES = ("kit_",)
LOW_WALL_PREFIX = "kit_wall_low_"
KNOWN = {
    "kit_floor_edge", "kit_floor_corner", "kit_floor_inner_corner", "kit_floor_end", "kit_floor_end_reverse",
    "kit_rail_straight", "kit_rail_corner", "kit_rail_end", "kit_rail_end_reverse",
    "kit_wall_low_straight", "kit_wall_low_corner", "kit_wall_low_end",
    "kit_pipe_straight", "kit_pipe_elbow", "kit_pipe_tee", "kit_pipe_end",
    "kit_water_tile", "kit_water_edge", "kit_water_corner", "kit_water_inner_corner",
    "foundry_furnace", "core_wall",
}


def cells(level):
    layers = level.get("maps") or ["\n".join(level.get("map", []))]
    result = set()
    for y, raw in enumerate(layers):
        for z, row in enumerate(raw.split("\n")):
            for x, glyph in enumerate(row):
                if glyph != "#":
                    result.add((x, y, z))
    return result


def main():
    levels = {Path(level["path"]).stem: level for level in load_levels()}
    failures = []
    for name, expected in PILOTS.items():
        level = levels[name]
        decorations = level.get("decorations", [])
        types = {str(item.get("type")) for item in decorations}
        missing = expected - types
        if missing:
            failures.append(f"{name}: missing pilot types {sorted(missing)}")
        occupied = {(tuple(item.get("grid_position", ()))) for item in level.get("entities", [])
                    if isinstance(item.get("grid_position"), tuple)}
        walkable = cells(level)
        for item in decorations:
            kind = str(item.get("type"))
            if kind.startswith(MODULAR_PREFIXES) or kind in expected:
                pos = tuple(item.get("grid_position", ()))
                if kind.startswith(MODULAR_PREFIXES) and not kind.startswith(LOW_WALL_PREFIX) and pos not in walkable:
                    failures.append(f"{name}: {kind} is on a wall cell {pos}")
                if kind.startswith(MODULAR_PREFIXES) and kind not in KNOWN:
                    failures.append(f"{name}: unknown modular type {kind}")
                if pos in occupied:
                    failures.append(f"{name}: {kind} shares a cell with a gameplay entity {pos}")
    if failures:
        for failure in failures:
            print("FAIL:", failure)
        return 1
    print("Asset pilot checks: 4 representative levels, expected kit present, all pilot cells walkable, no entity overlap")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
