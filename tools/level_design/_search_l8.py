#!/usr/bin/env python3
"""Scratch: random search Level 8 on the V49 ring shell.

V49 shell is the one that solves AND puts the bridge rotation on the optimal
route. Hand-tuning its contents kept landing at 56-64 moves, under the 85-100
par band, so this searches core/pedestal/plate placements on the fixed shell
and keeps whatever lands in the band with the highest interleaving.

Shell legend: '#' wall, ' ' free cell the search may fill, 'K' door (group K),
'r' bridge cell. The search assigns: 1 key plate (non-hold, group K), N cores,
N pedestals, 1 spawn. A core resting on the plate is allowed to be its final
home, so cores == pedestals + 1 is also searched.
"""
import random
import pathlib
import sys
import time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
from validate_levels import Logic, solve

L = {"R": (1, 0, 0), "L": (-1, 0, 0), "D": (0, 0, 1), "U": (0, 0, -1)}

# V49 ring: north corridor z1, ring row z3, chamber x4-6 z4-6 entered from row3,
# south corridor z7, west col x1 (split by the bridge at (1,4)), east col x9.
SHELL = [
    "###########",
    "#         #",
    "# ###K#####",
    "#         #",
    "#  #   #  #",
    "#  #   #  #",
    "#  #   #  #",
    "#         #",
    "###########",
]
BRIDGE = (1, 0, 4)
DOOR = (5, 0, 2)


def interleaving(lg, route):
    st = lg.start_state()
    ident = {b: i for i, b in enumerate(sorted(st[1]))}
    seq = []
    for ch in route:
        nxt = lg.rotate(st) if ch == "B" else lg.try_move(st, L[ch])
        if nxt is None:
            return 0, 0, []
        if nxt[1] != st[1]:
            src = next(b for b in st[1] if b not in nxt[1])
            dst = next(b for b in nxt[1] if b not in st[1])
            cid = ident.pop(src)
            ident[dst] = cid
            seq.append(cid)
        st = nxt
    runs = {}
    for i, cid in enumerate(seq):
        if i == 0 or seq[i - 1] != cid:
            runs[cid] = runs.get(cid, 0) + 1
    bpc = sum(runs.values()) / len(runs) if runs else 0
    return bpc, len(seq), sorted(runs.values(), reverse=True)


def render(cores, slots, plate, spawn):
    rows = [list(r) for r in SHELL]
    for x, _y, z in slots:
        rows[z][x] = "."
    for x, _y, z in cores:
        rows[z][x] = "*" if (x, 0, z) in slots else "$"
    rows[spawn[2]][spawn[0]] = "@"
    return ["".join(r) for r in rows]


def run(budget_s, n_cores, n_slots, lo=85, hi=100):
    free = [(x, 0, z) for z, row in enumerate(SHELL)
            for x, ch in enumerate(row) if ch == " "]
    free = [c for c in free if c != BRIDGE]
    best = []
    tried = solved = inband = 0
    deadline = time.time() + budget_s
    while time.time() < deadline:
        picks = random.sample(free, n_cores + n_slots + 2)
        cores = picks[:n_cores]
        slots = picks[n_cores:n_cores + n_slots]
        plate = picks[n_cores + n_slots]
        spawn = picks[-1]
        if plate in cores or plate in slots or spawn in cores:
            continue
        rows = render(cores, slots, plate, spawn)
        level = {"map": rows, "entities": [
            {"type": "plate", "grid_position": plate, "group": "K",
             "hold_required": False},
            {"type": "bridge", "grid_position": BRIDGE, "starts_open": False},
        ]}
        tried += 1
        lg = Logic(level)
        if len(lg.blocks) != n_cores or len(lg.slots) != n_slots:
            continue
        if lg.dead_squares() & set(lg.blocks):
            continue
        try:
            ok, _msg, moves, route = solve(level, max_states=400_000)
        except RecursionError:
            continue
        if not ok:
            continue
        solved += 1
        if not lo <= moves <= hi:
            continue
        if "B" not in route:
            continue
        inband += 1
        bpc, pushes, runs = interleaving(lg, route)
        best.append((bpc, moves, pushes, runs, rows, plate, route))
        best.sort(key=lambda e: (-e[0], -e[1]))
        best = best[:6]
    print("tried=%d solved=%d in-band-with-bridge=%d" % (tried, solved, inband))
    for bpc, moves, pushes, runs, rows, plate, route in best:
        print("\nmoves=%d pushes=%d bpc=%.2f %s plate=%s" % (
            moves, pushes, bpc, runs, plate))
        for r in rows:
            print("   " + r)
        print("   route " + route)
    return best


if __name__ == "__main__":
    budget = int(sys.argv[1]) if len(sys.argv) > 1 else 120
    cores = int(sys.argv[2]) if len(sys.argv) > 2 else 4
    slots = int(sys.argv[3]) if len(sys.argv) > 3 else 4
    run(budget, cores, slots)
