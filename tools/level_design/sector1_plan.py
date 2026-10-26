"""Sector 01 layout plan + camera-occlusion validator.

World axes match Godot: +X east (screen right), +Z south (screen bottom), +Y up.
The game camera sits at player + (18, 60, 42), so it looks over the SOUTH and EAST
side of whatever the player stands on. Tall buildings belong on the north/west side
of walkable space; anything on the south/east side gets height-capped here.
"""
import json
import math
import sys

import numpy as np

CAM_OFFSET = np.array([18.0, 60.0, 42.0])
TORSO = 0.9          # height on the player that must stay visible
CELL = 0.5           # raster resolution for walkable checks (m)
TERRACE_Y = 3.2

# ── Walkable floors: (name, x0, x1, z0, z1, y) ──────────────────────────────
FLOORS = [
    ("Checkpoint",      -12, 12,  26, 36, 0.0),
    ("Avenue",           -5,  5, -12, 26, 0.0),
    ("WestPlaza",       -18, -5,   0, 14, 0.0),
    ("EastAlley",         5, 26,   0, 4.5, 0.0),
    ("ServiceLane",      21, 26, 4.5, 12, 0.0),
    ("ParkingLot",        9, 26,  12, 30, 0.0),
    ("Driveway",          5,  9,  18, 24, 0.0),
    ("WestLane",        -18,-13, -12,  0, 0.0),
    ("EastLane",          9, 13, -12,  0, 0.0),
    ("Terrace",         -24, 12, -52,-20, TERRACE_Y),
]
# Stairs rise toward the north (from y0 at z1 to y1 at z0): (name, x0, x1, z0, z1, y0, y1)
STAIRS = [
    ("GrandStair", -3,  3, -20, -12, 0.0, TERRACE_Y),
    ("WestStair", -18,-13, -20, -12, 0.0, TERRACE_Y),
    ("EastStair",   9, 13, -20, -12, 0.0, TERRACE_Y),
]
# ── Solid masses: (name, x0, x1, z0, z1, base_y, target_height, kind) ────────
# Targets are the design intent; the validator lowers anything that would hide the player.
BLOCKS = [
    # West side of the avenue (far side → can be tall)
    ("WestRowSouth_Low",  -24, -5, 14, 18, 0.0, 2.6, "shed"),
    ("WestLaneGarden",    -13,-10, -12,  0, 0.0, 1.0, "wall"),
    ("WestRowNorth",      -10, -5,-12,  0, 0.0, 10.0, "building"),
    ("WestBack",          -30,-18,-12, 14, 0.0, 12.0, "building"),
    # East side of the avenue (camera side → stepped back and low)
    ("EastShops",         6.5,  9,   7, 18, 0.0, 4.0, "building"),
    ("EastLaneRail",       13, 16, -12,  0, 0.0, 1.0, "wall"),
    ("Warehouse",          16, 30, -12,  0, 0.0, 9.0, "building"),
    ("AlleyFence",          9, 21, 4.5, 5.5, 0.0, 1.2, "wall"),
    ("Garages",             9, 21, 5.5, 12, 0.0, 2.8, "shed"),
    ("EastRail",           26, 27.5,  0, 31, 0.0, 1.0, "wall"),
    ("EastContainers",   27.5, 30,   0, 31, 0.0, 5.2, "containers"),
    # Camera-side setback strips along the avenue: low planters keep the view open
    ("PlanterNorth",        5, 6.5, -12,  0, 0.0, 0.8, "planter"),
    ("PlanterAlley",        5,  9, 4.5,  7, 0.0, 0.8, "planter"),
    ("PlanterShops",        5, 6.5,  7, 18, 0.0, 0.8, "planter"),
    ("PlanterSouth",        5,  9,  24, 26, 0.0, 0.8, "planter"),
    ("LotSouthWall",       12, 26,  30, 31, 0.0, 1.0, "wall"),
    ("CheckpointEastWall", 12, 13,  31, 36, 0.0, 1.0, "wall"),
    ("CheckpointWestWall",-13,-12,  26, 28, 0.0, 1.0, "wall"),
    ("Pump",              6.5,  9,  -12, 0, 0.0, 4.0, "building"),
    # South edge (camera side of everything → must be low)
    ("SouthBarrier",      -16, 13,  36, 37, 0.0, 1.0, "wall"),
    ("PileupBus",         -16, -12, 28, 38, 0.0, 3.2, "bus"),
    # Retaining wall under the terrace is implicit (terrace floor at +3.2)
    ("RetainingWest",     -13, -3, -20,-12, 0.0, TERRACE_Y, "retaining"),
    ("RetainingMid",        3,  9, -20,-12, 0.0, TERRACE_Y, "retaining"),
    ("RetainingEast",      13, 16, -20,-12, 0.0, TERRACE_Y, "retaining"),
    ("RetainingFarWest",  -24,-18, -20,-12, 0.0, TERRACE_Y, "retaining"),
    # Terrace (far north: backdrop can be tall on the north/west)
    ("BlastGateWall",     -24, 16, -56,-52, TERRACE_Y, 5.0, "wall"),
    ("TerraceWestTower",  -30,-24, -56,-20, TERRACE_Y, 14.0, "building"),
    ("TerraceRail",        12, 13.5, -52,-20, TERRACE_Y, 1.0, "wall"),
    ("TerraceContainers", 13.5, 16, -48,-24, TERRACE_Y, 5.2, "containers"),
    ("CoverSandbagsW",    -12,-9, -40,-39, TERRACE_Y, 1.0, "cover"),
    ("CoverSandbagsE",      7, 10, -36,-35, TERRACE_Y, 1.0, "cover"),
]
# ── Enterable rooms: (name, x0, x1, z0, z1, base_y, wall_height, doors) ─────────
# doors: (side, centre along that wall, width). When the player is inside, the roof
# and the south/east (camera-side) walls fade out, so a room never hides its occupant.
ROOMS = [
    ("Clinic", -24, -5, 18, 26, 0.0, 3.6, [("east", 22.0, 2.4)]),
    ("Depot", -24, -16, -52, -44, TERRACE_Y, 3.6, [("south", -20.0, 2.4)]),
]
WALL_T = 0.3
ROOF_T = 0.65  # roof slab + parapet


