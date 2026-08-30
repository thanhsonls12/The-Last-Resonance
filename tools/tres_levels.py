#!/usr/bin/env python3
"""Read resources/levels/*.tres so the Python tools share Godot's level source.

The .tres resources are the single source of truth for runtime maps. This parser
extracts only the fields the solver and validator need, and keeps the field names
used by LevelData.
"""
import ast
import re
from pathlib import Path

LEVEL_DIR = Path(__file__).resolve().parent.parent / "resources" / "levels"

_STRING_ARRAY = re.compile(r'^(\w+) = Array\[String\]\(\[(.*)\]\)$', re.M)
_SCALAR = re.compile(r'^(\w+) = (-?\d+(?:\.\d+)?)$', re.M)
_QUOTED = re.compile(r'^(\w+) = "((?:[^"\\]|\\.)*)"$', re.M)
_ARRAY = re.compile(r'^(\w+) = (\[.*\])$', re.M)
_VECTOR3I = re.compile(r'Vector3i\(\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*(-?\d+)\s*\)')


def _parse_gd_array(raw):
    """Turn a Godot array literal into Python data. Vector3i becomes a tuple."""
    python_source = _VECTOR3I.sub(r'(\1, \2, \3)', raw)
    python_source = python_source.replace("true", "True").replace("false", "False")
    try:
        return ast.literal_eval(python_source)
    except (ValueError, SyntaxError):
        return []


def parse_level(path):
    text = path.read_text(encoding="utf-8")
    level = {"path": str(path), "map": [], "maps": [], "entities": [], "decorations": []}
    for key, body in _STRING_ARRAY.findall(text):
        level[key] = [row for row in re.findall(r'"((?:[^"\\]|\\.)*)"', body)]
    for key, value in _SCALAR.findall(text):
        level[key] = float(value) if "." in value else int(value)
    for key, value in _QUOTED.findall(text):
        level[key] = value.replace('\\"', '"').replace("\\n", "\n")
    for key, value in _ARRAY.findall(text):
        if key in ("entities", "decorations"):
            level[key] = _parse_gd_array(value)
    level.setdefault("name", level.get("title", path.stem))
    level["name"] = level.get("title", level["name"])
    return level


def load_levels():
    return [parse_level(p) for p in sorted(LEVEL_DIR.glob("level_*.tres"))]


if __name__ == "__main__":
    import sys
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    for level in load_levels():
        print("%-22s chapter=%s difficulty=%s par=%s rows=%d entities=%d" % (
            level.get("name"), level.get("chapter"), level.get("difficulty"),
            level.get("par_moves"), len(level["map"]), len(level["entities"])))
