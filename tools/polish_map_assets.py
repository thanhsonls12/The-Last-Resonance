"""Polish gameplay heroes, machinery and chapter landmarks before animation bake."""
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).parent))
from build_modular_kit import box, cylinder, material, point

ASSETS = ['Energy-Core', 'Core-Pedestal', 'Foundry-Furnace', 'Foundry-Press', 'Machine-Unit',
          'Archive-Data-Vault', 'Sanctuary-Shrine', 'Core-Reactor', 'Narrative-judgement_engine']


def bounds(objects):
    vertices = [obj.matrix_world @ vertex.co for obj in objects for vertex in obj.data.vertices]
    return Vector([min(v[i] for v in vertices) for i in range(3)]), Vector([max(v[i] for v in vertices) for i in range(3)])


def game_bounds(objects):
    low, high = bounds(objects)
    return Vector((low.x / 2, low.z / 2, -high.y / 2)), Vector((high.x / 2, high.z / 2, -low.y / 2))


def parent_detail(obj, parent):
    bpy.context.view_layer.update()
    matrix = obj.matrix_world.copy()
    obj.parent = parent
    obj.matrix_world = matrix
    return obj


def detail_box(name, center, size, mat, parent=None):
    obj = box('Detail_' + name, center, size, mat)
    if parent:
        parent_detail(obj, parent)
    return obj


def details(name, meshes, mats):
    steel, dark, copper, rubber = mats
    low, high = game_bounds(meshes)
    center = (low + high) / 2
    width, height, depth = high - low
    def find(prefix):
        return next(obj for obj in meshes if obj.name.startswith(prefix))
    if name == 'Energy-Core':
        facet = find('EnergyCore_Faceted')
        gem = material('Polished Core Crystal', (.035, .19, .24), .22, .26, .30)
        facet.data.materials.clear()
        facet.data.materials.append(gem)
        for x in (-.22, .22):
            detail_box('CoreClamp', (x, center.y, -.29), (.07, .12, .06), steel)
            detail_box('ClampInset', (x, center.y, -.325), (.025, .07, .012), dark)
    elif name == 'Core-Pedestal':
        for angle in range(0, 360, 60):
            x, z = math.cos(math.radians(angle)) * .25, math.sin(math.radians(angle)) * .25
            detail_box('SocketGuide', (x, .16, z), (.045, .07, .045), steel)
        for x in (-.24, .24):
            detail_box('SocketContact', (x, .115, 0), (.06, .025, .18), copper)
    elif name == 'Foundry-Press':
        piston = find('Press_Piston')
        a, b = game_bounds([piston])
        for x in (-width * .23, width * .23):
            cylinder('Detail_GuideRod', (x, low.y + .08, depth*.18), (x, high.y - .09, depth*.18), .023, steel, 10)
        detail_box('PistonCollar', ((a.x+b.x)/2, (a.y+b.y)/2, a.z-.01), ((b.x-a.x)*.75, .045, .025), copper, piston)
        detail_box('PressAnvil', (0, low.y+.045, 0), (width*.48, .09, depth*.65), dark)
    elif name in ('Foundry-Furnace', 'Machine-Unit'):
        body = find('Furnace_Body' if name == 'Foundry-Furnace' else 'Machine_Body')
        body_low, body_high = game_bounds([body])
        front = body_high.z + .006
        for i in range(5):
            detail_box('VentSlot', (-width*.22+i*width*.11, low.y+height*.36, front), (width*.065, height*.18, .022), dark)
        for i in range(4):
            detail_box('SideCoolingSlot', (body_high.x+.001, low.y+height*.42, center.z-depth*.22+i*depth*.14), (.012,height*.24,depth*.07), dark)
        for x in (-width*.36, width*.36):
            for y in (low.y+height*.18, low.y+height*.65):
                detail_box('Rivet', (x, y, front+.006), (.027, .027, .016), steel)
        if name == 'Foundry-Furnace':
            mouth = find('Furnace_Mouth')
            a, b = game_bounds([mouth])
            for x in (a.x+.025, b.x-.025):
                detail_box('HeatShield', (x, (a.y+b.y)/2, b.z+.001), (.035, b.y-a.y, .035), steel)
            detail_box('FurnaceToe', (0, low.y+.035, 0), (width*.92, .07, depth*.90), dark)
        else:
            detail_box('GaugeBezel', (width*.22, low.y+height*.55, front-.008), (width*.20, height*.16, .03), steel)
            detail_box('ServiceLatch', (-width*.33, low.y+height*.55, front-.012), (.04, .10, .025), copper)
            detail_box('RubberGasket', (0, low.y+height*.12, front+.005), (width*.74, .025, .018), rubber)
    elif name == 'Archive-Data-Vault':
        front = high.z * .55
        detail_box('VaultDoor', (0, low.y+height*.48, 0), (width*.60, height*.68, depth*.22), dark)
        for x in (-width*.35, width*.35):
            detail_box('VaultSeal', (x, low.y+height*.45, front), (.045, height*.64, .028), steel)
        for i in range(3):
            detail_box('DataSlot', (0, low.y+height*(.27+i*.16), front), (width*.43, .028, .025), steel)
        detail_box('VaultLock', (width*.25, low.y+height*.5, front+.008), (.075, .11, .035), copper)
    elif name == 'Sanctuary-Shrine':
        for x in (-width*.24, width*.24):
            detail_box('StoneSeam', (x, low.y+height*.18, low.z+.015), (.018, height*.16, .015), dark)
        for i in range(3):
            detail_box('ShrineInlay', (0, low.y+height*(.18+i*.06), low.z+.01), (width*.32, .015, .015), copper)
    elif name == 'Core-Reactor':
        for obj in [o for o in meshes if o.name.startswith('Core_Pylon')]:
            a, b = game_bounds([obj])
            detail_box('PylonCollar', ((a.x+b.x)/2, a.y+(b.y-a.y)*.65, (a.z+b.z)/2), (b.x-a.x+.008, .028, b.z-a.z+.008), steel)
        for angle in range(0, 360, 90):
            x,z=math.cos(math.radians(angle))*width*.27,math.sin(math.radians(angle))*depth*.27
            detail_box('ReactorFeed', (x, low.y+.075, z), (.05, .055, .12), copper)
    else:
        for i in range(4):
            detail_box('DecisionTerminal', (-width*.24+i*width*.16, low.y+height*.17, low.z+.025), (.055, .035, .02), copper)
        for x in (-width*.37, width*.37):
            detail_box('EngineBrace', (x, low.y+height*.37, center.z), (.035, height*.45, depth*.55), steel)


