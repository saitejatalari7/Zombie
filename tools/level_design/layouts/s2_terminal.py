"""Sector 02, layout A: the central terminal.

Bus bays in the south, the terminal forecourt, then the concourse (a big enterable hall
where the survivors are holed up). Behind it, raised platforms and two tracks with
wagons; the platforms are reached from the east street, and evac lands on platform 3.
"""
PLAT_Y = 0.4

ID = "s2_terminal"
SECTOR = {"id": 2, "name": "SECTOR 02: TRANSIT GRID", "bounds": [-40, -50, 80, 90]}

FLOORS = [
    ("BusBays",    -24,  24,  14,  34, 0.0),
    ("Forecourt",  -34,  30,   4,  14, 0.0),
    ("EastStreet",  10,  30, -14,   4, 0.0),
    ("PlatformRamp", 26, 30, -17.5, -14, 0.0),
    ("Platform1",  -34,  34, -21.5, -17.5, PLAT_Y),
    ("TrackA",     -34,  34, -26, -21.5, 0.0),
    ("Platform2",  -34,  34, -30, -26, PLAT_Y),
    ("TrackB",     -34,  34, -34.5, -30, 0.0),
    ("Platform3",  -34,  34, -40, -34.5, PLAT_Y),
]
BLOCKS = [
    # Backdrop
    ("Depot",       -40,  40, -50, -40, 0.0, 13.0, "building"),
    ("WestBack",    -40, -34, -40,  40, 0.0, 12.0, "building"),
    ("TicketHall",  -34, -26, -14,   4, 0.0,  8.0, "building"),
    # Track bed between the concourse and platform 1 (keeps the concourse roof clear of the view)
    ("TrackBuffer", -34,  26, -17.5, -14, 0.0, 0.3, "ballast"),
    # Rails and wagons
    ("RailsA",      -34,  34, -24.8, -22.7, 0.0, 0.05, "tracks"),
    ("RailsB",      -34,  34, -33.3, -31.2, 0.0, 0.05, "tracks"),
    ("WagonA1",     -30, -16, -25.5, -22, 0.0, 3.0, "railcar"),
    ("WagonA2",      -8,   6, -25.5, -22, 0.0, 3.0, "railcar"),
    ("WagonA3",      14,  28, -25.5, -22, 0.0, 3.0, "railcar"),
    ("WagonB1",     -26, -12, -34, -30.5, 0.0, 3.0, "railcar"),
    ("WagonB2",      -2,  12, -34, -30.5, 0.0, 3.0, "railcar"),
    ("WagonB3",      20,  30, -34, -30.5, 0.0, 3.0, "railcar"),
    # East edge (camera side)
    ("EastWall",     34,  40, -50,  40, 0.0, 1.2, "wall"),
    ("EastStreetWall", 30, 34, -17.5, 4, 0.0, 1.2, "wall"),
    ("ForecourtEastWall", 30, 34, 4, 14, 0.0, 1.2, "wall"),
    # South-west and south-east rows behind planter strips
    ("SWPlanter",   -34, -24,  14, 16.5, 0.0, 0.8, "planter"),
    ("Kiosks",      -34, -24, 16.5, 40, 0.0, 4.0, "shed"),
    ("SEPlanterW",   24, 26.5, 14, 40, 0.0, 0.8, "planter"),
    ("SEPlanterN", 26.5,  34,  14, 16.5, 0.0, 0.8, "planter"),
    ("Garage",     26.5,  34, 16.5, 40, 0.0, 4.0, "shed"),
    ("SouthWall",   -24,  24,  34,  36, 0.0, 1.0, "wall"),
    ("SouthBack",   -24,  24,  36,  40, 0.0, 1.0, "wall"),
    # Cover
    ("BayIslandW",  -14, -10,  22,  26, 0.0, 0.8, "planter"),
    ("BayIslandE",   10,  14,  22,  26, 0.0, 0.8, "planter"),
    ("ForecourtBags", -6,  -2,   8,   9, 0.0, 1.0, "cover"),
    ("StreetBags",   18,  21,  -6,  -5, 0.0, 1.0, "cover"),
    ("Counter",      -4,   6,  -9,  -8, 0.0, 1.1, "cover"),
    ("Benches",     -22, -16,   0,   1, 0.0, 0.8, "cover"),
]
ROOMS = [
    ("Concourse", -26, 10, -14, 4, 0.0, 4.2, [("south", -16.0, 3.0), ("south", 0.0, 3.0), ("east", -5.0, 3.0)]),
]
PROPS = [
    ("car_a", -18, 0, 20, 90), ("car_b", -4, 0, 28, 85), ("car_c", 18, 0, 19, 275), ("car_a", 6, 0, 31, 95),
    ("car_b", 22, 0, -10, 10), ("car_c", 14, 0, 0.5, 80),
    ("jersey", -10, 0, 12.5, 0), ("jersey", 12, 0, 12.5, 0),
    ("lamp", -20, PLAT_Y, -19.5, 90), ("lamp", 10, PLAT_Y, -19.5, 90), ("lamp", -16, PLAT_Y, -37, 90), ("lamp", 18, PLAT_Y, -37, 90),
    ("pole", -28, 0, 13, 0), ("pole", 28, 0, 3, 0),
    ("tree_a", -20, 0, 6, 30), ("tree_b", 20, 0, 7, 150),
    ("crate", -12, PLAT_Y, -28, 10), ("crate", 30, PLAT_Y, -37.5, -20), ("crate", 26, 0, -2, 30),
]
MARKERS = {
    "PlayerSpawn":    [(0, 0.3, 30)],
    "ExtractionZone": [(0, PLAT_Y, -37)],
    "ObjectiveSpawns": [(-18, 0.3, -6), (24, PLAT_Y + 0.3, -28), (-24, 0.3, 8)],
    "ZombieSpawners": [(-31, 0.3, 9), (28, 0.3, -10), (-32, 0.3, -24), (32, 0.3, -32),
                       (-20, 0.3, 31), (20, 0.3, 31), (-30, PLAT_Y + 0.3, -37)],
    "OpeningMob":     [(-4, 0.3, 20), (4, 0.3, 21), (0, 0.3, 18), (-6, 0.3, 16), (6, 0.3, 16)],
    "PickupSpawns":   [(-20, 0.3, 10), (20, 0.3, -4), (-10, PLAT_Y + 0.3, -28)],
    "BloodDecor":     [(2, 0.05, 24), (-12, 0.05, 6), (16, 0.05, -8)],
    "StepMarkers":    [(-8.0, 0.0, -4.0), (-18.0, 0.0, -6.0), (24.0, PLAT_Y, -28.0)],
    "IntelSpots":     [(4.0, 0.3, -12.5), (-22.0, 0.3, 32.0), (32.0, PLAT_Y + 0.3, -38.5)],
}
MARKER_NAMES = {
    "ZombieSpawners": ["WestForecourt", "EastStreetEnd", "TrackWestA", "TrackEastB",
                       "BayWest", "BayEast", "TerracePlatformWest"],
    "OpeningMob": ["Shambler1", "Shambler2", "Runner1", "Shambler3", "Runner2"],
    "ObjectiveSpawns": ["Concourse", "Platform2", "Forecourt"],
    "PickupSpawns": ["ForecourtPickup", "StreetPickup", "PlatformPickup"],
    "BloodDecor": ["Pool1", "Pool2", "Pool3"],
    "StepMarkers": ["SurvivorsCall", "MedicBarricade", "PlatformSwitch"],
    "IntelSpots": ["IntelTicketDesk", "IntelBusDepot", "IntelSignalRoom"],
}
