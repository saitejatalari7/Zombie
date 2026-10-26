"""Sector 03, layout A: the container quay (night).

The dock road in the south, a container yard, then the quay with its cargo cranes and the
dark sea beyond. The warehouse (enterable) holds the floodlight generator; the Brute nests
under the cranes; evac lands at the end of the pier.
"""
ID = "s3_quay"


def stack(name, x0, x1, z0, z1, h=2.6):
    """A container stack with a pallet strip on its north and west sides: the setback that
    lets a full-height container stand south-east of a lane without hiding the player."""
    return [
        (name + "PalletsN", x0, x1, z0, z0 + 1.5, 0.0, 0.7, "cover"),
        (name + "PalletsW", x0, x0 + 0.6, z0 + 1.5, z1, 0.0, 0.7, "cover"),
        (name, x0 + 0.6, x1, z0 + 1.5, z1, 0.0, h, "containers"),
    ]

SECTOR = {"id": 3, "name": "SECTOR 03: BLACKOUT DOCKS", "bounds": [-50, -52, 100, 76]}

FLOORS = [
    ("Road",     -46, 46,  10, 18, 0.0),
    ("Yard",     -46, 46, -31, 10, 0.0),
    ("PierGap",   -3,  3, -35, -31, 0.0),
    ("Pier",      -3,  3, -50, -35, 0.0),
]
BLOCKS = [
    # The sea and the pier deck over it
    ("Sea",       -50, 50, -52, -35, 0.0, 0.02, "water"),
    ("PierDeck",   -3,  3, -50, -35, 0.0, 0.05, "bridge"),
    # Crane rail strip along the quay edge: cranes, and crane-rail bed between them
    ("CraneW2",   -40, -30, -35, -31, 0.0, 18.0, "crane"),
    ("CraneW1",   -22, -12, -35, -31, 0.0, 18.0, "crane"),
    ("CraneE1",    12,  22, -35, -31, 0.0, 18.0, "crane"),
    ("CraneE2",    30,  40, -35, -31, 0.0, 18.0, "crane"),
    ("RailBed1",  -46, -40, -35, -31, 0.0, 0.3, "ballast"),
    ("RailBed2",  -30, -22, -35, -31, 0.0, 0.3, "ballast"),
    ("RailBed3",  -12,  -3, -35, -31, 0.0, 0.3, "ballast"),
    ("RailBed4",    3,  12, -35, -31, 0.0, 0.3, "ballast"),
    ("RailBed5",   22,  30, -35, -31, 0.0, 0.3, "ballast"),
    ("RailBed6",   40,  46, -35, -31, 0.0, 0.3, "ballast"),
    # Edges
    ("WestBack",  -50, -46, -35, 24, 0.0, 12.0, "building"),
    ("EastBack",   46,  50, -35, 24, 0.0, 1.2, "wall"),
    ("SouthPlanter", -46, 46, 18, 20.5, 0.0, 0.8, "planter"),
    ("SouthSheds", -46, 46, 20.5, 24, 0.0, 4.0, "shed"),
    # Warehouse buffer: bollards keep the warehouse roof out of the quay's view
    ("Bollards",  -46, -32, -20, -17, 0.0, 1.0, "cover"),
    # Container stacks (the yard's lanes)
    ("BittsW",    -10,  -8, -27, -26, 0.0, 0.9, "cover"),
    ("BittsE",      6,   8, -25, -24, 0.0, 0.9, "cover"),
]
BLOCKS += stack("StackN1", -26, -14, -14, -10)
BLOCKS += stack("StackN2", -6, 6, -14, -10)
BLOCKS += stack("StackN3", 14, 26, -14, -10)
BLOCKS += stack("StackN4", 32, 44, -14, -10)
BLOCKS += stack("StackM1", -20, -8, -4, 0)
BLOCKS += stack("StackM2", 2, 14, -4, 0)
BLOCKS += stack("StackM3", 22, 34, -4, 0)
BLOCKS += stack("StackS1", -26, -16, 4, 7)
BLOCKS += stack("StackS2", 8, 18, 4, 7)
BLOCKS += stack("StackS3", 30, 40, 4, 7)

ROOMS = [
    ("Warehouse", -46, -32, -17, -3, 0.0, 4.2, [("east", -10.0, 3.0), ("south", -39.0, 3.0)]),
]
PROPS = [
    ("lamp", -28, 0, -23.6, 0), ("lamp", 0, 0, -23.6, 0), ("lamp", 28, 0, -23.6, 0),
    ("lamp", -20, 0, 17.4, 180), ("lamp", 20, 0, 17.4, 180), ("lamp", 1, 0, -47, 90),
    ("car_a", -34, 0, 12, 85), ("car_b", 4, 0, 15, 95), ("car_c", 34, 0, 12, 260),
    ("crate", -12, 0, -20, 10), ("crate", 18, 0, -22, -20), ("crate", -2, 0, 3, 30), ("crate", 40, 0, -6, 0),
    ("jersey", -1.8, 0, -30, 90), ("pole", -44, 0, 9, 0),
]
MARKERS = {
    "PlayerSpawn":    [(-40, 0.3, 14)],
    "ExtractionZone": [(0, 0.0, -45)],
    "ObjectiveSpawns": [(-39, 0.3, -8), (26, 0.3, -27), (0, 0.3, -42)],
    "ZombieSpawners": [(40, 0.3, 14), (-40, 0.3, -12), (44, 0.3, -26), (-44, 0.3, -26),
                       (10, 0.3, 8), (20, 0.3, -7), (-20, 0.3, -20)],
    "OpeningMob":     [(-30, 0.3, 13), (-28, 0.3, 15), (-26, 0.3, 12), (-24, 0.3, 14), (-22, 0.3, 13)],
    "PickupSpawns":   [(-36, 0.3, -8), (8, 0.3, -20), (36, 0.3, 2)],
    "BloodDecor":     [(-32, 0.05, 12), (0, 0.05, -18), (24, 0.05, -26)],
    "StepMarkers":    [(-40.0, 0.0, -8.0), (26.0, 0.0, -27.0)],
    "IntelSpots":     [(-34.0, 0.3, -15.5), (0.0, 0.3, -7.0), (2.0, 0.3, -48.5)],
}
MARKER_NAMES = {
    "ZombieSpawners": ["RoadEast", "DoorWarehouse", "QuayEast", "QuayWest",
                       "YardSouth", "YardMid", "YardNorthWest"],
    "OpeningMob": ["Shambler1", "Runner1", "Shambler2", "Runner2", "Shambler3"],
    "ObjectiveSpawns": ["Warehouse", "Cranes", "Pier"],
    "PickupSpawns": ["WarehousePickup", "QuayPickup", "YardPickup"],
    "BloodDecor": ["Pool1", "Pool2", "Pool3"],
    "StepMarkers": ["FloodlightGenerator", "BruteCranes"],
    "IntelSpots": ["IntelHarbourMaster", "IntelContainer", "IntelPier"],
}
