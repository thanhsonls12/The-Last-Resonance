# Map composition pass

This pass returns focus to campaign map dressing after the mobile render work. The new scenery is placed only in `LevelData.decorations`; no ASCII map, entity, route or par value is changed.

The sparse Sanctuary/Core levels received perimeter dressing and chapter landmarks:

- Sanctuary: Levels 9, 10 and 12 add tree/rocks/vine silhouettes plus water-edge pieces and an upper-floor shrine/rail.
- Central Core: Levels 13 and 15 add generator/reactor/hologram silhouettes plus a floor edge/core wall at the room perimeter.
- Existing Foundry/Archive pilots remain unchanged and continue to serve as placement references.

The validator checks every campaign decoration for layer bounds, entity overlap and modular-on-wall mistakes while allowing chapter props to sit on authored wall cells as background scenery. It also confirms each level landmark is represented.

```powershell
python tools/validate_map_decorations.py
python tools/validate_asset_pilot.py
python tools/validate_levels.py
```

The props remain visual only. If a render later shows a tall prop hiding a Core or target, adjust its `scale`, `yaw` or perimeter cell before creating another asset.
