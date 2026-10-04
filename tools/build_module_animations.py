"""Author Blender idle clips on existing module GLBs without moving their roots.

blender --background --python tools/build_module_animations.py -- <project-root>
Original GLBs and editable .blend sources live under art/animated_modules.
Run this after the static asset generators when rebuilding the asset library.
"""
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

ASSETS = {
    'Conveyor': ('rollers',),
    'Foundry-Press': ('piston',),
    'Foundry-Gear': ('gear',),
    'Machine-Unit': ('exhaust',),
    'Hologram-Projector': ('hologram',),
    'Archive-Holo-Projector': ('archive_hologram',),
    'Core-Reactor': ('reactor',),
    'Core-Generator': ('generator',),
    'Core-Hologram-Dais': ('dais',),
    'Plant-Cluster': ('plant',),
    'Sanctuary-Tree': ('tree',),
    'Sanctuary-Vine-Arch': ('vine',),
    'Sanctuary-Shrine': ('shrine',),
    'Energy-Core': ('core',),
    'Core-Pedestal': ('pedestal',),
    'Terminal': ('terminal',),
    'Pressure-Plate': ('plate',),
    'gameplay/Core/Memory-Fragment': ('fragment',),
}


def bounds(objects):
    points = [obj.matrix_world @ Vector(corner) for obj in objects for corner in obj.bound_box]
    return (Vector([min(p[i] for p in points) for i in range(3)]),
            Vector([max(p[i] for p in points) for i in range(3)]))


def group(name, objects, pivot=None):
    if not objects:
        raise RuntimeError('No meshes for ' + name)
    lo, hi = bounds(objects)
    node = bpy.data.objects.new('Motion_' + name, None)
    bpy.context.collection.objects.link(node)
    parents = {obj.parent for obj in objects}
    if len(parents) == 1:
        node.parent = next(iter(parents))
    node.matrix_world.translation = (lo + hi) / 2 if pivot is None else pivot
    bpy.context.view_layer.update()
    for obj in objects:
        matrix = obj.matrix_world.copy()
        obj.parent = node
        obj.matrix_world = matrix
    return node


def spin(name, objects, turns=1, axis=None):
    lo, hi = bounds(objects)
    if axis is None:
        axis = min(range(3), key=lambda i: (hi - lo)[i])
    node = group(name, objects)
    node.rotation_mode = 'XYZ'
    for frame, amount in ((1, 0), (241, turns * math.tau)):
        node.rotation_euler[axis] = amount
        node.keyframe_insert('rotation_euler', frame=frame)
    return node


def oscillate(name, objects, amplitude, mode='location', axis=2, top_pivot=False):
    lo, hi = bounds(objects)
    pivot = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, hi.z if top_pivot else lo.z))
    node = group(name, objects, pivot)
    base = getattr(node, mode).copy()
    for frame, amount in ((1, 0), (61, 1), (121, 0), (181, -1), (241, 0)):
        value = base.copy()
        value[axis] += amount * amplitude
        setattr(node, mode, value)
        node.keyframe_insert(mode, frame=frame)
    return node


def animate(kind, meshes):
    def match(*prefixes):
        return [obj for obj in meshes if any(obj.name.startswith(prefix) for prefix in prefixes)]
    if kind == 'rollers':
        for obj in match('Conveyor_Roller'):
            spin(obj.name, [obj], 4, 1)
    elif kind == 'piston':
        oscillate('PressStroke', match('Press_Piston'), .18)
    elif kind == 'gear':
        spin('DriveGear', match('Drive_Gear'), .5, 2)
    elif kind == 'exhaust':
        oscillate('ExhaustPressure', match('Machine_ExhaustCap'), .012)
    elif kind == 'hologram':
        spin('HologramOrbit', match('Holo_Orbit'), 1, 2)
        oscillate('HologramGlyph', match('Holo_Glyph'), .045)
    elif kind == 'archive_hologram':
        spin('ArchiveProjection', match('Hologram_Ring'), 1, 2)
    elif kind == 'reactor':
        oscillate('ReactorSuspension', match('Central_Core.001'), .045)
        spin('ReactorCrystal', match('Central_Core.001'), .5, 2)
    elif kind == 'generator':
        spin('GeneratorRotor', match('Generator_Core'), 1, 2)
    elif kind == 'dais':
        oscillate('HologramFloat', match('Core_Hologram'), .045)
        spin('HologramTurn', match('Core_Hologram'), .5, 2)
    elif kind == 'plant':
        oscillate('VegetationWind', match('Plant_'), .018, 'rotation_euler', 1)
    elif kind == 'tree':
        oscillate('CanopyWind', match('Tree_Canopy'), .012, 'rotation_euler', 1)
    elif kind == 'vine':
        targets = match('Vine_', 'Hanging_Vine', 'Arch_Vine')
        if not targets:
            targets = [obj for obj in meshes if 'vine' in obj.name.lower() and 'arch' not in obj.name.lower()]
        oscillate('HangingVines', targets, .015, 'rotation_euler', 1, True)
    elif kind == 'shrine':
        spin('ShrineResonance', match('Shrine_Crystal'), .5, 2)
    elif kind == 'core':
        for prefix, turns in [('EnergyCore_Ring_X', 1), ('EnergyCore_Ring_Z', -1)]:
            spin(prefix, match(prefix), turns)
    elif kind == 'pedestal':
        spin('PedestalResonance', match('Pedestal_GlowRing'), 1, 2)
    elif kind == 'terminal':
        oscillate('TerminalScan', match('Terminal_Scan'), .025, 'location', 2)
    elif kind == 'fragment':
        spin('MemoryOrbit', match('MemoryShard_Ring'), 1)
        oscillate('MemorySuspension', match('MemoryShard_Inner'), .035)
    elif kind == 'plate':
        node = group('PlateCompression', match('Plate_Top', 'Plate_GlowBar'))
        base = node.location.copy()
        for frame, offset in ((1, 0), (5, -.08)):
            node.location = base + Vector((0, 0, offset))
            node.keyframe_insert('location', frame=frame)
    bpy.context.scene.frame_set(1)


