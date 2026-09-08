"""Build compact chapter-identity scenery for MAP_OBJECT_DESIGN_PLAN phase B.

Usage:
    blender --background --python tools/build_chapter_identity_props.py -- <project-root>

Coordinates are GAME units, Y-up. GLBs are authored at 2x to match the existing
runtime/editor scale of 0.5. Every prop keeps its pivot at footprint center / base.
These assets are scenery only; LevelData remains authoritative for blocked cells.
"""

import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def point(x, y, z):
    return Vector((2 * x, -2 * z, 2 * y))


def material(name, color, metal=0.0, rough=0.65, emission=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    node = mat.node_tree.nodes.get("Principled BSDF")
    node.inputs["Base Color"].default_value = (*color, 1.0)
    node.inputs["Metallic"].default_value = metal
    node.inputs["Roughness"].default_value = rough
    if emission > 0.0:
        node.inputs["Emission Color"].default_value = (*color, 1.0)
        node.inputs["Emission Strength"].default_value = emission
    return mat


def box(name, center, size, mat, rotation_y=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=point(*center))
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = (size[0] * 2, size[2] * 2, size[1] * 2)
    obj.rotation_euler[2] = math.radians(-rotation_y)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    return obj


def cylinder_between(name, start, end, radius, mat, vertices=10):
    a, b = point(*start), point(*end)
    direction = b - a
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius * 2,
        depth=direction.length,
        location=(a + b) / 2,
    )
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = direction.to_track_quat("Z", "Y")
    obj.data.materials.append(mat)
    return obj


def build(kind, mats):
    metal, dark, accent, stone, root_mat = mats

    if kind == "archive_access_panel_broken":
        box("PanelBody", (0, .20, 0), (.72, .40, .14), dark)
        box("PanelInset", (-.08, .22, -.075), (.43, .18, .018), metal)
        box("BrokenDoor", (.24, .22, -.10), (.18, .27, .035), metal, rotation_y=-8)
        box("StatusStrip", (-.22, .31, -.095), (.18, .022, .012), accent)
        box("DeadSlot", (.13, .12, -.095), (.15, .05, .012), dark)
    elif kind == "archive_storage_tray_low":
        box("TrayBase", (0, .07, 0), (.78, .14, .46), dark)
        box("TrayLipN", (0, .15, -.205), (.78, .10, .05), metal)
        box("TrayLipS", (0, .15, .205), (.78, .10, .05), metal)
        box("TrayLipW", (-.365, .15, 0), (.05, .10, .36), metal)
        box("DataCassetteA", (-.18, .17, 0), (.18, .07, .26), metal)
        box("DataCassetteB", (.10, .17, .03), (.18, .07, .20), metal)
    elif kind == "foundry_maintenance_box":
        box("MaintenanceCase", (0, .16, 0), (.70, .32, .52), dark)
        box("Lid", (0, .335, 0), (.72, .04, .54), metal)
        box("LatchL", (-.23, .24, -.275), (.10, .10, .04), metal)
        box("LatchR", (.23, .24, -.275), (.10, .10, .04), metal)
        box("WarningBand", (0, .12, -.285), (.36, .055, .012), accent)
    elif kind == "foundry_pipe_support":
        box("Foot", (0, .045, 0), (.66, .09, .46), dark)
        box("PostL", (-.22, .20, 0), (.10, .31, .12), metal)
        box("PostR", (.22, .20, 0), (.10, .31, .12), metal)
        cylinder_between("PipeClamp", (-.30, .36, 0), (.30, .36, 0), .075, metal, 12)
        box("ClampAccent", (0, .36, -.085), (.18, .035, .02), accent)
    elif kind == "sanctuary_broken_plinth_low":
        box("PlinthBase", (0, .08, 0), (.68, .16, .68), stone)
        box("PlinthMid", (-.04, .20, .02), (.52, .15, .52), stone, rotation_y=4)
        box("BrokenCap", (.08, .31, -.05), (.42, .09, .36), stone, rotation_y=-11)
        box("MissingShard", (-.25, .18, .20), (.15, .08, .18), dark, rotation_y=17)
    elif kind == "sanctuary_bank_root":
        box("BankStone", (0, .06, 0), (.74, .12, .52), stone)
        cylinder_between("RootA", (-.34, .12, -.10), (.26, .25, .08), .055, root_mat, 8)
        cylinder_between("RootB", (-.20, .10, .17), (.34, .19, -.16), .045, root_mat, 8)
        cylinder_between("RootFork", (.08, .17, .02), (.30, .29, .20), .035, root_mat, 8)
    elif kind == "core_data_cabinet_low":
        box("Cabinet", (0, .18, 0), (.74, .36, .44), dark)
        box("FrontPanel", (0, .20, -.235), (.62, .24, .03), metal)
        box("PanelSplit", (0, .20, -.255), (.025, .20, .012), dark)
        box("StatusLine", (0, .31, -.258), (.48, .018, .012), accent)
        box("FootL", (-.25, .035, 0), (.12, .07, .28), metal)
        box("FootR", (.25, .035, 0), (.12, .07, .28), metal)
    elif kind == "core_light_trim":
        box("TrimBase", (0, .095, 0), (.88, .19, .20), dark)
        box("PrecisionCap", (0, .205, 0), (.88, .03, .20), metal)
        box("LightChannel", (0, .145, -.108), (.66, .028, .012), accent)
        box("NodeL", (-.37, .145, -.108), (.035, .05, .012), accent)
        box("NodeR", (.37, .145, -.108), (.035, .05, .012), accent)
    else:
        raise ValueError(kind)


