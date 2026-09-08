#!/usr/bin/env python3
"""Scratch: score the Level 8 (Trái tim Foundry) map the campaign ships.

Kept as the record of what the map measures, so a future tweak can be compared
against it: par 87, 41 walkable cells, interleaving 2.67 and one local-console
bridge deployment.

Findings worth remembering while editing this map:
- str(pathlib.Path(__file__).resolve().parent.parent) is a pedestal glyph; plain floor is ' '. A '.' used as filler silently
  turns every cell into a required target.
- A core is stuck forever on a cell whose two push axes are both blocked, so
  corners and 1-wide corridor ends can hold a core only as its final rest.
- Pushing a core out of a room through a 1-cell door leaves the pusher behind
  it in the doorway. Either the room needs a second exit, or that push must be
  the last one the room needs.
- A closed bridge cell splits the ring; a core cannot cross a 1-cell bridge at
  all (the pusher would have to stand on the cell the core occupies), so the
  bridge is a route change for Kiro, never a core path.
"""
import pathlib
import sys
import time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
from validate_levels import Logic, solve

L = {"R": (1, 0, 0), "L": (-1, 0, 0), "D": (0, 0, 1), "U": (0, 0, -1)}

ROWS = [
    "###########",
    "#.     .###",
    "#.###K#####",
    "#   $    @#",
    "#  ##  # ##",
    "# $#   # ##",
    "## # $ # ##",
    "##       ##",
    "###########",
]
ENTS = [
    {"type": "plate", "grid_position": (7, 0, 3), "group": "K",
     "hold_required": False},
    {"type": "bridge", "grid_position": (1, 0, 4), "starts_open": False},
    {"type": "bridge_switch", "grid_position": (4, 0, 2)},
]


def score(name, rows, ents, max_states=2_000_000):
    level = {"map": rows, "entities": ents}
    widths = {len(r) for r in rows}
    if len(widths) != 1:
        print("%-6s WIDTH MISMATCH %s" % (name, widths))
        return None
    logic = Logic(level)
    floor = len([c for c in logic.floors if c not in logic.walls])
    if len(logic.blocks) != len(logic.required_targets()):
        print("%-6s cores=%d required=%d MISMATCH slots=%s plates=%s" % (
            name, len(logic.blocks), len(logic.required_targets()),
            sorted(logic.slots), logic.plates))
        return None
    started = time.time()
    ok, message, moves, route = solve(level, max_states=max_states)
    elapsed = time.time() - started
    if not ok:
        print("%-6s cores=%d floor=%d %s (%.1fs)" % (
            name, len(logic.blocks), floor, message, elapsed))
        return None
    state = logic.start_state()
    ident = {b: i for i, b in enumerate(sorted(state[1]))}
    pushed = []
    for step in route:
        nxt = logic.rotate(state) if step == "B" else logic.try_move(state, L[step])
        if nxt is None:
            print("%-6s route invalid at %r" % (name, step))
            return None
        if nxt[1] != state[1]:
            src = next(b for b in state[1] if b not in nxt[1])
            dst = next(b for b in nxt[1] if b not in state[1])
            ident[dst] = ident.pop(src)
            pushed.append(ident[dst])
        state = nxt
    runs = {}
    for i, core in enumerate(pushed):
        if i == 0 or pushed[i - 1] != core:
            runs[core] = runs.get(core, 0) + 1
    bpc = sum(runs.values()) / len(runs) if runs else 0
    print("%-6s cores=%d floor=%d moves=%d pushes=%d bpc=%.2f %s B=%d (%.1fs)" % (
        name, len(logic.blocks), floor, moves, len(pushed), bpc,
        sorted(runs.values(), reverse=True), route.count("B"), elapsed))
    print("       route " + route)
    return {"moves": moves, "bpc": bpc, "route": route}


if __name__ == "__main__":
    score("L8", ROWS, ENTS)
