"""Sector 03, layout B: the shipyard (night).

The lab's cargo ship sits on the slipway. You cross the yard, take the cutting torch from the
workshop, climb a gangway onto the deck (6 m up), hold it while the hold is cut open, and
kill what comes out. The bridge (enterable) is at the stern; evac lands on the foredeck.
"""
DECK_Y = 6.0

ID = "s3_shipyard"
SECTOR = {"id": 3, "name": "SECTOR 03: BLACKOUT DOCKS", "bounds": [-50, -58, 100, 82]}


def stack(name, x0, x1, z0, z1, h=2.6):
    """Container stack behind pallet strips (see s3_quay)."""
    return [
        (name + "PalletsN", x0, x1, z0, z0 + 1.5, 0.0, 0.7, "cover"),
        (name + "PalletsW", x0, x0 + 0.6, z0 + 1.5, z1, 0.0, 0.7, "cover"),
        (name, x0 + 0.6, x1, z0 + 1.5, z1, 0.0, h, "containers"),
    ]


FLOORS = [
    ("Yard",     -46, 46, -22, 14, 0.0),
    ("Slipway",  -46, 46, -30, -22, 0.0),
    ("Deck",     -30, 30, -46, -30, DECK_Y),
]
STAIRS = [
    ("GangwayW", -16, -12, -30, -22, 0.0, DECK_Y),
    ("GangwayE",  18,  22, -30, -22, 0.0, DECK_Y),
]
BLOCKS = [
    ("Sea",       -50, 50, -58, -46, 0.0, 0.02, "water"),
    # Dry dock walls either side of the hull
    ("DryDockW",  -50, -30, -46, -30, 0.0, 12.0, "building"),
    ("DockEdgeE",  30, 32.5, -46, -30, 0.0, 0.8, "planter"),
    ("GantryE",    34,  42, -46, -34, 0.0, 20.0, "crane"),
    ("GantryBedS", 34,  42, -34, -30, 0.0, 0.3, "ballast"),
    ("GantryBedW", 32.5, 34, -46, -30, 0.0, 0.3, "ballast"),
    ("GantryBedE", 42,  50, -46, -30, 0.0, 0.3, "ballast"),
    # Deck furniture
    ("HatchW",    -8,  -2, -42, -38, DECK_Y, 1.0, "containers"),
    ("HatchE",     4,  10, -42, -38, DECK_Y, 1.0, "containers"),
    ("Bollards",  12,  14, -33, -32, DECK_Y, 0.9, "cover"),
    # Edges
    ("WestBack",  -50, -46, -30, 24, 0.0, 12.0, "building"),
    ("EastBack",   46,  50, -30, 24, 0.0, 1.2, "wall"),
    ("SouthPlanter", -46, 46, 14, 16.5, 0.0, 0.8, "planter"),
    ("SouthSheds", -46, 46, 16.5, 24, 0.0, 4.0, "shed"),
    # Workshop buffer and yard furniture
    ("Scaffold",  -46, -34, -19, -16, 0.0, 1.0, "pipes"),
    ("PipesMid",   -6,   6, -12, -10, 0.0, 1.2, "pipes"),
    ("PipesEast",  24,  36,   2,   4, 0.0, 1.2, "pipes"),
]
BLOCKS += stack("PlateStackW", -26, -14, -4, 0)
BLOCKS += stack("PlateStackE", 10, 22, -16, -12)
BLOCKS += stack("YardStackS", -10, 2, 4, 8)
BLOCKS += stack("YardStackSE", 30, 42, -10, -6)

ROOMS = [
    ("Bridge",   -30, -18, -46, -38, DECK_Y, 3.4, [("south", -24.0, 3.0), ("east", -42.0, 2.6)]),
    ("Workshop", -46, -34, -16, -4, 0.0, 3.8, [("east", -10.0, 3.0)]),
]
PROPS = [
    ("lamp", -20, 0, 13.4, 180), ("lamp", 20, 0, 13.4, 180), ("lamp", 0, 0, -21.4, 0),
    ("lamp", -6, DECK_Y, -31, 0), ("lamp", 26, DECK_Y, -44, 90),
    ("crate", -30, 0, -26, 10), ("crate", 28, 0, -26, -20), ("crate", 0, DECK_Y, -44, 30), ("crate", 40, 0, 10, 0),
    ("car_a", -38, 0, 2, 20), ("car_c", 14, 0, 8, 250),
]
MARKERS = {
    "PlayerSpawn":    [(-40, 0.3, 10)],
    "ExtractionZone": [(20, DECK_Y, -40)],
    "ObjectiveSpawns": [(-40, 0.3, -10), (0, DECK_Y + 0.3, -35), (20, DECK_Y + 0.3, -40)],
    "ZombieSpawners": [(43, 0.3, 7), (-42, 0.3, -12), (0, 0.3, -26), (40, 0.3, -26),
                       (-24, DECK_Y + 0.3, -42), (26, DECK_Y + 0.3, -34), (10, 0.3, 2)],
    "OpeningMob":     [(-30, 0.3, 8), (-28, 0.3, 10), (-26, 0.3, 7), (-24, 0.3, 9), (-22, 0.3, 8)],
    "PickupSpawns":   [(-38, 0.3, -8), (0, DECK_Y + 0.3, -32), (30, 0.3, 0)],
    "BloodDecor":     [(-30, 0.05, 10), (0, 0.05, -24), (14, DECK_Y + 0.05, -36)],
    "StepMarkers":    [(-40.0, 0.0, -10.0), (0.0, DECK_Y, -35.0), (-22.0, DECK_Y, -34.0)],
    "IntelSpots":     [(-28.0, DECK_Y + 0.3, -44.5), (-44.5, 0.3, -14.5), (44.0, 0.3, -28.0)],
}
MARKER_NAMES = {
    "ZombieSpawners": ["YardEast", "DoorWorkshop", "SlipwayMid", "SlipwayEast",
                       "TerraceBridge", "TerraceDeckEast", "YardMid"],
    "OpeningMob": ["Shambler1", "Runner1", "Shambler2", "Runner2", "Shambler3"],
    "ObjectiveSpawns": ["Workshop", "Deck", "Foredeck"],
    "PickupSpawns": ["WorkshopPickup", "DeckPickup", "YardPickup"],
    "BloodDecor": ["Pool1", "Pool2", "Pool3"],
    "StepMarkers": ["CuttingTorch", "HoldBreach", "BruteHold"],
    "IntelSpots": ["IntelShipLog", "IntelWorkshop", "IntelSlipway"],
}
