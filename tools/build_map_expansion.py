"""Build 13 map assets, a separate Blender gallery and a rendered preview.

blender --background --python tools/build_map_expansion.py -- <project-root>
Game coordinates are Y-up; exported meshes use the existing 2x authoring grid.
"""
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).parent))
from build_modular_kit import box, cylinder, material, point


CHAPTERS = {
    'archive': ((.14, .21, .29), (.33, .43, .51), (.045, .065, .08), (.17, .42, .48)),
    'foundry': ((.19, .12, .085), (.40, .27, .15), (.055, .04, .03), (.48, .21, .075)),
    'sanctuary': ((.20, .29, .27), (.42, .50, .44), (.065, .13, .12), (.18, .30, .09)),
    'core': ((.085, .14, .21), (.33, .45, .53), (.025, .045, .07), (.12, .47, .53)),
}
KINDS = ['energy_node'] + [f'{chapter}_{piece}' for chapter in CHAPTERS
                          for piece in ('floor_variant', 'wall_variant')] + [
    'elevator_support_column', 'elevator_support_brace',
    'elevator_deck_fascia', 'elevator_threshold']


def line(name, a, b, width, height, mat):
    dx, dz = b[0] - a[0], b[2] - a[2]
    obj = box(name, tuple((a[i] + b[i]) / 2 for i in range(3)),
              (math.hypot(dx, dz), height, width), mat)
    obj.rotation_euler.z = -math.atan2(dz, dx)
    return obj


def ring(name, radius, tube, y, mat):
    bpy.ops.mesh.primitive_torus_add(major_segments=32, minor_segments=6,
                                   major_radius=radius * 2, minor_radius=tube * 2,
                                   location=point(0, y, 0))
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)


def patch(name, outline, y, mat):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata([point(x, y, z) for x, z in outline], [],
                    [tuple(reversed(range(len(outline))))])
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)


def bolts(mat, y, z=.37):
    for x in (-.37, .37):
        for depth in (-z, z):
            cylinder('Fastener', (x, y, depth), (x, y + .007, depth), .018, mat, 8)


