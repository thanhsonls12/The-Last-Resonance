"""Scratch: hill-climb for a trial map that is hard rather than merely long.

Objective is interleaving (how many separate visits each Core needs) plus trap
density (dead squares per open cell), under a move-count ceiling so the winner
cannot buy its score with tedium the way trial_01 did.
"""
import os
import pathlib
import random
import sys
import time
from pathlib import Path

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
from _fast import Board, DIR_LETTERS, solve_fast

MAX_MOVES = int(os.environ.get("HARD_MAX_MOVES", "90"))
MIN_MOVES = int(os.environ.get("HARD_MIN_MOVES", "30"))
SEARCH_STATES = int(os.environ.get("HARD_STATES", "200000"))
REJECTS = {}


def reject(reason):
    REJECTS[reason] = REJECTS.get(reason, 0) + 1
    return None


def render(w, h, walls, goals, cores, player):
    rows = []
    for z in range(h):
        row = []
        for x in range(w):
            cell = (x, z)
            if x in (0, w - 1) or z in (0, h - 1) or cell in walls:
                row.append("#")
            elif cell == player:
                row.append("+" if cell in goals else "@")
            elif cell in cores:
                row.append("*" if cell in goals else "$")
            elif cell in goals:
                row.append(".")
            else:
                row.append(" ")
        rows.append("".join(row))
    return rows


def connected(w, h, walls, must):
    open_cells = {(x, z) for x in range(1, w - 1) for z in range(1, h - 1)
                  if (x, z) not in walls}
    if not must <= open_cells:
        return None
    seen = {next(iter(must))}
    frontier = list(seen)
    while frontier:
        x, z = frontier.pop()
        for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nxt = (x + dx, z + dz)
            if nxt in open_cells and nxt not in seen:
                seen.add(nxt)
                frontier.append(nxt)
    return open_cells if seen == open_cells else None


