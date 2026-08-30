"""Verify The Last Resonance Sokoban maps against the engine rules.

Replicates src/core/game_logic.gd:
  - doors_open():  every plate must hold a BLOCK (player standing on it does nothing)
  - _check_won():  every block sits on a slot or a plate, and every slot holds a block
  - terrain:       walls and closed doors block both player and blocks

Two modes per level:
  - no entry in ROUTES -> push-optimal search, then the walk is replayed concretely.
                          The count is achievable but not guaranteed move-optimal.
  - entry in ROUTES    -> replays that hand-authored route; the count is that route's
                          length. Used for the bigger maps, where search is too slow.

Both modes prove solvability. Treat the numbers as par, not as a proven minimum.

Usage: python tools/verify_maps.py
"""

import heapq
import re
from collections import deque
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
LEVEL_DIR = PROJECT_ROOT / "resources" / "levels"
CATALOGUE_PATH = PROJECT_ROOT / "src" / "data" / "levels.gd"
SOLID_DECORATIONS = {
    "data_rack", "archive_shelf", "workbench", "crate", "machine",
    "broken_robot", "broken_wall", "broken_pillar", "rock", "door_frame",
}


def load_resource_maps():
    """Read the canonical runtime maps directly from LevelData .tres files."""
    maps = {}
    for path in sorted(LEVEL_DIR.glob("level_*.tres")):
        source = path.read_text(encoding="utf-8-sig")
        match = re.search(r'^map = Array\[String\]\(\[(.*)\]\)\s*$', source, re.MULTILINE)
        if not match:
            raise ValueError("Cannot read map from %s" % path)
        maps[path.stem] = re.findall(r'"([^"]*)"', match.group(1))
    return maps


MAPS = load_resource_maps()


def load_catalogue_maps():
    """Read fallback map rows from Levels.ALL for drift detection."""
    source = CATALOGUE_PATH.read_text(encoding="utf-8-sig")
    sections = re.findall(
        r'"map"\s*:\s*\[(.*?)\]\s*,\s*"entities"', source, re.DOTALL)
    return [re.findall(r'"([^"]*)"', section) for section in sections]


def solid_decoration_errors(name, rows):
    """Reject visual blockers on walkable cells because GameLogic makes them walls."""
    source = (LEVEL_DIR / (name + ".tres")).read_text(encoding="utf-8-sig")
    line = re.search(r'^decorations = \[(.*)\]\s*$', source, re.MULTILINE)
    if not line:
        return []
    errors = []
    for body in re.findall(r'\{([^{}]+)\}', line.group(1)):
        type_match = re.search(r'"type"\s*:\s*"([^"]+)"', body)
        pos_match = re.search(
            r'"grid_position"\s*:\s*Vector3i\((-?\d+),\s*(-?\d+),\s*(-?\d+)\)', body)
        if not type_match or not pos_match or type_match.group(1) not in SOLID_DECORATIONS:
            continue
        x, y, z = map(int, pos_match.groups())
        cell = rows[z][x] if y == 0 and 0 <= z < len(rows) and 0 <= x < len(rows[z]) else None
        if cell != "#":
            errors.append("%s at (%d,%d,%d) overlaps '%s'" % (
                type_match.group(1), x, y, z, cell))
    return errors

DIRS = ((0, -1), (0, 1), (-1, 0), (1, 0))
STEPS = {"U": (0, -1), "D": (0, 1), "L": (-1, 0), "R": (1, 0)}

# Hand-authored routes. Levels with more than three boxes are validated by
# replaying the intended route instead of searching the whole state space.
ROUTES = {
    "level_01": "RRDRUU",
    "level_02": "ULLLURRRRDLLLLDRRRR",
    "level_03": "ULURRRRRDDLDLDDLLLLDRRRRRRR",
    "level_04": "LLULD" "URURRRRDRD" "LLLLLLLDDDRRR" "LLULUURUUUUU"
                "RRRRRRDDLDDRUUUU",
}


def parse(rows):
    walls, floors, slots, plates, doors, blocks = set(), set(), set(), set(), set(), set()
    player = None
    for z, row in enumerate(rows):
        for x, c in enumerate(row):
            v = (x, z)
            floors.add(v)
            if c == "#":
                walls.add(v)
            elif c == ".":
                slots.add(v)
            elif c == "p":
                plates.add(v)
            elif c == "D":
                doors.add(v)
            elif c == "$":
                blocks.add(v)
            elif c == "*":
                blocks.add(v)
                slots.add(v)
            elif c == "@":
                player = v
            elif c == "+":
                player = v
                slots.add(v)
    return walls, floors, slots, plates, doors, blocks, player


