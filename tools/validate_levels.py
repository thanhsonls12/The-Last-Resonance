#!/usr/bin/env python3
"""Solver and validator for the levels in resources/levels/*.tres.

Mirrors the deterministic rules in src/core/game_logic.gd: push, grouped
plate/door, portal, elevator, rotating bridge, energy routing, multi-floor and
decorations that carry collision. Finds an optimal route with A* over a Manhattan
lower bound, prunes squares no Core can ever leave, and prints the route so the
same string can be pasted into tests/verify.gd.

Run: py -3 tools/validate_levels.py
"""
import heapq
from itertools import count

from tres_levels import load_levels

PLATE_GLYPHS = {"p": "", "k": "K", "l": "L", "m": "M"}
DOOR_GLYPHS = {"D": "", "K": "K", "L": "L", "M": "M"}
DECORATION_WALL_TYPES = {
    "data_rack", "archive_shelf", "workbench", "crate", "machine",
    "broken_robot", "broken_wall", "broken_pillar", "rock", "door_frame",
}
DIRS = [(1, 0, 0), (-1, 0, 0), (0, 0, 1), (0, 0, -1)]
DIR_LETTERS = {(1, 0, 0): "R", (-1, 0, 0): "L", (0, 0, 1): "D", (0, 0, -1): "U"}


