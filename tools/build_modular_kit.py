"""Create grid-snapped map modules using Blender's native mesh primitives.

blender --background --python tools/build_modular_kit.py -- <project-root>
Coordinates below are GAME units, Y-up. Export is authored at 2x for the
existing BoardView scale of 0.5. Pivots stay at the cell center / floor plane;
edge and water geometry intentionally extends below the floor plane.
"""
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def point(x, y, z):
    return Vector((2 * x, -2 * z, 2 * y))


def material(name, color, metal=0.0, rough=.65, emission=0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    node = mat.node_tree.nodes.get('Principled BSDF')
    node.inputs['Base Color'].default_value = (*color, 1)
    node.inputs['Metallic'].default_value = metal
    node.inputs['Roughness'].default_value = rough
    if emission:
        node.inputs['Emission Color'].default_value = (*color, 1)
        node.inputs['Emission Strength'].default_value = emission
    return mat


def box(name, center, size, mat):
    bpy.ops.mesh.primitive_cube_add(size=1, location=point(*center))
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = (size[0] * 2, size[2] * 2, size[1] * 2)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    return obj


def cylinder(name, start, end, radius, mat, vertices=12):
    a, b = point(*start), point(*end)
    direction = b - a
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius * 2,
                                       depth=direction.length, location=(a + b) / 2)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = 'QUATERNION'
    obj.rotation_quaternion = direction.to_track_quat('Z', 'Y')
    obj.data.materials.append(mat)


def tube(name, path, mat, radius=.10):
    # Continuous elbow with open connection faces, not two intersecting boxes.
    verts, faces = [], []
    rings = 12
    for index, p in enumerate(path):
        before, after = path[max(0, index - 1)], path[min(len(path) - 1, index + 1)]
        tangent = Vector((after[0] - before[0], 0, after[2] - before[2])).normalized()
        side = Vector((-tangent.z, 0, tangent.x))
        for j in range(rings):
            angle = 2 * math.pi * j / rings
            v = Vector(p) + side * (radius * math.cos(angle)) + Vector((0, radius * math.sin(angle), 0))
            verts.append(point(*v))
    for i in range(len(path) - 1):
        for j in range(rings):
            a = i * rings + j
            b = i * rings + (j + 1) % rings
            faces.append((a, b, b + rings, a + rings))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    # Recalculate normals after the game-to-Blender coordinate conversion.
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode='OBJECT')
    obj.select_set(False)


