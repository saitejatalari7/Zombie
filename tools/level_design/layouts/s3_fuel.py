"""Sector 03, layout C: the fuel depot (night).

Giant fuel tanks along the north edge, a maze of pipe racks in the middle where the Brute
hunts, the control room (enterable) in the north-east corner, and the harbour on the east
side. Evac lands at the end of the jetty.
"""
ID = "s3_fuel"
SECTOR = {"id": 3, "name": "SECTOR 03: BLACKOUT DOCKS", "bounds": [-50, -54, 100, 78]}

FLOORS = [
    ("Depot",    -46, 40, -28, 14, 0.0),
    ("TankRoad", -46, 40, -36, -28, 0.0),
    ("Jetty",     40, 49, -12, -6, 0.0),
]
BLOCKS = [
    # Tank row (north edge)
    ("TankA", -46, -30, -52, -36, 0.0, 12.0, "tank"),
    ("TankB", -26, -10, -52, -36, 0.0, 12.0, "tank"),
    ("TankC",  -6,  10, -52, -36, 0.0, 12.0, "tank"),
    ("TankD",  14,  30, -52, -36, 0.0, 12.0, "tank"),
    ("TankPipes1", -30, -26, -52, -36, 0.0, 1.2, "pipes"),
    ("TankPipes2", -10,  -6, -52, -36, 0.0, 1.2, "pipes"),
    ("TankPipes3",  10,  14, -52, -36, 0.0, 1.2, "pipes"),
    ("ControlYard", 30,  34, -52, -36, 0.0, 1.2, "pipes"),
    ("NorthFence", -50,  50, -54, -52, 0.0, 3.0, "wall"),
    # Harbour and jetty
    ("Harbour",   40, 50, -36, 24, 0.0, 0.02, "water"),
    ("JettyDeck", 40, 49, -12, -6, 0.0, 0.05, "bridge"),
    ("JettyEnd",  49, 50, -12, -6, 0.0, 1.0, "cover"),
    ("EastBack",  46, 50, -52, -36, 0.0, 1.2, "wall"),
    # Pipe-rack maze
    ("RackN1", -40, -20, -22, -20, 0.0, 1.2, "pipes"),
    ("RackN2", -10,  14, -22, -20, 0.0, 1.2, "pipes"),
    ("RackN3",  22,  36, -22, -20, 0.0, 1.2, "pipes"),
    ("RackM1", -30,  -8, -12, -10, 0.0, 1.2, "pipes"),
    ("RackM2",   4,  30, -12, -10, 0.0, 1.2, "pipes"),
    ("RackS1", -40, -24,  -2,   0, 0.0, 1.2, "pipes"),
    ("RackS2", -14,   6,  -2,   0, 0.0, 1.2, "pipes"),
    ("RackS3",  16,  36,  -2,   0, 0.0, 1.2, "pipes"),
    ("Drums",  -20, -16,   6,   8, 0.0, 1.0, "cover"),
    ("DrumsE",  20,  24,   6,   8, 0.0, 1.0, "cover"),
    # Edges
    ("WestBack", -50, -46, -52, 24, 0.0, 12.0, "building"),
    ("SouthPlanter", -46, 40, 14, 16.5, 0.0, 0.8, "planter"),
    ("SouthSheds", -46, 40, 16.5, 24, 0.0, 4.0, "shed"),
]
ROOMS = [
    ("ControlRoom", 34, 46, -50, -36, 0.0, 3.6, [("south", 37.5, 3.0)]),
]
PROPS = [
    ("lamp", -36, 0, -29, 0), ("lamp", 0, 0, -29, 0), ("lamp", 30, 0, -29, 0),
    ("lamp", -24, 0, 13.4, 180), ("lamp", 16, 0, 13.4, 180), ("lamp", 46, 0, -6.6, 0),
    ("crate", -34, 0, -6, 10), ("crate", 0, 0, 4, -20), ("crate", 34, 0, -16, 30),
    ("car_b", -38, 0, 8, 80), ("car_c", 30, 0, 10, 260),
    ("jersey", 38.6, 0, 0, 90), ("jersey", 38.6, 0, -18, 90),
]
MARKERS = {
    "PlayerSpawn":    [(-40, 0.3, 10)],
    "ExtractionZone": [(45.5, 0.0, -9)],
    "ObjectiveSpawns": [(0, 0.3, -32), (10, 0.3, -6), (40, 0.3, -43)],
    "ZombieSpawners": [(36, 0.3, 10), (-44, 0.3, -32), (36, 0.3, -32), (42, 0.3, -46),
                       (-20, 0.3, -6), (0, 0.3, 9), (20, 0.3, -16)],
    "OpeningMob":     [(-30, 0.3, 8), (-28, 0.3, 10), (-26, 0.3, 7), (-24, 0.3, 9), (-22, 0.3, 8)],
    "PickupSpawns":   [(-36, 0.3, -16), (26, 0.3, -4), (-4, 0.3, -32)],
    "BloodDecor":     [(-32, 0.05, 10), (8, 0.05, -16), (30, 0.05, -30)],
    "StepMarkers":    [(0.0, 0.0, -32.0), (10.0, 0.0, -6.0), (40.0, 0.0, -44.0)],
    "IntelSpots":     [(-28.0, 0.3, -34.0), (44.5, 0.3, -48.5), (48.0, 0.3, -7.0)],
}
MARKER_NAMES = {
    "ZombieSpawners": ["DepotSouthEast", "TankRoadWest", "TankRoadEast", "DoorControlRoom",
                       "PipesWest", "DepotSouth", "PipesEast"],
    "OpeningMob": ["Shambler1", "Runner1", "Shambler2", "Runner2", "Shambler3"],
    "ObjectiveSpawns": ["TankRoad", "Pipes", "ControlRoom"],
    "PickupSpawns": ["WestPickup", "PipesPickup", "TankPickup"],
    "BloodDecor": ["Pool1", "Pool2", "Pool3"],
    "StepMarkers": ["MainValve", "BrutePipes", "ControlRoom"],
    "IntelSpots": ["IntelTankLog", "IntelControlRoom", "IntelJetty"],
}