def expand_rooms(rooms):
    """Rooms -> (solid parts tagged with the room name, walkable floors). Mirrors LayoutBuilder._build_room."""
    parts, floors = [], []
    for name, x0, x1, z0, z1, base, h, doors in rooms:
        walls = {
            "north": (x0, x1, z0, z0 + WALL_T, "x"),
            "south": (x0, x1, z1 - WALL_T, z1, "x"),
            "west": (x0, x0 + WALL_T, z0 + WALL_T, z1 - WALL_T, "z"),
            "east": (x1 - WALL_T, x1, z0 + WALL_T, z1 - WALL_T, "z"),
        }
        for side, (a0, a1, c0, c1, axis) in walls.items():
            spans = [(a0, a1)] if axis == "x" else [(c0, c1)]
            for dside, at, width in doors:
                if dside != side:
                    continue
                g0, g1 = at - width / 2, at + width / 2
                spans = [piece for lo, hi in spans for piece in ((lo, min(hi, g0)), (max(lo, g1), hi)) if piece[1] - piece[0] > 0.01]
                if axis == "x":
                    floors.append((f"{name}Door", g0, g1, c0, c1, base))
                else:
                    floors.append((f"{name}Door", a0, a1, g0, g1, base))
            for i, (lo, hi) in enumerate(spans):
                if axis == "x":
                    parts.append((f"{name}:{side}{i}", lo, hi, c0, c1, base, h, "roomwall"))
                else:
                    parts.append((f"{name}:{side}{i}", a0, a1, lo, hi, base, h, "roomwall"))
        parts.append((f"{name}:roof", x0, x1, z0, z1, base + h, ROOF_T, "roof"))
        floors.append((f"{name}Interior", x0 + WALL_T, x1 - WALL_T, z0 + WALL_T, z1 - WALL_T, base))
    return parts, floors


ROOM_PARTS, ROOM_FLOORS = expand_rooms(ROOMS)
FLOORS = FLOORS + ROOM_FLOORS


def all_blocks():
    return BLOCKS + ROOM_PARTS


