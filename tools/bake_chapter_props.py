"""Blender: --background --python tools/bake_chapter_props.py -- <project-root>.

Extract 15 scenery assemblies from existing chapter rosters, preserving materials.
Only writes the new chapter GLBs and their measured bounds report.
"""
import json
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

GROUPS = {
    'Mechanical_Foundry': {
        'Foundry-Furnace': ['Furnace_'],
        'Foundry-Press': ['Machine_Press_', 'Press_'],
        'Foundry-Gear': ['Drive_Gear_', 'Gear_Axle'],
        'Foundry-Pipe-Valve': ['Pipe_'],
        'Foundry-Lamp': ['Factory_Light', 'Light_Stand'],
    },
    'Flooded_Sanctuary': {
        'Sanctuary-Pool': ['Water_Basin', 'Sacred_Water', 'Water_Orb'],
        'Sanctuary-Shrine': ['Broken_Shrine_', 'Shrine_'],
        'Sanctuary-Tree': ['Ancient_Tree_', 'Tree_Canopy'],
        'Sanctuary-Vine-Arch': ['Vine_Arch_', 'Hanging_Vine'],
        'Sanctuary-Rocks': ['Rock_'],
    },
    'Central_Core': {
        'Core-Reactor': ['Central_Core', 'Core_Pylon_'],
        'Core-Generator': ['Energy_Generator', 'Generator_'],
        'Core-Wall': ['HighTech_Wall', 'Wall_Energy_Line'],
        'Core-Hologram-Dais': ['Hologram_Dais', 'Core_Hologram'],
        'Core-Portal-Frame': ['Portal_'],
    },
}


def main():
    root = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
    output = root / 'assets/models/baked'
    output.mkdir(parents=True, exist_ok=True)
    report = []
    for chapter, groups in GROUPS.items():
        source = root / f'assets/models/environments/chapters/{chapter}/{chapter}_Asset_Roster.glb'
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.gltf(filepath=str(source))
        for name, prefixes in groups.items():
            meshes = [o for o in bpy.data.objects if o.type == 'MESH'
                      and any(o.name.startswith(p) for p in prefixes)]
            if not meshes:
                raise RuntimeError(f'No meshes for {name}')
            vertices = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
            low = Vector(tuple(min(v[i] for v in vertices) for i in range(3)))
            high = Vector(tuple(max(v[i] for v in vertices) for i in range(3)))
            shift = Matrix.Translation(Vector((-(low.x + high.x) / 2,
                                               -(low.y + high.y) / 2, -low.z)))
            # Export detached copies so parent transforms cannot shift the pivot
            # and presentation nodes never become part of the exported assembly.
            copies = []
            bpy.ops.object.select_all(action='DESELECT')
            for original in meshes:
                copy = original.copy()
                copy.data = original.data.copy()
                copy.parent = None
                bpy.context.collection.objects.link(copy)
                copy.matrix_world = shift @ original.matrix_world
                copy.select_set(True)
                copies.append(copy)
            bpy.context.view_layer.objects.active = copies[0]
            bpy.ops.export_scene.gltf(filepath=str(output / f'{name}.glb'),
                                      export_format='GLB', use_selection=True, export_apply=True)
            triangles = 0
            for copy in copies:
                copy.data.calc_loop_triangles()
                triangles += len(copy.data.loop_triangles)
            size = high - low
            report.append({'name': name, 'chapter': chapter,
                           'source': source.relative_to(root).as_posix(),
                           'source_meshes': [o.name for o in meshes],
                           'triangles': triangles,
                           'game_size_xyz': [round(size.x * .5, 4), round(size.z * .5, 4), round(size.y * .5, 4)]})
            for copy in copies:
                bpy.data.objects.remove(copy, do_unlink=True)
    (root / 'docs/CHAPTER_PROPS_BOUNDS.json').write_text(
        json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(f'BAKED {len(report)} chapter props')


main()
