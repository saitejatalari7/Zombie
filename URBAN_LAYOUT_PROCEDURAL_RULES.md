# Procedural Urban Layout Rules & Architectural Grammar
## Tactical Isometric Zombie Extraction Layouts — "Protocol: Crimson"

This document establishes the mandatory design rules, sightline geometry, and procedural variation grammar for generating urban street layouts in Godot 4 and Blender. Every procedural generation tool and manual level build must strictly adhere to these rules.

---

## 1. Camera Sightline & Occlusion Geometry (Zero Blindspots)

> **Correction (verified against `scripts/camera_follow.gd`):** the camera sits at player + **(9.9, 33, 23.1)**, i.e. **south-EAST** of the player (screen right and screen bottom), not south-west. Its view line climbs **1.31 m per metre** of horizontal distance. So:
> * Tall buildings belong on the **north and west** edges of walkable space.
> * On the **south and east** edges, a wall at horizontal distance *d* (measured toward the camera) may be at most about **1.31 × d** tall, or it hides the player.
> * `tools/level_design/sector1_plan.py` enforces this automatically by ray-casting every walkable cell to the camera and lowering offending blocks. Run it after any layout change.
> The diagram and quadrant names below predate this correction; where they disagree, this note wins.

In an isometric / elevated top-down perspective, any tall structure positioned between the camera and the playable street will occlude the player, zombies, and combat feedback. Relying on transparency / raycast fading is only an emergency fail-safe—**the layout geometry itself must eliminate occlusion natively**.

```
  Camera Eye (Elevated South-West)
       \
        \  Line of Sight (45° Pitch)
         \
          ▼  [Background: Tall 8-16m Buildings - Never occludes]
              │
              ├── [Mid-ground: Main Street Corridor (Action Zone)]
              │
             [Foreground: Low ≤ 2.8m Structures / Retaining Walls]
```

### 1.1 The Stepped Elevation Rule (Amphitheater Principle)
* **Foreground Quadrant (Screen Bottom & Bottom-Right)**:
  * **Strict Height Limit**: Maximum height **2.8m** (single-story flat roofs, garages, or annexes).
  * **Preferred Structures**: Low concrete retaining walls (1.0m–1.4m), street curbs, drainage channels, open parking aprons, single-layer shipping containers (2.6m), or chain-link fences.
  * **Rule**: The camera must maintain an unhindered downhill sightline directly into the street floor at all times.
* **Mid-Ground Quadrant (Central Combat Corridor)**:
  * Street width: **5.5m to 7.5m** (tight enough to funnel zombies, wide enough for player dodging and weapon projectile arcs).
  * Building heights flanking the corridor: **5.0m to 8.0m** (2 stories), stepped back from the curb.
* **Background Quadrant (Screen Top & Top-Left)**:
  * Building heights: **8.0m to 16.0m** (3 to 5 stories).
  * Background structures act as the towering concrete canyon backdrop. Because they are positioned *behind* the street relative to the camera vector, they never block gameplay.

### 1.2 Street Axis Alignment
* Streets must run **parallel or diagonal along the camera's isometric sightline** (e.g. running from lower-left to upper-right, or along the diagonal Z/X axis).
* Streets must **never** run horizontally tucked directly behind a tall foreground building.
* Any side alley turning off the main street must turn **away** from the camera (into the upper quadrants) or into an open-air sunken plaza.

---

## 2. Edge-to-Edge Frustum Enclosure (Zero Void / Islanding)

The game world must **never** resemble a floating miniature diorama block in an empty skybox. The viewport must be 100% enclosed within a continuous, suffocating quarantine metropolis.

### 2.1 Infinite Perimeter Envelope
* **Screen Edge Clipping**: Every edge of the viewport (top, bottom, left, right) must intersect solid building facades, rooftops, or barricaded street terminuses.
* **Continuous Sub-Base**: The ground asphalt/sidewalk foundation slab must extend at least **30 meters beyond the camera frustum** in all directions, ensuring no horizon voids or grey voids are ever exposed during camera shake or mobile rotation.