def room_of(x, z):
    """Room whose footprint (doorways included) contains (x, z): its cutaway is active there."""
    for name, x0, x1, z0, z1, *_ in ROOMS:
        if x0 <= x < x1 and z0 <= z < z1:
            return name
    return None


# Props: (type, x, y, z, yaw_degrees). Low clutter only; the builder gives each a fitted box collider.
PROPS = [
    ("car_a", -1.6, 0, 12, 25), ("car_b", 2.0, 0, 9, -150), ("car_c", -2.2, 0, -3, 200), ("car_a", 1.8, 0, -7, 30),
    ("car_b", 12, 0, 15, 90), ("car_c", 16, 0, 15.5, 95), ("car_a", 20, 0, 22, 80), ("car_b", 13, 0, 27, 100),
    ("jersey", -8.5, 0, 27, 0), ("jersey", -5.5, 0, 27.2, 4), ("jersey", 5.5, 0, 27.2, -4), ("jersey", 8.5, 0, 27, 0),
    ("pole", 4.6, 0, 21, 0), ("pole", 4.6, 0, 1, 0), ("lamp", -4.6, 0, 17, 90), ("lamp", -4.6, 0, -1, 90),
    ("tree_a", -14, 0, 10, 20), ("tree_b", -8, 0, 2.5, 140), ("tree_b", 6, TERRACE_Y, -48, 60),
    ("crate", -10.5, TERRACE_Y, -37.5, 10), ("crate", 8.5, TERRACE_Y, -33.5, -15), ("crate", 24, 0, 28, 30),
]
MARKERS = {
    "PlayerSpawn":   [(0, 0.3, 32)],
    "ExtractionZone":[(0, TERRACE_Y, -42)],
    "ObjectiveSpawns": [(22, 0.3, 2), (19, 0.3, 26), (-14, TERRACE_Y + 0.3, -42)],
    "ZombieSpawners": [(-16, 0.3, 4), (-4.5, 0.3, -6), (24, 0.3, 1), (24, 0.3, 14),
                       (11, 0.3, -6), (-4, TERRACE_Y + 0.3, -50), (10, TERRACE_Y + 0.3, -24)],
    "OpeningMob":     [(-1.5, 0.3, 6), (1.5, 0.3, 4), (0, 0.3, 2), (-2, 0.3, 0), (2, 0.3, -2)],
    "PickupSpawns":   [(-12, 0.3, 6), (11, 0.3, 20), (8, TERRACE_Y + 0.3, -30)],
    "BloodDecor":     [(1.5, 0.05, 8), (-2.0, 0.05, -2), (3.0, 0.05, 20)],
    # Story step locations (contracts reference them by name)
    "StepMarkers":    [(-15.5, 0.0, 9.0), (-20.0, TERRACE_Y, -48.5), (-14.0, 0.0, 22.0), (22.0, 0.3, 2.0)],
    # Optional intel documents (lore + research cores)
    "IntelSpots":     [(-21.0, 0.3, 24.5), (25.0, 0.3, 25.0), (9.0, TERRACE_Y + 0.3, -50.0)],
}
# Marker names. The zombie spawner treats names containing "door", "terrace", "bay" etc.
# (or markers above 1.2 m) as building spawns; the last OpeningMob marker is a runner.
MARKER_NAMES = {
    "ZombieSpawners": ["DoorWestPlaza", "DoorAvenueNorth", "AlleyEnd", "BayParkingEast",
                       "EastLaneGate", "TerraceBlastGate", "TerraceEastStair"],
    "OpeningMob": ["Shambler1", "Shambler2", "Shambler3", "Shambler4", "Runner1"],
    "ObjectiveSpawns": ["EastAlley", "ParkingLot", "TerraceDepot"],
    "PickupSpawns": ["PlazaPickup", "ParkingPickup", "TerracePickup"],
    "BloodDecor": ["Pool1", "Pool2", "Pool3"],
    "StepMarkers": ["NestWestPlaza", "DepotFuse", "ClinicKeycard", "RecorderCase"],
    "IntelSpots": ["IntelClinic", "IntelParking", "IntelTerrace"],
}
SECTOR = {"id": 1, "name": "SECTOR 01: QUARANTINE BLOCK", "bounds": [-30, -56, 60, 94]}


