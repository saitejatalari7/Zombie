"""Sector 01, layout A: the avenue. Push north up the avenue and climb to the terrace LZ."""
TERRACE_Y = 3.2

ID = "s1_avenue"
SECTOR = {"id": 1, "name": "SECTOR 01: QUARANTINE BLOCK", "bounds": [-30, -56, 60, 94]}

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
ROOMS = [
    ("Clinic", -24, -5, 18, 26, 0.0, 3.6, [("east", 22.0, 2.4)]),
    ("Depot", -24, -16, -52, -44, TERRACE_Y, 3.6, [("south", -20.0, 2.4)]),
]
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
# The zombie spawner treats names containing "door", "terrace", "bay" etc. (or markers above
# 1.2 m) as building spawns; the last OpeningMob marker is a runner.
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