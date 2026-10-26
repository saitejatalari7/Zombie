"""Sector 04, layout B: the research wing.

A courtyard with three labs (enterable) along its north edge and the cold-storage yard of
freezer banks to the east. The research files are in Lab B, Patient Zero's sample in Lab C;
you carry it back to the entrance helipad with the runners on your trail.
"""
ID = "s4_labs"
SECTOR = {"id": 4, "name": "SECTOR 04: CRIMSON COMPLEX", "bounds": [-46, -56, 92, 84]}


def bank(name, x0, x1, z0, z1, h=2.4):
    """A freezer bank behind low crate strips on its north and west sides, so it keeps its
    height south-east of a walkway (same setback trick as the container stacks)."""
    return [
        (name + "StripN", x0, x1, z0, z0 + 1.5, 0.0, 0.6, "cover"),
        (name + "StripW", x0, x0 + 0.6, z0 + 1.5, z1, 0.0, 0.6, "cover"),
        (name, x0 + 0.6, x1, z0 + 1.5, z1, 0.0, h, "freezer"),
    ]


FLOORS = [
    ("Entrance",  -10, 10,   0, 24, 0.0),
    ("Courtyard", -40, 42, -34,  0, 0.0),
    ("CryoYard",   14, 42, -48, -34, 0.0),
]
BLOCKS = [
    # Backdrop
    ("NorthBack",  -46, 46, -56, -48, 0.0, 16.0, "building"),
    ("WestBack",   -46, -40, -48, 28, 0.0, 12.0, "building"),
    ("EastBack",    42, 46, -48, 28, 0.0, 1.2, "wall"),
    # Gaps between the labs (low, so one lab never hides the next one's interior)
    ("LabGapAB",   -24, -22, -48, -34, 0.0, 0.8, "planter"),
    ("LabGapBC",    -6,  -4, -48, -34, 0.0, 0.8, "planter"),
    ("LabGapCY",    12,  14, -48, -34, 0.0, 0.8, "planter"),
    # South: clinic and garage behind planters (camera side)
    ("ClinicPlanterN", -40, -10, 0, 2.5, 0.0, 0.8, "planter"),
    ("ClinicPlanterE", -12.5, -10, 2.5, 28, 0.0, 0.8, "planter"),
    ("Clinic",     -40, -12.5, 2.5, 28, 0.0, 4.5, "building"),
    ("GaragePlanterN", 10, 42, 0, 2.5, 0.0, 0.8, "planter"),
    ("GaragePlanterW", 10, 12.5, 2.5, 28, 0.0, 0.8, "planter"),
    ("Garage",    12.5, 42, 2.5, 28, 0.0, 4.5, "shed"),
    ("SouthGate",  -10, 10, 24, 28, 0.0, 1.0, "wall"),
    ("Helipad",     -6,  6,  6, 16, 0.0, 0.03, "helipad"),
    # Courtyard cover: decontamination tents and planters
    ("TentW",      -30, -24, -20, -16, 0.0, 1.0, "cover"),
    ("TentE",       20,  26, -14, -10, 0.0, 1.0, "cover"),
    ("Planter1",   -12,  -6,  -8,  -6, 0.0, 0.8, "planter"),
    ("Planter2",     4,  10, -22, -20, 0.0, 0.8, "planter"),
]
BLOCKS += bank("BankN1", 18, 30, -46, -42)
BLOCKS += bank("BankN2", 32, 41, -46, -42)
BLOCKS += bank("BankS1", 22, 34, -40, -36)

ROOMS = [
    ("LabA", -40, -24, -48, -34, 0.0, 4.0, [("south", -32.0, 3.0)]),
    ("LabB", -22,  -6, -48, -34, 0.0, 4.0, [("south", -14.0, 3.0)]),
    ("LabC",  -4,  12, -48, -34, 0.0, 4.0, [("south", 4.0, 3.0)]),
]
PROPS = [
    ("car_b", -6, 0, 20, 10), ("car_a", 30, 0, -4, 80), ("car_c", -32, 0, -6, 100),
    ("lamp", -36, 0, -1, 0), ("lamp", 0, 0, -33.4, 0), ("lamp", 38, 0, -1, 0), ("lamp", 9, 0, 18, 270),
    ("crate", 16, 0, -36, 10), ("crate", -36, 0, -30, 20), ("crate", 38, 0, -30, -10),
    ("tree_a", -20, 0, -4, 30), ("tree_b", 16, 0, -24, 160), ("jersey", 0, 0, -2, 0),
]
MARKERS = {
    "PlayerSpawn":    [(0, 0.3, 20)],
    "ExtractionZone": [(0, 0.0, 11)],
    "ObjectiveSpawns": [(-14, 0.3, -42), (37, 0.3, -38), (4, 0.3, -42)],
    "ZombieSpawners": [(-36, 0.3, -4), (38, 0.3, -4), (-32, 0.3, -44), (40, 0.3, -38),
                       (-14, 0.3, -44), (4, 0.3, -45), (20, 0.3, -24)],
    "OpeningMob":     [(-4, 0.3, -2), (4, 0.3, -3), (0, 0.3, -6), (-8, 0.3, -4), (8, 0.3, -4)],
    "PickupSpawns":   [(-30, 0.3, -26), (30, 0.3, -20), (-14, 0.3, -38)],
    "BloodDecor":     [(0, 0.05, 2), (-20, 0.05, -24), (24, 0.05, -34.5)],
    "StepMarkers":    [(-14.0, 0.0, -42.0), (37.0, 0.0, -38.0), (4.0, 0.0, -42.0)],
    "IntelSpots":     [(-38.0, 0.3, -46.0), (40.5, 0.3, -46.5), (10.5, 0.3, -46.5)],
}
MARKER_NAMES = {
    "ZombieSpawners": ["CourtyardWest", "CourtyardEast", "DoorLabA", "CryoYardEnd",
                       "DoorLabB", "DoorLabC", "CourtyardMid"],
    "OpeningMob": ["Runner1", "Shambler1", "Runner2", "Shambler2", "Runner3"],
    "ObjectiveSpawns": ["LabB", "CryoYard", "LabC"],
    "PickupSpawns": ["CourtyardWestPickup", "CourtyardEastPickup", "LabPickup"],
    "BloodDecor": ["Pool1", "Pool2", "Pool3"],
    "StepMarkers": ["LabTerminal", "BruteCryo", "SampleCase"],
    "IntelSpots": ["IntelLabA", "IntelCryoYard", "IntelLabC"],
}
