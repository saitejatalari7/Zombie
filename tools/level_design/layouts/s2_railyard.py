"""Sector 02, layout B: the switching yard.

A wide yard crossed by five tracks of wagons that form lanes and cover. The signal tower
and the locomotive shed (both enterable) line the north edge; evac lands on the raised
loading dock on the east side.
"""
DOCK_Y = 1.2

ID = "s2_railyard"
SECTOR = {"id": 2, "name": "SECTOR 02: TRANSIT GRID", "bounds": [-50, -44, 100, 74]}

TRACK_Z = [-24, -16, -8, 0, 8]
WAGONS = {  # track z -> wagon x-spans
    -24: [(-40, -26), (-14, 2), (14, 30)],
    -16: [(-30, -16), (-4, 12), (24, 38)],
    -8:  [(-42, -28), (-16, -2), (10, 26)],
    0:   [(-34, -20), (-6, 8), (20, 34)],
    8:   [(-26, -12), (2, 16), (28, 42)],
}

FLOORS = [
    ("Yard", -46, 46, -30, 20, 0.0),
    ("Dock",  38, 46, -12, -2, DOCK_Y),
]
STAIRS = [
    ("DockStair", 40, 44, -2, 1.5, 0.0, DOCK_Y),
]
BLOCKS = [
    # Backdrop (north and west)
    ("Warehouse",   -50, -10, -44, -30, 0.0, 12.0, "building"),
    ("OfficeYard",    2,  4.5, -44, -30, 0.0, 0.8, "planter"),
    ("Offices",     4.5,  16, -44, -30, 0.0,  9.0, "building"),
    ("WestBack",    -50, -46, -30,  30, 0.0, 12.0, "building"),
    ("NorthEnd",     40,  50, -44, -30, 0.0,  1.2, "wall"),
    # East and south (camera side)
    ("EastWall",     46,  50, -30,  30, 0.0,  1.2, "wall"),
    ("SouthPlanter", -46, 46,  20, 22.5, 0.0, 0.8, "planter"),
    ("ContainerStacks", -46, 46, 22.5, 30, 0.0, 5.2, "containers"),
    # Dock flank wall (keeps the stair the only way up)
    ("DockCrates",   44,  46, -2, 1.5, 0.0, 1.2, "cover"),
    ("DockCratesW",  38,  40, -2, 1.5, 0.0, 1.2, "cover"),
]
for z in TRACK_Z:
    x1 = 38 if z in (-8, 0) else 46
    BLOCKS.append((f"Rails{z}", -46, x1, z - 1.05, z + 1.05, 0.0, 0.05, "tracks"))
    for i, (a, b) in enumerate(WAGONS[z]):
        BLOCKS.append((f"Wagon{z}_{i}", a, b, z - 1.5, z + 1.5, 0.0, 3.0, "railcar"))

ROOMS = [
    ("SignalTower", -10,  2, -38, -30, 0.0, 3.6, [("south", -4.0, 3.0)]),
    ("LocoShed",     16, 40, -42, -30, 0.0, 4.5, [("south", 28.0, 4.0)]),
]
PROPS = [
    ("crate", -36, 0, -12, 10), ("crate", 6, 0, -20, -20), ("crate", 34, 0, 13, 30), ("crate", -6, 0, 13, 0),
    ("lamp", -24, 0, -28.5, 0), ("lamp", 8, 0, -28.5, 0), ("lamp", 44.5, 0, 15, 270),
    ("pole", -44, 0, 4, 0), ("pole", 20, 0, 18.5, 0),
    ("car_c", -40, 0, 11, 70), ("car_a", 40, 0, 16, 100),
    ("tree_b", -44, 0, -27, 20),
]
MARKERS = {
    "PlayerSpawn":    [(-40, 0.3, 16)],
    "ExtractionZone": [(42, DOCK_Y, -7)],
    "ObjectiveSpawns": [(-4, 0.3, -34), (28, 0.3, -36), (0, 0.3, -12)],
    "ZombieSpawners": [(-44, 0.3, -20), (44, 0.3, -24), (0, 0.3, 17), (-4, 0.3, -35),
                       (34, 0.3, -39), (24, 0.3, 17), (44, DOCK_Y + 0.3, -10)],
    "OpeningMob":     [(-30, 0.3, 12), (-28, 0.3, 11), (-26, 0.3, 13), (-24, 0.3, 11), (-22, 0.3, 12)],
    "PickupSpawns":   [(-36, 0.3, -4), (10, 0.3, 4), (24, 0.3, -33)],
    "BloodDecor":     [(-34, 0.05, 14), (-8, 0.05, -12), (30, 0.05, -4)],
    "StepMarkers":    [(-4.0, 0.0, -34.0), (0.0, 0.0, -12.0), (28.0, 0.0, -36.0)],
    "IntelSpots":     [(0.5, 0.3, -36.5), (38.5, 0.3, -40.5), (-19.0, 0.3, 4.0)],
}
MARKER_NAMES = {
    "ZombieSpawners": ["YardWest", "YardEastNorth", "SouthGate", "DoorSignalTower",
                       "DoorLocoShed", "SidingSouth", "TerraceDock"],
    "OpeningMob": ["Shambler1", "Runner1", "Shambler2", "Shambler3", "Runner2"],
    "ObjectiveSpawns": ["SignalTower", "LocoShed", "YardCentre"],
    "PickupSpawns": ["WestPickup", "YardPickup", "ShedPickup"],
    "BloodDecor": ["Pool1", "Pool2", "Pool3"],
    "StepMarkers": ["NorthSwitch", "YardNest", "Shunter"],
    "IntelSpots": ["IntelSignalTower", "IntelLocoShed", "IntelWagon"],
}
