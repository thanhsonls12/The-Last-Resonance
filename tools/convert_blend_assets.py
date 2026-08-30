"""Batch-export Blender asset scenes to Godot-friendly binary glTF files.

Run with Blender, for example:

        blender --background --python tools/convert_blend_assets.py -- \
        "C:\\path\\to\\outputs" "D:\\GodotProjects\\The Last Resonance"

The source categories are routed to the project's asset folders with ``.blend``
replaced by ``.glb``. Cameras and lights are intentionally excluded; meshes,
armatures, and empties are retained, including named animation actions.
"""

import os
import sys
from pathlib import Path

import bpy


def cli_args():

    args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    if len(args) < 2:
        raise SystemExit(
            "Usage: blender --background --python tools/convert_blend_assets.py -- "
            "<source-root> <project-root>"
        )
    source_root = Path(args[0]).expanduser().resolve()
    project_root = Path(args[1]).expanduser().resolve()
    return source_root, project_root


def destination_for(source_root: Path, project_root: Path, source_path: Path):

    relative_path = source_path.relative_to(source_root)
    category = relative_path.parts[0] if relative_path.parts else ""
    if len(relative_path.parts) == 1:
        if source_path.name == "Kiro_K7.blend":
            return project_root / "assets" / "models" / "characters" / "Kiro_K7_roster.glb"
        return project_root / "assets" / "models" / source_path.with_suffix(".glb").name
    tail = Path(*relative_path.parts[1:]).with_suffix(".glb")
    routes = {
        "Animations": Path("assets", "models", "animations"),
        "Chapter_Assets": Path("assets", "models", "environments", "chapters"),
        "Characters": Path("assets", "models", "characters"),
        "Decorative_Props": Path("assets", "models", "props"),
        "Environment_Modular_Kit": Path("assets", "models", "environments", "modular_kit"),
        "Gameplay_Objects": Path("assets", "models", "gameplay"),
        "Material_Texture_Library": Path("assets", "materials"),
    }
    if category in routes:
        return project_root / routes[category] / tail
    return project_root / "assets" / "models" / tail


def exportable_objects():

    bpy.ops.object.select_all(action="DESELECT")
    selected = []
    for obj in bpy.context.scene.objects:
        if obj.type in {"MESH", "ARMATURE", "EMPTY"}:
            obj.select_set(True)
            selected.append(obj)
    if selected:
        bpy.context.view_layer.objects.active = selected[0]
    return selected


def export_file(source_path: Path, destination_path: Path):

    bpy.ops.wm.open_mainfile(filepath=str(source_path))
    selected = exportable_objects()
    if not selected:
        raise RuntimeError("scene contains no mesh, armature, or empty objects")

    destination_path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(destination_path),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_animations=True,
        export_animation_mode="ACTIONS",
        export_force_sampling=True,
        export_frame_step=1,
    )


def main():

    source_root, project_root = cli_args()
    blend_files = sorted(source_root.rglob("*.blend"))
    if not blend_files:
        raise SystemExit(f"No .blend files found under {source_root}")

    succeeded = []
    failed = []
    for index, source_path in enumerate(blend_files, start=1):
        destination_path = destination_for(source_root, project_root, source_path)
        print(f"[{index}/{len(blend_files)}] EXPORT {source_path} -> {destination_path}", flush=True)
        try:
            export_file(source_path, destination_path)
            succeeded.append((source_path, destination_path))
        except Exception as error:  # keep the batch moving and report all failures
            failed.append((source_path, str(error)))
            print(f"FAILED {source_path}: {error}", flush=True)

    print(f"EXPORTED {len(succeeded)} of {len(blend_files)} Blender files", flush=True)
    if failed:
        for source_path, error in failed:
            print(f"ERROR {source_path}: {error}", flush=True)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