### 2.2 Lore-Accurate Cordon Boundaries (Level Exits)
Streets do not fade into the void; they are physically severed by quarantine containment infrastructure:
1. **North / Main Terminus**: Brutalist reinforced concrete blast-gate (5m high) with hazard stripes, floodlight stanchions, and armored guard booths.
2. **South / Foreground Terminus**: Catastrophic traffic pileup—jackknifed municipal bus or armored transport wedged between building walls, flanked by concrete jersey barriers.
3. **East / Alley Terminus**: Stacked shipping containers (2-high, 5.2m), heavy-duty security roll-up doors, and razor wire.
4. **West / Upper Terrace Terminus**: Massive concrete retaining cliff face topped with non-playable high-rise silhouettes.

---

## 3. Procedural Non-Repetitive Building Grammar

To prevent procedural urban layouts from feeling like repeating sterile boxes, building generation must employ procedural variation across **6 modular dimensions**:

```
           [Rooftop Furniture] (AC units, water tanks, antennas, access boxes)
                 ┌───┴───┐
                 │       │   <- [Parapet Lip: 0.4m - 0.6m]
    [Setback] -> ┌───────┴──────┐
                 │  Upper Story │  <- [Recessed Dark Window Voids (0.9m x 1.2m)]
                 │  (Terrace)   │
    [Ground]  -> └──────────────┴────────┐
                 │  Ground Floor Shop/Door │ <- [Exterior Wrap Staircase]
                 └─────────────────────────┘
```

### 3.1 Asymmetric Footprints & Geometry Variations
Never generate a grid of identical uniform boxes. Every building chooses from a grammar of footprint archetypes:
* **Archetype A: Chamfered Corner / Diagonal Wedge** — One vertical edge is beveled at 45° (matching the diorama reference building), creating an angled facade that catches diagonal sunlight.
* **Archetype B: Stepped-Back Terrace** — Ground floor has a larger footprint; upper 2nd and 3rd stories are set back by 1.5m–2.5m, forming an accessible or decorative balcony ledge.
* **Archetype C: L-Shape / Nook Creator** — The building wraps around a corner, creating an alley alcove ideal for loot crates, dumpster nooks, or zombie spawn ambush points.
* **Archetype D: Cantilever / Overhang** — The 2nd floor overhangs the 1st floor sidewalk by 0.8m–1.2m, creating deep cast shadows over the pedestrian path.

### 3.2 Facade Modulation & Fenestration
* **Window Rhythms**: Window voids are recessed **0.15m to 0.25m** into the wall with contrasting dark recess materials (`Color(0.18, 0.18, 0.20)`).
* **Randomized Window Patterns**:
  * Vary horizontal spacing (e.g., pairs of windows separated by solid wall columns).
  * Vary floor count (ground floor commercial doors, upper residential punch windows).
  * Add protruding window sills (0.08m projection) to catch directional sun highlights.
* **Exterior Wrap Staircases**:
  * Buildings flanking multi-level streets must feature narrow exterior metal/concrete staircases (1.0m width) climbing along the facade to 2nd-floor doors.

### 3.3 Rooftop Clutter Scatter
Every flat roof must receive 2 to 5 procedural clutter elements:
* **HVAC / AC Condenser Units**: Box body with a cylindrical top fan grill.
* **Rooftop Stairwell Access Housing**: A rectangular doorway box (1.8m x 2.2m x 1.6m) with a single dark door.
* **Water Cisterns / Cylindrical Tanks**: Raised on low wooden/steel runners.
* **Piped Ducting & Vents**: Low square ducts running along parapet corners.
* **Continuous Parapet Walls**: 0.45m to 0.65m high perimeter lips around every roof edge to give solid architectural silhouette definition.

---

## 4. Street Topology & Flow Grammar (The 3-Street Interconnect)

A level layout must provide **tactical variety**, not a single linear hallway. The standard sector topology consists of **3 distinct interconnecting street tiers**:

1. **Tier 1: Main Commercial Avenue (The Spine)**:
   * Width: 6.5m–7.5m.
   * Runs diagonally across the primary camera axis.
   * Contains the primary zombie horde flow, abandoned civilian vehicles, and central road curbs.
2. **Tier 2: The Branching Service Alley (Flank / Chokepoint)**:
   * Width: 3.8m–5.0m.
   * Branches off at a 90° T-junction or 45° Y-fork.
   * Packed with dumpsters, pallet stacks, and tight vehicle wreckage—high risk, close-quarters combat zone.
