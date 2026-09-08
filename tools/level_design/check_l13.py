"""Solve the authored Central Core introduction without modifying resources."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from tres_levels import parse_level
from validate_levels import solve

level = parse_level(Path(__file__).resolve().parents[2] / "resources/levels/level_13.tres")
print(solve(level))
