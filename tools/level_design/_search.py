"""Scratch: randomized search for compact maps with high interleaving.

Scores candidates by blocks/core (how often the solver must come back to a Core
it already moved), not by route length. Length is what made trial_01 tedious
rather than hard.
"""
import pathlib
import random, sys, time
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
from validate_levels import Logic, solve
L = {"R": (1,0,0), "L": (-1,0,0), "D": (0,0,1), "U": (0,0,-1)}

SHAPES = [
    ["########","#      #","# ## # #","#      #","# # ## #","#      #","########"],
    ["#########","#       #","# ### # #","#       #","# # ### #","#       #","#########"],
    ["########","#      #","#  ##  #","# #  # #","#  ##  #","#      #","########"],
    ["#########","##     ##","#  ###  #","#  # #  #","#  ###  #","##     ##","#########"],
    ["########","#   #  #","# # #  #","# #    #","#   ## #","#  #   #","########"],
]

def interleaving(lv, route):
    lg = Logic(lv); st = lg.start_state()
    ident = {b: i for i, b in enumerate(sorted(st[1]))}
    seq = []
    for ch in route:
        nxt = lg.try_move(st, L[ch])
        if nxt[1] != st[1]:
            src = next(b for b in st[1] if b not in nxt[1])
            dst = next(b for b in nxt[1] if b not in st[1])
            cid = ident.pop(src); ident[dst] = cid
            seq.append(cid)
        st = nxt
    blocks = {}
    for i, cid in enumerate(seq):
        if i == 0 or seq[i-1] != cid:
            blocks[cid] = blocks.get(cid, 0) + 1
    return sum(blocks.values()) / len(blocks), len(seq), sorted(blocks.values(), reverse=True)

def render(shape, goals, cores, player):
    rows = [list(r) for r in shape]
    for x, z in goals:  rows[z][x] = "."
    for x, z in cores:  rows[z][x] = "*" if (x, z) in goals else "$"
    px, pz = player
    rows[pz][px] = "+" if (px, pz) in goals else "@"
    return ["".join(r) for r in rows]

def run(budget_s, n_cores):
    best = []
    deadline = time.time() + budget_s
    tried = solved = 0
    while time.time() < deadline:
        shape = random.choice(SHAPES)
        free = [(x, z) for z, r in enumerate(shape) for x, c in enumerate(r) if c == " "]
        if len(free) < 2 * n_cores + 1:
            continue
        picks = random.sample(free, 2 * n_cores + 1)
        goals = picks[:n_cores]; cores = picks[n_cores:2*n_cores]; player = picks[-1]
        if set(goals) & set(cores):
            continue
        rows = render(shape, goals, cores, player)
        lv = {"map": rows, "entities": []}
        tried += 1
        try:
            ok, _msg, moves, route = solve(lv, max_states=120_000)
        except RecursionError:
            continue
        if not ok or moves < 15:
            continue
        solved += 1
        bpc, pushes, dist = interleaving(lv, route)
        best.append((bpc, pushes, moves, dist, rows, route))
        best.sort(key=lambda e: (-e[0], -e[1]))
        best = best[:6]
    print("tried=%d solved=%d" % (tried, solved))
    for bpc, pushes, moves, dist, rows, route in best:
        print("\nblocks/core=%.2f %s pushes=%d moves=%d" % (bpc, dist, pushes, moves))
        for r in rows:
            print("   " + r)
        print("   route " + route)
