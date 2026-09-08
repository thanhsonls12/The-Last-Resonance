"""Search Level 11 option D: 2 layers <=9x7, 1 e-pair, 2 cores/2 slots
(1 pair per floor), no portal/door/bridge, par 55-70.
T1 core physically gates e. T2 slot visible straight-line from e-exit.
"""
import pathlib, random, sys, time
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
from validate_levels import Logic, solve

S1 = [
    ["########",
     "#      #",
     "# ## # #",
     "# #  # #",
     "#  #   #",
     "#      #",
     "########"],
    ["#######",
     "#     #",
     "# ### #",
     "# #   #",
     "#   # #",
     "#     #",
     "#######"],
    ["########",
     "#      #",
     "# ###  #",
     "# #  # #",
     "#    # #",
     "#      #",
     "########"],
]
S2 = [
    ["########",
     "#      #",
     "# #### #",
     "# #    #",
     "#  # # #",
     "#      #",
     "########"],
    ["#########",
     "#       #",
     "# ##### #",
     "# #   # #",
     "# # #   #",
     "#   ### #",
     "#       #",
     "#########"],
    ["########",
     "#      #",
     "# ## # #",
     "# #  # #",
     "#  #   #",
     "#      #",
     "########"],
]
L = {"R": (1, 0, 0), "L": (-1, 0, 0), "D": (0, 0, 1), "U": (0, 0, -1)}


def free(shape):
    return [(x, z) for z, r in enumerate(shape) for x, c in enumerate(r) if c == " "]


def render(shape, extra):
    rows = [list(r) for r in shape]
    for (x, z), ch in extra.items():
        rows[z][x] = ch
    return ["".join(r) for r in rows]


def reach(rows, start, blocked):
    seen = {start}
    stack = [start]
    while stack:
        x, z = stack.pop()
        for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            q = (x + dx, z + dz)
            if q in seen or q in blocked:
                continue
            if not (0 <= q[1] < len(rows) and 0 <= q[0] < len(rows[0])):
                continue
            if rows[q[1]][q[0]] == "#":
                continue
            seen.add(q)
            stack.append(q)
    return seen


def visible(rows, a, b):
    if a[0] == b[0]:
        step = 1 if b[1] > a[1] else -1
        return all(rows[z][a[0]] != "#" for z in range(a[1] + step, b[1], step))
    if a[1] == b[1]:
        step = 1 if b[0] > a[0] else -1
        return all(rows[a[1]][x] != "#" for x in range(a[0] + step, b[0], step))
    return False


def walkable(rows):
    return sum(1 for r in rows for c in r if c != "#")


def entry_analysis(lv, route):
    """At first T2 arrival: is an immediate core push legal? How many moves
    after entry before the first T2-core push in the optimal route?"""
    lg = Logic(lv)
    st = lg.start_state()
    entry_idx, estate = -1, None
    for i, ch in enumerate(route):
        st = lg.try_move(st, L[ch])
        if st[0][1] == 1:
            entry_idx, estate = i, st
            break
    if entry_idx < 0:
        return None
    t2cores = {b for b in estate[1] if b[1] == 1}
    greedy = False
    for d in ((1, 0, 0), (-1, 0, 0), (0, 0, 1), (0, 0, -1)):
        p, blocks, bo, ep = estate
        tgt = (p[0] + d[0], p[1] + d[1], p[2] + d[2])
        if tgt in t2cores and lg.try_move(estate, d) is not None:
            greedy = True
    st = estate
    gap = 0
    for ch in route[entry_idx + 1:]:
        pre = set(st[1])
        st = lg.try_move(st, L[ch])
        gap += 1
        if set(st[1]) != pre:
            break
    return greedy, gap


def run(budget):
    best = []
    tried = solved = 0
    deadline = time.time() + budget
    while time.time() < deadline:
        s1, s2 = random.choice(S1), random.choice(S2)
        f1, f2 = free(s1), free(s2)
        common = sorted(set(f1) & set(f2))
        if not common or len(f1) < 4 or len(f2) < 3:
            continue
        e = random.choice(common)
        r1 = [c for c in f1 if c != e]
        r2 = [c for c in f2 if c != e]
        if len(r1) < 3 or len(r2) < 2:
            continue
        p1, c1, g1 = random.sample(r1, 3)
        c2, g2 = random.sample(r2, 2)
        rows1 = render(s1, {e: "e", p1: "@", c1: "$", g1: "."})
        rows2 = render(s2, {e: "e", c2: "$", g2: "."})
        if max(len(r) for r in rows1 + rows2) > 9 or max(len(rows1), len(rows2)) > 7:
            continue
        if walkable([rows1, rows2]) > 42:
            continue
        if e in reach(rows1, p1, {c1}):
            continue  # T1 core must gate e
        if e not in reach(rows1, p1, set()):
            continue
        if not visible(rows2, e, g2):
            continue
        lv = {"maps": ["\n".join(rows1), "\n".join(rows2)], "entities": []}
        tried += 1
        try:
            ok, _m, moves, route = solve(lv, max_states=150_000)
        except RecursionError:
            continue
        if not ok or not (55 <= moves <= 70):
            continue
        solved += 1
        an = entry_analysis(lv, route)
        best.append((moves, an, rows1, rows2, route, e, p1, c1, g1, c2, g2))
        best.sort(key=lambda t: (t[0], -(t[1][1] if t[1] else 0)))
        best = best[:8]
    print("tried=%d solved_in_range=%d" % (tried, solved))
    for moves, an, rows1, rows2, route, e, p1, c1, g1, c2, g2 in best:
        print("\n=== moves=%d entry=%s e=%s T1(@%s $%s .%s) T2($%s .%s)" % (
            moves, an, e, p1, c1, g1, c2, g2))
        print("  T1:")
        for r in rows1:
            print("   " + r)
        print("  T2:")
        for r in rows2:
            print("   " + r)
        print("   route " + route)


if __name__ == "__main__":
    run(float(sys.argv[1]) if len(sys.argv) > 1 else 120)