def bevel(meshes):
    for obj in meshes:
        dimensions = obj.dimensions
        width = min(.018, min(dimensions) * .10)
        if width < .002:
            continue
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        modifier = obj.modifiers.new('Machined Edges', 'BEVEL')
        modifier.width = width
        modifier.segments = 2
        modifier.affect = 'EDGES'
        bpy.ops.object.modifier_apply(modifier=modifier.name)
        obj.select_set(False)


def tune_materials(meshes):
    for mat in {m for obj in meshes for m in obj.data.materials if m}:
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get('Principled BSDF')
        label = mat.name.lower()
        if any(word in label for word in ('metal', 'steel', 'copper', 'brass')):
            bsdf.inputs['Metallic'].default_value = .70
            bsdf.inputs['Roughness'].default_value = .38
        elif any(word in label for word in ('stone', 'rock', 'wood')):
            bsdf.inputs['Metallic'].default_value = 0
            bsdf.inputs['Roughness'].default_value = .90
        elif 'rubber' in label:
            bsdf.inputs['Metallic'].default_value = 0
            bsdf.inputs['Roughness'].default_value = .82


def signs(root):
    output = root / 'assets/models/signage'
    output.mkdir(parents=True, exist_ok=True)
    for chapter, code, color in [(1,'I',(.10,.48,.62)),(2,'II',(.62,.32,.10)),(3,'III',(.20,.45,.30)),(4,'IV',(.28,.46,.62))]:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        steel = material('Sector Housing', (.035,.055,.075), .6, .42)
        accent = material('Sector Accent', color, .25, .5, .10)
        ink = material('Sector Legend', (.55,.67,.70), .1, .6)
        box('SectorPanel', (0,.21,0), (.65,.30,.055), steel)
        for side in (-1,1):
            box('SectorStripe', (-.25,.21,side*.032), (.035,.23,.009), accent)
            for i in range(4):
                box('SectorCode', (.17+i*.03,.13,side*.034), (.015,.055,.005), ink)
            bpy.ops.object.text_add(location=point(-.035,.235,side*.034))
            text=bpy.context.object
            text.name='SectorNumeral'
            text.data.body=code
            text.data.align_x='CENTER'
            text.data.align_y='CENTER'
            text.data.size=.32
            text.rotation_euler=(math.pi/2,0,0 if side==1 else math.pi)
            text.data.materials.append(ink)
            bpy.ops.object.convert(target='MESH')
        bpy.ops.object.select_all(action='SELECT')
        bpy.ops.object.join()
        bpy.context.scene.cursor.location=(0,0,0)
        bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
        bpy.ops.export_scene.gltf(filepath=str(output/f'sector_{chapter}.glb'),export_format='GLB',use_selection=True,export_apply=True)