def build(kind, mats):
    base, trim, recess, accent = mats
    if kind == 'energy_node':
        cylinder('NodeHousing', (0, 0, 0), (0, .055, 0), .36, base, 32)
        cylinder('NodeInset', (0, .055, 0), (0, .065, 0), .285, recess, 32)
        ring('NodeRim', .31, .018, .071, trim)
        cylinder('NodeLens', (0, .065, 0), (0, .088, 0), .245, accent, 32)
        for i in range(4):
            angle = i * math.pi / 2
            x, z = math.cos(angle) * .31, math.sin(angle) * .31
            cylinder('NodeBolt', (x, .083, z), (x, .098, z), .022, recess, 8)
        return
    if 'floor_variant' in kind:
        chapter = kind.split('_')[0]
        box('FloorBacking', (0, .008, 0), (.98, .016, .98), recess)
        for x in (-.245, .245):
            for z in (-.245, .245):
                box('SurfacePanel', (x, .018, z), (.474, .02, .474), base)
        if chapter == 'archive':
            crack = [(-.43, .03, -.30), (-.16, .03, -.12), (.02, .03, -.18),
                     (.16, .03, .07), (.40, .03, .17)]
            for a, b in zip(crack, crack[1:]):
                line('Fracture', a, b, .013, .002, recess)
            line('FractureBranch', crack[2], (-.03, .03, .18), .011, .002, recess)
            box('RepairStaple', (-.22, .036, -.15), (.10, .012, .025), trim)
            box('RepairStaple', (.13, .036, .02), (.10, .012, .025), trim)
        elif chapter == 'foundry':
            patch('OxidizedCorner', [(-.46, -.46), (-.13, -.46), (-.19, -.32),
                                     (-.34, -.23), (-.46, -.28)], .029, accent)
            patch('RustStain', [(.12, .18), (.46, .10), (.46, .46), (.26, .46)], .029, accent)
            for z in (-.12, 0, .12):
                line('GripRib', (-.37, .034, z), (.37, .034, z), .025, .012, trim)
            bolts(recess, .03)
        elif chapter == 'sanctuary':
            patch('MossBank', [(-.47, -.47), (-.04, -.47), (-.10, -.36),
                                (-.30, -.26), (-.47, -.20)], .031, accent)
            patch('MossBank', [(.26, .28), (.47, .16), (.47, .47), (.12, .47)], .031, accent)
            patch('DampStone', [(-.23, -.09), (.04, -.17), (.25, .06), (.10, .20),
                                (-.20, .13)], .029, trim)
            line('StoneCrack', (-.32, .032, .30), (.03, .032, .19), .012, .002, recess)
        else:
            box('CenterRecess', (0, .03, 0), (.20, .004, .64), recess)
            for x in (-.08, .08):
                box('ConductiveTrace', (x, .034, 0), (.018, .004, .52), accent)
            box('TraceCross', (0, .034, .18), (.54, .004, .018), accent)
            bolts(trim, .029)
        return
    if 'wall_variant' in kind:
        chapter = kind.split('_')[0]
        box('WallBody', (0, .16, 0), (.96, .32, .18), base)
        box('WallFoot', (0, .025, 0), (.98, .05, .22), recess)
        for x in (-.35, 0, .35):
            box('CapSegment', (x, .34, 0), (.28, .04, .22), trim)
        for side in (-1, 1):
            z = side * .094
            box('PanelRecess', (0, .17, z), (.80, .16, .014), recess)
            box('InsetPanel', (0, .18, z + side * .009), (.73, .12, .012), base)
            if chapter == 'archive':
                for x, height in ((-.22, .08), (-.05, .05), (.10, .025)):
                    box('CrackedInset', (x, .20, z + side * .017), (.018, height, .004), recess)
                box('RepairPlate', (.28, .19, z + side * .02), (.12, .08, .025), trim)
            elif chapter == 'foundry':
                for x in (-.28, .04, .24):
                    box('RustRun', (x, .15, z + side * .017), (.055, .15, .004), accent)
                box('ServiceStrip', (0, .27, z + side * .018), (.76, .025, .016), trim)
            elif chapter == 'sanctuary':
                for x, height in ((-.31, .12), (-.20, .19), (.27, .09)):
                    box('MossGrowth', (x, height / 2 + .04, z + side * .018), (.09, height, .008), accent)
            else:
                box('Conduit', (0, .18, z + side * .018), (.62, .025, .006), accent)
                for x in (-.33, .33):
                    box('ConduitSocket', (x, .18, z + side * .02), (.055, .075, .016), trim)
        return
    if kind == 'elevator_support_column':
        box('FootPlate', (0, .035, 0), (.32, .07, .32), trim)
        box('SupportWeb', (0, .575, 0), (.12, 1.01, .12), base)
        for z in (-.075, .075):
            box('Flange', (0, .575, z), (.24, 1.01, .045), trim)
        box('TopPlate', (0, 1.105, 0), (.32, .07, .32), trim)
        box('ColumnInset', (0, .58, -.102), (.08, .66, .01), recess)
    elif kind == 'elevator_support_brace':
        for x in (-.44, .44):
            box('FramePost', (x, .57, 0), (.12, 1.14, .14), base)
        for y in (.035, 1.105):
            box('FrameBeam', (0, y, 0), (1, .07, .18), trim)
        for sign in (-1, 1):
            cylinder('CrossBrace', (-.40, .14 if sign == 1 else 1.01, 0),
                     (.40, 1.01 if sign == 1 else .14, 0), .025, trim, 8)
        box('BraceHub', (0, .575, -.035), (.15, .15, .035), recess)
    elif kind == 'elevator_deck_fascia':
        box('DeckFascia', (0, -.10, -.456), (1, .20, .10), base)
        box('FasciaCap', (0, -.026, -.456), (1, .04, .10), trim)
        box('FasciaInset', (0, -.105, -.504), (.76, .06, .008), recess)
        for x in (-.28, .28):
            box('FasciaFastener', (x, -.10, -.512), (.035, .035, .008), trim)
    else:
        box('ThresholdBase', (0, .008, -.40), (.80, .016, .18), base)
        for x in (-.33, -.22, -.11, 0, .11, .22, .33):
            box('ThresholdGrip', (x, .019, -.40), (.055, .006, .13), trim)
        box('ThresholdMarker', (0, .023, -.475), (.46, .004, .012), accent)


def consolidate(kind):
    meshes = list(bpy.context.scene.objects)
    # Keep the NodeLens addressable for the game's live energy material.
    groups = {}
    for obj in meshes:
        key = 'NodeLens' if obj.name.startswith('NodeLens') else 'Housing'
        groups.setdefault(key, []).append(obj)
    for name, objects in groups.items():
        bpy.ops.object.select_all(action='DESELECT')
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        bpy.ops.object.join()
        obj = bpy.context.object
        obj.name = 'NodeLens' if name == 'NodeLens' else kind
        bpy.context.scene.cursor.location = (0, 0, 0)
        bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return list(bpy.context.scene.objects)