def build(kind, mats):
    steel, trim, pipe, stone, water, glow = mats
    ports = []
    if kind.startswith('floor_'):
        if kind == 'floor_edge':
            box('Fascia', (0, -.20, -.42), (1, .4, .16), steel)
            box('TopTrim', (0, .012, -.42), (1, .024, .16), trim)
            box('InsetStripe', (0, -.10, -.501), (.80, .025, .006), glow)
        elif kind == 'floor_corner':
            box('NorthFascia', (-.08, -.20, -.42), (.84, .4, .16), steel)
            box('EastFascia', (.42, -.20, 0), (.16, .4, 1), steel)
            box('NorthTrim', (-.08, .012, -.42), (.84, .024, .16), trim)
            box('EastTrim', (.42, .012, 0), (.16, .024, 1), trim)
        elif kind == 'floor_inner_corner':
            box('SouthFascia', (.08, -.20, .42), (.84, .4, .16), steel)
            box('WestFascia', (-.42, -.20, -.08), (.16, .4, .84), steel)
            box('SouthTrim', (.08, .012, .42), (.84, .024, .16), trim)
            box('WestTrim', (-.42, .012, -.08), (.16, .024, .84), trim)
        else:
            x = -.46 if kind == 'floor_end_reverse' else .46
            box('EndPlate', (x, -.20, -.42), (.08, .4, .16), trim)
    elif kind.startswith('rail_'):
        def beam(name, a, b):
            for height in (.32, .64):
                center = ((a[0] + b[0]) / 2, height, (a[1] + b[1]) / 2)
                size = (abs(a[0] - b[0]) or .06, .055, abs(a[1] - b[1]) or .06)
                box(name, center, size, trim)
        def post(x, z):
            box('Post', (x, .32, z), (.08, .64, .08), steel)
            box('Foot', (x, .025, z), (.14, .05, .14), steel)
        if kind == 'rail_straight':
            beam('Rail', (-.5, -.43), (.5, -.43))
            post(0, -.43)
            ports = [[-.5, .64, -.43], [.5, .64, -.43]]
        elif kind == 'rail_corner':
            beam('NorthRail', (-.5, -.43), (.43, -.43))
            beam('EastRail', (.43, -.43), (.43, .5))
            post(.43, -.43)
            ports = [[-.5, .64, -.43], [.43, .64, .5]]
        elif kind == 'rail_end_reverse':
            beam('ReverseEndRail', (0, -.43), (.5, -.43))
            post(0, -.43)
            ports = [[.5, .64, -.43]]
        else:
            beam('EndRail', (-.5, -.43), (0, -.43))
            post(0, -.43)
            ports = [[-.5, .64, -.43]]
    elif kind.startswith('wall_low_'):
        # Low architectural boundary for cells that are already blocked by the
        # puzzle map. It deliberately stays below Kiro/Core silhouette height.
        def wall_segment(name, center, size):
            box(name, center, size, steel)
            box(name + 'Cap', (center[0], .355, center[2]),
                (size[0], .025, size[2]), trim)
        if kind == 'wall_low_straight':
            wall_segment('LowWall', (0, .175, 0), (.96, .35, .18))
            box('Inset', (0, .20, -.096), (.62, .055, .012), glow)
            ports = [[-.5, .175, 0], [.5, .175, 0]]
        elif kind == 'wall_low_corner':
            wall_segment('WestEast', (-.04, .175, 0), (.88, .35, .18))
            wall_segment('NorthSouth', (.35, .175, .04), (.18, .35, .88))
            box('CornerAccent', (.35, .20, -.10), (.055, .055, .22), glow)
            ports = [[-.5, .175, 0], [.35, .175, .5]]
        else:
            wall_segment('LowWallEnd', (-.24, .175, 0), (.48, .35, .18))
            box('EndCap', (0, .175, 0), (.06, .35, .24), trim)
            ports = [[-.5, .175, 0]]
    elif kind.startswith('pipe_'):
        west, east, south = (-.5, .22, 0), (.5, .22, 0), (0, .22, .5)
        if kind == 'pipe_straight':
            tube('Pipe', [west, east], pipe)
            ports = [west, east]
        elif kind == 'pipe_elbow':
            path = [west, (-.16, .22, 0)]
            for i in range(1, 7):
                angle = -math.pi / 2 + i * math.pi / 12
                path.append((-.16 + .16 * math.cos(angle), .22, .16 + .16 * math.sin(angle)))
            path.append(south)
            tube('Elbow', path, pipe)
            ports = [west, south]
        elif kind == 'pipe_tee':
            tube('ThroughPipe', [west, east], pipe)
            tube('Branch', [(0, .22, 0), south], pipe)
            cylinder('Joint', (0, .10, 0), (0, .34, 0), .135, trim)
            ports = [west, east, south]
        else:
            tube('EndPipe', [west, (0, .22, 0)], pipe)
            cylinder('Cap', (-.015, .22, 0), (.035, .22, 0), .12, trim)
            ports = [west]
        for p in ports:
            direction = Vector((p[0], 0, p[2])).normalized()
            a, b = Vector(p) - direction * .10, Vector(p) - direction * .04
            cylinder('Coupling', a, b, .13, trim)
        box('Mount', (-.25, .05, 0), (.12, .1, .22), steel)
    else:
        # An opaque shallow-water overlay, with no refraction or transparency.
        # Bottom at floor plane; water sits above it so existing floor cannot hide it.
        box('Bed', (0, .025, 0), (1, .05, 1), stone)
        def pool(cx, cz, sx, sz):
            box('Water', (cx, .065, cz), (sx, .02, sz), water)
        def bank(cx, cz, sx, sz):
            box('Bank', (cx, .10, cz), (sx, .20, sz), stone)
            box('BankCap', (cx, .21, cz), (sx, .02, sz), trim)
        if kind == 'water_tile':
            pool(0, 0, 1, 1)
        elif kind == 'water_edge':
            bank(0, -.42, 1, .16)
            pool(0, .08, 1, .84)
        elif kind == 'water_corner':
            bank(-.08, -.42, .84, .16)
            bank(.42, 0, .16, 1)
            pool(-.08, .08, .84, .84)
        else:
            bank(.42, -.42, .16, .16)
            pool(-.08, 0, .84, 1)
            pool(.42, .08, .16, .84)
        for x, z, width in [(-.15, .13, .28), (.12, .30, .18)]:
            box('WaterRipple', (x, .077, z), (width, .003, .012), glow)
    return [list(p) for p in ports]


def main():
    root = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
    output = root / 'assets/models/modular'
    output.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mats = [material('Kit Steel', (.09, .14, .18), .65),
            material('Kit Trim', (.32, .44, .49), .45),
            material('Foundry Copper', (.38, .18, .07), .65),
            material('Sanctuary Stone', (.18, .27, .25)),
            material('Sanctuary Water', (.015, .25, .31), .2, .25),
            material('Kit Accent', (.06, .65, .68), emission=.6)]
    kinds = ['floor_edge', 'floor_corner', 'floor_inner_corner', 'floor_end', 'floor_end_reverse',
             'rail_straight', 'rail_corner', 'rail_end', 'rail_end_reverse',
             'wall_low_straight', 'wall_low_corner', 'wall_low_end',
             'pipe_straight', 'pipe_elbow', 'pipe_tee', 'pipe_end',
             'water_tile', 'water_edge', 'water_corner', 'water_inner_corner']
    report = []
    for kind in kinds:
        for obj in list(bpy.data.objects):
            bpy.data.objects.remove(obj, do_unlink=True)
        ports = build(kind, mats)
        meshes = list(bpy.context.scene.objects)
        bpy.ops.object.select_all(action='SELECT')
        bpy.ops.export_scene.gltf(filepath=str(output / f'{kind}.glb'),
                                  export_format='GLB', use_selection=True, export_apply=True)
        vertices = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
        game_vertices = [(v.x / 2, v.z / 2, -v.y / 2) for v in vertices]
        low = [round(min(v[i] for v in game_vertices), 5) for i in range(3)]
        high = [round(max(v[i] for v in game_vertices), 5) for i in range(3)]
        for obj in meshes:
            obj.data.calc_loop_triangles()
        report.append({'type': 'kit_' + kind, 'path': f'assets/models/modular/{kind}.glb',
                       'bounds_min': low, 'bounds_max': high, 'ports': ports,
                       'triangles': sum(len(o.data.loop_triangles) for o in meshes),
                       'source': 'tools/build_modular_kit.py', 'gameplay_collision': False})
    (root / 'docs/MODULAR_KIT_BOUNDS.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(f'BUILT {len(kinds)} modular assets')


if __name__ == '__main__':
    main()