def main():
    root = Path(sys.argv[sys.argv.index("--") + 1]).resolve()
    output = root / "assets/models/baked"
    output.mkdir(parents=True, exist_ok=True)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    mats = [
        material("Identity Metal", (.24, .31, .35), .55, .48),
        material("Identity Dark", (.075, .095, .11), .35, .64),
        material("Identity Accent", (.08, .48, .54), .20, .35, .35),
        material("Identity Stone", (.22, .25, .24), .04, .82),
        material("Identity Root", (.16, .11, .07), .0, .90),
    ]
    kinds = [
        ("archive_access_panel_broken", 1),
        ("archive_storage_tray_low", 1),
        ("foundry_maintenance_box", 2),
        ("foundry_pipe_support", 2),
        ("sanctuary_broken_plinth_low", 3),
        ("sanctuary_bank_root", 3),
        ("core_data_cabinet_low", 4),
        ("core_light_trim", 4),
    ]
    report = []
    for kind, chapter in kinds:
        for obj in list(bpy.data.objects):
            bpy.data.objects.remove(obj, do_unlink=True)
        build(kind, mats)
        meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
        # Normalize the independent-prop pivot: X/Z centered on the measured
        # footprint, Y at the lowest point. Asymmetric damage/details must not
        # silently shift the placement anchor away from the grid cell center.
        world_vertices = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
        low_blender = Vector(tuple(min(v[i] for v in world_vertices) for i in range(3)))
        high_blender = Vector(tuple(max(v[i] for v in world_vertices) for i in range(3)))
        shift = Vector((
            -(low_blender.x + high_blender.x) / 2,
            -(low_blender.y + high_blender.y) / 2,
            -low_blender.z,
        ))
        for obj in meshes:
            obj.location += shift
        bpy.ops.object.select_all(action="SELECT")
        path = output / f"Identity-{kind}.glb"
        bpy.ops.export_scene.gltf(
            filepath=str(path), export_format="GLB", use_selection=True, export_apply=True
        )
        vertices = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
        game_vertices = [(v.x / 2, v.z / 2, -v.y / 2) for v in vertices]
        low = [round(min(v[i] for v in game_vertices), 5) for i in range(3)]
        high = [round(max(v[i] for v in game_vertices), 5) for i in range(3)]
        triangles = 0
        surfaces = 0
        for obj in meshes:
            obj.data.calc_loop_triangles()
            triangles += len(obj.data.loop_triangles)
            surfaces += len(obj.data.materials)
        report.append({
            "type": kind,
            "chapter": chapter,
            "path": path.relative_to(root).as_posix(),
            "bounds_min": low,
            "bounds_max": high,
            "triangles": triangles,
            "surfaces": surfaces,
            "gameplay_collision": False,
            "source": "tools/build_chapter_identity_props.py",
        })

    (root / "docs/CHAPTER_IDENTITY_PROPS_BOUNDS.json").write_text(
        json.dumps(report, indent=2) + "\n", encoding="utf-8"
    )
    print(f"BUILT {len(kinds)} chapter identity props")


if __name__ == "__main__":
    main()
