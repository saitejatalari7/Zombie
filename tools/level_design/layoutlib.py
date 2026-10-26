"""Shared layout pipeline: camera-occlusion caps, reachability, boundary rails, nav grid, export.

A layout is a module in layouts/ that defines the data below; build_layouts.py runs this
pipeline on each one and writes scripts/layout/plans/<ID>.gd for LayoutBuilder.

World axes match Godot: +X east (screen right), +Z south (screen bottom), +Y up.
The game camera sits south-east of the player (CAM_OFFSET, camera_follow.gd), so it looks
over the SOUTH and EAST side of whatever the player stands on. Tall buildings belong on the
north/west side of walkable space; anything on the south/east side gets height-capped here.

Layout module contents:
  ID, SECTOR {"id", "name", "bounds": [x, z, w, h]}
  FLOORS  [(name, x0, x1, z0, z1, y)]                walkable rectangles
  STAIRS  [(name, x0, x1, z0, z1, y0, y1)]           rise toward -Z (y0 at z1, y1 at z0)
  BLOCKS  [(name, x0, x1, z0, z1, base, height, kind)] solids; height is a target, may be capped
  ROOMS   [(name, x0, x1, z0, z1, base, height, [(side, at, width)])]  enterable, with cutaway
  PROPS   [(type, x, y, z, yaw)]
  MARKERS {group: [(x, y, z)]}, MARKER_NAMES {group: [name]}
"""
import json
import math
from collections import deque

import numpy as np

CAM_OFFSET = np.array([9.9, 33.0, 23.1])
TORSO = 0.9          # height on the player that must stay visible
CELL = 0.5           # raster resolution for walkable checks (m)
WALL_T = 0.3
ROOF_T = 0.65        # roof slab + parapet
STEP_MAX = 0.45      # tallest height change the player walks over

# Prop footprints in the model's own space (x0, x1, z0, z1), measured from the .glb meshes.
# Thin props only get a 0.4 m trunk collider in LayoutBuilder, so that is their footprint.
PROP_FOOTPRINTS = {
    "car_a": (-0.64, 0.81, -2.03, 1.10),
    "car_b": (-1.35, 1.35, -1.15, 1.15),
    "car_c": (-0.57, 0.65, -0.90, 0.90),
    "jersey": (-1.25, 1.25, -0.30, 0.30),
    "crate": (-0.76, 0.76, -0.52, 0.50),
    "pole": (-0.2, 0.2, -0.2, 0.2), "lamp": (-0.2, 0.2, -0.2, 0.2),
    "tree_a": (-0.2, 0.2, -0.2, 0.2), "tree_b": (-0.2, 0.2, -0.2, 0.2),
}
PROP_MARGIN = 0.25   # keep zombies (radius ~0.4) from planning a path that grazes a prop

# Hive sites: open floor needed around each size of hive (m), how many sites per layout,
# and how far they keep from the spawn, the LZ and story objectives.
HIVE_CLEARANCE = {"L": 3.0, "M": 2.0, "S": 1.3}
HIVE_SITE_COUNT = 6
HIVE_MIN_SPACING = 12.0
HIVE_SPAWN_CLEAR = 22.0
HIVE_LZ_CLEAR = 10.0
HIVE_MARKER_CLEAR = 5.0

REQUIRED_MARKERS = ("PlayerSpawn", "ExtractionZone", "ZombieSpawners", "OpeningMob", "PickupSpawns")


