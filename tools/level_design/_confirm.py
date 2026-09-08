"""Scratch: confirm a candidate map with the authoritative solver.

_fast is only a search accelerator; validate_levels.solve is what the game rules
are mirrored from, so the par_moves that ships must come from here.
"""
import pathlib
import sys
import time
from pathlib import Path

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
from _fast import solve_fast
from _hard import measure
from validate_levels import solve

rows = [line.rstrip("\n") for line in
        Path(sys.argv[1]).read_text(encoding="utf-8").splitlines() if line.strip()]
widths = {len(r) for r in rows}
print("size %dx%d widths=%s" % (len(rows[0]), len(rows), widths))
result = measure(rows)
print("measure:", result[1] if result else "rejected by search gates")
t = time.time()
ok_fast, moves_fast, route_fast = solve_fast(rows, max_states=2_000_000)
print("fast    solved=%s moves=%d %.1fs" % (ok_fast, moves_fast, time.time() - t))
t = time.time()
ok_ref, msg, moves_ref, route_ref = solve({"map": rows, "entities": []})
print("ref     solved=%s moves=%d %s %.1fs" % (ok_ref, moves_ref, msg, time.time() - t))
print("route   %s" % route_ref)
if ok_fast and ok_ref and moves_fast != moves_ref:
    print("MISMATCH: fast=%d ref=%d" % (moves_fast, moves_ref))