3. **Tier 3: The Elevated Upper Terrace (High Ground)**:
   * Elevation: **+3.0m to +3.6m** above the Main Avenue.
   * Connected via a **16-to-22 step split-level street staircase** (step rise 0.18m, tread 0.35m) with concrete handrail parapets.
   * Separated from the lower street by a heavy monolithic concrete retaining wall.
   * Serves as extraction point, high-value supply crate zone, or boss encounter arena.

---

## 5. Micro-Clutter & Obstacle Placement Grammar

Props must never be scattered purely at random—they must tell an environmental story of sudden quarantine evacuation:

### 5.1 Abandoned Vehicles
* Model: Low-poly civilian sedans, station wagons, and delivery vans.
* **Placement Rules**:
  * Angled at 15° to 35° relative to the curb (abandoned in a hurry).
  * Paired to create natural **funnel chokepoints** (leaving 2.5m–3.5m clearance for the player to maneuver while forcing zombies into dense clusters).
  * Rubble and glass debris scatter (8–14 small rock/brick fragments) around vehicle wheel wells.

### 5.2 Utility Poles & Procedural Catenary Cables
* Height: **8.0m to 8.5m**.
* Features 2 crossbars with ceramic insulator pins.
* Placed along sidewalk curb lines at 18m–25m intervals.
* **Catenary Power Lines**: 3 to 4 sagging cable curves spanning pole-to-pole, with 1–2 service drop lines running directly into building wall connectors.

### 5.3 Dead Bare Trees
* Angular, leafless, branching silhouettes casting dramatic skeletal shadows across the white clay ground.
* Placed in sidewalk cutouts or alley corners to break up hard architectural vertical lines.

### 5.4 Tactical Cover & Breakables
* Stacked wooden pallets (tilted/leaning).
* Military supply crates with glowing top markers (`mat_emission`).
* Overturned commercial dumpsters with trash bag scatter.

---

## 6. Contrast, Lighting, & Readability Standards

The aesthetic signature is **high-contrast Mediterranean monochrome with visceral crimson arterial feedback**:

| Surface / Element | Material / Color | Roughness | Visual Purpose |
|---|---|---|---|
| **Architectural Clay** | `Color(0.85, 0.85, 0.87)` | 0.82 | Clean, sculptural, matte white/light-grey backdrop |
| **Street Pavement** | `Color(0.78, 0.78, 0.80)` | 0.88 | Distinct tone underfoot, shows blood stains clearly |
| **Curbs & Steps** | `Color(0.92, 0.92, 0.94)` | 0.75 | Highlights elevation changes and navigable walkways |
| **Window & Door Voids** | `Color(0.18, 0.18, 0.20)` | 0.92 | Deep black/charcoal negative space accents |
| **Vehicle Bodies** | `Color(0.80, 0.81, 0.84)` | 0.65 | Slightly smoother clay finish to separate from walls |
| **Arterial Blood** | `Color(0.75, 0.02, 0.04)` | 0.35 (glossy) | High-contrast visceral gameplay reward, zero halo |
| **Supply Crates / Objectives**| Crimson / Cyan Emission | N/A | Immediate player eye draw through fog and shadows |

### 6.1 Lighting Calibration
* **Key Sun Light**:
  * Angle: **-52° pitch, 38° yaw** (strikes diagonally across the street canyon, creating crisp 45° angular building shadows).
  * Color: `Color(1.0, 0.99, 0.96)`, Energy: `1.4–1.6`.
  * Shadows: 4-split directional shadows with tight shadow bias (`0.005`) to prevent shadow acne on white clay.
* **Ambient Sky Fill**:
  * Source: Color `Color(0.55, 0.58, 0.65)`, Energy `0.40`.
  * Ambient light must never blow out shadows—crevices and alleys must stay moody and distinct.
* **SSAO (Screen Space Ambient Occlusion)**:
  * Mandatory in engine: Radius `1.8m–2.2m`, Intensity `2.5–3.0`.
  * Provides the distinctive CG clay-render contact shadow where buildings meet streets and steps meet risers.