def alive_cells(w, h, walls, goals):
    """Cells a Core can still be pushed out of, given only walls and goals.

    Sampling Cores from these instead of from every free cell is what makes the
    hill-climb spend its time on solvable candidates: in an open room most
    wall-adjacent cells are already one-way traps.
    """
    rows = render(w, h, walls, goals, set(), None)
    board = Board(rows)
    return [(i % board.w, i // board.w) for i in range(board.w * board.h)
            if board.open[i] and i not in board.dead]


def measure(rows):
    """(score, detail) for a candidate, or None when it fails a hard gate."""
    board = Board(rows)
    if any(b in board.dead for b in board.boxes):
        return reject("core on dead square")
    solved, moves, route = solve_fast(rows, max_states=SEARCH_STATES)
    if not solved:
        return reject("unsolved or over state cap")
    if not MIN_MOVES <= moves <= MAX_MOVES:
        return reject("short route" if moves < MIN_MOVES else "long route")
    player, boxes = board.player, frozenset(board.boxes)
    ident = {b: i for i, b in enumerate(sorted(boxes))}
    pushes = []
    for letter in route:
        d = DIR_LETTERS.index(letter)
        target = board.edge[d][player]
        if target in boxes:
            beyond = board.edge[d][target]
            boxes = frozenset(boxes - {target} | {beyond})
            core = ident.pop(target)
            ident[beyond] = core
            pushes.append(core)
        player = target
    visits = {}
    for i, core in enumerate(pushes):
        if i == 0 or pushes[i - 1] != core:
            visits[core] = visits.get(core, 0) + 1
    if len(visits) < len(board.boxes):
        return reject("idle core")
    counts = sorted(visits.values(), reverse=True)
    open_count = sum(1 for flag in board.open if flag)
    dead_frac = len(board.dead) / open_count
    score = (8 * min(counts) + 3 * (sum(counts) / len(counts))
             + 4 * dead_frac + len(pushes) / 12.0 + moves / 40.0)
    return score, {"moves": moves, "pushes": len(pushes), "visits": counts,
                   "dead_frac": dead_frac, "open": open_count, "route": route}


def mutate(w, h, walls, goals, cores, player, rng):
    walls, goals, cores = set(walls), set(goals), set(cores)
    interior = [(x, z) for x in range(1, w - 1) for z in range(1, h - 1)]
    kind = rng.random()
    if kind < 0.25 and len(walls) < len(interior) - 3 * len(cores) - 4:
        walls ^= {rng.choice(interior)}
    elif kind < 0.55:
        pool = [c for c in alive_cells(w, h, walls, goals)
                if c not in cores and c != player]
        if not pool:
            return None
        cores.discard(rng.choice(sorted(cores)))
        cores.add(rng.choice(pool))
    elif kind < 0.8:
        free = [c for c in interior if c not in walls and c not in cores]
        goals.discard(rng.choice(sorted(goals)))
        goals.add(rng.choice(free))
    else:
        free = [c for c in interior if c not in walls and c not in cores]
        player = rng.choice(free)
    if len(goals) != len(cores) or player in cores:
        return None
    must = cores | goals | {player}
    if walls & must or connected(w, h, walls, must) is None:
        return None
    return walls, goals, cores, player


def seed_from_rows(rows):
    """(w, h, walls, goals, cores, player) parsed back out of a rendered map."""
    h = len(rows)
    w = max(len(r) for r in rows)
    walls, goals, cores, player = set(), set(), set(), None
    for z, row in enumerate(rows):
        for x, glyph in enumerate(row):
            cell = (x, z)
            if glyph == "#":
                if 0 < x < w - 1 and 0 < z < h - 1:
                    walls.add(cell)
                continue
            if glyph in ".*+":
                goals.add(cell)
            if glyph in "$*":
                cores.add(cell)
            if glyph in "@+":
                player = cell
    return w, h, walls, goals, cores, player


def run(budget_s, n_cores=4, w=8, h=7, seed=None, start=None):
    rng = random.Random(seed)
    seed_state = None
    if start is not None:
        w, h, walls, goals, cores, player = seed_from_rows(start)
        seed_state = (walls, goals, cores, player)
        n_cores = len(cores)
    interior = [(x, z) for x in range(1, w - 1) for z in range(1, h - 1)]
    deadline = time.time() + budget_s
    best_score, best = -1.0, None
    current, current_score = seed_state, -1.0
    if seed_state is not None:
        seeded = measure(render(w, h, *seed_state))
        if seeded is None:
            print("seed map fails the gates; climbing from it anyway")
        else:
            current_score = seeded[0]
            print("seed score=%.2f visits=%s" % (seeded[0], seeded[1]["visits"]))
    evaluated = 0
    while time.time() < deadline:
        if current is None:
            if seed_state is not None:
                current, current_score = seed_state, -1.0
                continue
            walls = {c for c in interior if rng.random() < 0.12}
            goals = set()
            free = [c for c in interior if c not in walls]
            if len(free) < 3 * n_cores + 2:
                continue
            goals = set(rng.sample(free, n_cores))
            pool = [c for c in alive_cells(w, h, walls, goals) if c not in goals]
            if len(pool) < n_cores + 1:
                continue
            picks = rng.sample(pool, n_cores)
            rest = [c for c in free if c not in picks]
            cand = (walls, goals, set(picks), rng.choice(rest))
            if connected(w, h, walls, cand[1] | cand[2] | {cand[3]}) is None:
                continue
        else:
            cand = mutate(w, h, *current, rng)
            if cand is None:
                continue
        rows = render(w, h, *cand)
        evaluated += 1
        try:
            result = measure(rows)
        except (RecursionError, StopIteration):
            continue
        if result is None:
            if rng.random() < 0.15:
                current, current_score = None, -1.0
            continue
        score, detail = result
        if score >= current_score:
            current, current_score = cand, score
        if score > best_score:
            best_score, best = score, (rows, detail)
            print("score=%.2f visits=%s moves=%d pushes=%d dead=%.2f open=%d"
                  % (score, detail["visits"], detail["moves"], detail["pushes"],
                     detail["dead_frac"], detail["open"]))
            for row in rows:
                print("   " + row)
            print("   route " + detail["route"], flush=True)
    print("evaluated=%d best=%.2f" % (evaluated, best_score))
    print("rejects " + ", ".join("%s=%d" % kv for kv in
                                 sorted(REJECTS.items(), key=lambda kv: -kv[1])))
    return best


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "refine":
        rows = [line.rstrip("\n") for line in
                Path(sys.argv[2]).read_text(encoding="utf-8").splitlines() if line.strip()]
        budget = float(sys.argv[3]) if len(sys.argv) > 3 else 300.0
        tag = int(sys.argv[4]) if len(sys.argv) > 4 else 0
        run(budget, seed=int(time.time()) + tag * 7919, start=rows)
        raise SystemExit(0)
    budget = float(sys.argv[1]) if len(sys.argv) > 1 else 300.0
    cores = int(sys.argv[2]) if len(sys.argv) > 2 else 4
    width = int(sys.argv[3]) if len(sys.argv) > 3 else 8
    height = int(sys.argv[4]) if len(sys.argv) > 4 else 7
    tag = int(sys.argv[5]) if len(sys.argv) > 5 else 0
    run(budget, cores, width, height, seed=int(time.time()) + tag * 7919)
