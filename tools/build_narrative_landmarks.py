"""Build five distinct story fixtures, without changing gameplay type IDs.

Run with Blender --background --python tools/build_narrative_landmarks.py -- <root>.
Coordinates are game units; GLBs use the existing 2x authoring convention.
"""
import json
import sys
from pathlib import Path
import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_chapter_identity_props import box, cylinder_between, material


def build(kind, steel, dark, cyan, amber, stone):
    # A full base fixes the center and confines every fixture to one blocked cell.
    box('Base', (0, .04, 0), (.82, .08, .82), dark)
    if kind == 'silence_reliquary':
        # Two separated bus bars and an open isolation blade: the cut in the grid.
        for x in (-.22, .22):
            box('BusBar', (x, .20, 0), (.12, .24, .55), steel)
        box('DisconnectedBlade', (-.15, .39, 0), (.10, .14, .44), amber)
        box('IsolationHousing', (0, .13, .28), (.66, .10, .10), stone)
    elif kind == 'elias_testament':
        # A sealed archive cassette in an asymmetric reader, not a projector.
        box('Reader', (0, .17, .06), (.62, .18, .52), steel)
        box('Cassette', (0, .33, .02), (.34, .14, .32), dark)
        box('Seal', (0, .415, .02), (.08, .03, .24), amber)
        box('Readout', (0, .22, -.22), (.42, .05, .035), cyan)
    elif kind == 'soul_archive':
        # Three separately housed records preserve the idea of individuals.
        for x in (-.25, 0, .25):
            box('RecordHousing', (x, .30, .03), (.18, .44, .38), steel)
            box('RecordWindow', (x, .32, -.17), (.09, .27, .025), cyan)
        box('Header', (0, .54, .03), (.74, .04, .42), dark)
    elif kind == 'eva_conduit':
        # An open projection cradle with four feed terminals for four story beats.
        cylinder_between('ProjectionWell', (0, .08, 0), (0, .22, 0), .23, steel, 16)
        cylinder_between('Lens', (0, .22, 0), (0, .24, 0), .15, cyan, 16)
        for x in (-.30, .30):
            for z in (-.30, .30):
                box('FeedTerminal', (x, .18, z), (.12, .20, .12), steel)
    elif kind == 'judgement_engine':
        # Neutral handover desk, with three unlit outlets rather than a chosen ending.
        box('Desk', (0, .22, .04), (.74, .28, .55), steel)
        for x in (-.24, 0, .24):
            box('Outlet', (x, .39, .04), (.16, .06, .32), dark)
        box('HandoverLine', (0, .27, -.25), (.54, .025, .02), amber)
    else:
        raise ValueError(kind)


def main():
    root = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mats = [material('Narrative Steel', (.21,.29,.32), .45),
            material('Narrative Dark', (.055,.075,.09)),
            material('Record Cyan', (.08,.44,.48), emission=.3),
            material('Seal Amber', (.46,.25,.07), emission=.15),
            material('Isolation Stone', (.25,.29,.27))]
    report = []
    for kind in ('silence_reliquary','elias_testament','soul_archive','eva_conduit','judgement_engine'):
        for obj in list(bpy.data.objects):
            bpy.data.objects.remove(obj, do_unlink=True)
        build(kind, *mats)
        meshes = list(bpy.context.scene.objects)
        bpy.ops.object.select_all(action='SELECT')
        path = root / 'assets/models/baked' / f'Narrative-{kind}.glb'
        bpy.ops.export_scene.gltf(filepath=str(path), export_format='GLB', use_selection=True, export_apply=True)
        vertices = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
        game = [(v.x / 2, v.z / 2, -v.y / 2) for v in vertices]
        for obj in meshes:
            obj.data.calc_loop_triangles()
        report.append({'type':kind, 'path':path.relative_to(root).as_posix(),
                       'bounds_min':[round(min(v[i] for v in game),5) for i in range(3)],
                       'bounds_max':[round(max(v[i] for v in game),5) for i in range(3)],
                       'triangles':sum(len(o.data.loop_triangles) for o in meshes),
                       'gameplay_collision':False})
    (root / 'docs/NARRATIVE_LANDMARK_BOUNDS.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    print('Built five narrative landmarks')


if __name__ == '__main__':
    main()