def solve(rows):
    walls, floors, slots, plates, doors, blocks, player = parse(rows)
    targets = slots | plates

    def doors_open(bx):
        if not doors:
            return True
        if not plates:
            return False
        return all(p in bx for p in plates)

    def blocked(v, dopen):
        return v not in floors or v in walls or (v in doors and not dopen)

    def static_blocked(v):
        """Blocked even with every door open - i.e. permanently impassable."""
        return v not in floors or v in walls

    def live_cells():
        """Cells a box can still be driven to a target from.

        Reverse search: from each target, pull the box backwards. A pull from c
        to c-d needs the box cell c-d and the player cell c-2d to be passable.
        Doors are treated as open so nothing solvable is ever pruned.
        """
        live = set(targets)
        q = deque(targets)
        while q:
            c = q.popleft()
            for dx, dz in DIRS:
                prev = (c[0] - dx, c[1] - dz)
                stand = (c[0] - 2 * dx, c[1] - 2 * dz)
                if prev in live:
                    continue
                if static_blocked(prev) or static_blocked(stand):
                    continue
                live.add(prev)
                q.append(prev)
        return live

    live = live_cells()
    if any(b not in live for b in blocks):
        return len(blocks), len(slots), len(plates), None

    def won(bx):
        if not bx:
            return not slots and not plates
        if any(b not in targets for b in bx):
            return False
        return all(s in bx for s in slots)

    def reachable(start, bx, dopen):
        """Walk distances from start, treating blocks as obstacles."""
        dist = {start: 0}
        q = deque([start])
        while q:
            v = q.popleft()
            for dx, dz in DIRS:
                n = (v[0] + dx, v[1] + dz)
                if n in dist or n in bx or blocked(n, dopen):
                    continue
                dist[n] = dist[v] + 1
                q.append(n)
        return dist

    def norm(p, bx, dopen):
        """Canonical player cell: the smallest cell it can walk to."""
        return min(reachable(p, bx, dopen))

    # Phase 1: push-optimal BFS over (canonical player, boxes). Small state space.
    start_bx = frozenset(blocks)
    start = (norm(player, start_bx, doors_open(start_bx)), start_bx)
    prev = {start: None}
    q = deque([start])
    goal = None
    while q:
        st = q.popleft()
        p, bx = st
        if won(bx):
            goal = st
            break
        dopen = doors_open(bx)
        dist = reachable(p, bx, dopen)
        for b in bx:
            for dx, dz in DIRS:
                stand = (b[0] - dx, b[1] - dz)
                dest = (b[0] + dx, b[1] + dz)
                if stand not in dist:
                    continue
                if dest in bx or dest not in live or blocked(dest, dopen):
                    continue
                nbx = frozenset((bx - {b}) | {dest})
                ns = (norm(b, nbx, doors_open(nbx)), nbx)
                if ns not in prev:
                    prev[ns] = (st, stand, b, dest)
                    q.append(ns)
    if goal is None:
        return len(blocks), len(slots), len(plates), None

    # Phase 2: replay that push sequence with a concrete player to count real moves.
    pushes = []
    cur = goal
    while prev[cur] is not None:
        st, stand, b, dest = prev[cur]
        pushes.append((stand, b, dest))
        cur = st
    pushes.reverse()

    moves = 0
    p = player
    bx = frozenset(blocks)
    for stand, b, dest in pushes:
        dopen = doors_open(bx)
        moves += reachable(p, bx, dopen)[stand] + 1
        bx = frozenset((bx - {b}) | {dest})
        p = b
    return len(blocks), len(slots), len(plates), moves


def replay(rows, route):
    """Walk a scripted route through the engine rules. Returns (moves, won, error)."""
    walls, floors, slots, plates, doors, blocks, player = parse(rows)
    bx = set(blocks)
    p = player

    def dopen():
        if not doors:
            return True
        if not plates:
            return False
        return all(pl in bx for pl in plates)

    def blocked(v):
        return v not in floors or v in walls or (v in doors and not dopen())

    moves = 0
    for i, ch in enumerate(route):
        dx, dz = STEPS[ch]
        t = (p[0] + dx, p[1] + dz)
        if blocked(t):
            return moves, False, "step %d (%s): terrain blocks %s" % (i + 1, ch, t)
        if t in bx:
            beyond = (t[0] + dx, t[1] + dz)
            if blocked(beyond) or beyond in bx:
                return moves, False, "step %d (%s): push into %s blocked" % (i + 1, ch, beyond)
            bx.discard(t)
            bx.add(beyond)
        p = t
        moves += 1

    if any(b not in (slots | plates) for b in bx):
        return moves, False, "route ends with a block off-target"
    if any(s not in bx for s in slots):
        return moves, False, "route ends with an empty goal"
    return moves, True, None


def main():
    failed = False
    catalogue_maps = load_catalogue_maps()
    resource_maps = [MAPS[name] for name in sorted(MAPS)]
    if catalogue_maps != resource_maps:
        print("FAIL: src/data/levels.gd fallback maps differ from runtime .tres maps")
        failed = True

    for name in sorted(MAPS):
        rows = MAPS[name]
        decoration_errors = solid_decoration_errors(name, rows)
        for error in decoration_errors:
            print("%s COLLISION ERROR: %s" % (name, error))
        failed = failed or bool(decoration_errors)
        _, _, slots_, plates_, _, blocks_, _ = parse(rows)
        n_boxes, n_slots, n_plates = len(blocks_), len(slots_), len(plates_)
        need = n_slots + n_plates
        note = ""
        if n_boxes != need:
            note = "  <-- BOX COUNT MISMATCH: need %d (slots %d + plates %d)" % (
                need, n_slots, n_plates)
        if name in ROUTES:
            moves, ok, err = replay(rows, ROUTES[name])
            status = "route wins in %d moves" % moves if ok else "ROUTE FAILED: %s" % err
        else:
            _, _, _, moves = solve(rows)
            status = "UNSOLVABLE" if moves is None else "solved, par %d moves" % moves
            failed = failed or moves is None
        print("%-9s boxes=%d slots=%d plates=%d -> %s%s"
              % (name, n_boxes, n_slots, n_plates, status, note))
        failed = failed or bool(note) or "FAILED" in status

    if failed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
