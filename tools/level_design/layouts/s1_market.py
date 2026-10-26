"""Sector 01, layout B: the market square.

A plus-shaped district around a central square. Each arm ends in something to do:
the market hall (west, walk-through room), the classroom (end of the north street),
the raised parking deck (east, up a stair). The LZ is in the square itself, so the
evac hold is a stand against four approaches at once.
"""
DECK_Y = 3.2

ID = "s1_market"
SECTOR = {"id": 1, "name": "SECTOR 01: QUARANTINE BLOCK", "bounds": [-40, -56, 80, 96]}

FLOORS = [
    ("SouthRoad",   -4,   4,  12,  36, 0.0),
    ("Square",     -14,  14, -14,  12, 0.0),
    ("WestStreet", -34, -14,  -3,   3, 0.0),
    ("NorthStreet", -4,   4, -34, -14, 0.0),
    ("EastStreet",  14,  36,  -3,   3, 0.0),
    ("CarLot",      14,  36,   3,  20, 0.0),
    ("Deck",        18,  36, -30, -14, DECK_Y),
]
STAIRS = [
    ("DeckStair", 26, 32, -14, -3, 0.0, DECK_Y),
]
# The camera sits south-east of the player: tall blocks only where nothing walkable lies
# north or west of them. Camera-side rows sit behind 2.5 m planter strips so they can
# keep a house height instead of being capped to a fence.
BLOCKS = [
    # Backdrop (north and west edges)
    ("NorthBack",    -40,  40, -60, -48, 0.0, 14.0, "building"),
    ("WestBack",     -40, -34, -48,  40, 0.0, 14.0, "building"),
    ("Tenements",    -34,  -4, -48, -19, 0.0, 12.0, "building"),
    ("Kiosk",        -14,  -4, -19, -14, 0.0,  3.3, "shed"),
    ("WarehouseN",    16,  40, -48, -30, 0.0,  9.0, "building"),
    ("WarehouseYard", 12.5, 16, -48, -30, 0.0, 0.8, "planter"),
    # North-east block: south of the classroom, east of the north street
    ("OfficesPlanterW", 4, 6.5, -34, -14, 0.0, 0.8, "planter"),
    ("OfficesPlanterN", 6.5, 18, -34, -31.5, 0.0, 0.8, "planter"),
    ("Offices",      6.5,  18, -31.5, -14, 0.0, 6.0, "building"),
    ("ClassroomEast", 12,  12.5, -48, -34, 0.0, 1.0, "wall"),
    # Under and around the raised deck
    ("ShopsPlanter",  14, 16.5, -14,  -3, 0.0, 0.8, "planter"),
    ("Shops",       16.5,  26, -14,  -3, 0.0,  4.0, "building"),
    ("DeckPillars",   32,  40, -14,  -3, 0.0,  1.0, "wall"),
    ("EastWall",      36,  40, -30,  22, 0.0,  1.2, "wall"),
    # South-west rows behind planters
    ("SWPlanter",    -34, -14,   3, 5.5, 0.0,  0.8, "planter"),
    ("SWHouses",     -34, -14, 5.5,  40, 0.0,  4.5, "building"),
    ("SWRowPlanter", -14,  -4,  12, 14.5, 0.0, 0.8, "planter"),
    ("SWRow",        -14,  -4, 14.5, 40, 0.0,  4.5, "building"),
    # South-east: pharmacy behind a planter, lot wall
    ("PharmacyPlanterW", 4, 6.5, 12, 36, 0.0, 0.8, "planter"),
    ("PharmacyPlanterN", 6.5, 14, 12, 14.5, 0.0, 0.8, "planter"),
    ("Pharmacy",     6.5,  14, 14.5, 36, 0.0, 4.5, "shed"),
    ("LotSouthWall",  14,  40,  20,  22, 0.0,  1.0, "wall"),
    ("SouthGate",     -4,   4,  36,  38, 0.0,  1.0, "wall"),
    # Cover
    ("Fountain",      -3,   3,  -4,   2, 0.0,  0.9, "planter"),
    ("PlanterNW",    -11,  -8, -11,  -9, 0.0,  0.8, "planter"),
    ("PlanterSE",      8,  11,   8,  10, 0.0,  0.8, "planter"),
    ("SandbagsW",    -10,  -7,   5,   6, 0.0,  1.0, "cover"),
    ("SandbagsE",      6,   9,  -4,  -3, 0.0,  1.0, "cover"),
    ("LotContainers", 28,  34,   8,  11, 0.0,  1.2, "containers"),
    ("DeckCover",     24,  27, -24, -23, DECK_Y, 1.0, "cover"),
    ("StreetCover",   -1.5, 1.5, -27, -26, 0.0, 1.0, "cover"),
]
ROOMS = [
    # Walk-through: in from the west street, out into the square
    ("MarketHall", -34, -14, -19, -3, 0.0, 4.2, [("south", -26.0, 3.0), ("east", -9.0, 3.0)]),
    # End of the north street
    ("Classroom",   -4,  12, -48, -34, 0.0, 3.6, [("south", 0.0, 3.0)]),
]
PROPS = [
    ("car_a", 18, 0, 8, 80), ("car_b", 22, 0, 15, 100), ("car_c", 31, 0, 16, 260), ("car_a", 24, 0, 6, 95),
    ("car_b", 1.5, 0, 22, 170), ("car_c", -2, 0, 28, 20),
    ("jersey", -2.5, 0, 14, 0), ("jersey", 2.5, 0, 14.2, 4),
    ("lamp", -12.5, 0, 10, 90), ("lamp", 12.5, 0, -12, 270), ("pole", 3.6, 0, 30, 0), ("pole", -3.6, 0, -24, 0),
    ("tree_a", -12, 0, 1, 20), ("tree_b", 11, 0, 1, 140), 
    ("crate", 21, DECK_Y, -27, 10), ("crate", 34, DECK_Y, -17, -20), ("crate", -24, 0, 1.5, 15), ("crate", 20, 0, 18, 30),
]
MARKERS = {
    "PlayerSpawn":    [(0, 0.3, 31)],
    "ExtractionZone": [(8, 0.0, -8)],
    "ObjectiveSpawns": [(-28, 0.3, -12), (30, DECK_Y + 0.3, -24), (8, 0.3, -40)],
    "ZombieSpawners": [(-31, 0.3, 0), (-30, 0.3, -15), (-3, 0.3, -20), (2, 0.3, -31),
                       (33, DECK_Y + 0.3, -27), (33, 0.3, 16), (34, 0.3, 0)],
    "OpeningMob":     [(-2, 0.3, 9), (2, 0.3, 7), (0, 0.3, 5), (-5, 0.3, 4), (4, 0.3, 3)],
    "PickupSpawns":   [(-24, 0.3, -10), (28, DECK_Y + 0.3, -19), (24, 0.3, 12)],
    "BloodDecor":     [(1.0, 0.05, 18), (-6.0, 0.05, -6), (20.0, 0.05, 0)],
    "StepMarkers":    [(-28.0, 0.0, -12.0), (0.0, 0.0, -24.0), (30.0, DECK_Y, -26.0), (6.0, 0.0, -42.0)],
    "IntelSpots":     [(-18.5, 0.3, -16.5), (10.5, 0.3, -46.5), (34.0, DECK_Y + 0.3, -28.0)],
}
MARKER_NAMES = {
    "ZombieSpawners": ["WestStreetEnd", "DoorMarketHall", "NorthStreetDoor", "ClassroomDoor",
                       "TerraceDeckStair", "BayCarLot", "EastStreetEnd"],
    "OpeningMob": ["Shambler1", "Shambler2", "Shambler3", "Shambler4", "Runner1"],
    "ObjectiveSpawns": ["MarketHall", "ParkingDeck", "Classroom"],
    "PickupSpawns": ["HallPickup", "DeckPickup", "LotPickup"],
    "BloodDecor": ["Pool1", "Pool2", "Pool3"],
    "StepMarkers": ["StallLedger", "StreetNest", "DeckRelay", "ClassroomMeds"],
    "IntelSpots": ["IntelMarket", "IntelClassroom", "IntelDeck"],
}
