# Level & character design tools

Design-time tools. They run on any machine with Python 3 + numpy; Godot is not needed.

## Sector layouts: `sector1_plan.py`

The layout of Sector 01 (floors, stairs, building blocks, props, markers) lives in this
script. Running it:

1. **Camera check**: ray-casts every walkable 0.5 m cell to the game camera
   (`camera_follow.gd` offset direction) and lowers any block that would hide the
   player's chest. Prints which blocks were capped and why.
2. **Reachability**: walks the map from the player spawn and reports the walking
   distance to the LZ, every objective spot, zombie spawn and pickup. Markers placed
   inside solids are reported.
3. **Boundaries**: every edge of walkable space must end in a wall, building or
   railing. Open-ground "holes" are reported; railings and invisible blockers are
   generated for the builder.
4. **Export**: writes the plan as a GDScript constant that `LayoutBuilder` turns into
   geometry with exact box collisions.

```
python3 tools/level_design/sector1_plan.py /tmp/sector1_plan.json scripts/layout/plans/sector1_quarantine_block.gd
```

Never edit `scripts/layout/plans/*.gd` by hand: change the plan and re-run, so the
checks run again.

## Characters: `characters.json` + `build_character_scenes.py`

Low-poly clay character specs (pivots named like the parts the game animates, box
parts, colours). Regenerate the Godot scenes after editing the JSON:

```
python3 tools/level_design/build_character_scenes.py
```

Writes `assets/models/characters/<id>_model.tscn`.
