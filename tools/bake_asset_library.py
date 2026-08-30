"""Bake per-asset glTF files out of the authored Blender showcase rosters.

Every roster in ``assets/models`` holds an entire presentation scene: all assets
laid out side by side on a display board. Instancing those files directly makes
BoardView scale the whole board down into a single grid cell, so the roster must
be split into one clean file per asset first.

Meshes are grouped by the name prefixes the artist already used, display-board
geometry is dropped, and each group is recentred on the X/Z footprint while its
authored height is preserved (a ceiling stays high, a hovering core keeps its
hover).

Run with Blender:

    blender --background --python tools/bake_asset_library.py -- <project-root>
"""

import sys
from pathlib import Path

import bpy

OUTPUT_DIR = Path("assets/models/baked")

# Substring marking presentation-board geometry that must never reach the game.
DISPLAY_MARKER = "_Display_"

MANIFEST = {
    "assets/models/environments/modular_kit/Environment_Modular_Kit_Roster.glb": {
        "Floor-Tile": ["FloorTile_"],
        "Wall-Module": ["Wall_"],
        "Pillar": ["Pillar_"],
        "Stair-Module": ["Stair_"],
        "Platform-Module": ["Platform_"],
        "Railing-Module": ["Railing_"],
        "Ceiling-Module": ["Ceiling_"],
        "Door-Frame": ["DoorFrame_"],
        "Window-Module": ["Window_"],
        "Broken-Wall": ["BrokenWall_"],
        "Broken-Pillar": ["BrokenPillar_"],
        "Rubble-Patch": ["Rubble_"],
    },
    "assets/models/gameplay/Gameplay_Objects_Roster.glb": {
        "Energy-Core": ["EnergyCore_"],
        "Core-Pedestal": ["Pedestal_"],
        "Pressure-Plate": ["Plate_"],
        "Door": ["Door_"],
        "Portal": ["Portal_"],
        "Elevator": ["Elevator_"],
        "Bridge": ["Bridge_"],
        "Conveyor": ["Conveyor_"],
        "Memory-Fragment": ["MemoryShard_"],
        "Terminal": ["Terminal_"],
        "Switch": ["Switch_"],
        "Energy-Cable": ["EnergyCable_"],
    },
    "assets/models/props/Decorative_Props_Roster.glb": {
        "Archive-Shelf": ["ArchiveShelf_"],
        "Data-Storage-Rack": ["DataRack_"],
        "Hologram-Projector": ["Holo_"],
        "Archive-Workbench": ["Workbench_"],
        "Cargo-Crate": ["Crate_"],
        "Machine-Unit": ["Machine_"],
        "Debris-Pile": ["Debris_"],
        "Moss-Patch": ["Moss_"],
        "Plant-Cluster": ["Plant_"],
        "Rock-Cluster": ["Rock_"],
        "Cable-Coil": ["CableCoil_"],
        "Pipe-Cluster": ["PipeCluster_"],
        "SciFi-Lamp": ["Lamp_"],
        "Broken-Robot": ["BrokenRobot_"],
    },
    "assets/models/environments/chapters/Forgotten_Archive/Forgotten_Archive_Asset_Roster.glb": {
        "Archive-Bookshelf": ["Bookshelf_", "Shelf", "Data_Tome"],
        "Archive-Data-Vault": ["Data_Vault_"],
        "Archive-Broken-Column": ["Broken_Column", "Column_Fracture"],
        "Archive-Terminal": ["Archive_Terminal_", "Archive_Hologram"],
        "Archive-Plinth": ["Display_Plinth"],
        "Archive-Holo-Projector": ["Hologram_Projector", "Hologram_Ring"],
    },
}


def project_root() -> Path:
    args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    if not args:
        raise SystemExit(
            "Usage: blender --background --python tools/bake_asset_library.py -- <project-root>"
        )
    return Path(args[0]).expanduser().resolve()


def import_roster(path: Path) -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path))
    for obj in list(bpy.data.objects):
        if obj.type == "MESH" and DISPLAY_MARKER in obj.name:
            bpy.data.objects.remove(obj, do_unlink=True)


def group_meshes(prefixes) -> list:
    return [
        obj
        for obj in bpy.data.objects
        if obj.type == "MESH" and any(obj.name.startswith(p) for p in prefixes)
    ]


def footprint_centre(objects) -> tuple:
    xs, ys = [], []
    for obj in objects:
        for vertex in obj.data.vertices:
            world = obj.matrix_world @ vertex.co
            xs.append(world.x)
            ys.append(world.y)
    return (min(xs) + max(xs)) * 0.5, (min(ys) + max(ys)) * 0.5


def export_group(objects, destination: Path) -> None:
    # Blender is Z-up here; the glTF exporter converts to the Y-up convention
    # Godot expects, so only the horizontal footprint needs recentring.
    centre_x, centre_y = footprint_centre(objects)
    for obj in objects:
        obj.location.x -= centre_x
        obj.location.y -= centre_y

    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]

    destination.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(destination),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
    )

    for obj in objects:
        obj.location.x += centre_x
        obj.location.y += centre_y


def main() -> None:
    root = project_root()
    baked = 0
    for source, groups in MANIFEST.items():
        source_path = root / source
        if not source_path.exists():
            print(f"MISSING ROSTER {source_path}")
            continue
        import_roster(source_path)
        print(f"\n=== {source_path.name} ===")
        for name, prefixes in groups.items():
            objects = group_meshes(prefixes)
            if not objects:
                print(f"  SKIP {name}: no mesh matched {prefixes}")
                continue
            destination = root / OUTPUT_DIR / f"{name}.glb"
            export_group(objects, destination)
            tris = 0
            for obj in objects:
                obj.data.calc_loop_triangles()
                tris += len(obj.data.loop_triangles)
            print(f"  {name}.glb  meshes={len(objects)} tris={tris}")
            baked += 1
    print(f"\nbaked {baked} assets into {OUTPUT_DIR}")


main()

