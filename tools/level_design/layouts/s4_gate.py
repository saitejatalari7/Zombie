"""Sector 04, layout A: the main gate of Crimson Complex.

The approach road, the checkpoint wall, the security plaza with the guard house
(enterable, holds the gate override), and the admin podium up a grand stair, where evac
lands on the helipad.
"""
DECK_Y = 4.0

ID = "s4_gate"
SECTOR = {"id": 4, "name": "SECTOR 04: CRIMSON COMPLEX", "bounds": [-44, -54, 88, 84]}

FLOORS = [
    ("ApproachRoad", -8,  8,  10, 28, 0.0),
    ("Plaza",       -40, 40, -20, 10, 0.0),
    ("Podium",      -20, 20, -40, -26, DECK_Y),
]
STAIRS = [
    ("GrandStair", -4, 4, -26, -20, 0.0, DECK_Y),
]
BLOCKS = [
    # Backdrop
    ("Tower",      -20, 20, -54, -40, 0.0, 18.0, "building"),
    ("WestWing",   -44, -20, -54, -20, 0.0, 14.0, "building"),
    ("WestBack",   -44, -40, -20, 30, 0.0, 12.0, "building"),
    ("EastPlanter", 20, 23, -40, -20, 0.0, 0.8, "planter"),
    ("EastWing",    23, 44, -54, -20, 0.0, 12.0, "building"),
    ("EastBack",    40, 44, -20, 30, 0.0, 1.2, "wall"),
    # Podium base either side of the stair
    ("PodiumBaseW", -20, -4, -26, -20, 0.0, DECK_Y, "retaining"),
    ("PodiumBaseE",   4, 20, -26, -20, 0.0, DECK_Y, "retaining"),
    ("Helipad",      -6,  6, -38, -30, DECK_Y, 0.03, "helipad"),
    ("PodiumPlanterW", -18, -14, -30, -28, DECK_Y, 0.8, "planter"),
    ("PodiumPlanterE",  14,  18, -30, -28, DECK_Y, 0.8, "planter"),
    # Checkpoint wall with the gate gap
    ("GateWallW",  -40, -8, 10, 12, 0.0, 3.0, "wall"),
    ("GateWallE",    8, 40, 10, 12, 0.0, 3.0, "wall"),
    # Outside the wall (camera side): rows behind planters
    ("BunkerPlanter", -40, -8, 12, 14.5, 0.0, 0.8, "planter"),
    ("Bunkers",     -40, -8, 14.5, 30, 0.0, 4.5, "building"),
    ("DepotPlanterW", 8, 10.5, 12, 30, 0.0, 0.8, "planter"),
    ("DepotPlanterN", 10.5, 40, 12, 14.5, 0.0, 0.8, "planter"),
    ("Depot",     10.5, 40, 14.5, 30, 0.0, 4.5, "shed"),
    ("SouthEdge",   -8,  8, 28, 30, 0.0, 1.0, "wall"),
    # Plaza cover
    ("SandbagsW",  -16, -12, 0, 1, 0.0, 1.0, "cover"),
    ("SandbagsE",   12,  16, -4, -3, 0.0, 1.0, "cover"),
    ("TankTrapsW", -24, -20, -12, -10, 0.0, 1.0, "cover"),
    ("TankTrapsE",  22,  26, 4, 6, 0.0, 1.0, "cover"),
    ("FlagPlanter", -3,  3, -12, -9, 0.0, 0.8, "planter"),
]
ROOMS = [
    ("GuardHouse", -40, -28, -20, -8, 0.0, 3.6, [("east", -14.0, 3.0), ("south", -34.0, 3.0)]),
]
PROPS = [
    ("jersey", -4.5, 0, 11, 0), ("jersey", 4.5, 0, 11, 0), ("jersey", 0, 0, 16, 0),
    ("car_a", -5, 0, 22, 10), ("car_c", 5, 0, 25, 190), ("car_b", 30, 0, -10, 80), ("car_a", -18, 0, 6, 100),
    ("lamp", -36, 0, 8.6, 0), ("lamp", 36, 0, 8.6, 0), ("lamp", -10, DECK_Y, -39, 0), ("lamp", 10, DECK_Y, -39, 0),
    ("pole", 7.4, 0, 20, 0), ("crate", 34, 0, -16, 10), ("crate", -10, DECK_Y, -34, 20),
    ("tree_a", -24, 0, -18, 30), ("tree_b", 26, 0, -18, 160),
]
MARKERS = {
    "PlayerSpawn":    [(0, 0.3, 24)],
    "ExtractionZone": [(0, DECK_Y, -34)],
    "ObjectiveSpawns": [(-34, 0.3, -14), (0, 0.3, -6), (0, DECK_Y + 0.3, -32)],
    "ZombieSpawners": [(-36, 0.3, 4), (36, 0.3, 4), (-34, 0.3, -16), (36, 0.3, -16),
                       (-16, DECK_Y + 0.3, -36), (16, DECK_Y + 0.3, -36), (20, 0.3, -6)],
    "OpeningMob":     [(-4, 0.3, 6), (4, 0.3, 5), (0, 0.3, 3), (-8, 0.3, 2), (8, 0.3, 2)],
    "PickupSpawns":   [(-30, 0.3, 4), (30, 0.3, -2), (12, DECK_Y + 0.3, -36)],
    "BloodDecor":     [(0, 0.05, 18), (-10, 0.05, -4), (14, 0.05, -14)],
    "StepMarkers":    [(-34.0, 0.0, -14.0), (0.0, 0.0, -4.0)],
    "IntelSpots":     [(-38.5, 0.3, -18.5), (36.0, 0.3, -18.0), (-16.0, DECK_Y + 0.3, -38.5)],
}
MARKER_NAMES = {
    "ZombieSpawners": ["PlazaWest", "PlazaEast", "DoorGuardHouse", "PlazaNorthEast",
                       "TerracePodiumWest", "TerracePodiumEast", "PlazaMid"],
    "OpeningMob": ["Runner1", "Shambler1", "Runner2", "Shambler2", "Shambler3"],
    "ObjectiveSpawns": ["GuardHouse", "Plaza", "Podium"],
    "PickupSpawns": ["PlazaWestPickup", "PlazaEastPickup", "PodiumPickup"],
    "BloodDecor": ["Pool1", "Pool2", "Pool3"],
    "StepMarkers": ["GateOverride", "PlazaHold"],
    "IntelSpots": ["IntelGuardLog", "IntelMotorPool", "IntelPodium"],
}