class Layout:
    def __init__(self, mod):
        self.id = mod.ID
        self.sector = mod.SECTOR
        self.rooms = list(getattr(mod, "ROOMS", []))
        self.room_parts, room_floors = expand_rooms(self.rooms)
        self.floors = list(mod.FLOORS) + room_floors
        self.stairs = list(getattr(mod, "STAIRS", []))
        self.blocks = list(mod.BLOCKS)
        self.props = list(getattr(mod, "PROPS", []))
        self.markers = mod.MARKERS
        self.marker_names = getattr(mod, "MARKER_NAMES", {})
        bx, bz, bw, bh = self.sector["bounds"]
        # Raster window: the bounds plus a margin
        self.gx0, self.gz0 = math.floor(bx) - 5.0, math.floor(bz) - 5.0
        self.gw = int(math.ceil((bw + 10) / CELL))
        self.gh = int(math.ceil((bh + 10) / CELL))
        self.solids = self.blocks + self.room_parts
        self.prop_cells = self._prop_cells()
        self._prop_levels = sorted({p[2] for p in self.props})

    def _prop_cells(self):
        """Raster cells covered by a prop's collider: not walkable, but not a hole either."""
        out = set()
        for ptype, px, py, pz, yaw in self.props:
            x0, x1, z0, z1 = PROP_FOOTPRINTS[ptype]
            c, s_ = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
            r = max(abs(x0), abs(x1), abs(z0), abs(z1)) + PROP_MARGIN + CELL
            for i in range(math.floor((px - r) / CELL), math.ceil((px + r) / CELL)):
                for j in range(math.floor((pz - r) / CELL), math.ceil((pz + r) / CELL)):
                    dx, dz = (i + 0.5) * CELL - px, (j + 0.5) * CELL - pz
                    # world -> model space (Godot yaw about +Y)
                    lx = dx * c - dz * s_
                    lz = dx * s_ + dz * c
                    if (x0 - PROP_MARGIN <= lx <= x1 + PROP_MARGIN and z0 - PROP_MARGIN <= lz <= z1 + PROP_MARGIN):
                        out.add((i, j, py))
        return out

    # ── geometry queries ──
    def walk_height(self, x, z):
        for _, x0, x1, z0, z1, y0, y1 in self.stairs:
            if x0 <= x < x1 and z0 <= z < z1:
                return y0 + (y1 - y0) * (z1 - z) / (z1 - z0)
        best = None
        for _, x0, x1, z0, z1, y in self.floors:
            if x0 <= x < x1 and z0 <= z < z1:
                best = y if best is None else max(best, y)
        return best

    def blocked(self, x, z, y, solids=None):
        """Is a standing player (y .. y+1.8) inside a solid here? Roofs overhead don't count."""
        for _, x0, x1, z0, z1, by, h, _ in (solids if solids is not None else self.solids):
            if x0 <= x < x1 and z0 <= z < z1 and by + h > y + 0.05 and by < y + 1.8:
                return True
        return False

    def solid_top(self, x, z, solids):
        top = None
        for _, x0, x1, z0, z1, by, h, _ in solids:
            if x0 <= x < x1 and z0 <= z < z1:
                top = by + h if top is None else max(top, by + h)
        return top

    def _prop_here(self, x, z, y):
        k = cell_key(x, z)
        return any((k[0], k[1], py) in self.prop_cells for py in self._prop_levels if abs(py - y) < 0.6)

    def room_of(self, x, z):
        for name, x0, x1, z0, z1, *_ in self.rooms:
            if x0 <= x < x1 and z0 <= z < z1:
                return name
        return None

    def walkable_cells(self):
        cells = []
        for i in range(self.gw):
            for j in range(self.gh):
                x = self.gx0 + (i + 0.5) * CELL
                z = self.gz0 + (j + 0.5) * CELL
                y = self.walk_height(x, z)
                if y is not None and not self.blocked(x, z, y) and not self._prop_here(x, z, y):
                    cells.append((x, y, z))
        return cells


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


def cell_key(x, z):
    return (math.floor(x / CELL), math.floor(z / CELL))


def walk_distances(L, cells):
    idx = {cell_key(x, z): y for x, y, z in cells}
    sx, _, sz = L.markers["PlayerSpawn"][0]
    start = min(idx, key=lambda k: (k[0] * CELL - sx) ** 2 + (k[1] * CELL - sz) ** 2)
    dist = {start: 0.0}
    q = deque([start])
    while q:
        c = q.popleft()
        for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (c[0] + dx, c[1] + dz)
            if n in idx and n not in dist and abs(idx[n] - idx[c]) <= STEP_MAX:
                dist[n] = dist[c] + CELL
                q.append(n)
    return idx, dist


