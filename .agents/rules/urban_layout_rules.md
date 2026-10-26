---
description: Mandatory rules and procedural architectural grammar for building urban layouts in Godot 4 and Blender
globs: ["scenes/sectors/*", "tools/generate_urban_layout*", "tools/generate_environment*", "tests/capture_*"]
---

# Tactical Isometric Urban Layout Rules

Always refer to [URBAN_LAYOUT_PROCEDURAL_RULES.md](file:///d:/Godot_Devs/Zombie_shooter/URBAN_LAYOUT_PROCEDURAL_RULES.md) when generating, modifying, or testing 3D urban layouts in Godot 4 or Blender.

## Critical Constraints to Always Enforce:

1. **Zero Foreground Playable Occlusion (The Stepped Elevation Rule)**:
   - Foreground structures (screen bottom & bottom-right) must NEVER exceed **2.8m** in height.
   - Use low flat-roof garages (≤ 2.8m), retaining walls (1.0m-1.4m), curbs, and open parking aprons in the foreground.
   - Place all tall monolithic structures (8m-16m, 3-5 stories) strictly in the **background** (top & top-left) where they can never block line-of-sight to the playable street floor.
   - Never place a tall building between the camera and a combat corridor.

2. **Edge-to-Edge Architectural Enclosure (Zero Void / Islanding)**:
   - The scene must NEVER look like a floating diorama box or isolated arena in a skybox.
   - The viewport frustum must be completely filled edge-to-edge with urban architecture, rooftops, or cordons.
   - Outer street exits must be physically blocked by lore-accurate quarantine boundaries: 5m reinforced blast-gates, jackknifed bus wreckage, or stacked shipping containers.
   - Ground sub-base slab must extend ≥ 30m beyond frustum limits.

3. **Procedural Building Variation (Non-Repetitive Grammar)**:
   - Every building must select an asymmetric archetype: chamfered 45° angle wedges, stepped-back roof terraces, L-shape nook creators, or cantilever overhangs.
   - Facades must feature 0.18m recessed dark window voids (`Color(0.18, 0.18, 0.20)`), protruding sills, and exterior wrap staircases.
   - Rooftops must feature continuous 0.5m parapet lips, HVAC fan chillers, stairwell access boxes, and water cisterns.

4. **3-Street Interconnecting Topology**:
   - Every sector must provide 3 interconnected combat paths:
     1. Main Avenue: 6.5m–7.5m diagonal corridor with abandoned vehicle chokepoints.
     2. Service Alley: 3.8m–5.0m branching chokepoint corridor.
     3. Upper Terrace: Elevated +3.2m above main street, reached via a 16-to-22 step street staircase with retaining parapets.

5. **Lighting & Contrast Hierarchy**:
   - Monochromatic architectural clay (`Color(0.85, 0.85, 0.87)`), darker road asphalt (`Color(0.78, 0.78, 0.80)`), and stark dark voids.
   - Directional sun at -52° pitch, 38° yaw casting sharp diagonal shadows.
   - SSAO active (radius 2.0m, intensity 2.8) to pop architectural steps and crevices.
   - Arterial crimson blood splatters (`Color(0.75, 0.02, 0.04)`) pop with maximum visual contrast against the matte ground.
