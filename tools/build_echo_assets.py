"""Author the echo expansion in Blender, preserving an editable source gallery."""
import math
import sys
from pathlib import Path
import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).parent))
from build_modular_kit import box, cylinder, material, point

ROOT = Path(sys.argv[sys.argv.index('--') + 1])
OUT = ROOT / 'assets/models/echo_expansion'
ART = ROOT / 'art/echo_expansion'
OUT.mkdir(parents=True, exist_ok=True)
ART.mkdir(parents=True, exist_ok=True)
(ART / '.gdignore').write_text('')


def ring(name, radius, tube, location, mat):
    bpy.ops.mesh.primitive_torus_add(major_segments=24, minor_segments=6, major_radius=radius*2, minor_radius=tube*2, location=point(*location))
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    return obj


def pivot(name, location, children):
    node = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(node)
    node.location = point(*location)
    bpy.context.view_layer.update()
    for child in children:
        matrix = child.matrix_world.copy()
        child.parent = node
        child.matrix_world = matrix
    return node


def animate(node, clip, axis, amount, looping=False):
    node.rotation_mode = 'XYZ'
    frames = [(1, 0), (13, amount), (25, 0)] if looping else [(1, 0), (25, amount)]
    for frame, value in frames:
        node.rotation_euler[axis] = value
        node.keyframe_insert('rotation_euler', frame=frame)
    action = node.animation_data.action
    action.name = clip + '_' + node.name
    track = node.animation_data.nla_tracks.new()
    track.name = clip
    track.strips.new(clip, 1, action)
    node.animation_data.action = None


gallery = bpy.data.scenes.new('Echo Expansion Studio')
bpy.context.window.scene = gallery
gallery.render.fps = 24
materials = [material('Oxidized Titanium', (.10,.19,.21), .75,.36),
              material('Ancient Stone', (.30,.40,.35), .0,.85),
              material('Patinated Brass', (.50,.32,.13), .7,.38),
              material('Tidal Signal', (.12,.72,.47), .3,.25,1.5),
              material('Dark Rubber', (.025,.04,.045), .0,.8)]
metal, stone, brass, glow, rubber = materials


