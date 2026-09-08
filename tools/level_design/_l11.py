import pathlib, sys, time, random
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
from validate_levels import Logic, solve

L = {"R": (1,0,0), "L": (-1,0,0), "D": (0,0,1), "U": (0,0,-1)}

SHAPES = [
    ["#########","# ###   #","#     # #","# ### # #","# #   # #","#   ### #","#########"],
    ["#########","#   ### #","# #     #","# # ### #","# #   # #","# ###   #","#########"],
    ["#########","# #   # #","# # # # #","#   #   #","# ### # #","#     # #","#########"],
    ["#########","#   #   #","# # # # #","# #   # #","# # # # #","#   #   #","#########"],
    ["########","#      #","# #### #","# #    #","# # ## #","#      #","########"],
    ["#########","##     ##","#  ###  #","#      ##","#  ###  #","##     ##","#########"],
]

def diag(lv, route):
    lg = Logic(lv)
    st = lg.start_state()
    l0slots = [s for s in lg.slots if s[1] == 0]
    rides = 0; first_ok = None; core_elev = False
    for ch in route:
        nxt = lg.try_move(st, L[ch])
        if nxt is None:
            return "BROKEN"
        old = set(st[1]); new = set(nxt[1])
        for b in new - old:
            src = next((s for s in old - new), None)
            if src is not None and src[1] != b[1]:
                core_elev = True
        if nxt[0][1] != st[0][1]:
            rides += 1
            if rides == 1:
                first_ok = all(s in st[1] for s in l0slots)
        st = nxt
    return "rides=%d first_ok=%s core_elev=%s won=%s" % (rides, first_ok, core_elev, lg.won(st))

def run(budget_s=500):
    rng = random.Random(99173)
    tried = inrange = 0
    deadline = time.time() + budget_s
    while time.time() < deadline:
        s0 = rng.choice(SHAPES); s1 = rng.choice(SHAPES)
        free0 = [(x,z) for z,r in enumerate(s0) for x,c in enumerate(r) if c==" "]
        free1 = [(x,z) for z,r in enumerate(s1) for x,c in enumerate(r) if c==" "]
        common = sorted(set(free0) & set(free1))
        if len(common) < 1 or len(free0) < 4 or len(free1) < 3:
            continue
        ex,ez = rng.choice(common)
        rest0 = [p for p in free0 if p != (ex,ez)]
        rest1 = [p for p in free1 if p != (ex,ez)]
        if len(rest0) < 3 or len(rest1) < 2:
            continue
        g0,c0,p0 = rng.sample(rest0,3)
        g1,c1 = rng.sample(rest1,2)
        def render(shape, extra):
            rows=[list(r) for r in shape]
            for (x,z),ch in extra.items():
                rows[z][x]=ch
            return ["".join(r) for r in rows]
        r0 = render(s0, {(ex,ez):"e", g0:".", c0:"$", p0:"@"})
        r1 = render(s1, {(ex,ez):"e", g1:".", c1:"$"})
        lv={"map":[],"maps":["\n".join(r0),"\n".join(r1)],"entities":[],"decorations":[]}
        tried+=1
        try:
            ok,msg,moves,route=solve(lv,max_states=150_000)
        except RecursionError:
            continue
        if not ok or not 40 <= moves <= 85:
            continue
        inrange+=1
        lg = Logic(lv)
        walk = len(lg.floors - lg.walls)
        print("CAND moves=%d walk=%d e=(%d,%d) %s" % (moves, walk, ex, ez, diag(lv, route)), flush=True)
        for r in r0: print("  L0 " + r)
        for r in r1: print("  L1 " + r)
        print("  route " + route, flush=True)
        if inrange >= 15:
            break
    print("tried=%d inrange=%d" % (tried, inrange))

run()