def pick_hive_sites(L, cells):
    """Hive sites for the layout: reachable open floor, spread out, biggest sizes first.
    Returns (points, names). Names carry the biggest hive that fits: HiveL_1, HiveM_2..."""
    idx, dist = walk_distances(L, cells)
    def flat(a, b):
        return math.hypot(a[0] - b[0], a[2] - b[2])
    spawn = L.markers["PlayerSpawn"][0]
    lz = L.markers["ExtractionZone"][0]
    keep_off = [p for g in ("StepMarkers", "ObjectiveSpawns", "IntelSpots", "PickupSpawns") for p in L.markers.get(g, [])]

    def capacity(k, y):
        for size in ("L", "M", "S"):
            r = HIVE_CLEARANCE[size]
            n = int(math.ceil(r / CELL))
            ok = True
            for di in range(-n, n + 1):
                for dj in range(-n, n + 1):
                    if (di * di + dj * dj) * CELL * CELL > r * r:
                        continue
                    h = idx.get((k[0] + di, k[1] + dj))
                    if h is None or abs(h - y) > 0.3:
                        ok = False
                        break
                if not ok:
                    break
            if ok:
                return size
        return None

    cands = []
    for k, y in sorted(idx.items()):
        if k not in dist or k[0] % 2 or k[1] % 2:
            continue  # reachable only; a 1 m grid of candidates is plenty
        p = ((k[0] + 0.5) * CELL, y, (k[1] + 0.5) * CELL)
        if L.room_of(p[0], p[2]):
            continue  # hives grow in the open, where the camera always sees them
        if flat(p, spawn) < HIVE_SPAWN_CLEAR or flat(p, lz) < HIVE_LZ_CLEAR:
            continue
        if any(flat(p, q) < HIVE_MARKER_CLEAR for q in keep_off):
            continue
        cap = capacity(k, y)
        if cap:
            cands.append((p, cap))
    chosen = []
    # Biggest first: up to 2 mound sites, then nest sites, then pods; farthest-point spread
    for size, quota in (("L", 2), ("M", 2), ("S", HIVE_SITE_COUNT)):
        fits = [c for c in cands if "SML".index(c[1]) >= "SML".index(size)]
        while fits and quota > 0 and len(chosen) < HIVE_SITE_COUNT:
            best, best_d = None, -1.0
            for p, cap in fits:
                d = min([flat(p, q) for q, _ in chosen] + [flat(p, spawn)])
                if d > best_d:
                    best, best_d = (p, cap), d  # named by what the site can hold
            if best is None or (chosen and best_d < HIVE_MIN_SPACING):
                break
            chosen.append(best)
            quota -= 1
    points = [(round(p[0], 2), round(p[1], 2), round(p[2], 2)) for p, _ in chosen]
    names = [f"Hive{size}_{i + 1}" for i, (_, size) in enumerate(chosen)]
    return points, names


def check_reachability(L, cells):
    """Breadth-first walk from the player spawn. Returns (report dict, problems list)."""
    idx, dist = walk_distances(L, cells)
    out = {"reachable_share": f"{len(dist) / len(idx):.1%}"}
    problems = []
    for group, points in L.markers.items():
        if group in ("PlayerSpawn", "BloodDecor"):
            continue
        names = L.marker_names.get(group, [])
        for i, (x, y, z) in enumerate(points):
            label = f"{group}[{names[i] if i < len(names) else i}]"
            k = cell_key(x, z)
            if k not in idx:
                out[label] = "NOT ON A WALKABLE CELL"
                problems.append(label + " not on a walkable cell")
                continue
            d = dist.get(k)
            if d is None:
                out[label] = "UNREACHABLE"
                problems.append(label + " unreachable")
            else:
                out[label] = f"{d:.0f} m walk"
    if len(dist) < len(idx) * 0.97:
        problems.append(f"only {len(dist) / len(idx):.0%} of walkable space is reachable from the spawn")
    return out, problems


def compute_barriers(L, cells, solids):
    """Edges where walkable space ends without a real wall. Returns merged segments.
    kind "rail": a visible railing (drop-off, or flush ledge)
    kind "blocker": low wall/planter already visible: invisible collider only
    kind "void": open ground with nothing there; these are design holes to fix."""
    idx = {cell_key(x, z): y for x, y, z in cells}
    edges = {"rail": [], "void": [], "blocker": []}
    for (i, j), y in idx.items():
        for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (i + di, j + dj)
            if n in idx and abs(idx[n] - y) <= STEP_MAX:
                continue
            nx, nz = (n[0] + 0.5) * CELL, (n[1] + 0.5) * CELL
            if L._prop_here(nx, nz, y):
                continue  # the prop's own collider closes this edge
            top = L.solid_top(nx, nz, solids)
            if top is not None and top >= y + 1.5:
                continue  # a real wall already stops the player
            if n in idx and idx[n] > y + STEP_MAX:
                continue  # neighbour is higher floor: its own edge gets the rail
            if top is None and n not in idx:
                kind = "void"
            elif (n in idx and idx[n] < y - STEP_MAX) or (top is not None and top <= y + 0.05):
                kind = "rail"
            else:
                kind = "blocker"
            if di != 0:
                ex = (i + (1 if di > 0 else 0)) * CELL
                edges[kind].append(("v", ex, j * CELL, (j + 1) * CELL, y))
            else:
                ez = (j + (1 if dj > 0 else 0)) * CELL
                edges[kind].append(("h", ez, i * CELL, (i + 1) * CELL, y))
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


def build_nav_grid(L, cells):
    """Walkable grid for the zombie flow field: one string per row, one char per cell.
    '.' = not walkable, otherwise chr(48 + floor height in decimetres)."""
    rows = [["."] * L.gw for _ in range(L.gh)]
    for x, y, z in cells:
        i = math.floor((x - L.gx0) / CELL)
        j = math.floor((z - L.gz0) / CELL)
        if 0 <= i < L.gw and 0 <= j < L.gh:
            rows[j][i] = chr(48 + int(round(y * 10)))
    return dict(x0=L.gx0, z0=L.gz0, cell=CELL, w=L.gw, h=L.gh, rows=["".join(r) for r in rows])