def build(kind):
    if kind == 'tidal_valve':
        box('StoneHousing', (0,.34,0), (.65,.65,.50), stone)
        box('GaugePanel', (0,.50,-.26), (.34,.17,.025), metal)
        for x in [-.10,0,.10]:
            box('PressureTick', (x,.50,-.28), (.025,.08,.01), glow)
        cylinder('Axle', (0,.30,-.21),(0,.30,-.37),.055,brass)
        wheel = ring('Handwheel', .21,.025,(0,.30,-.39),brass)
        wheel.rotation_euler.x = math.pi/2
        spokes = [box('WheelSpoke', (0,.30,-.39), (.39,.035,.035), brass), box('WheelSpoke', (0,.30,-.39), (.035,.39,.035), brass)]
        rotor = pivot('ValveRotor',(0,.30,-.39),[wheel]+spokes)
        animate(rotor,'ValveTurn',1,math.pi)
    elif kind in ['tidal_raft','dry_crossing']:
        box('Deck', (0,0,0),(.88,.07,.88 if kind=='tidal_raft' else .72),metal)
        for x in [-.35,-.175,0,.175,.35]:
            box('Slat', (x,.042,0),(.12,.022,.72),stone)
        for x in [-.37,.37]:
            box('Pontoon', (x,-.095,0),(.16,.14,.80),rubber)
            box('DeckSignal', (x,.059,0),(.025,.018,.75),glow)
        for x in [-.34,.34]:
            for z in [-.34,.34]:
                cylinder('DeckBolt',(x,.057,z),(x,.068,z),.025,brass)
    elif kind == 'mote':
        box('MoteBody',(0,0,0),(.18,.12,.16),metal)
        box('Eye',(0,.018,-.09),(.09,.04,.025),glow)
        box('Brow',(0,.053,-.075),(.14,.018,.045),brass)
        ring('CoreHalo',.09,.012,(0,-.025,0),glow)
        for side in [-1,1]:
            panel = box('WingArmor',(side*.155,.005,0),(.12,.025,.18),metal)
            strip = box('WingSignal',(side*.17,.021,0),(.025,.009,.13),glow)
            wing = pivot('Wing_L' if side<0 else 'Wing_R',(side*.09,0,0),[panel,strip])
            animate(wing,'Hover',1,side*.18,True)
            animate(wing,'Perch',1,-side*.85)
            box('LandingClaw',(side*.06,-.079,.025),(.023,.05,.05),brass)
    elif kind == 'kiro_tidal_pack':
        box('BackPlate',(0,0,0),(.25,.26,.075),metal)
        for side in [-1,1]:
            box('ArmorFin',(side*.11,.015,.025),(.055,.31,.09),brass)
            box('TidalTrim',(side*.105,.018,.078),(.018,.22,.02),glow)
        cylinder('ReserveCell',(0,-.08,.075),(0,.08,.075),.048,rubber)
        ring('CoreSocket',.055,.012,(0,0,.09),glow).rotation_euler.x=math.pi/2
    elif kind == 'restoration_station':
        box('Foundation',(0,.07,0),(1.8,.14,1.35),stone)
        box('ServiceDeck',(0,.16,0),(1.30,.045,1.05),metal)
        ring('DockLight',.42,.025,(0,.19,0),glow)
        for side in [-1,1]:
            box('ServicePillar',(side*.72,.75,.28),(.22,1.30,.27),metal)
            box('PillarTrim',(side*.72,.83,.13),(.025,.70,.022),glow)
            arm = box('RestorationArm',(side*.43,.94,.05),(.38,.085,.10),brass)
            joint = pivot('ServiceArm_L' if side<0 else 'ServiceArm_R',(side*.68,.94,.05),[arm])
            animate(joint,'Restore',2,side*.35,True)
        box('StationHeader',(0,1.44,.28),(1.65,.15,.30),metal)
        box('ServiceDisplay',(0,1.44,.11),(.65,.07,.022),glow)
        for x in [-.35,0,.35]:
            box('RearVent',(x,.65,.61),(.21,.45,.07),rubber)
    elif kind == 'memory_echo':
        box('MemoryFoot',(0,.035,0),(.30,.07,.30),stone)
        cylinder('MemoryStem',(0,.07,0),(0,.16,0),.045,brass)
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=.12*2,location=point(0,.30,0))
        crystal=bpy.context.object
        crystal.name='EchoCrystal'
        crystal.scale=(.65,.65,1.25)
        crystal.data.materials.append(glow)
        rings=[ring('EchoOrbit',.18,.009,(0,.30,0),brass)]
        rings.append(box('OrbitGlyph',(.18,.30,0),(.035,.035,.06),glow))
        orb=pivot('MemoryOrbit',(0,.30,0),rings)
        animate(orb,'Resonate',2,math.tau)


for index, kind in enumerate(['tidal_valve','tidal_raft','dry_crossing','mote','kiro_tidal_pack','restoration_station','memory_echo']):
    collection=bpy.data.collections.new(kind)
    gallery.collection.children.link(collection)
    layer=next(c for c in bpy.context.view_layer.layer_collection.children if c.collection==collection)
    bpy.context.view_layer.active_layer_collection=layer
    build(kind)
    gallery.frame_set(1)
    for obj in list(collection.objects):
        if obj.type=='MESH':
            bevel=obj.modifiers.new('Edge Highlights','BEVEL')
            bevel.width=.012
            bevel.segments=1
            bpy.context.view_layer.objects.active=obj
            bpy.ops.object.modifier_apply(modifier=bevel.name)
    groups={}
    for obj in collection.objects:
        if obj.type=='MESH':
            groups.setdefault(obj.parent,[]).append(obj)
    for parent, meshes in groups.items():
        if len(meshes)>1:
            bpy.ops.object.select_all(action='DESELECT')
            for obj in meshes:
                obj.select_set(True)
            bpy.context.view_layer.objects.active=meshes[0]
            bpy.ops.object.join()
            bpy.context.object.name=kind+'_surfaces' if parent is None else parent.name+'_surfaces'
    bpy.ops.object.select_all(action='DESELECT')
    for obj in collection.objects:
        obj.select_set(True)
    gallery.frame_set(1)
    bpy.ops.export_scene.gltf(filepath=str(OUT/(kind+'.glb')),export_format='GLB',use_selection=True,export_apply=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_frame_range=False,export_force_sampling=True)
    print('AUTHORED',kind)
    for obj in collection.objects:
        if obj.parent is None:
            obj.location += point((index % 4)*2.6,0,(index // 4)*2.6)
bpy.ops.wm.save_as_mainfile(filepath=str(ART/'echo_expansion.blend'))
print('Echo expansion complete')
