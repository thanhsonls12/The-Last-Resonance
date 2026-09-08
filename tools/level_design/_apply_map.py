"""Scratch: rewrite one level's map/par and re-seat its decorations.

Shrinking a map invalidates every decoration coordinate, and a solid decoration
left on a walkable cell silently bricks it (see solid_decoration_errors). So the
solid types are re-seated onto border wall cells and the soft types onto free
wall or floor cells, keeping each type's original multiplicity.

Run: py -3 tools/_apply_map.py <level_file> <map_file> [par]
"""
import ast
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
from validate_levels import DECORATION_WALL_TYPES

VEC = re.compile(r"Vector3i\((-?\d+),\s*(-?\d+),\s*(-?\d+)\)")


def parse_decos(text):
    raw = re.search(r"^decorations = (\[.*?\])$", text, re.M | re.S).group(1)
    return ast.literal_eval(VEC.sub(r"(\1, \2, \3)", raw))


def dump_decos(decos):
    out = []
    for d in decos:
        parts = []
        for k, v in d.items():
            if k == "grid_position":
                parts.append('"grid_position": Vector3i(%d, %d, %d)' % v)
            elif isinstance(v, str):
                parts.append('"%s": "%s"' % (k, v))
            elif isinstance(v, float):
                parts.append('"%s": %s' % (k, v))
            else:
                parts.append('"%s": %s' % (k, v))
        out.append("{ " + ", ".join(parts) + " }")
    return "[" + ", ".join(out) + "]"


def seat(rows, decos):
    """Re-seat decorations: solid types on wall cells, soft types on border walls.

    Positions are taken with a co-prime stride rather than in reading order, so a
    run of the same type in the source list does not land as one solid block of
    identical props along the top edge.
    """
    h, w = len(rows), len(rows[0])
    walls = []
    for z in range(h):
        for x in range(w):
            if rows[z][x] == "#":
                walls.append((x, 0, z))
    border = [p for p in walls if p[0] in (0, w - 1) or p[2] in (0, h - 1)]
    used = set()

    def pick(pool, i):
        if not pool:
            return None
        stride = next((s for s in (7, 5, 3, 1) if len(pool) % s), 1)
        for k in range(len(pool)):
            spot = pool[(i * stride + k) % len(pool)]
            if spot not in used:
                return spot
        return None

    out = []
    for i, deco in enumerate(decos):
        pool = walls if deco["type"] in DECORATION_WALL_TYPES else border
        spot = pick(pool, i)
        if spot is None:
            continue
        used.add(spot)
        new = dict(deco)
        new["grid_position"] = spot
        yaw = {0: 180.0, h - 1: 0.0}.get(spot[2])
        if yaw is None:
            yaw = 90.0 if spot[0] == 0 else -90.0
        if "yaw" in new:
            new["yaw"] = yaw
        out.append(new)
    return out


def main():
    level_path = Path(sys.argv[1])
    rows = [line.rstrip("\n") for line in
            Path(sys.argv[2]).read_text(encoding="utf-8").splitlines() if line.strip()]
    text = level_path.read_text(encoding="utf-8")
    widths = {len(r) for r in rows}
    if len(widths) != 1:
        raise SystemExit("width mismatch %s" % widths)
    map_line = "map = Array[String]([%s])" % ", ".join('"%s"' % r for r in rows)
    text = re.sub(r"^map = Array\[String\]\(\[.*?\]\)$", map_line, text, count=1, flags=re.M)
    if len(sys.argv) > 3:
        text = re.sub(r"^par_moves = \d+$", "par_moves = %s" % sys.argv[3], text,
                      count=1, flags=re.M)
    text = re.sub(r"^decorations = \[.*?\]$",
                  "decorations = " + dump_decos(seat(rows, parse_decos(text))),
                  text, count=1, flags=re.M | re.S)
    level_path.write_text(text, encoding="utf-8")
    print("wrote %s (%dx%d)" % (level_path.name, widths.pop(), len(rows)))


if __name__ == "__main__":
    main()
