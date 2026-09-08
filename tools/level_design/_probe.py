"""Scratch: score candidate maps on interleaving, not length."""
import pathlib
import sys, time
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
from validate_levels import Logic, solve
L = {"R": (1,0,0), "L": (-1,0,0), "D": (0,0,1), "U": (0,0,-1)}

def score(name, rows, ents=None):
    lv = {"map": rows, "entities": ents or []}
    w = {len(r) for r in rows}
    if len(w) != 1:
        print("%-6s WIDTH MISMATCH %s" % (name, w)); return
    lg = Logic(lv)
    floor = len([c for c in lg.floors if c not in lg.walls])
    t = time.time()
    ok, msg, moves, route = solve(lv)
    dt = time.time() - t
    if not ok:
        print("%-6s cores=%d floor=%d  %s (%.1fs)" % (name, len(lg.blocks), floor, msg, dt)); return
    st = lg.start_state()
    ident = {b: i for i, b in enumerate(sorted(st[1]))}
    seq = []
    for ch in route:
        nxt = lg.rotate(st) if ch == "B" else lg.try_move(st, L[ch])
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
    bpc = sum(blocks.values()) / len(blocks)
    print("%-6s cores=%d floor=%d dens=%.2f moves=%d pushes=%d blocks/core=%.1f %s solve=%.1fs"
          % (name, len(lg.blocks), floor, len(lg.blocks)/floor, moves, len(seq), bpc,
             sorted(blocks.values(), reverse=True), dt))
    print("       route %s" % route)