def build_gallery(source, report):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.name = 'Animated_Module_Gallery'
    scene.frame_start, scene.frame_end = 1, 241
    scene.render.fps = 30
    for index, entry in enumerate(report):
        blend = source.parent.parent / entry['source']
        with bpy.data.libraries.load(str(blend), link=False) as (available, loaded):
            loaded.objects = list(available.objects)
        objects = [obj for obj in loaded.objects if obj is not None]
        collection = bpy.data.collections.new('ANIM_' + Path(entry['path']).stem)
        scene.collection.children.link(collection)
        display = bpy.data.objects.new('Module_' + Path(entry['path']).stem, None)
        collection.objects.link(display)
        for obj in objects:
            collection.objects.link(obj)
        bpy.context.view_layer.update()
        for obj in objects:
            if obj.parent is None:
                matrix = obj.matrix_world.copy()
                obj.parent = display
                obj.matrix_world = matrix
        display.location = Vector(((index % 5) * 5.5, -(index // 5) * 5, 0))
    scene.frame_set(1)
    bpy.ops.object.camera_add(location=(33, -36, 32))
    camera = bpy.context.object
    camera.rotation_euler = (Vector((11, -7.5, 1)) - camera.location).to_track_quat('-Z', 'Y').to_euler()
    camera.data.type = 'ORTHO'
    camera.data.ortho_scale = 34
    scene.camera = camera
    bpy.ops.object.light_add(type='AREA', location=(10, -5, 25))
    light = bpy.context.object
    light.data.energy = 2500
    light.data.size = 16
    scene.render.resolution_x, scene.render.resolution_y = 1600, 1000
    scene.render.resolution_percentage = 100
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == 'VIEW_3D':
                area.spaces.active.region_3d.view_perspective = 'CAMERA'
                area.spaces.active.shading.type = 'MATERIAL'
    bpy.ops.object.select_all(action='DESELECT')
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(source / 'Animated_Module_Gallery.blend'))


def main():
    root = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
    source = root / 'art/animated_modules'
    source.mkdir(parents=True, exist_ok=True)
    (source / '.gdignore').write_text('', encoding='utf-8')
    if '--gallery-only' in sys.argv:
        report = json.loads((root / 'docs/MODULE_ANIMATIONS.json').read_text(encoding='utf-8'))
        build_gallery(source, report)
        return
    report = []
    for name, modes in ASSETS.items():
        relative = Path('assets/models') / (name + '.glb') if name.startswith('gameplay/') else Path('assets/models/baked') / (name + '.glb')
        path = root / relative
        original = source / 'originals' / relative
        original.parent.mkdir(parents=True, exist_ok=True)
        if not original.exists():
            original.write_bytes(path.read_bytes())
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.gltf(filepath=str(original))
        meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
        lo, hi = bounds(meshes)
        scene = bpy.context.scene
        scene.name = 'Idle'
        scene.render.fps = 30
        scene.frame_start, scene.frame_end = 1, 241
        for mode in modes:
            animate(mode, meshes)
        if modes == ('plate',):
            scene.name = 'Press'
            scene.frame_end = 5
        scene.frame_set(1)
        # Linear rotation keeps belts steady. Smooth curves give piston/wind a soft return.
        for obj in scene.objects:
            if obj.animation_data and obj.animation_data.action:
                action = obj.animation_data.action
                for layer in action.layers:
                    for strip in layer.strips:
                        for bag in strip.channelbags:
                            for curve in bag.fcurves:
                                if len(curve.keyframe_points) == 2:
                                    for key in curve.keyframe_points:
                                        key.interpolation = 'LINEAR'
        source_path = source / (name.replace('/', '_') + '.blend')
        bpy.context.preferences.filepaths.save_version = 0
        bpy.ops.wm.save_as_mainfile(filepath=str(source_path))
        bpy.ops.object.select_all(action='SELECT')
        bpy.ops.export_scene.gltf(filepath=str(path), export_format='GLB', use_selection=True,
                                  export_animations=True, export_animation_mode='SCENE',
                                  export_anim_scene_split_object=False, export_frame_range=True,
                                  export_force_sampling=True, export_apply=False)
        report.append({'path': relative.as_posix(), 'source': source_path.relative_to(root).as_posix(),
                       'clip': scene.name, 'duration': (scene.frame_end - scene.frame_start) / scene.render.fps, 'modes': list(modes),
                       'bounds_blender_min': list(lo), 'bounds_blender_max': list(hi),
                       'animated_parts': [obj.name for obj in scene.objects if obj.animation_data]})
    (root / 'docs/MODULE_ANIMATIONS.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    build_gallery(source, report)
    print(f'AUTHORED {len(report)} animated modules')


if __name__ == '__main__':
    main()
