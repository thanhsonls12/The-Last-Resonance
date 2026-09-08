"""Scratch: score every level in the catalogue on the interleaving metric."""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))
import _probe
import tres_levels

for lv in tres_levels.load_levels():
    _probe.score(pathlib.Path(lv["path"]).stem, lv["map"], lv.get("entities"))
