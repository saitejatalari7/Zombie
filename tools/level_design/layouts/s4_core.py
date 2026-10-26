"""Sector 04, layout C: the containment core (the finale).

The core yard, the cryo hall (a big enterable hall full of freezer banks, where Crimson
Prime sleeps), and the roof deck over the east wing, up a stair, with the helipad.
"""
DECK_Y = 6.0

ID = "s4_core"
SECTOR = {"id": 4, "name": "SECTOR 04: CRIMSON COMPLEX", "bounds": [-48, -60, 96, 90]}


def bank(name, x0, x1, z0, z1, h=2.4):
    """Freezer bank behind low crate strips (see s4_labs)."""
    return [
        (name + "StripN", x0, x1, z0, z0 + 1.5, 0.0, 0.6, "cover"),
        (name + "StripW", x0, x0 + 0.6, z0 + 1.5, z1, 0.0, 0.6, "cover"),
        (name, x0 + 0.6, x1, z0 + 1.5, z1, 0.0, h, "freezer"),
    ]


FLOORS = [
    ("Road",      -8,  8,   6, 26, 0.0),
    ("Yard",     -44, 44, -20,  6, 0.0),
    ("HallApron", -30, 18, -24, -20, 0.0),
    ("RoofDeck",  22, 44, -50, -28, DECK_Y),
]
STAIRS = [
    ("DeckStair", 36, 42, -28, -20, 0.0, DECK_Y),
]
BLOCKS = [
    # Backdrop
    ("NorthBack",  -48, 48, -60, -50, 0.0, 18.0, "building"),
    ("WestBlock",  -48, -30, -50, -20, 0.0, 14.0, "building"),
    ("WestBack",   -48, -44, -20, 30, 0.0, 12.0, "building"),
    ("EastBack",    44, 48, -50, 30, 0.0, 1.2, "wall"),
    # Between the hall and the roof deck, and under the deck
    ("WingGap",     18, 22, -50, -20, 0.0, 0.8, "planter"),
    ("DeckBaseW",   22, 36, -28, -20, 0.0, DECK_Y, "retaining"),
    ("DeckBaseE",   42, 44, -28, -20, 0.0, DECK_Y, "retaining"),
    ("Helipad",     30, 40, -46, -36, DECK_Y, 0.03, "helipad"),
    ("DeckVents",   24, 28, -48, -46, DECK_Y, 1.0, "pipes"),
    # South rows behind planters (camera side)
    ("BarracksPlanterN", -44, -8, 6, 8.5, 0.0, 0.8, "planter"),
    ("BarracksPlanterE", -10.5, -8, 8.5, 30, 0.0, 0.8, "planter"),
    ("Barracks",   -44, -10.5, 8.5, 30, 0.0, 4.5, "building"),
    ("GaragePlanterN", 8, 44, 6, 8.5, 0.0, 0.8, "planter"),
    ("GaragePlanterW", 8, 10.5, 8.5, 30, 0.0, 0.8, "planter"),
    ("Garage",    10.5, 44, 8.5, 30, 0.0, 4.5, "shed"),
    ("SouthGate",   -8,  8, 26, 30, 0.0, 1.0, "wall"),
    # Yard cover and the two power couplings
    ("CouplingW",  -40, -36, -12, -10, 0.0, 1.2, "pipes"),
    ("CouplingE",   34,  40, -12, -10, 0.0, 1.2, "pipes"),
    ("SandbagsW",  -20, -16,  -4,  -3, 0.0, 1.0, "cover"),
    ("SandbagsE",   14,  18,   0,   1, 0.0, 1.0, "cover"),
    ("TentMid",     -4,   4, -12,  -8, 0.0, 1.0, "cover"),
]
# The cryo hall's freezer banks (the arena)
BLOCKS += bank("HallBankNW", -26, -16, -46, -42)
BLOCKS += bank("HallBankNE",   2,  12, -46, -42)
BLOCKS += bank("HallBankSW", -24, -14, -34, -30)
BLOCKS += bank("HallBankSE",   4,  14, -34, -30)

ROOMS = [
    ("CryoHall", -30, 18, -50, -24, 0.0, 6.0, [("south", -6.0, 4.0), ("south", 10.0, 3.0)]),
]
PROPS = [
    ("car_a", -5, 0, 20, 10), ("car_c", 5, 0, 14, 190), ("car_b", -30, 0, 0, 80), ("car_a", 30, 0, -4, 100),
    ("jersey", -4, 0, 7, 0), ("jersey", 4, 0, 7.3, 6),
    ("lamp", -38, 0, 5, 0), ("lamp", 38, 0, 5, 0), ("lamp", -2, 0, -21, 0), ("lamp", 26, DECK_Y, -30, 0),
    ("crate", -36, 0, -18, 10), ("crate", 30, 0, -16, 20), ("crate", 26, DECK_Y, -40, 0),
    ("tree_b", -24, 0, 2, 40),
]
MARKERS = {
    "PlayerSpawn":    [(0, 0.3, 22)],
    "ExtractionZone": [(35, DECK_Y, -41)],
    "ObjectiveSpawns": [(-38, 0.3, -14), (37, 0.3, -14), (-6, 0.3, -38)],
    "ZombieSpawners": [(-40, 0.3, 2), (40, 0.3, 2), (-28, 0.3, -48), (16, 0.3, -48),
                       (-6, 0.3, -27), (28, DECK_Y + 0.3, -34), (0, 0.3, -16)],
    "OpeningMob":     [(-4, 0.3, 2), (4, 0.3, 1), (0, 0.3, -2), (-10, 0.3, -1), (10, 0.3, -1)],
    "PickupSpawns":   [(-30, 0.3, -6), (30, 0.3, -8), (-6, 0.3, -36)],
    "BloodDecor":     [(0, 0.05, 12), (-20, 0.05, -14), (-6, 0.05, -38)],
    "StepMarkers":    [(-38.0, 0.0, -14.0), (37.0, 0.0, -14.0), (-6.0, 0.0, -27.5), (-6.0, 0.0, -39.0)],
    "IntelSpots":     [(-28.5, 0.3, -48.5), (16.5, 0.3, -48.5), (42.0, DECK_Y + 0.3, -48.0)],
}
MARKER_NAMES = {
    "ZombieSpawners": ["YardWest", "YardEast", "DoorHallWest", "DoorHallEast",
                       "DoorHallSouth", "TerraceRoofDeck", "YardMid"],
    "OpeningMob": ["Runner1", "Shambler1", "Runner2", "Shambler2", "Runner3"],
    "ObjectiveSpawns": ["CouplingWest", "CouplingEast", "CryoHall"],
    "PickupSpawns": ["YardWestPickup", "YardEastPickup", "HallPickup"],
    "BloodDecor": ["Pool1", "Pool2", "Pool3"],
    "StepMarkers": ["CouplingWest", "CouplingEast", "CoreDoors", "CrimsonPrime"],
    "IntelSpots": ["IntelCryoWest", "IntelCryoEast", "IntelRoofDeck"],
}