class Logic:
    def __init__(self, level):
        self.walls = set()
        self.floors = set()
        self.slots = set()
        self.plates = {}
        self.plate_hold_required = {}
        self.doors = {}
        self.portals = {}
        self.portal_links = {}
        self.elevators = set()
        self.elevator_links = {}
        self.bridges = set()
        self.energy_nodes = []
        self.blocks = set()
        self.player = (0, 0, 0)
        if level.get("maps"):
            for y, layer in enumerate(level["maps"]):
                self._parse(layer.split("\n"), y)
        else:
            self._parse(level["map"], 0)
        self._build_portal_links()
        self._build_elevator_links()
        self._apply_entities(level.get("entities", []))
        self._apply_decorations(level.get("decorations", []))

    def _parse(self, rows, y):
        for z, row in enumerate(rows):
            for x, glyph in enumerate(row):
                v = (x, y, z)
                if glyph in PLATE_GLYPHS:
                    self.floors.add(v)
                    self.plates[v] = PLATE_GLYPHS[glyph]
                    self.plate_hold_required[v] = True
                elif glyph in DOOR_GLYPHS:
                    self.floors.add(v)
                    self.doors[v] = DOOR_GLYPHS[glyph]
                elif glyph == "#":
                    self.walls.add(v)
                    self.floors.add(v)
                elif glyph == " ":
                    self.floors.add(v)
                elif glyph == ".":
                    self.floors.add(v)
                    self.slots.add(v)
                elif glyph in ("a", "b"):
                    self.floors.add(v)
                    self.portals[v] = glyph
                elif glyph == "e":
                    self.floors.add(v)
                    self.elevators.add(v)
                elif glyph == "r":
                    self.floors.add(v)
                elif glyph == "$":
                    self.floors.add(v)
                    self.blocks.add(v)
                elif glyph == "*":
                    self.floors.add(v)
                    self.blocks.add(v)
                    self.slots.add(v)
                elif glyph == "@":
                    self.floors.add(v)
                    self.player = v
                elif glyph == "+":
                    self.floors.add(v)
                    self.player = v
                    self.slots.add(v)

    def _build_portal_links(self):
        keys = list(self.portals)
        if len(keys) == 2:
            self.portal_links[keys[0]] = keys[1]
            self.portal_links[keys[1]] = keys[0]

    def _build_elevator_links(self):
        grouped = {}
        for p in self.elevators:
            grouped.setdefault((p[0], p[2]), []).append(p)
        for ps in grouped.values():
            if len(ps) == 2:
                self.elevator_links[ps[0]] = ps[1]
                self.elevator_links[ps[1]] = ps[0]

    def _apply_entities(self, entities):
        ordered = []
        for e in entities:
            pos = e.get("grid_position")
            if pos is None:
                continue
            kind = e.get("type", "")
            if kind == "bridge":
                self.bridges.add(pos)
            elif kind == "plate":
                self.floors.add(pos)
                self.plates[pos] = e.get("group", self.plates.get(pos, ""))
                self.plate_hold_required[pos] = bool(e.get("hold_required", True))
            elif kind == "door":
                self.floors.add(pos)
                self.doors[pos] = e.get("group", self.doors.get(pos, ""))
            elif kind == "energy_node":
                ordered.append((int(e.get("order", len(ordered) + 1)), pos))
        ordered.sort(key=lambda a: a[0])
        self.energy_nodes = [p for _, p in ordered]

    def _apply_decorations(self, decorations):
        for deco in decorations:
            pos = deco.get("grid_position")
            if pos is not None and deco.get("type") in DECORATION_WALL_TYPES:
                self.walls.add(pos)

    # --- pure helpers over an explicit state ---
    def targets(self):
        return self.slots | set(self.plates)

    def required_targets(self):
        held = {p for p, need in self.plate_hold_required.items() if need}
        return self.slots | held

    def door_open(self, v, blocks):
        group = self.doors[v]
        group_plates = [p for p, g in self.plates.items() if g == group]
        if not group_plates:
            return False
        return all(p in blocks for p in group_plates)

    def door_state(self, blocks):
        return {v: self.door_open(v, blocks) for v in self.doors}

    def terrain_blocked(self, v, doors, bridge_open):
        return (v not in self.floors or v in self.walls
                or (v in self.doors and not doors.get(v, False))
                or (v in self.bridges and not bridge_open))

    def energy_allowed(self, v, energy_progress):
        if not self.energy_nodes:
            return True
        idx = self.energy_nodes.index(v) if v in self.energy_nodes else -1
        return idx < 0 or idx <= energy_progress

    def can_block_enter(self, v, blocks, doors, bridge_open, ep):
        return (not self.terrain_blocked(v, doors, bridge_open)
                and v not in blocks and self.energy_allowed(v, ep))

    def try_move(self, state, d):
        player, blocks, bridge_open, ep = state
        doors = self.door_state(blocks)
        target = (player[0] + d[0], player[1] + d[1], player[2] + d[2])
        if self.terrain_blocked(target, doors, bridge_open):
            return None
        pushed = False
        dest = None
        if target in blocks:
            beyond = (target[0] + d[0], target[1] + d[1], target[2] + d[2])
            if self.terrain_blocked(beyond, doors, bridge_open) or beyond in blocks:
                return None
            dest = beyond
            if beyond in self.portal_links:
                exit_ = self.portal_links[beyond]
                if not self.can_block_enter(exit_, blocks, doors, bridge_open, ep) or exit_ == player:
                    return None
                dest = exit_
            if beyond in self.elevator_links:
                exit_ = self.elevator_links[beyond]
                if not self.can_block_enter(exit_, blocks, doors, bridge_open, ep):
                    return None
                dest = exit_
            if not self.energy_allowed(dest, ep):
                return None
            pushed = True
        player_dest = target
        if target in self.elevator_links:
            pe = self.elevator_links[target]
            if self.terrain_blocked(pe, doors, bridge_open) or pe in blocks:
                return None
            player_dest = pe
        new_blocks = blocks
        new_ep = ep
        if pushed:
            new_blocks = set(blocks)
            new_blocks.discard(target)
            new_blocks.add(dest)
            new_blocks = frozenset(new_blocks)
            if new_ep < len(self.energy_nodes) and dest == self.energy_nodes[new_ep]:
                new_ep += 1
        return (player_dest, new_blocks, bridge_open, new_ep)

    def rotate(self, state):
        player, blocks, bridge_open, ep = state
        if not self.bridges:
            return None
        for b in self.bridges:
            if player == b or b in blocks:
                return None
        return (player, blocks, not bridge_open, ep)

    def won(self, state):
        _player, blocks, _bridge_open, ep = state
        if ep < len(self.energy_nodes):
            return False
        allowed = self.targets()
        if any(b not in allowed for b in blocks):
            return False
        return all(t in blocks for t in self.required_targets())

    def start_state(self):
        return (self.player, frozenset(self.blocks), True, 0)

    def dead_squares(self):
        """Cells a Core can never be pulled out of, so no solution passes through.

        Doors and bridges count as open here: an optimistic map keeps more cells
        alive, which can only ever make the pruning weaker, never wrong.
        """
        if self.portal_links or self.elevator_links or self.energy_nodes:
            return set()
        open_cells = {v for v in self.floors if v not in self.walls}
        alive = set(self.targets())
        frontier = list(alive)
        while frontier:
            cell = frontier.pop()
            for d in DIRS:
                pull_from = (cell[0] + d[0], cell[1] + d[1], cell[2] + d[2])
                player_cell = (cell[0] + 2 * d[0], cell[1] + 2 * d[1], cell[2] + 2 * d[2])
                if pull_from in alive or pull_from not in open_cells:
                    continue
                if player_cell not in open_cells:
                    continue
                alive.add(pull_from)
                frontier.append(pull_from)
        return open_cells - alive


