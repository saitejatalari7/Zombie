# Level & character design tools

Design-time tools. They run on any machine with Python 3 + numpy; Godot is not needed.

## Sector layouts: `layouts/*.py` + `build_layouts.py`

Each layout is a data file in `layouts/` (floors, stairs, blocks, rooms, props, markers).
A sector has several layouts; a contract picks one with its `"layout"` key
(`GameManager.CONTRACTS`), and `LayoutSector` builds `scripts/layout/plans/<id>.gd`.

```
python3 tools/level_design/build_layouts.py              # every layout
python3 tools/level_design/build_layouts.py s1_market    # one
```

`layoutlib.py` runs the same checks on every layout and refuses to export one that fails:

1. **Camera**: ray-casts every walkable 0.5 m cell to the game camera and caps any block
   that would hide the player's chest. Tall blocks only survive where nothing walkable lies
   north or west of them; camera-side rows keep their height behind a 2.5 m planter strip.
2. **Props**: wrecked cars, barriers and crates use their measured footprints, so the
   zombie flow field routes around them and markers can't sit inside one.
3. **Reachability**: every marker must be on a walkable cell reachable from the spawn.
4. **Boundaries**: every edge of walkable space ends in a wall, building, railing or prop.
   Open-ground holes fail the build; railings and invisible blockers are generated.
5. **Export**: the plan plus the nav grid, as a GDScript constant (ships in every export).

Block kinds: `building`, `shed`, `wall`, `planter`, `cover`, `containers`, `bus`,
`retaining` (under a raised floor; never capped), `water` (canal surface), `bridge`,
`tracks` (walkable rails), `ballast`, `railcar`, `crane`, `tank` (fuel tank), `pipes` (pipe rack).
Container stacks keep full height behind pallet strips (see `stack()` in the Sector 03 layouts).

Never edit `scripts/layout/plans/*.gd` by hand.

### Checking a layout in Godot (Linux, headless)

```
xvfb-run -a godot --rendering-driver opengl3 --resolution 1000x1000 --path . \
    --script res://tests/qa_layout_overview.gd -- s1_market /tmp/s1_market   # whole-map renders
xvfb-run -a godot --rendering-driver opengl3 --path . \
    --script res://tests/qa_layout_play.gd -- s1_market /tmp/mk               # game camera at each step
godot --headless --path . --script res://tests/qa_contract_bot.gd            # every contract, start to evac
godot --headless --path . --script res://tests/qa_zombie_reach.gd -- s1_market
```

## Characters: `characters.json` + `build_character_scenes.py`

Low-poly clay character specs (pivots named like the parts the game animates, box
parts, colours). Regenerate the Godot scenes after editing the JSON:

```
python3 tools/level_design/build_character_scenes.py
```

Writes `assets/models/characters/<id>_model.tscn`.
