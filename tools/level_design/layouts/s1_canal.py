"""Sector 01, layout C: the canal crossing.

A west-to-east run along a canal. The south street and the north promenade are joined by
two bridges; the elevated rail viaduct above the promenade is reached by two stairs and
ends at the train platform where evac lands. The pump house (enterable) sits under the
viaduct; the east yard on the south bank is the far end of the map.
"""
VIADUCT_Y = 4.0

ID = "s1_canal"
SECTOR = {"id": 1, "name": "SECTOR 01: QUARANTINE BLOCK", "bounds": [-60, -36, 120, 60]}

FLOORS = [
    ("SouthPlaza",  -56, -40,   9,  18, 0.0),
    ("SouthStreet", -56,  56,   2,   9, 0.0),
    ("EastYard",     40,  56,   9,  18, 0.0),
    ("BridgeWest",  -32, -27,  -8,   2, 0.0),
    ("BridgeEast",   18,  23,  -8,   2, 0.0),
    ("Promenade",   -56,  56, -14,  -8, 0.0),
    ("Viaduct",     -40,  56, -28, -20, VIADUCT_Y),
]
STAIRS = [
    ("StairWest", -20, -15, -20, -14, 0.0, VIADUCT_Y),
    ("StairEast",  30,  35, -20, -14, 0.0, VIADUCT_Y),
]
BLOCKS = [
    # Backdrop: north and west edges
    ("NorthBack",   -60,  60, -36, -28, 0.0, 14.0, "building"),
    ("SignalBox",   -60, -40, -28, -20, 0.0, 10.0, "building"),
    ("WestBack",    -60, -56, -20,  24, 0.0, 12.0, "building"),
    ("EastBack",     56,  60, -28,  24, 0.0,  1.2, "wall"),
    # Viaduct embankment between the stairs (the promenade's north wall)
    ("EmbankmentW",  -56, -20, -20, -14, 0.0, VIADUCT_Y, "retaining"),
    ("EmbankmentMW", -15,  -6, -20, -14, 0.0, VIADUCT_Y, "retaining"),
    ("EmbankmentME",   8,  30, -20, -14, 0.0, VIADUCT_Y, "retaining"),
    ("EmbankmentE",   35,  56, -20, -14, 0.0, VIADUCT_Y, "retaining"),
    # The canal and its two bridges
    ("Canal",       -56,  56,  -8,   2, 0.0, 0.02, "water"),
    ("BridgeDeckW", -32, -27,  -8,   2, 0.0, 0.05, "bridge"),
    ("BridgeDeckE",  18,  23,  -8,   2, 0.0, 0.05, "bridge"),
    ("Barge",       -12,   2,  -6,  -2, 0.0, 1.2, "containers"),
    # South bank: houses behind a planter strip (camera side)
    ("SouthPlanter",  -40,  40,   9, 11.5, 0.0, 0.8, "planter"),
    ("SouthPlanterW", -40, -37.5, 11.5, 18, 0.0, 0.8, "planter"),
    ("SouthHouses", -37.5,  40, 11.5,  24, 0.0, 4.5, "building"),
    ("SouthEdge",     -60,  60,  18,  24, 0.0, 1.2, "wall"),
    # Cover
    ("BenchesW",     -46, -43, -11, -10, 0.0, 0.9, "cover"),
    ("BenchesE",      12,  15, -11, -10, 0.0, 0.9, "cover"),
    ("PlanterPlaza", -50, -47,  13,  15, 0.0, 0.8, "planter"),
    ("SandbagsS",    -10,  -7,   5,   6, 0.0, 1.0, "cover"),
    ("SandbagsYard",  45,  48,  12,  13, 0.0, 1.0, "cover"),
    ("ViaductCoverW", -24, -21, -25, -24, VIADUCT_Y, 1.0, "cover"),
    ("ViaductCoverE",  22,  25, -24, -23, VIADUCT_Y, 1.0, "cover"),
]
ROOMS = [
    ("PumpHouse", -6, 8, -20, -14, 0.0, 3.6, [("south", 1.0, 3.0)]),
]
PROPS = [
    ("car_a", -48, 0, 5, 85), ("car_b", -18, 0, 4, 95), ("car_c", 2, 0, 6.5, 260), ("car_a", 32, 0, 5, 80),
    ("car_b", 53, 0, 12, 20), ("car_c", -52, 0, 16, 200),
    ("lamp", -36, 0, -8.6, 0), ("lamp", -6, 0, -8.6, 0), ("lamp", 26, 0, -8.6, 0), ("lamp", 50, 0, -8.6, 0),
    ("pole", -24, 0, 8.4, 0), ("pole", 12, 0, 8.4, 0), ("pole", 44, 0, 8.4, 0),
    ("jersey", -27, 0, 3.5, 90), ("jersey", 23.5, 0, 3.5, 90),
    ("tree_a", -44, 0, 16, 20), ("tree_b", 52, 0, 11, 140),
    ("crate", -30, VIADUCT_Y, -26, 10), ("crate", 44, VIADUCT_Y, -26.5, -15), ("crate", 54, 0, 10.5, 30),
]
MARKERS = {
    "PlayerSpawn":    [(-50, 0.3, 13)],
    "ExtractionZone": [(48, VIADUCT_Y, -24)],
    "ObjectiveSpawns": [(1, 0.3, -17), (49, 0.3, 14), (-34, VIADUCT_Y + 0.3, -24)],
    "ZombieSpawners": [(-50, 0.3, -11), (1, 0.3, -18), (52, 0.3, -11), (52, 0.3, 14),
                       (6, 0.3, 5), (-36, VIADUCT_Y + 0.3, -24), (38, VIADUCT_Y + 0.3, -24)],
    "OpeningMob":     [(-40, 0.3, 6), (-38, 0.3, 4), (-36, 0.3, 7), (-34, 0.3, 5), (-31, 0.3, 6)],
    "PickupSpawns":   [(-22, 0.3, -11), (10, 0.3, 6), (16, VIADUCT_Y + 0.3, -24)],
    "BloodDecor":     [(-44, 0.05, 6), (-29, 0.05, -3), (20, 0.05, -11)],
    "StepMarkers":    [(1.0, 0.0, -17.5), (49.0, 0.0, 14.0), (-34.0, VIADUCT_Y, -24.0)],
    "IntelSpots":     [(6.5, 0.3, -15.5), (-38.5, VIADUCT_Y + 0.3, -26.5), (54.5, 0.3, 16.5)],
}
MARKER_NAMES = {
    "ZombieSpawners": ["PromenadeWest", "DoorPumpHouse", "PromenadeEast", "BayEastYard",
                       "SouthStreetMid", "TerraceViaductWest", "TerraceViaductEast"],
    "OpeningMob": ["Shambler1", "Shambler2", "Shambler3", "Shambler4", "Runner1"],
    "ObjectiveSpawns": ["PumpHouse", "EastYard", "ViaductWest"],
    "PickupSpawns": ["PromenadePickup", "StreetPickup", "ViaductPickup"],
    "BloodDecor": ["Pool1", "Pool2", "Pool3"],
    "StepMarkers": ["SluiceWheel", "YardNest", "FlareCase"],
    "IntelSpots": ["IntelPumpHouse", "IntelSignalBox", "IntelEastYard"],
}