def build(L, verbose=True):
    """Runs every check. Returns (plan dict for the game, problems list, text report)."""
    cells = L.walkable_cells()
    report, problems = [], []
    for group in REQUIRED_MARKERS:
        if not L.markers.get(group):
            problems.append(f"missing marker group {group}")
    if "HiveSites" not in L.markers:
        pts, names = pick_hive_sites(L, cells)
        L.markers = dict(L.markers, HiveSites=pts)
        L.marker_names = dict(L.marker_names, HiveSites=names)
    hive_sizes = "".join(n[4] for n in L.marker_names.get("HiveSites", []))
    if len(L.markers["HiveSites"]) < 4 or "M" not in hive_sizes and "L" not in hive_sizes:
        problems.append(f"too few hive sites ({hive_sizes}); open up more floor")
    report.append(f"  hive sites: {' '.join(L.marker_names['HiveSites'])}")
    out_blocks = []
    for b in L.blocks:
        name, x0, x1, z0, z1, by, target, kind = b
        h = target if kind == "retaining" else max_visible_height(b, cells)
        out_blocks.append(dict(name=name, x0=x0, x1=x1, z0=z0, z1=z1, base=by, height=h, target=target, kind=kind))
        if h + 1e-6 < target:
            report.append(f"  capped {name:22s} {target:5.1f} m -> {h:4.1f} m")
    final = [(b["name"], b["x0"], b["x1"], b["z0"], b["z1"], b["base"], b["height"], b["kind"]) for b in out_blocks]
    solids = final + L.room_parts
    hidden = 0
    for x, y, z in cells:
        p = np.array([x, y + TORSO, z])
        own = L.room_of(x, z)
        if any(ray_hits_block(p, fb, fb[6]) for fb in solids
               if fb[7] != "retaining" and not (own and fb[0].startswith(own + ":"))):
            hidden += 1
    if hidden:
        problems.append(f"{hidden} walkable cells hidden from the camera")
    reach, reach_problems = check_reachability(L, cells)
    problems += reach_problems
    barriers = compute_barriers(L, cells, solids)
    voids = [b for b in barriers if b["kind"] == "void"]
    for v in voids:
        problems.append(f"open-ground hole x {v['x0']:.1f}..{v['x1']:.1f} z {v['z0']:.1f}..{v['z1']:.1f} y {v['y']}")
    room_names = [r[0] for r in L.rooms]
    plan = dict(
        sector=dict(L.sector, layout=L.id),
        floors=[dict(name=n, x0=a, x1=b, z0=c, z1=d, y=y) for n, a, b, c, d, y in L.floors
                if not any(n.startswith(r) for r in room_names)],
        stairs=[dict(name=n, x0=a, x1=b, z0=c, z1=d, y0=y0, y1=y1) for n, a, b, c, d, y0, y1 in L.stairs],
        blocks=out_blocks,
        rooms=[dict(name=n, x0=a, x1=b, z0=c, z1=d, base=y, height=h,
                    doors=[dict(side=ds, at=at, width=w) for ds, at, w in doors])
               for n, a, b, c, d, y, h, doors in L.rooms],
        barriers=[b for b in barriers if b["kind"] != "void"],
        props=[dict(type=t, pos=[x, y, z], yaw=r) for t, x, y, z, r in L.props],
        markers=L.markers, marker_names=L.marker_names,
        nav=build_nav_grid(L, cells),
    )
    rails = sum(1 for b in barriers if b["kind"] == "rail")
    blockers = sum(1 for b in barriers if b["kind"] == "blocker")
    text = [f"== {L.id}: {len(cells)} walkable cells ({len(cells) * CELL * CELL:.0f} m2), "
            f"{rails} railings, {blockers} blockers, {len(voids)} holes, {hidden} hidden cells"]
    text += report
    text += [f"  {k:34s} {v}" for k, v in reach.items()]
    return plan, problems, "\n".join(text)


def export_gdscript(plan, path, source):
    """Write the plan as a GDScript constant so it ships in every export (JSON files don't by default)."""
    body = json.dumps(plan, indent="\t")
    with open(path, "w") as f:
        f.write("extends RefCounted\n")
        f.write(f"## Generated from tools/level_design/layouts/{source}.py by build_layouts.py. Do not edit by hand:\n")
        f.write("## change the layout there and re-run it so the camera and walkability checks run again.\n\n")
        f.write("const PLAN := " + body + "\n")