def main():
    root = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
    output = root / 'assets/models/map_expansion'
    output.mkdir(parents=True, exist_ok=True)
    source = root / 'art/map_expansion'
    source.mkdir(parents=True, exist_ok=True)
    (source / '.gdignore').write_text('', encoding='utf-8')
    bpy.ops.wm.read_factory_settings(use_empty=True)
    palettes = {name: [material(f'Expansion {name} {role}', color, .5 if name in ('core', 'foundry') else .1,
                                .85 if name == 'sanctuary' else .65,
                                .18 if name == 'core' and role == 'Accent' else 0)
                       for role, color in zip(('Base', 'Trim', 'Recess', 'Accent'), colors)]
                for name, colors in CHAPTERS.items()}
    report = []
    gallery = []
    for kind in KINDS:
        for obj in list(bpy.context.scene.objects):
            bpy.data.objects.remove(obj, do_unlink=True)
        chapter = kind.split('_')[0]
        mats = palettes.get(chapter, palettes['core'])
        build(kind, mats)
        meshes = consolidate(kind)
        bpy.ops.object.select_all(action='SELECT')
        bpy.ops.export_scene.gltf(filepath=str(output / f'{kind}.glb'), export_format='GLB',
                                  use_selection=True, export_apply=True)
        verts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
        game = [(v.x / 2, v.z / 2, -v.y / 2) for v in verts]
        for obj in meshes:
            obj.data.calc_loop_triangles()
        triangles = sum(len(obj.data.loop_triangles) for obj in meshes)
        assert triangles <= 1500, (kind, triangles)
        report.append({'type': kind, 'path': f'assets/models/map_expansion/{kind}.glb',
                       'bounds_min': [round(min(v[i] for v in game), 6) for i in range(3)],
                       'bounds_max': [round(max(v[i] for v in game), 6) for i in range(3)],
                       'triangles': triangles,
                       'surfaces': sum(len(obj.data.materials) for obj in meshes),
                       'source': 'tools/build_map_expansion.py', 'gameplay_collision': False})
        gallery.append((kind, [(obj.data.copy(), obj.name) for obj in meshes]))
    for obj in list(bpy.context.scene.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    # Four little rooms expose floor tiling and both faces of the wall variants.
    positions = {'archive': (-3.2, 0, -2.2), 'foundry': (.7, 0, -2.2),
                 'sanctuary': (-3.2, 0, 1.7), 'core': (.7, 0, 1.7)}
    for kind, mesh_data in gallery:
        collection = bpy.data.collections.new('EXP_' + kind)
        bpy.context.scene.collection.children.link(collection)
        if kind.endswith('floor_variant'):
            origin = positions[kind.split('_')[0]]
            centers = [(origin[0] + x, 0, origin[2] + z) for z in range(3) for x in range(3)]
        elif kind.endswith('wall_variant'):
            origin = positions[kind.split('_')[0]]
            centers = [(origin[0] + x, 0, origin[2] - .40) for x in range(3)]
        else:
            centers = {'energy_node': [(1.7, .038, 2.7)],
                       'elevator_support_column': [(5, 0, -1.8), (6, 0, -1.8), (5, 0, -.8), (6, 0, -.8)],
                       'elevator_support_brace': [(5.5, 0, -.8)],
                       'elevator_deck_fascia': [(5, 1.15, -.8), (6, 1.15, -.8)],
                       'elevator_threshold': [(5.5, 1.15, -.5)]}[kind]
        for index, center in enumerate(centers):
            for mesh, name in mesh_data:
                obj = bpy.data.objects.new(f'{kind}_{index}_{name}', mesh)
                collection.objects.link(obj)
                obj.location = point(*center)
                if kind in ('elevator_deck_fascia', 'elevator_threshold'):
                    obj.rotation_euler.z = math.pi
                if kind.endswith('floor_variant') and index % 2:
                    obj.rotation_euler.z = math.pi / 2
    box('ElevatedDeck', (5.5, 1.04, -1.3), (2, .20, 2), palettes['core'][0])
    box('ElevatedDeckSurface', (5.5, 1.145, -1.3), (2, .01, 2), palettes['core'][1])
    for chapter, origin in positions.items():
        box('RoomBase_' + chapter, (origin[0] + 1, -.075, origin[2] + 1),
            (3.1, .15, 3.1), palettes[chapter][2])
    scene = bpy.context.scene
    scene.name = 'Map_Expansion_Gallery'
    scene.world = bpy.data.worlds.new('Expansion World')
    scene.world.use_nodes = True
    scene.world.node_tree.nodes['Background'].inputs[0].default_value = (.07, .095, .13, 1)
    scene.world.node_tree.nodes['Background'].inputs[1].default_value = .5
    bpy.ops.object.light_add(type='AREA', location=point(1, 10, 2))
    light = bpy.context.object
    light.data.energy = 2400
    light.data.shape = 'DISK'
    light.data.size = 14
    bpy.ops.object.camera_add(location=point(13, 15, 18))
    camera = bpy.context.object
    target = point(1.9, .15, 1.1)
    camera.rotation_euler = (target - camera.location).to_track_quat('-Z', 'Y').to_euler()
    camera.data.type = 'ORTHO'
    camera.data.ortho_scale = 26
    scene.camera = camera
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 24
    scene.render.threads_mode = 'FIXED'
    scene.render.threads = 6
    scene.cycles.use_denoising = True
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 1050
    scene.render.resolution_percentage = 100
    scene.view_settings.view_transform = 'AgX'
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == 'VIEW_3D':
                area.spaces.active.region_3d.view_perspective = 'CAMERA'
                area.spaces.active.shading.type = 'MATERIAL'
    bpy.ops.object.select_all(action='DESELECT')
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(source / 'Map_Expansion_Gallery.blend'))
    (root / 'docs/MAP_EXPANSION_BOUNDS.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    scene.render.filepath = str(root / 'docs/MAP_EXPANSION_PREVIEW.png')
    bpy.ops.render.render(write_still=True)
    print(f'BUILT {len(report)} expansion assets; {sum(item["triangles"] for item in report)} triangles total')


if __name__ == '__main__':
    main()