def walk_height(x, z):
    """Floor height at (x, z) if walkable, else None."""
    for _, x0, x1, z0, z1, y0, y1 in STAIRS:
        if x0 <= x < x1 and z0 <= z < z1:
            return y0 + (y1 - y0) * (z1 - z) / (z1 - z0)
    best = None
    for _, x0, x1, z0, z1, y in FLOORS:
        if x0 <= x < x1 and z0 <= z < z1:
            best = y if best is None else max(best, y)
    return best


def blocked(x, z, y):
    """Is a standing player (y .. y+1.8) inside a solid here? Roofs overhead don't count."""
    for b in all_blocks():
        _, x0, x1, z0, z1, by, h, _ = b
        if x0 <= x < x1 and z0 <= z < z1 and by + h > y + 0.05 and by < y + 1.8:
            return True
    return False


def walkable_cells():
    cells = []
    xs = np.arange(-35, 35, CELL) + CELL / 2
    zs = np.arange(-60, 45, CELL) + CELL / 2
    for x in xs:
        for z in zs:
            y = walk_height(x, z)
            if y is not None and not blocked(x, z, y):
                cells.append((x, y, z))
    return cells


def ray_hits_block(p, blk, height):
    """Does the ray from p toward the camera pass through blk's box (with given height)?"""
    _, x0, x1, z0, z1, by, _, _ = blk
    lo = np.array([x0, by, z0]); hi = np.array([x1, by + height, z1])
    d = CAM_OFFSET
    tmin, tmax = 1e-4, 1.0
    for i in range(3):
        if abs(d[i]) < 1e-9:
            if p[i] < lo[i] or p[i] > hi[i]:
                return False
        else:
            t1 = (lo[i] - p[i]) / d[i]; t2 = (hi[i] - p[i]) / d[i]
            tmin = max(tmin, min(t1, t2)); tmax = min(tmax, max(t1, t2))
            if tmin > tmax:
                return False
    return True


def max_visible_height(blk, cells):
    """Tallest height for blk that never hides the player's torso on any walkable cell."""
    _, x0, x1, z0, z1, by, target, _ = blk
    # Only cells to the north/west can be hidden by this block (camera is south-east)
    near = [np.array([x, y + TORSO, z]) for x, y, z in cells
            if x <= x1 + 1 and z <= z1 + 1 and x >= x0 - 60 and z >= z0 - 60]
    lo, hi = 0.0, target
    if not any(ray_hits_block(p, blk, hi) for p in near):
        return hi
    for _ in range(14):
        mid = (lo + hi) / 2
        if any(ray_hits_block(p, blk, mid) for p in near):
            hi = mid
        else:
            lo = mid
    return math.floor(lo * 10) / 10


def check_reachability(cells):
    """Breadth-first walk from the player spawn over walkable cells (max 0.45 m step)."""
    from collections import deque
    idx = {(math.floor(x / CELL), math.floor(z / CELL)): y for x, y, z in cells}
    def key(x, z):
        return (math.floor(x / CELL), math.floor(z / CELL))
    sx, _, sz = MARKERS["PlayerSpawn"][0]
    start = min(idx, key=lambda k: (k[0] * CELL - sx) ** 2 + (k[1] * CELL - sz) ** 2)
    dist = {start: 0.0}
    q = deque([start])
    while q:
        c = q.popleft()
        for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (c[0] + dx, c[1] + dz)
            if n in idx and n not in dist and abs(idx[n] - idx[c]) <= 0.45:
                dist[n] = dist[c] + CELL
                q.append(n)
    out = {"reachable_share": f"{len(dist) / len(idx):.1%}"}
    for group in ("ExtractionZone", "ObjectiveSpawns", "ZombieSpawners", "PickupSpawns", "StepMarkers", "IntelSpots"):
        for i, (x, y, z) in enumerate(MARKERS[group]):
            k = key(x, z)
            if k not in idx:
                out[f"{group}[{i}]"] = "NOT ON A WALKABLE CELL (inside a solid or off the map)"
                continue
            d = dist.get(k)
            out[f"{group}[{i}]"] = "UNREACHABLE" if d is None else f"{d:.0f} m walk"
    return out


