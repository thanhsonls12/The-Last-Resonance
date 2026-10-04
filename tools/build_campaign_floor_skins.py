"""Combine the current floor foundation with chapter panels at the old inset height."""
import sys
from pathlib import Path

import bpy


def main():
    root = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
    output = root / 'assets/models/map_surfaces'
    output.mkdir(parents=True, exist_ok=True)
    for chapter in ('archive', 'foundry', 'sanctuary', 'core'):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.gltf(filepath=str(root / 'assets/models/baked/Floor-Tile.glb'))
        foundation = next(obj for obj in bpy.context.scene.objects if obj.name.startswith('FloorTile_StoneSlab'))
        for obj in list(bpy.context.scene.objects):
            if obj != foundation:
                bpy.data.objects.remove(obj, do_unlink=True)
        bpy.ops.import_scene.gltf(filepath=str(root / f'assets/models/map_expansion/{chapter}_floor_variant.glb'))
        panels = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH' and obj != foundation]
        recess = next(mat for obj in panels for mat in obj.data.materials if 'Recess' in mat.name)
        foundation.data.materials.clear()
        foundation.data.materials.append(recess)
        for obj in panels:
            obj.location.z += .2
        bpy.ops.object.select_all(action='DESELECT')
        for obj in [foundation] + panels:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = foundation
        bpy.ops.object.join()
        model = bpy.context.object
        model.name = chapter + '_floor_skin'
        bpy.context.scene.cursor.location = (0, 0, 0)
        bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
        bpy.ops.export_scene.gltf(filepath=str(output / f'{chapter}_floor_variant.glb'),
                                  export_format='GLB', use_selection=True, export_apply=True)
    print('BUILT four complete campaign floor skins')


if __name__ == '__main__':
    main()
