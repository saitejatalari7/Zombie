"""Sector 02, layout C: the interchange.

A three-tier climb: the street, the bus-station deck (3.2 m) with the toll booth at its
west end, and the elevated highway (6.4 m) where evac lands. Two stairs between each tier,
so there is always a second way up when one is choked.
"""
DECK_Y = 3.2
HWY_Y = 6.4

ID = "s2_overpass"
SECTOR = {"id": 2, "name": "SECTOR 02: TRANSIT GRID", "bounds": [-40, -50, 80, 86]}

FLOORS = [
    ("Street",  -34, 34,  10, 32, 0.0),
    ("Deck",    -34, 34, -14,  2, DECK_Y),
    ("Highway", -34, 34, -40, -22, HWY_Y),
]
STAIRS = [
    ("StairSW", -26, -20,   2,  10, 0.0, DECK_Y),
    ("StairSE",  20,  26,   2,  10, 0.0, DECK_Y),
    ("StairNW", -20, -14, -22, -14, DECK_Y, HWY_Y),
    ("StairNE",  28,  34, -22, -14, DECK_Y, HWY_Y),
]
BLOCKS = [
    # Backdrop
    ("Skyline",  -40, 40, -50, -40, 0.0, 16.0, "building"),
    ("WestBack", -40, -34, -40, 36, 0.0, 12.0, "building"),
    ("EastBack",  34, 40, -40, 36, 0.0, 1.2, "wall"),
    # Embankments between the tiers (under the raised floors)
    ("EmbankSW", -34, -26, 2, 10, 0.0, DECK_Y, "retaining"),
    ("EmbankSM", -20,  20, 2, 10, 0.0, DECK_Y, "retaining"),
    ("EmbankSE",  26,  34, 2, 10, 0.0, DECK_Y, "retaining"),
    ("EmbankNW", -34, -20, -22, -14, 0.0, HWY_Y, "retaining"),
    ("EmbankNM", -14,  28, -22, -14, 0.0, HWY_Y, "retaining"),
    # South edge (camera side)
    ("SouthWall", -40, 40, 32, 36, 0.0, 1.0, "wall"),
    # Cover on every tier
    ("StreetBagsW", -14, -11, 20, 21, 0.0, 1.0, "cover"),
    ("StreetBagsE",  10,  13, 22, 23, 0.0, 1.0, "cover"),
    ("BusShelter",   -6,   6, -2, -0.5, DECK_Y, 1.0, "cover"),
    ("DeckPlanter",  12,  16, -10, -7, DECK_Y, 0.8, "planter"),
    ("Tanker",       -2,   12, -35, -31, HWY_Y, 1.2, "containers"),
    ("MedianW",     -30, -18, -27, -26.5, HWY_Y, 0.9, "cover"),
    ("MedianE",      16,  28, -27, -26.5, HWY_Y, 0.9, "cover"),
]
ROOMS = [
    ("TollBooth", -34, -22, -14, -4, DECK_Y, 3.4, [("south", -28.0, 3.0), ("east", -9.0, 2.6)]),
]
PROPS = [
    ("car_a", -22, 0, 16, 80), ("car_b", -2, 0, 26, 95), ("car_c", 18, 0, 17, 260), ("car_a", 28, 0, 27, 100),
    ("car_b", -8, DECK_Y, -6, 10), ("car_c", 24, DECK_Y, -4, 200),
    ("car_a", -24, HWY_Y, -33, 85), ("car_b", 20, HWY_Y, -36, 95), ("car_c", -12, HWY_Y, -24, 270),
    ("jersey", -4, HWY_Y, -24, 0), ("jersey", 0, HWY_Y, -24.3, 6), ("jersey", 16, HWY_Y, -31, 90),
    ("lamp", -30, 0, 31, 0), ("lamp", 30, 0, 31, 0), ("lamp", 0, HWY_Y, -39, 0),
    ("pole", -16, 0, 11, 0), ("pole", 16, 0, 11, 0),
    ("crate", 30, DECK_Y, -12, 10), ("crate", -30, HWY_Y, -38, -20),
]
MARKERS = {
    "PlayerSpawn":    [(0, 0.3, 28)],
    "ExtractionZone": [(24, HWY_Y, -32)],
    "ObjectiveSpawns": [(10, DECK_Y + 0.3, -4), (-28, DECK_Y + 0.3, -9), (-10, HWY_Y + 0.3, -31)],
    "ZombieSpawners": [(-32, 0.3, 20), (32, 0.3, 20), (31, DECK_Y + 0.3, -8), (-30, DECK_Y + 0.3, -10),
                       (-30, HWY_Y + 0.3, -30), (30, HWY_Y + 0.3, -37), (12, DECK_Y + 0.3, 0)],
    "OpeningMob":     [(-6, 0.3, 16), (6, 0.3, 15), (0, 0.3, 13), (-12, 0.3, 14), (12, 0.3, 14)],
    "PickupSpawns":   [(-20, 0.3, 24), (20, DECK_Y + 0.3, -10), (0, HWY_Y + 0.3, -37)],
    "BloodDecor":     [(4, 0.05, 20), (-14, DECK_Y + 0.05, -6), (10, HWY_Y + 0.05, -28)],
    "StepMarkers":    [(8.0, DECK_Y, -6.0), (-28.0, DECK_Y, -9.0), (-10.0, HWY_Y, -31.0)],
    "IntelSpots":     [(-32.5, DECK_Y + 0.3, -12.5), (14.0, HWY_Y + 0.3, -33.0), (32.0, 0.3, 30.0)],
}
MARKER_NAMES = {
    "ZombieSpawners": ["StreetWest", "StreetEast", "TerraceDeckEast", "DoorTollBooth",
                       "TerraceHighwayWest", "TerraceHighwayEast", "TerraceDeckMid"],
    "OpeningMob": ["Shambler1", "Shambler2", "Runner1", "Shambler3", "Runner2"],
    "ObjectiveSpawns": ["Deck", "TollBooth", "Highway"],
    "PickupSpawns": ["StreetPickup", "DeckPickup", "HighwayPickup"],
    "BloodDecor": ["Pool1", "Pool2", "Pool3"],
    "StepMarkers": ["RampNest", "TollRadio", "OverpassHold"],
    "IntelSpots": ["IntelTollBooth", "IntelTanker", "IntelBillboard"],
}