def solid_top(x, z):
    top = None
    for b in all_blocks():
        _, x0, x1, z0, z1, by, h, _ = b
        if x0 <= x < x1 and z0 <= z < z1:
            top = by + h if top is None else max(top, by + h)
    return top


def compute_barriers(cells, blocks):
    """Edges where walkable space ends without a real wall. Returns merged segments.
    kind "rail": a visible 0.9 m railing (drop-off, low ledge or low solid next to a floor)
    kind "void": open ground with nothing there; these are design holes to fix."""
    global BLOCKS
    saved = BLOCKS
    BLOCKS = [(b["name"], b["x0"], b["x1"], b["z0"], b["z1"], b["base"], b["height"], b["kind"]) for b in blocks]
    idx = {(math.floor(x / CELL), math.floor(z / CELL)): y for x, y, z in cells}
    edges = {"rail": [], "void": [], "blocker": []}
    for (i, j), y in idx.items():
        for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (i + di, j + dj)
            if n in idx and abs(idx[n] - y) <= 0.45:
                continue
            nx, nz = (n[0] + 0.5) * CELL, (n[1] + 0.5) * CELL
            top = solid_top(nx, nz)
            if top is not None and top >= y + 1.5:
                continue  # a real wall already stops the player
            if n in idx and idx[n] > y + 0.45:
                continue  # neighbour is higher floor: its own edge gets the rail
            if top is None and n not in idx:
                kind = "void"
            elif (n in idx and idx[n] < y - 0.45) or (top is not None and top <= y + 0.05):
                kind = "rail"      # drop-off or flush ledge: visible railing + collider
            else:
                kind = "blocker"   # low wall/planter already visible: collider only
            edges.setdefault(kind, [])
            # edge line in world units
            if di != 0:
                ex = (i + (1 if di > 0 else 0)) * CELL
                edges[kind].append(("v", ex, j * CELL, (j + 1) * CELL, y))
            else:
                ez = (j + (1 if dj > 0 else 0)) * CELL
                edges[kind].append(("h", ez, i * CELL, (i + 1) * CELL, y))
    BLOCKS = saved
    out = []
    for kind, es in edges.items():
        groups = {}
        for o, line, a0, a1, y in es:
            groups.setdefault((o, round(line, 3), round(y, 2)), []).append((a0, a1))
        for (o, line, y), spans in groups.items():
            spans.sort()
            cur = list(spans[0])
            for a0, a1 in spans[1:] + [(None, None)]:
                if a0 is not None and abs(a0 - cur[1]) < 1e-6:
                    cur[1] = a1
                    continue
                if o == "v":
                    out.append(dict(kind=kind, x0=line, x1=line, z0=cur[0], z1=cur[1], y=y))
                else:
                    out.append(dict(kind=kind, x0=cur[0], x1=cur[1], z0=line, z1=line, y=y))
                if a0 is not None:
                    cur = [a0, a1]
    return out


NAV_X0, NAV_Z0, NAV_W, NAV_H = -35.0, -60.0, 140, 210  # 0.5 m cells covering x -35..35, z -60..45


def build_nav_grid(cells):
    """Walkable grid for the zombie flow field: one string per row, one char per cell.
    '.' = not walkable, otherwise chr(48 + floor height in decimetres)."""
    rows = [["."] * NAV_W for _ in range(NAV_H)]
    for x, y, z in cells:
        i = math.floor((x - NAV_X0) / CELL)
        j = math.floor((z - NAV_Z0) / CELL)
        if 0 <= i < NAV_W and 0 <= j < NAV_H:
            rows[j][i] = chr(48 + int(round(y * 10)))
    return dict(x0=NAV_X0, z0=NAV_Z0, cell=CELL, w=NAV_W, h=NAV_H, rows=["".join(r) for r in rows])


def export_gdscript(data, path):
    """Write the plan as a GDScript constant so it ships in every export (JSON files don't by default)."""
    game = {k: data[k] for k in ("sector", "floors", "stairs", "blocks", "rooms", "barriers", "props", "markers", "marker_names", "nav")}
    # Room interiors and door thresholds are built by LayoutBuilder._build_room, not as plain floors
    game["floors"] = [f for f in game["floors"] if not any(f["name"].startswith(r["name"]) for r in game["rooms"])]
    body = json.dumps(game, indent="\t")
    with open(path, "w") as f:
        f.write("extends RefCounted\n")
        f.write("## Generated by tools/level_design/sector1_plan.py. Do not edit by hand:\n")
        f.write("## change the plan there and re-run it so the camera and walkability checks run again.\n\n")
        f.write("const PLAN := " + body + "\n")