def _heuristic(logic, blocks, targets):
    """Lower bound on remaining pushes, so it is also a bound on remaining moves."""
    total = 0
    for b in blocks:
        if b in targets:
            continue
        total += min(abs(b[0] - t[0]) + abs(b[1] - t[1]) + abs(b[2] - t[2]) for t in targets)
    return total


def solve(level, max_states=3_000_000):
    """A* for a shortest route. Returns (solved, message, moves, route)."""
    logic = Logic(level)
    cores = len(logic.blocks)
    required = len(logic.required_targets())
    if cores < required:
        return (False, "core/target mismatch cores=%d required=%d" % (cores, required), 0, "")
    start = logic.start_state()
    if logic.won(start):
        return (True, "trivial", 0, "")
    targets = logic.targets()
    if not targets:
        return (False, "no target on map", 0, "")
    dead = logic.dead_squares() - targets
    tie = count()
    best = {start: 0}
    came = {start: None}
    queue = [(_heuristic(logic, start[1], targets), next(tie), start)]
    while queue:
        _f, _t, state = heapq.heappop(queue)
        g = best[state]
        moves = [(d, logic.try_move(state, d)) for d in DIRS]
        if logic.bridges:
            moves.append((None, logic.rotate(state)))
        for step, nxt in moves:
            if nxt is None or best.get(nxt, 1 << 30) <= g + 1:
                continue
            if any(b in dead for b in nxt[1]):
                continue
            best[nxt] = g + 1
            came[nxt] = (state, step)
            if logic.won(nxt):
                return (True, "solved", g + 1, _route(came, nxt))
            heapq.heappush(queue, (g + 1 + _heuristic(logic, nxt[1], targets), next(tie), nxt))
        if len(best) > max_states:
            return (False, "state limit exceeded (%d states)" % len(best), 0, "")
    return (False, "no solution (%d states)" % len(best), 0, "")


def _route(came, state):
    steps = []
    while came[state] is not None:
        state, step = came[state]
        steps.append("B" if step is None else DIR_LETTERS[step])
    steps.reverse()
    return "".join(steps)


def main():
    import sys
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    levels = load_levels()
    ok = True
    print("=== THE LAST RESONANCE LEVEL SOLVER ===")
    for i, level in enumerate(levels):
        solved, message, moves, route = solve(level)
        par = int(level.get("par_moves", 0))
        tag = "PASS" if solved else "FAIL"
        if not solved:
            ok = False
        print("Level %02d C%s D%s [%s]: %s (%s, optimal=%d, par=%d)" % (
            i + 1, level.get("chapter", "?"), level.get("difficulty", "?"),
            level.get("name", "?"), tag, message, moves, par))
        if solved:
            print("    route %s" % route)
            if par != moves:
                ok = False
                print("    FAIL: par_moves=%d but optimal route is %d moves" % (par, moves))
    print("==================================")
    print("RESULT:", "ALL SOLVABLE AND PAR CORRECT" if ok else "FAILURES PRESENT")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