def main():
    root=Path(sys.argv[sys.argv.index('--')+1]).resolve()
    source=root/'art/asset_polish'
    source.mkdir(parents=True,exist_ok=True)
    (source/'.gdignore').write_text('',encoding='utf-8')
    report=[]
    for name in ASSETS:
        path=root/f'assets/models/baked/{name}.glb'
        animated_original=root/f'art/animated_modules/originals/assets/models/baked/{name}.glb'
        baseline=source/'originals'/f'{name}.glb'
        baseline.parent.mkdir(parents=True,exist_ok=True)
        if not baseline.exists():
            baseline.write_bytes((animated_original if animated_original.exists() else path).read_bytes())
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.gltf(filepath=str(baseline))
        meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
        original_low,original_high=game_bounds(meshes)
        mats=[material('Polish Steel',(.20,.28,.32),.7,.38),material('Polish Recess',(.025,.037,.045),.25,.80),
              material('Polish Copper',(.34,.20,.085),.65,.45),material('Polish Rubber',(.025,.028,.03),0,.85)]
        bevel(meshes)
        details(name,meshes,mats)
        meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
        tune_materials(meshes)
        # Keep the established footprint/pivot; details are inset into the original envelope.
        for obj in meshes:
            if obj.name.startswith('Detail_'):
                for vertex in obj.data.vertices:
                    world=obj.matrix_world@vertex.co
                    lo=Vector((original_low.x*2-.002,-original_high.z*2-.002,original_low.y*2))
                    hi=Vector((original_high.x*2+.002,-original_low.z*2+.002,original_high.y*2))
                    world=Vector([max(lo[i],min(hi[i],world[i])) for i in range(3)])
                    vertex.co=obj.matrix_world.inverted()@world
	
        groups={}
        for obj in meshes:
            if obj.name.startswith('Detail_'):
                groups.setdefault(obj.parent,[]).append(obj)
        for parent,objects in groups.items():
            bpy.ops.object.select_all(action='DESELECT')
            for obj in objects: obj.select_set(True)
            bpy.context.view_layer.objects.active=objects[0]
            bpy.ops.object.join()
            bpy.context.object.name='Detail_Assembly'
        meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
        for obj in meshes: obj.data.calc_loop_triangles()
        triangles=sum(len(o.data.loop_triangles) for o in meshes)
        bpy.context.preferences.filepaths.save_version=0
        bpy.ops.wm.save_as_mainfile(filepath=str(source/f'{name}.blend'))
        bpy.ops.object.select_all(action='SELECT')
        bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_apply=True)
        if animated_original.exists(): animated_original.write_bytes(path.read_bytes())
        report.append({'asset':name,'path':path.relative_to(root).as_posix(),'triangles':triangles,
                       'bounds_min':list(original_low),'bounds_max':list(original_high)})
    signs(root)
    (root/'docs/ASSET_POLISH_BOUNDS.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('POLISHED nine models and four sector sign assets')


if __name__=='__main__': main()
