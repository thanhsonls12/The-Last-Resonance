"""Author chapter floor bands and low walls while preserving puzzle fields."""
import hashlib
import json
import re
from pathlib import Path

from tres_levels import load_levels, parse_level

ROOT = Path(__file__).resolve().parents[1]
CHAPTERS = {1: 'archive', 2: 'foundry', 3: 'sanctuary', 4: 'core'}
PASS = 'chapter_surface'


def literal(value):
    if isinstance(value, tuple):
        return 'Vector3i(%d, %d, %d)' % value
    if isinstance(value, bool):
        return 'true' if value else 'false'
    if isinstance(value, dict):
        return '{ ' + ', '.join(json.dumps(k) + ': ' + literal(v) for k, v in value.items()) + ' }'
    if isinstance(value, list):
        return '[' + ', '.join(literal(v) for v in value) + ']'
    return json.dumps(value, ensure_ascii=False)


def puzzle_fields(level):
    return {k: v for k, v in level.items() if k not in ('decorations', 'path')}


def main():
    report = []
    for level in load_levels():
        path = Path(level['path'])
        before = puzzle_fields(level)
        decos = []
        for item in level['decorations']:
            if item.get('surface_pass') != PASS:
                decos.append(item)
            elif item.get('replaces_type'):
                restored = {k: v for k, v in item.items() if k not in ('surface_pass', 'replaces_type')}
                restored['type'] = item['replaces_type']
                decos.append(restored)
        chapter = int(level['chapter'])
        prefix = CHAPTERS[chapter]
        layers = [raw.splitlines() for raw in level['maps']] if level['maps'] else [level['map']]
        entities = {tuple(item['grid_position']) for item in level['entities'] if 'grid_position' in item}
        occupied = {d['grid_position'] for d in decos if not d['type'].startswith('kit_floor') and not d['type'].startswith('kit_rail')}
        wet = [d['grid_position'] for d in decos if 'water' in d['type'] or d['type'] == 'sanctuary_pool']
        added = []
        layer_counts = []
        for y, rows in enumerate(layers):
            width, height = max(map(len, rows)), len(rows)
            def glyph(x, z):
                return rows[z][x] if 0 <= z < height and 0 <= x < len(rows[z]) else '#'
            def playable(x, z):
                return 0 <= z < height and 0 <= x < len(rows[z]) and glyph(x, z) != '#'
            candidates = []
            selected = []
            for z, row in enumerate(rows):
                for x, char in enumerate(row):
                    pos = (x, y, z)
                    if char != ' ' or pos in entities or pos in occupied:
                        continue
                    candidates.append(pos)
                    if chapter == 1:
                        choose = x % 4 in (0, 1) or z == height - 2
                        yaw = ((x // 2 + z // 2) % 4) * 90.0
                    elif chapter == 2:
                        choose = z % 3 != 0 and (x % 3 != 0 or z % 3 == 1)
                        yaw = 0.0 if width >= height else 90.0
                    elif chapter == 3:
                        near_water = any(p[1] == y and abs(p[0] - x) + abs(p[2] - z) <= 2 for p in wet)
                        edge = any(glyph(nx, nz) == '#' for nx, nz in ((x-1,z),(x+1,z),(x,z-1),(x,z+1)))
                        choose = near_water or (edge and (x // 2 + z // 2) % 3 != 0)
                        yaw = ((x // 2 + z // 2) % 4) * 90.0
                    else:
                        choose = x % 3 == 0 or z % 3 == 0 or x == width // 2
                        yaw = 90.0 if z % 3 == 0 else 0.0
                    if choose:
                        selected.append((pos, yaw))
            if len(selected) < min(5, len(candidates)):
                used = {p for p, _ in selected}
                for pos in sorted(candidates, key=lambda p: abs(p[0]-width//2)+abs(p[2]-height//2)):
                    if pos not in used:
                        selected.append((pos, 0.0))
                    if len(selected) >= min(5, len(candidates)):
                        break
            for pos, yaw in selected:
                added.append({'type': prefix + '_floor_variant', 'grid_position': pos, 'yaw': yaw,
                              'surface_skin': True, 'surface_pass': PASS})
            walls = 0
            all_occupied = {d['grid_position'] for d in decos}
            for z, row in enumerate(rows):
                for x, char in enumerate(row):
                    pos = (x, y, z)
                    if char != '#' or pos in all_occupied or pos in entities:
                        continue
                    if x in (0, width-1) and z in (0, height-1):
                        continue
                    east_west = playable(x-1, z) or playable(x+1, z)
                    north_south = playable(x, z-1) or playable(x, z+1)
                    if not east_west and not north_south:
                        continue
                    boundary = x in (0, width-1) or z in (0, height-1)
                    connected_wall = any(0 <= nx < width and 0 <= nz < height and glyph(nx,nz) == '#'
                                         for nx,nz in ((x-1,z),(x+1,z),(x,z-1),(x,z+1)))
                    if not boundary and not connected_wall:
                        continue
                    yaw = 90.0 if (east_west and not north_south) or x in (0,width-1) else 0.0
                    added.append({'type': prefix + '_wall_variant', 'grid_position': pos, 'yaw': yaw, 'surface_pass': PASS})
                    walls += 1
            if walls == 0:
                existing = next((d for d in decos if d['type'] == 'kit_wall_low_straight' and d['grid_position'][1] == y), None)
                if existing:
                    replacement = dict(existing)
                    replacement.update(type=prefix + '_wall_variant', surface_pass=PASS, replaces_type=existing['type'])
                    decos.remove(existing)
                    added.append(replacement)
                    walls += 1
            layer_counts.append({'floor': y, 'floor_skins': len(selected), 'low_walls': walls})
        text = path.read_text(encoding='utf-8')
        updated, count = re.subn(r'^decorations = .*$', 'decorations = ' + literal(decos + added), text, flags=re.M)
        assert count == 1
        path.write_text(updated, encoding='utf-8')
        assert puzzle_fields(parse_level(path)) == before, path
        report.append({'level': path.stem, 'chapter': chapter, 'layers': layer_counts,
                       'puzzle_sha256': hashlib.sha256(json.dumps(before, sort_keys=True, ensure_ascii=False).encode()).hexdigest()})
    (ROOT / 'docs/CAMPAIGN_SURFACES.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print('APPLIED chapter surfaces to 15 levels; puzzle fields unchanged')
    for entry in report:
        print(entry['level'], entry['layers'])


if __name__ == '__main__':
    main()