def main():
    cells = walkable_cells()
    out_blocks = []
    report = []
    for b in BLOCKS:
        name, x0, x1, z0, z1, by, target, kind = b
        if kind == "retaining":
            h = target  # retaining walls sit north of the street below; terrace is on top
        else:
            h = max_visible_height(b, cells)
        out_blocks.append(dict(name=name, x0=x0, x1=x1, z0=z0, z1=z1, base=by, height=h, target=target, kind=kind))
        if h + 1e-6 < target:
            culprits = set()
            for x, y, z in cells:
                if ray_hits_block(np.array([x, y + TORSO, z]), b, h + 0.3):
                    for fn, a0, a1, c0, c1, _ in FLOORS:
                        if a0 <= x < a1 and c0 <= z < c1:
                            culprits.add(fn)
                    for sn, a0, a1, c0, c1, _, _ in STAIRS:
                        if a0 <= x < a1 and c0 <= z < c1:
                            culprits.add(sn)
            report.append(f"  capped {name:20s} {target:5.1f} m -> {h:4.1f} m   (would hide: {', '.join(sorted(culprits))})")
    # Final verification with the capped heights
    final = [(b["name"], b["x0"], b["x1"], b["z0"], b["z1"], b["base"], b["height"], b["kind"]) for b in out_blocks]
    final += ROOM_PARTS
    hidden = 0
    for x, y, z in cells:
        p = np.array([x, y + TORSO, z])
        own = room_of(x, z)
        if any(ray_hits_block(p, fb, fb[6]) for fb in final
               if fb[7] != "retaining" and not (own and fb[0].startswith(own + ":"))):
            hidden += 1
    reach = check_reachability(cells)
    barriers = compute_barriers(cells, out_blocks)
    voids = [b for b in barriers if b["kind"] == "void"]
    rails = [b for b in barriers if b["kind"] == "rail"]
    blockers = [b for b in barriers if b["kind"] == "blocker"]
    print(f"barriers: {len(rails)} railings, {len(blockers)} invisible blockers, {len(voids)} open-ground holes")
    for v in voids:
        print(f"  HOLE x {v['x0']:.1f}..{v['x1']:.1f}  z {v['z0']:.1f}..{v['z1']:.1f}  y {v['y']}")
    data = dict(
        camera_offset=CAM_OFFSET.tolist(), torso=TORSO, cell=CELL,
        floors=[dict(name=n, x0=a, x1=b, z0=c, z1=d, y=y) for n, a, b, c, d, y in FLOORS],
        stairs=[dict(name=n, x0=a, x1=b, z0=c, z1=d, y0=y0, y1=y1) for n, a, b, c, d, y0, y1 in STAIRS],
        sector=SECTOR, blocks=out_blocks, markers=MARKERS, marker_names=MARKER_NAMES, barriers=barriers,
        nav=build_nav_grid(cells),
        rooms=[dict(name=n, x0=a, x1=b, z0=c, z1=d, base=y, height=h,
                    doors=[dict(side=ds, at=at, width=w) for ds, at, w in doors])
               for n, a, b, c, d, y, h, doors in ROOMS],
        props=[dict(type=t, pos=[x, y, z], yaw=r) for t, x, y, z, r in PROPS],
        stats=dict(walkable_cells=len(cells), walkable_m2=len(cells) * CELL * CELL, hidden_cells=hidden, reach=reach),
    )
    out_path = sys.argv[1] if len(sys.argv) > 1 else "sector1_plan.json"
    json.dump(data, open(out_path, "w"), indent=1)
    if len(sys.argv) > 2:
        export_gdscript(data, sys.argv[2])
    for k, v in reach.items():
        print(f"  {k:28s} {v}")
    print(f"walkable: {len(cells)} cells ({len(cells) * CELL * CELL:.0f} m2), hidden after caps: {hidden}")
    print("\n".join(report) if report else "  no caps needed")


if __name__ == "__main__":
    main()
