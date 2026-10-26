extends Node
## GameManager.gd — Global Autoload
## Manages persistent game state: economy, progression, weapon upgrades, skills, user settings.
## Uses encrypted save/load to prevent casual save-file tampering on Android.

# ─── Signals ───────────────────────────────────────────────────────────────────
signal coins_changed(new_amount: int)
signal research_cores_changed(new_amount: int)
signal clearance_level_changed(new_level: int)
signal clearance_xp_changed(current_xp: int, required_xp: int)
signal skill_equipped(slot: int, skill_id: String)
signal weapon_upgraded(weapon_id: String, track: String, new_level: int)
signal outpost_upgraded(facility: String, new_level: int)
signal in_run_loot_changed(current_sc: int, current_rc: int)
signal in_run_kills_changed(total_run_kills: int)
signal mission_resolved(summary: Dictionary)
signal game_saved()
signal game_loaded()

# ─── Constants ─────────────────────────────────────────────────────────────────
const SAVE_PATH := "user://protocol_crimson_save.dat"
const SAVE_TMP_PATH := "user://protocol_crimson_save.tmp"
const SAVE_BACKUP_PATH := "user://protocol_crimson_save.bak"
const SAVE_KEY := "CR1MS0N_PR0T0C0L_K3Y"
const SAVE_VERSION := 2

## Contract dossiers per Sector (a list: the Command Board lets the player pick one).
## Single source of truth for the board text AND the actual payout, so the hub can
## never advertise one reward and pay another. "job" selects the MissionJob script.
const CONTRACTS: Dictionary = {
	1: [
		{
			"id": "s1_beacon",
			"layout": "s1_avenue",
			"job": "steps",
			"title": "SECTOR 01: LIGHT THE BEACON",
			"desc": "The Quarantine Block went dark when the medevac fell. No beacon, no evac birds. Clear the avenue, burn out the nest in the West Plaza, and pull the beacon fuse from the terrace depot.",
			"type": "TYPE: SECURE & SIGNAL",
			"threat": "THREAT: LOW [NEST ACTIVE]",
			"payout_sc": 350,
			"payout_rc": 1,
			"xp": 120,
			"kills_required": 0,
			"is_night": false,
			"briefing": "WARDEN, this is Overwatch. The block's evac beacon is dead and nothing can land. Get it lit.",
			"steps": [
				{"type": "kill", "count": 12, "title": "CLEAR THE AVENUE",
					"radio": "The avenue is crawling. Thin them out before you push north."},
				{"type": "destroy", "marker": "NestWestPlaza", "title": "BURN OUT THE NEST",
					"radio": "Thermal shows a nest in the West Plaza. It keeps birthing them. Put it down."},
				{"type": "search", "marker": "DepotFuse", "seconds": 4.0, "title": "PULL THE BEACON FUSE",
					"radio": "Beacon fuse is inside the depot on the terrace. Get in there and pull it."},
			],
			"extract_radio": "Fuse is in, the beacon is live. Hold the terrace, evac is inbound.",
		},
		{
			"id": "s1_recorder",
			"layout": "s1_avenue",
			"job": "steps",
			"title": "SECTOR 01: THE FLIGHT RECORDER",
			"desc": "The medevac carrying the first Crimson samples crashed in this block. Its flight recorder knows where the samples came from. Find the pilot's keycard, open the wreck container, and carry the recorder out.",
			"type": "TYPE: ASSET RECOVERY",
			"threat": "THREAT: LOW [RUNNERS HUNT CARRIER]",
			"payout_sc": 420,
			"payout_rc": 2,
			"xp": 150,
			"kills_required": 0,
			"is_night": false,
			"briefing": "WARDEN, Overwatch. The medevac pilot didn't make it, but his recorder might tell us what he was carrying.",
			"steps": [
				{"type": "search", "marker": "ClinicKeycard", "seconds": 3.0, "title": "FIND THE PILOT'S KEYCARD",
					"radio": "The pilot crawled into the clinic on the avenue. Search it for his keycard."},
				{"type": "carry", "marker": "RecorderCase", "title": "TAKE THE FLIGHT RECORDER",
					"radio": "Keycard opens the wreck container in the east alley. The recorder is inside."},
			],
			"extract_radio": "Recorder secured. It's heavy and the runners can smell it. Get to the terrace.",
		},
		{
			"id": "s1_market",
			"layout": "s1_market",
			"job": "steps",
			"title": "SECTOR 01: MARKET DAY",
			"desc": "The market square was the block's last aid station. Its quartermaster kept a ledger of every survivor and supply run. Find it, burn out the nest in the north street, and patch the radio relay on the parking deck.",
			"type": "TYPE: SALVAGE & SIGNAL",
			"threat": "THREAT: MEDIUM [FOUR APPROACHES]",
			"payout_sc": 480,
			"payout_rc": 2,
			"xp": 170,
			"kills_required": 0,
			"is_night": false,
			"briefing": "WARDEN, Overwatch. The market square was the last aid station in this block. Whatever they knew is in that hall.",
			"steps": [
				{"type": "kill", "count": 10, "title": "CLEAR THE SQUARE",
					"radio": "The square's overrun. Clear some room to work."},
				{"type": "search", "marker": "StallLedger", "seconds": 4.0, "title": "FIND THE SUPPLY LEDGER",
					"radio": "The ledger is in the market hall, west side of the square. It has two doors, use either."},
				{"type": "destroy", "marker": "StreetNest", "title": "BURN OUT THE NEST",
					"radio": "Ledger says the north street went bad first. There's a nest up there. Burn it."},
				{"type": "search", "marker": "DeckRelay", "seconds": 5.0, "title": "PATCH THE RADIO RELAY",
					"radio": "Relay box is on the parking deck. Stairs are off the east street."},
			],
			"extract_radio": "Relay's up, I can hear the whole district. The bird lands in the square. Hold it from every side.",
		},
		{
			"id": "s1_canal",
			"layout": "s1_canal",
			"job": "steps",
			"title": "SECTOR 01: CANAL CROSSING",
			"desc": "The horde moves through the storm tunnels under the canal. Open the sluice to flood them, burn the nest in the east yard, then carry the flare case along the rail viaduct to the platform where evac can land.",
			"type": "TYPE: SABOTAGE & ESCORT",
			"threat": "THREAT: MEDIUM [LONG CARRY]",
			"payout_sc": 540,
			"payout_rc": 2,
			"xp": 190,
			"kills_required": 0,
			"is_night": false,
			"briefing": "WARDEN, Overwatch. They're coming up out of the storm tunnels. Drown the tunnels and we cut this block's supply of dead in half.",
			"steps": [
				{"type": "kill", "count": 10, "title": "CLEAR THE SOUTH STREET",
					"radio": "South street first. Make some room."},
				{"type": "search", "marker": "SluiceWheel", "seconds": 5.0, "title": "OPEN THE SLUICE",
					"radio": "Sluice wheel is in the pump house under the viaduct. Cross the west bridge."},
				{"type": "destroy", "marker": "YardNest", "title": "BURN OUT THE NEST",
					"radio": "Water's moving. The ones it flushed out are nesting in the east yard. Burn it."},
				{"type": "carry", "marker": "FlareCase", "title": "TAKE THE FLARE CASE",
					"radio": "Flare case is on the viaduct, west end. Bring it to the platform. It's heavy and they'll smell it."},
			],
			"extract_radio": "Flares are lit on the platform. Bird's two minutes out. Hold the viaduct.",
		},
	],
	2: [
		{
			"id": "s2_medic",
			"layout": "s2_terminal",
			"job": "steps",
			"title": "SECTOR 02: THE LAST MEDIC",
			"desc": "A field medic has kept a dozen survivors alive inside the central terminal for nine days. She has seen what Crimson does to the blood. Get to her, hold the concourse while she packs her samples, then signal the platform for evac.",
			"type": "TYPE: RESCUE & DEFEND",
			"threat": "THREAT: MEDIUM [RUNNER PACKS]",
			"payout_sc": 620,
			"payout_rc": 3,
			"xp": 260,
			"kills_required": 0,
			"is_night": false,
			"briefing": "WARDEN, Overwatch. Someone's been broadcasting from the central terminal every night at nine. A medic. She says she knows what's in the blood.",
			"steps": [
				{"type": "kill", "count": 14, "title": "CLEAR THE BUS BAYS",
					"radio": "Runners in the bays. They're faster than anything in the block. Keep moving."},
				{"type": "reach", "marker": "SurvivorsCall", "radius": 3.0, "title": "FIND THE SURVIVORS",
					"radio": "She's in the concourse. Doors are on the forecourt."},
				{"type": "defend", "marker": "MedicBarricade", "seconds": 25.0, "title": "HOLD THE CONCOURSE",
					"radio": "She needs time to pack the samples and they heard the doors. Hold the hall."},
				{"type": "search", "marker": "PlatformSwitch", "seconds": 4.0, "title": "SIGNAL PLATFORM 3",
					"radio": "Platform signal box is on platform two. Throw it and the bird knows where to land."},
			],
			"extract_radio": "Signal's green. Evac lands on platform three. Get her there.",
		},
		{
			"id": "s2_yard",
			"layout": "s2_railyard",
			"job": "steps",
			"title": "SECTOR 02: SWITCHING YARD",
			"desc": "The medic's samples need the lab train route. The switching yard still has a working shunter. Throw the north switch, burn the nest choking the yard, and hold the loco shed while the engine warms.",
			"type": "TYPE: SABOTAGE & DEFEND",
			"threat": "THREAT: MEDIUM [OPEN GROUND]",
			"payout_sc": 680,
			"payout_rc": 3,
			"xp": 280,
			"kills_required": 0,
			"is_night": false,
			"briefing": "WARDEN, Overwatch. The evacuation trains all went to one place. The shunter in this yard can tell us where the line ends.",
			"steps": [
				{"type": "kill", "count": 14, "title": "CLEAR THE YARD",
					"radio": "Lots of open ground out there. Use the wagons."},
				{"type": "search", "marker": "NorthSwitch", "seconds": 4.0, "title": "THROW THE SWITCH",
					"radio": "Switch lever is in the signal tower, north side of the yard."},
				{"type": "destroy", "marker": "YardNest", "title": "BURN OUT THE NEST",
					"radio": "There's a nest in the middle of the yard. It'll swamp the shed if you leave it."},
				{"type": "defend", "marker": "Shunter", "seconds": 25.0, "title": "HOLD THE LOCO SHED",
					"radio": "Shunter's in the loco shed. It's loud when it starts and they will come. Hold."},
			],
			"extract_radio": "Engine's running and the route log is mine. Evac on the east dock. Go.",
		},
		{
			"id": "s2_overpass",
			"layout": "s2_overpass",
			"job": "steps",
			"title": "SECTOR 02: HIGH GROUND",
			"desc": "Overwatch is deaf to the east. Climb the interchange, burn the nest on the bus deck, raise the relay in the toll booth, and hold the overpass until the signal locks.",
			"type": "TYPE: SIGNAL & DEFEND",
			"threat": "THREAT: HIGH [THREE TIERS]",
			"payout_sc": 720,
			"payout_rc": 3,
			"xp": 300,
			"kills_required": 0,
			"is_night": false,
			"briefing": "WARDEN, Overwatch. I can't see past the interchange. Get up high and give me eyes on the lab road.",
			"steps": [
				{"type": "kill", "count": 14, "title": "CLEAR THE ON-RAMP",
					"radio": "Street level first. Stairs up are on both ends."},
				{"type": "destroy", "marker": "RampNest", "title": "BURN OUT THE NEST",
					"radio": "Nest on the bus deck. Burn it before you go higher."},
				{"type": "search", "marker": "TollRadio", "seconds": 4.0, "title": "RAISE THE RELAY",
					"radio": "Toll booth at the west end of the deck has a relay. Patch me in."},
				{"type": "defend", "marker": "OverpassHold", "seconds": 25.0, "title": "HOLD THE OVERPASS",
					"radio": "Relay's up. Get on the highway and hold while I lock the signal."},
			],
			"extract_radio": "I can see the lab road. Bird's coming in on the highway, east end.",
		},
	],
	3: [
		{
			"id": "s3_floodlights",
			"layout": "s3_quay",
			"job": "steps",
			"title": "SECTOR 03: FLOODLIGHTS",
			"desc": "The docks went dark the night the lab's ship came in. Something big came off it and nests under the cranes. Restart the floodlights, kill the Brute, and get out along the pier.",
			"type": "TYPE: NIGHT HUNT",
			"threat": "THREAT: HIGH [BRUTE, NIGHT]",
			"payout_sc": 820,
			"payout_rc": 4,
			"xp": 360,
			"kills_required": 0,
			"is_night": true,
			"briefing": "WARDEN, Overwatch. The docks have been dark for a week. Thermal shows one heat signature three times the size of the others. Bring a light.",
			"steps": [
				{"type": "kill", "count": 16, "title": "CLEAR THE CONTAINER YARD",
					"radio": "Your weapon light is all you've got until the floodlights are back. Stay in the lanes."},
				{"type": "search", "marker": "FloodlightGenerator", "seconds": 5.0, "title": "RESTART THE GENERATOR",
					"radio": "Floodlight generator is in the warehouse, west side of the yard."},
				{"type": "hunt", "marker": "BruteCranes", "health": 8500.0, "title": "KILL THE BRUTE",
					"radio": "Lights are up and so is it. Under the east cranes. Keep your distance and keep shooting. Burn it if you can."},
			],
			"extract_radio": "It's down. Bird lands at the end of the pier. Hold it.",
		},
		{
			"id": "s3_hold",
			"layout": "s3_shipyard",
			"job": "steps",
			"title": "SECTOR 03: THE HOLD",
			"desc": "The lab's cargo ship never unloaded. Whatever is sealed in its hold is why the docks fell. Take the cutting torch from the workshop, climb aboard, and hold the deck while the hold is opened.",
			"type": "TYPE: BREACH & HUNT",
			"threat": "THREAT: HIGH [BRUTE, HIGH DECK]",
			"payout_sc": 880,
			"payout_rc": 4,
			"xp": 380,
			"kills_required": 0,
			"is_night": true,
			"briefing": "WARDEN, Overwatch. The ship on the slipway is registered to Crimson Complex. Its manifest says 'medical supplies'. Let's see.",
			"steps": [
				{"type": "kill", "count": 16, "title": "CLEAR THE SLIPWAY",
					"radio": "Yard first. The gangways are the only way up and you don't want company on them."},
				{"type": "search", "marker": "CuttingTorch", "seconds": 4.0, "title": "GET THE CUTTING TORCH",
					"radio": "Cutting torch is in the workshop on the west side."},
				{"type": "defend", "marker": "HoldBreach", "seconds": 25.0, "title": "HOLD THE DECK",
					"radio": "Torch is cutting. It's loud and it's slow. Hold the deck."},
				{"type": "hunt", "marker": "BruteHold", "health": 9500.0, "title": "KILL WHAT CAME OUT",
					"radio": "Hold's open. Something just climbed out by the bridge. Kill it."},
			],
			"extract_radio": "Hold's full of cold-storage crates. All empty. Bird lands on the foredeck.",
		},
		{
			"id": "s3_fuel",
			"layout": "s3_fuel",
			"job": "steps",
			"title": "SECTOR 03: DEAD MAN'S SWITCH",
			"desc": "The horde follows the fuel lines to the lab. Close the main valve, kill the Brute stalking the pipe racks, and hold the control room while the depot is rigged to burn.",
			"type": "TYPE: SABOTAGE & HOLD",
			"threat": "THREAT: SEVERE [BRUTE, PIPE MAZE]",
			"payout_sc": 950,
			"payout_rc": 5,
			"xp": 420,
			"kills_required": 0,
			"is_night": true,
			"briefing": "WARDEN, Overwatch. Every lit road to the lab runs through this depot. Burn it and they lose the way.",
			"steps": [
				{"type": "kill", "count": 16, "title": "CLEAR THE DEPOT",
					"radio": "Depot's crawling. The pipe racks make good cover and bad corners."},
				{"type": "search", "marker": "MainValve", "seconds": 5.0, "title": "CLOSE THE MAIN VALVE",
					"radio": "Main valve is on the tank road, north side."},
				{"type": "hunt", "marker": "BrutePipes", "health": 10500.0, "title": "KILL THE BRUTE",
					"radio": "Valve's shut and the pressure drop woke something in the pipes. It's big. Kill it."},
				{"type": "defend", "marker": "ControlRoom", "seconds": 25.0, "title": "HOLD THE CONTROL ROOM",
					"radio": "Control room, north-east corner. Arm the ignition and hold while it counts down."},
			],
			"extract_radio": "Ignition's armed. Get to the jetty, the bird won't wait for the fire.",
		},
	],
	4: [
		{
			"id": "s4_gate",
			"layout": "s4_gate",
			"job": "steps",
			"title": "SECTOR 04: THE FRONT DOOR",
			"desc": "Crimson Complex is still sealed and still running on reserve power. Breach the checkpoint, take the gate override from the guard house, and hold the plaza while the inner doors cycle open.",
			"type": "TYPE: BREACH & HOLD",
			"threat": "THREAT: SEVERE [RUNNER PACKS]",
			"payout_sc": 1050,
			"payout_rc": 5,
			"xp": 480,
			"kills_required": 0,
			"is_night": false,
			"briefing": "WARDEN, Overwatch. This is where it started. Everything we found points here. Open the front door.",
			"steps": [
				{"type": "kill", "count": 18, "title": "BREACH THE CHECKPOINT",
					"radio": "They've been waiting at the gate for weeks. Clear the plaza."},
				{"type": "search", "marker": "GateOverride", "seconds": 5.0, "title": "TAKE THE GATE OVERRIDE",
					"radio": "Override key is in the guard house, north-west corner of the plaza."},
				{"type": "defend", "marker": "PlazaHold", "seconds": 25.0, "title": "HOLD THE PLAZA",
					"radio": "Inner doors are cycling. Every alarm in the Complex just went off. Hold."},
			],
			"extract_radio": "Doors are open. Bird lands on the podium helipad. Up the stairs.",
		},
		{
			"id": "s4_labs",
			"layout": "s4_labs",
			"job": "steps",
			"title": "SECTOR 04: COLD STORAGE",
			"desc": "The research wing holds the Protocol Crimson files and the first sample ever taken: Patient Zero. Pull the files, kill the Brute guarding the freezers, and carry the sample out.",
			"type": "TYPE: RECOVERY & HUNT",
			"threat": "THREAT: SEVERE [BRUTE, LONG CARRY]",
			"payout_sc": 1150,
			"payout_rc": 6,
			"xp": 520,
			"kills_required": 0,
			"is_night": false,
			"briefing": "WARDEN, Overwatch. The medic says Patient Zero's sample could be the start of a cure. Bring it home.",
			"steps": [
				{"type": "kill", "count": 18, "title": "CLEAR THE COURTYARD",
					"radio": "Courtyard's full. Labs are on the north side."},
				{"type": "search", "marker": "LabTerminal", "seconds": 5.0, "title": "PULL THE RESEARCH FILES",
					"radio": "Files are on the terminal in Lab B. Middle door."},
				{"type": "hunt", "marker": "BruteCryo", "health": 11000.0, "title": "KILL THE BRUTE",
					"radio": "Something's awake in the cold-storage yard, east side. It's guarding the freezers."},
				{"type": "carry", "marker": "SampleCase", "title": "TAKE PATIENT ZERO'S SAMPLE",
					"radio": "Sample case is in Lab C. Every one of them will smell it. Run for the entrance."},
			],
			"extract_radio": "I have the files and you have the sample. Bird's at the entrance helipad.",
		},
		{
			"id": "s4_core",
			"layout": "s4_core",
			"job": "steps",
			"finale": true,
			"title": "SECTOR 04: PROTOCOL CRIMSON",
			"desc": "The Complex runs on reserve power, and when it runs out every freezer opens. Cut both power couplings, hold the cryo hall while the freezers vent, and end what's sleeping in the middle of it.",
			"type": "TYPE: FINAL OPERATION",
			"threat": "THREAT: EXTREME [CRIMSON PRIME]",
			"payout_sc": 1400,
			"payout_rc": 8,
			"xp": 650,
			"kills_required": 0,
			"is_night": false,
			"briefing": "WARDEN, Overwatch. The files say there's a reason the freezers have to stay cold. They call it Crimson Prime. We end this tonight.",
			"steps": [
				{"type": "kill", "count": 20, "title": "BREACH THE CORE YARD",
					"radio": "Core yard first. Everything they made is between you and that hall."},
				{"type": "search", "marker": "CouplingWest", "seconds": 4.0, "title": "CUT THE WEST COUPLING",
					"radio": "Two power couplings feed the hall. West one first."},
				{"type": "search", "marker": "CouplingEast", "seconds": 4.0, "title": "CUT THE EAST COUPLING",
					"radio": "Half the power's gone. East coupling now."},
				{"type": "defend", "marker": "CoreDoors", "seconds": 30.0, "title": "HOLD THE CRYO HALL",
					"radio": "The freezers are venting. Everything in there is waking up. Hold the doors."},
				{"type": "hunt", "marker": "CrimsonPrime", "health": 18000.0, "scale": 1.9, "frenzy": true,
					"boss_name": "CrimsonPrime", "title": "END CRIMSON PRIME",
					"radio": "That's it. That's Crimson Prime. Everything you have, WARDEN. Burn it."},
			],
			"extract_radio": "It's over. It's actually over. Bird's on the roof, east wing. Come home, WARDEN.",
		},
	],
}

## Intel documents hidden in sectors (marker name -> lore). Found once, kept forever.
const INTEL: Dictionary = {
	"IntelClinic": {"sector": 1, "title": "CLINIC INTAKE LOG",
		"text": "Day 3. Patients with crimson eyes and no pulse. They still walk. The army took our samples to a medevac."},
	"IntelParking": {"sector": 1, "title": "SOLDIER'S NOTE",
		"text": "They said the strain was contained at the lab. So why are we guarding a car park full of bodies?"},
	"IntelTerrace": {"sector": 1, "title": "PILOT'S LAST CALL",
		"text": "Mayday, Crimson One going down. Cargo has breached. Repeat: the samples are awake."},
	"IntelMarket": {"sector": 1, "title": "QUARTERMASTER'S LEDGER",
		"text": "Rations for 140. Then 90. Then 31. The bitten ones asked to sleep in the hall. We said yes. That was the mistake."},
	"IntelClassroom": {"sector": 1, "title": "CHALKBOARD",
		"text": "Written in red chalk, a child's hand: THEY DONT LIKE FIRE. Underneath, an adult's: the army knew."},
	"IntelDeck": {"sector": 1, "title": "RELAY OPERATOR'S LOG",
		"text": "Picked up military chatter on the lab frequency. Three words, over and over: Protocol Crimson active."},
	"IntelPumpHouse": {"sector": 1, "title": "MAINTENANCE TAG",
		"text": "Sluice 4 sealed by order of the quarantine office. Do not open. Tunnels are full."},
	"IntelSignalBox": {"sector": 1, "title": "LAST TRAIN MANIFEST",
		"text": "Evacuation train 06:40. 212 passengers. Arrived at the lab station: 0 passengers. Cars sealed from outside."},
	"IntelEastYard": {"sector": 1, "title": "SPRAY-PAINTED WALL",
		"text": "BURN THE BODIES. THEY GET UP AGAIN. THE RED ONES ARE FASTER."},
	"IntelTicketDesk": {"sector": 2, "title": "MEDIC'S NOTEBOOK",
		"text": "Crimson isn't a virus. It's in the blood like a passenger. Fire makes it let go. Cold makes it sleep."},
	"IntelBusDepot": {"sector": 2, "title": "DRIVER'S ROSTER",
		"text": "Route 9 diverted to the lab station by military order. No stops. Driver signature crossed out."},
	"IntelSignalRoom": {"sector": 2, "title": "SIGNAL LOG",
		"text": "Platform 3 held for 'sealed cargo'. Guard posted. Guard reports noises from inside the cars."},
	"IntelSignalTower": {"sector": 2, "title": "SWITCH ORDERS",
		"text": "All lines to terminate at Crimson Complex. Do not route civilian traffic. This order does not exist."},
	"IntelLocoShed": {"sector": 2, "title": "ENGINEER'S PHOTO",
		"text": "A crew photo, one face circled in red. On the back: 'he got bit on the lab run and drove us home anyway.'"},
	"IntelWagon": {"sector": 2, "title": "CARGO TAG",
		"text": "BIOHAZARD. PROPERTY OF CRIMSON COMPLEX. KEEP BELOW 4 DEGREES. DO NOT OPEN IN TRANSIT."},
	"IntelTollBooth": {"sector": 2, "title": "TOLL CAMERA PRINTOUT",
		"text": "06:12, the morning it started: forty army trucks heading east to the lab. 07:30: none coming back."},
	"IntelTanker": {"sector": 2, "title": "TANKER MANIFEST",
		"text": "Liquid nitrogen, 20,000 litres, for Crimson Complex cold storage. Delivery refused: 'facility compromised'."},
	"IntelBillboard": {"sector": 2, "title": "DEFACED BILLBOARD",
		"text": "Over a smiling family, in red: THEY KNEW. THEY BUILT IT. THE LAB IS PAST THE YARD."},
	"IntelHarbourMaster": {"sector": 3, "title": "HARBOUR MASTER'S DESK",
		"text": "Night shift refused the lab ship. Army unloaded it themselves. By morning the night shift was gone."},
	"IntelContainer": {"sector": 3, "title": "SCRATCHED CONTAINER DOOR",
		"text": "Scratched from the inside: 14 DAYS. NO FOOD. THEY PUT THE BIG ONE IN WITH US."},
	"IntelPier": {"sector": 3, "title": "FLARE GUN, ONE SHOT LEFT",
		"text": "Taped to the grip: 'If you're reading this, the big one doesn't like light. Neither do we anymore.'"},
	"IntelShipLog": {"sector": 3, "title": "CAPTAIN'S LOG",
		"text": "Cargo: Crimson Brute, unit 4. Sedated at minus 20. Day 9: the cold failed. Day 9: we stopped writing."},
	"IntelWorkshop": {"sector": 3, "title": "WELDER'S WARNING",
		"text": "Don't cut the hold. We heard it walking around in there before the power went."},
	"IntelSlipway": {"sector": 3, "title": "SHIPPING ORDER",
		"text": "Protocol Crimson: field test of enhanced carriers in a contained population. Contained population: this city."},
	"IntelTankLog": {"sector": 3, "title": "DEPOT TANK LOG",
		"text": "All four tanks reserved for Crimson Complex generators. They need the power to keep the freezers on."},
	"IntelControlRoom": {"sector": 3, "title": "EMERGENCY ORDER",
		"text": "If the depot is lost, the Complex runs on reserve for 72 hours. After that the freezers open. All of them."},
	"IntelJetty": {"sector": 3, "title": "FISHERMAN'S RADIO",
		"text": "Looping on channel 16: 'Do not approach the lab by sea. They are shooting boats. They are shooting everyone.'"},
	"IntelGuardLog": {"sector": 4, "title": "GUARD ROSTER",
		"text": "Day 1: 40 on shift. Day 2: 22. Day 3: orders to lock the gate from outside. We are inside."},
	"IntelMotorPool": {"sector": 4, "title": "MOTOR POOL WHITEBOARD",
		"text": "TRUCKS TO: transit terminal, docks, quarantine block. CARGO: 'carriers'. Someone wrote underneath: people."},
	"IntelPodium": {"sector": 4, "title": "DIRECTOR'S SPEECH NOTES",
		"text": "Protocol Crimson will make the soldier who cannot fall. Today we begin the city-scale trial."},
	"IntelLabA": {"sector": 4, "title": "LAB A WHITEBOARD",
		"text": "Carrier strain spreads through blood. Fire denatures it. Cold puts it to sleep. Do not let the cold fail."},
	"IntelCryoYard": {"sector": 4, "title": "FREEZER TAG",
		"text": "PATIENT ZERO. Volunteer. Night nurse at the quarantine clinic. Asked us to use her to find a cure."},
	"IntelLabC": {"sector": 4, "title": "RESEARCHER'S LAST NOTE",
		"text": "The sample in this case is clean. She was immune. We could have stopped all of it. Get it out."},
	"IntelCryoWest": {"sector": 4, "title": "CRYO HALL LOG",
		"text": "Subject Prime: 41 carriers fused. Kept at minus 40. If reserve power fails, Prime wakes first."},
	"IntelCryoEast": {"sector": 4, "title": "POWER SCHEDULE",
		"text": "Reserve power: 72 hours. Fuel deliveries cancelled. The docks depot is gone. Hours remaining: 3."},
	"IntelRoofDeck": {"sector": 4, "title": "PILOT'S NOTE",
		"text": "Last bird out of the Complex. Left room for one more. Nobody came. If you're reading this, I waited."},
}
const INTEL_RC_REWARD := 1

## Paired operative skills (Design Doc Section 5)
const SKILLS_DATA: Dictionary = {
	"blood_siphon": {
		"name": "BLOOD SIPHON",
		"pair": "crimson_berserker",
		"desc": "+25% fire rate while you stand in fresh blood.",
		"cost_rc": 5,
		"level_req": 2,
	},
	"hemorrhage_rounds": {
		"name": "HEMORRHAGE ROUNDS",
		"pair": "crimson_berserker",
		"desc": "Zombies die into blood pools twice as wide: more ground for Blood Siphon.",
		"cost_rc": 5,
		"level_req": 4,
	},
	"napalm_gel": {
		"name": "NAPALM GEL",
		"pair": "tactical_demolisher",
		"desc": "Molotov fire burns 50% longer & slows targets by 40%.",
		"cost_rc": 10,
		"level_req": 6,
	},
	"thermobaric_ignition": {
		"name": "THERMOBARIC IGNITION",
		"pair": "tactical_demolisher",
		"desc": "Shooting burning hostiles triggers concussive blasts.",
		"cost_rc": 10,
		"level_req": 8,
	},
	"silent_treads": {
		"name": "SILENT TREADS",
		"pair": "ghost_operative",
		"desc": "Walking in blood leaves no scent tracks for Runners.",
		"cost_rc": 15,
		"level_req": 12,
	},
	"strobe_torch": {
		"name": "STROBE TORCH",
		"pair": "ghost_operative",
		"desc": "In Night Ops, flashlight cone periodically stuns zombies.",
		"cost_rc": 15,
		"level_req": 15,
	},
}

## Content that actually works in a run. Everything else shows as "in development"
## in the hub and can't be bought; anything bought before this existed is refunded on load.
const PLAYABLE_SECTORS: Array[int] = [1, 2, 3, 4]
const IMPLEMENTED_WEAPONS: Array[String] = ["assault_carbine"]
const IMPLEMENTED_SKILLS: Array[String] = ["blood_siphon", "hemorrhage_rounds"]
const WEAPON_UPGRADE_COST_STEP := 150  # Tier N costs N * 150 SC (matches the Armory)

## Per-kill bounty (SC, unbanked until extraction) and XP.
const KILL_REWARDS: Dictionary = {
	"shambler": {"sc": 1, "xp": 2},
	"runner": {"sc": 5, "xp": 4},
	"tank": {"sc": 25, "xp": 15},
}

## Clearance level each Sector unlocks at (index = sector id).
## A sector opens when the previous one has been extracted from once AND the player
## has reached this clearance level (index = sector id).
const SECTOR_UNLOCK_LEVELS: Array[int] = [0, 1, 3, 6, 10]

## Armory track display names (shared with the hub and the debrief's next-goal line)
const UPGRADE_TRACK_NAMES: Dictionary = {
	"damage_knockback": "OVERPRESSURE ROUNDS",
	"fire_rate_mag": "EXTENDED DRUM",
	"penetration": "PIERCING CORE",
	"crit_autoaim": "LASER TARGETER",
}

const COMMS_PAYOUT_BONUS_PER_TIER := 0.15  # +15% contract SC per Comms Array tier
const MEDBAY_HEALTH_PER_TIER := 20.0       # +20 starting armor/HP per Medbay tier
const EVAC_HOLD_BASE := 20.0               # Seconds to hold the LZ before evac arrives
const HELIPAD_EVAC_REDUCTION_PER_TIER := 3.0 # Tactical Helipad: -3 s per tier
const EVAC_HOLD_MIN := 8.0
const FIRST_CLEAR_MULTIPLIER := 2          # First successful extraction per sector pays double
const FAILURE_LOOT_KEPT := 0.3             # KIA keeps 30% of unbanked SC
const FAILURE_XP_KEPT := 0.5               # KIA keeps 50% of combat XP

## XP to go from level N to N+1 (index N). Tuned so a sector-1 run (~200-250 XP)
## gives a level-up every 1-2 runs early on; after level 10 it's 600 + 60 per level.
const XP_PER_LEVEL: Array[int] = [
	0,    # Level 0 → 1 (unused)
	150,  # Level 1 → 2
	220,  # Level 2 → 3
	280,  # Level 3 → 4
	300,  # Level 4 → 5
	320,  # Level 5 → 6
	400,  # Level 6 → 7
	440,  # Level 7 → 8
	470,  # Level 8 → 9
	490,  # Level 9 → 10
]
const XP_AFTER_10_BASE := 600
const XP_AFTER_10_STEP := 60

const MAX_CLEARANCE_LEVEL := 50
const MAX_WEAPON_UPGRADE_LEVEL := 10
const MAX_OUTPOST_UPGRADE_LEVEL := 5

enum WeaponID { ASSAULT_CARBINE, TACTICAL_SHOTGUN, HIGH_CALIBER_SMG }
const WEAPON_IDS: Array[String] = ["assault_carbine", "tactical_shotgun", "high_caliber_smg"]
const UPGRADE_TRACKS: Array[String] = ["damage_knockback", "fire_rate_mag", "penetration", "crit_autoaim"]
const OUTPOST_FACILITIES: Array[String] = ["comms_array", "medbay", "helipad"]

# ─── Persistent State ─────────────────────────────────────────────────────────
## Banked Economy (Safe in Outpost Vault)
var survival_coins: int = 0:
	set(value):
		survival_coins = maxi(value, 0)
		coins_changed.emit(survival_coins)

var research_cores: int = 0:
	set(value):
		research_cores = maxi(value, 0)
		research_cores_changed.emit(research_cores)

## Progression
var clearance_level: int = 1:
	set(value):
		clearance_level = clampi(value, 1, MAX_CLEARANCE_LEVEL)
		clearance_level_changed.emit(clearance_level)

var clearance_xp: int = 0
var has_completed_tutorial: bool = false
var highest_sector_unlocked: int = 1
## Sectors with at least one successful extraction: { "1": true }
var sectors_cleared: Dictionary = {}
## Intel documents found: { "IntelClinic": true }
var intel_found: Dictionary = {}

## Skills
var unlocked_skills: Dictionary = {}
var equipped_skills: Array[String] = ["", ""]  # 2 paired skill slots

## Weapon upgrades: { "weapon_id": { "track_name": level_int } }
var weapon_upgrades: Dictionary = {}

## Outpost facility levels: { "facility_name": level_int }
var outpost_levels: Dictionary = {}

## Settings (Saved & Restored)
var saved_master_volume: float = 1.0
var saved_sfx_volume: float = 1.0
var saved_music_volume: float = 0.7
var saved_haptics_enabled: bool = true
var saved_screen_shake: bool = true
var saved_blood_full: bool = true   # FULL vs LOW blood decals (performance)

## Hub tab to open next time the hub loads (e.g. "armory" from the debrief's Upgrade button)
var pending_hub_tab: String = ""

## Lifetime Statistics
var total_kills: int = 0
var total_missions_completed: int = 0
var total_extractions: int = 0

# ─── In-Run Temporary State (Volatile until Extraction) ─────────────────────────
var current_sector: int = 1
var current_contract: Dictionary = {}
var in_run_sc: int = 0
var in_run_rc: int = 0
var in_run_xp: int = 0
var in_run_kills: Dictionary = {
	"shambler": 0,
	"runner": 0,
	"tank": 0,
}
## True between start_mission_run() and complete/fail/abandon. Guards against double payouts.
var run_active: bool = false
var last_mission_summary: Dictionary = {}
## Set by load_game() when purchases of unreleased content were refunded; the hub shows it once.
var pending_refund_sc: int = 0
var pending_refund_rc: int = 0

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_init_default_upgrades()
	load_game()
	if pending_refund_sc > 0 or pending_refund_rc > 0:
		save_game()
	_apply_loaded_settings()
	print("[GameManager] Ready — Clearance Lv.%d | Vault SC: %d | Vault RC: %d" % [
		clearance_level, survival_coins, research_cores
	])


func _notification(what: int) -> void:
	# Persist progress when Android backgrounds the app or the window closes.
	# Unbanked run loot is intentionally NOT saved: it only counts once extracted.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


func _init_default_upgrades() -> void:
	for weapon_id in WEAPON_IDS:
		if not weapon_upgrades.has(weapon_id):
			weapon_upgrades[weapon_id] = {}
			for track in UPGRADE_TRACKS:
				weapon_upgrades[weapon_id][track] = 0

	for facility in OUTPOST_FACILITIES:
		if not outpost_levels.has(facility):
			outpost_levels[facility] = 0


# ─── Economy (Vault) ───────────────────────────────────────────────────────────
func add_coins(amount: int) -> void:
	survival_coins += amount


func spend_coins(amount: int) -> bool:
	if survival_coins >= amount:
		survival_coins -= amount
		return true
	return false


func add_research_cores(amount: int) -> void:
	research_cores += amount


func spend_research_cores(amount: int) -> bool:
	if research_cores >= amount:
		research_cores -= amount
		return true
	return false


# ─── In-Run Loot & Combat Tracking ─────────────────────────────────────────────
func get_contracts(sector_id: int) -> Array:
	return CONTRACTS.get(sector_id, CONTRACTS[1])


func get_contract(sector_id: int, index: int = 0) -> Dictionary:
	var list := get_contracts(sector_id)
	return list[clampi(index, 0, list.size() - 1)]


## The contract being played: whatever the Command Board deployed, or the sector's
## first contract when main.tscn is launched directly from the editor.
func get_active_contract() -> Dictionary:
	if not current_contract.is_empty():
		return current_contract
	return get_contract(current_sector)


## Contract SC payout after the Comms Array bonus (what the board should advertise).
func get_contract_payout_sc(contract: Dictionary) -> int:
	var base: int = contract["payout_sc"]
	var mult := 1.0 + COMMS_PAYOUT_BONUS_PER_TIER * float(get_outpost_level("comms_array"))
	return int(round(float(base) * mult))


func is_sector_cleared(sector_id: int) -> bool:
	return sectors_cleared.get(str(sector_id), false)


func get_evac_hold_time() -> float:
	var t := EVAC_HOLD_BASE - HELIPAD_EVAC_REDUCTION_PER_TIER * float(get_outpost_level("helipad"))
	return maxf(EVAC_HOLD_MIN, t)


func get_medbay_health_bonus() -> float:
	return MEDBAY_HEALTH_PER_TIER * float(get_outpost_level("medbay"))


func start_mission_run() -> void:
	in_run_sc = 0
	in_run_rc = 0
	in_run_xp = 0
	for k in in_run_kills.keys():
		in_run_kills[k] = 0
	run_active = true
	last_mission_summary = {}
	in_run_loot_changed.emit(in_run_sc, in_run_rc)
	in_run_kills_changed.emit(0)


func is_intel_found(intel_id: String) -> bool:
	return intel_found.get(intel_id, false)


## Marks an intel document as read (saved immediately) and adds its research core
## to the run's unbanked loot. Returns the lore entry, or {} if unknown/already found.
func collect_intel(intel_id: String) -> Dictionary:
	if not INTEL.has(intel_id) or is_intel_found(intel_id):
		return {}
	intel_found[intel_id] = true
	add_in_run_research_core(INTEL_RC_REWARD)
	save_game()
	return INTEL[intel_id]


func get_intel_progress(sector_id: int) -> Vector2i:
	var found := 0
	var total := 0
	for intel_id in INTEL:
		if int(INTEL[intel_id]["sector"]) == sector_id:
			total += 1
			if is_intel_found(intel_id):
				found += 1
	return Vector2i(found, total)


func get_run_kill_count() -> int:
	var total := 0
	for k in in_run_kills:
		total += int(in_run_kills[k])
	return total


func record_kill(enemy_type: String) -> void:
	total_kills += 1
	if not run_active:
		return  # e.g. a burning zombie dying after extraction already paid out
	var reward: Dictionary = KILL_REWARDS.get(enemy_type, KILL_REWARDS["shambler"])

	in_run_kills[enemy_type] = int(in_run_kills.get(enemy_type, 0)) + 1
	in_run_sc += int(reward["sc"])
	in_run_xp += int(reward["xp"])
	in_run_loot_changed.emit(in_run_sc, in_run_rc)
	in_run_kills_changed.emit(get_run_kill_count())


func add_in_run_research_core(amount: int = 1) -> void:
	in_run_rc += amount
	in_run_loot_changed.emit(in_run_sc, in_run_rc)


# ─── Mission Completion / Failure Resolution ───────────────────────────────────
## Successfully extracted: Payouts + in-run bounty + XP deposited directly into Vault
func apply_mission_rewards(contract_payout_sc: int, contract_payout_rc: int, kill_bonus_sc: int, xp_earned: int) -> void:
	# Add contract reward + kill bonus to vault
	add_coins(contract_payout_sc + kill_bonus_sc)
	add_research_cores(contract_payout_rc + in_run_rc)
	add_xp(xp_earned)
	
	total_missions_completed += 1
	total_extractions += 1
	
	# Clear in-run cache
	in_run_sc = 0
	in_run_rc = 0
	save_game()


## Mission failed (KIA): Forfeits contract bonus and 70% of in-run loot.
## The player keeps 30% of what they scavenged in that run.
## CRITICAL: Existing vault balance is NEVER penalized!
func apply_mission_failure_penalty(unbanked_sc: int) -> int:
	var kept_loot := int(float(unbanked_sc) * FAILURE_LOOT_KEPT)
	add_coins(kept_loot)
	
	in_run_sc = 0
	in_run_rc = 0
	save_game()
	return kept_loot


## Player reached the LZ with the contract objective met. Banks everything and
## returns a summary for the debrief screen. Safe to call twice (second call is a no-op).
func complete_mission() -> Dictionary:
	if not run_active:
		return {}
	run_active = false

	var sector := current_sector
	var contract := get_active_contract()
	var first_clear := not is_sector_cleared(sector)
	var mult := FIRST_CLEAR_MULTIPLIER if first_clear else 1
	var contract_sc := get_contract_payout_sc(contract) * mult
	var contract_rc: int = contract["payout_rc"]
	var contract_xp: int = int(contract["xp"]) * mult

	var summary := _base_summary(true)
	summary["contract_sc"] = contract_sc
	summary["kill_sc"] = in_run_sc
	summary["total_sc"] = contract_sc + in_run_sc
	summary["total_rc"] = contract_rc + in_run_rc
	summary["contract_xp"] = contract_xp
	summary["kill_xp"] = in_run_xp
	summary["total_xp"] = contract_xp + in_run_xp
	summary["first_clear"] = first_clear

	var level_before := clearance_level
	var sector_before := highest_sector_unlocked
	sectors_cleared[str(sector)] = true
	apply_mission_rewards(contract_sc, contract_rc, in_run_sc, contract_xp + in_run_xp)
	_update_sector_unlock()
	save_game()

	_finish_summary(summary, level_before, sector_before)
	return summary


## Player was killed. Keeps a share of unbanked SC and combat XP; contract reward and RC are lost.
func fail_mission() -> Dictionary:
	if not run_active:
		return {}
	run_active = false

	var kept_xp := int(float(in_run_xp) * FAILURE_XP_KEPT)
	var summary := _base_summary(false)
	summary["lost_sc"] = in_run_sc
	summary["total_rc"] = 0
	summary["total_xp"] = kept_xp

	var level_before := clearance_level
	var sector_before := highest_sector_unlocked
	add_xp(kept_xp)
	summary["total_sc"] = apply_mission_failure_penalty(in_run_sc)

	_finish_summary(summary, level_before, sector_before)
	return summary


## Quit or restart mid-run: nothing is banked, nothing is penalised.
func abandon_mission() -> void:
	run_active = false
	in_run_sc = 0
	in_run_rc = 0
	in_run_xp = 0
	save_game()  # Lifetime kill stats


func _base_summary(success: bool) -> Dictionary:
	return {
		"success": success,
		"sector": current_sector,
		"title": get_active_contract()["title"],
		"kills": in_run_kills.duplicate(),
		"kill_count": get_run_kill_count(),
		"intel": get_intel_progress(current_sector),
		"finale": bool(get_active_contract().get("finale", false)),
	}


func _finish_summary(summary: Dictionary, level_before: int, sector_before: int) -> void:
	summary["level_before"] = level_before
	summary["level_after"] = clearance_level
	summary["sector_unlocked"] = highest_sector_unlocked if highest_sector_unlocked > sector_before else 0
	summary["xp_now"] = clearance_xp
	summary["xp_needed"] = get_xp_for_next_level()
	last_mission_summary = summary
	mission_resolved.emit(summary)


# ─── Progression ───────────────────────────────────────────────────────────────
func add_xp(amount: int) -> void:
	clearance_xp += amount
	_check_level_up()
	clearance_xp_changed.emit(clearance_xp, get_xp_for_next_level())


func get_xp_for_next_level() -> int:
	if clearance_level >= MAX_CLEARANCE_LEVEL:
		return 0
	if clearance_level >= XP_PER_LEVEL.size():
		return XP_AFTER_10_BASE + (clearance_level - XP_PER_LEVEL.size()) * XP_AFTER_10_STEP
	return XP_PER_LEVEL[clearance_level]


func _check_level_up() -> void:
	var required := get_xp_for_next_level()
	while required > 0 and clearance_xp >= required and clearance_level < MAX_CLEARANCE_LEVEL:
		clearance_xp -= required
		clearance_level += 1
		_update_sector_unlock()
		required = get_xp_for_next_level()


func _update_sector_unlock() -> void:
	# Never re-lock a sector the player already had access to.
	highest_sector_unlocked = maxi(highest_sector_unlocked, get_sector_for_level(clearance_level))


func get_sector_for_level(level: int) -> int:
	var sector := 1
	for s in range(2, SECTOR_UNLOCK_LEVELS.size()):
		if level >= SECTOR_UNLOCK_LEVELS[s] and is_sector_cleared(s - 1):
			sector = s
		else:
			break
	return sector


## What the player is short of for sector `sector_id` ("" when it's open).
func get_sector_unlock_hint(sector_id: int) -> String:
	if sector_id <= highest_sector_unlocked:
		return ""
	var needs: Array[String] = []
	if not is_sector_cleared(sector_id - 1):
		needs.append("Finish Sector %d" % (sector_id - 1))
	if clearance_level < SECTOR_UNLOCK_LEVELS[sector_id]:
		needs.append("Reach level %d" % SECTOR_UNLOCK_LEVELS[sector_id])
	return " and ".join(needs)


## The cheapest Armory upgrade for the equipped weapon, for the debrief's next-goal line.
## Returns {} when everything is maxed.
func get_next_armory_goal() -> Dictionary:
	var best := {}
	for track in UPGRADE_TRACKS:
		var lv := get_weapon_upgrade_level(IMPLEMENTED_WEAPONS[0], track)
		if lv >= MAX_WEAPON_UPGRADE_LEVEL:
			continue
		var cost := (lv + 1) * WEAPON_UPGRADE_COST_STEP
		if best.is_empty() or cost < int(best["cost"]):
			best = {"name": UPGRADE_TRACK_NAMES.get(track, track), "level": lv + 1, "cost": cost}
	return best


# ─── Skills ────────────────────────────────────────────────────────────────────
func unlock_skill(skill_id: String) -> void:
	unlocked_skills[skill_id] = true
	save_game()


func is_skill_unlocked(skill_id: String) -> bool:
	return unlocked_skills.get(skill_id, false)


func equip_skill(slot: int, skill_id: String) -> bool:
	if slot < 0 or slot > 1:
		return false
	if not is_skill_unlocked(skill_id):
		return false
	equipped_skills[slot] = skill_id
	skill_equipped.emit(slot, skill_id)
	save_game()
	return true


func unequip_skill(slot: int) -> void:
	if slot >= 0 and slot <= 1:
		equipped_skills[slot] = ""
		skill_equipped.emit(slot, "")
		save_game()


func get_equipped_skills() -> Array[String]:
	return equipped_skills


# ─── Weapon Upgrades ──────────────────────────────────────────────────────────
func get_weapon_upgrade_level(weapon_id: String, track: String) -> int:
	if weapon_upgrades.has(weapon_id) and weapon_upgrades[weapon_id].has(track):
		return weapon_upgrades[weapon_id][track]
	return 0


func upgrade_weapon(weapon_id: String, track: String, cost_sc: int) -> bool:
	var current_level := get_weapon_upgrade_level(weapon_id, track)
	if current_level >= MAX_WEAPON_UPGRADE_LEVEL:
		return false
	if not spend_coins(cost_sc):
		return false
	weapon_upgrades[weapon_id][track] = current_level + 1
	weapon_upgraded.emit(weapon_id, track, current_level + 1)
	save_game()
	return true


# ─── Outpost Upgrades ─────────────────────────────────────────────────────────
func get_outpost_level(facility: String) -> int:
	return outpost_levels.get(facility, 0)


func upgrade_outpost(facility: String, cost_sc: int, cost_rc: int = 0) -> bool:
	var current_level := get_outpost_level(facility)
	if current_level >= MAX_OUTPOST_UPGRADE_LEVEL:
		return false
	if survival_coins < cost_sc or research_cores < cost_rc:
		return false
	spend_coins(cost_sc)
	if cost_rc > 0:
		spend_research_cores(cost_rc)
	outpost_levels[facility] = current_level + 1
	outpost_upgraded.emit(facility, current_level + 1)
	save_game()
	return true


# ─── Settings Synchronization ──────────────────────────────────────────────────
func sync_settings_from_managers() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		saved_master_volume = am.master_volume
		saved_sfx_volume = am.sfx_volume
		saved_music_volume = am.music_volume
		saved_haptics_enabled = am.haptics_enabled


func _apply_loaded_settings() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.master_volume = saved_master_volume
		am.sfx_volume = saved_sfx_volume
		am.music_volume = saved_music_volume
		am.haptics_enabled = saved_haptics_enabled


func save_settings_only() -> void:
	save_game()


# ─── Save / Load System ────────────────────────────────────────────────────────
## Crash-safe save: write to a temp file, keep the previous good save as a backup,
## then swap the temp file into place. A half-written file can never replace a good one.
func save_game() -> void:
	sync_settings_from_managers()
	
	var config := ConfigFile.new()
	config.set_value("meta", "version", SAVE_VERSION)

	# Economy
	config.set_value("economy", "survival_coins", survival_coins)
	config.set_value("economy", "research_cores", research_cores)

	# Progression
	config.set_value("progression", "clearance_level", clearance_level)
	config.set_value("progression", "clearance_xp", clearance_xp)
	config.set_value("progression", "has_completed_tutorial", has_completed_tutorial)
	config.set_value("progression", "highest_sector_unlocked", highest_sector_unlocked)
	config.set_value("progression", "sectors_cleared", sectors_cleared)
	config.set_value("progression", "intel_found", intel_found)

	# Skills
	config.set_value("skills", "unlocked_skills", unlocked_skills)
	config.set_value("skills", "equipped_skills_0", equipped_skills[0])
	config.set_value("skills", "equipped_skills_1", equipped_skills[1])

	# Weapon upgrades
	config.set_value("weapons", "upgrades", weapon_upgrades)

	# Outpost
	config.set_value("outpost", "levels", outpost_levels)

	# Settings
	config.set_value("settings", "master_volume", saved_master_volume)
	config.set_value("settings", "sfx_volume", saved_sfx_volume)
	config.set_value("settings", "music_volume", saved_music_volume)
	config.set_value("settings", "haptics_enabled", saved_haptics_enabled)
	config.set_value("settings", "screen_shake", saved_screen_shake)
	config.set_value("settings", "blood_full", saved_blood_full)

	# Stats
	config.set_value("stats", "total_kills", total_kills)
	config.set_value("stats", "total_missions_completed", total_missions_completed)
	config.set_value("stats", "total_extractions", total_extractions)

	var err := config.save_encrypted_pass(SAVE_TMP_PATH, SAVE_KEY)
	if err != OK:
		push_warning("[GameManager] Failed to save game: %s" % error_string(err))
		return
	
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, SAVE_BACKUP_PATH)
		DirAccess.remove_absolute(SAVE_PATH)
	err = DirAccess.rename_absolute(SAVE_TMP_PATH, SAVE_PATH)
	if err != OK:
		push_warning("[GameManager] Failed to finalize save: %s" % error_string(err))
		return
	game_saved.emit()


## Loads the main save, falling back to the temp file (interrupted swap) and then the backup.
func load_game() -> void:
	var config: ConfigFile = null
	for path in [SAVE_PATH, SAVE_TMP_PATH, SAVE_BACKUP_PATH]:
		config = _try_load_config(path)
		if config:
			if path != SAVE_PATH:
				push_warning("[GameManager] Main save unreadable, recovered from %s" % path)
			break
	if not config:
		return

	# Economy
	survival_coins = _read_int(config, "economy", "survival_coins", 0, 0, 999999999)
	research_cores = _read_int(config, "economy", "research_cores", 0, 0, 999999999)

	# Progression
	clearance_level = _read_int(config, "progression", "clearance_level", 1, 1, MAX_CLEARANCE_LEVEL)
	clearance_xp = _read_int(config, "progression", "clearance_xp", 0, 0, 999999999)
	has_completed_tutorial = _read_bool(config, "progression", "has_completed_tutorial", false)
	highest_sector_unlocked = _read_int(config, "progression", "highest_sector_unlocked", 1, 1, SECTOR_UNLOCK_LEVELS.size() - 1)
	sectors_cleared = {}
	var cleared = config.get_value("progression", "sectors_cleared", {})
	if cleared is Dictionary:
		for k in cleared:
			if cleared[k] == true:
				sectors_cleared[str(k)] = true
	_update_sector_unlock()

	intel_found = {}
	var intel = config.get_value("progression", "intel_found", {})
	if intel is Dictionary:
		for k in intel:
			if intel[k] == true and INTEL.has(str(k)):
				intel_found[str(k)] = true

	# Skills
	unlocked_skills = {}
	var skills = config.get_value("skills", "unlocked_skills", {})
	if skills is Dictionary:
		for k in skills:
			if skills[k] == true:
				unlocked_skills[str(k)] = true
	for slot in range(2):
		var id := _read_string(config, "skills", "equipped_skills_%d" % slot, "")
		equipped_skills[slot] = id if is_skill_unlocked(id) else ""

	# Weapon upgrades (clamped so a corrupt value can't exceed the max tier)
	weapon_upgrades = {}
	var upgrades = config.get_value("weapons", "upgrades", {})
	if upgrades is Dictionary:
		for weapon_id in WEAPON_IDS:
			weapon_upgrades[weapon_id] = {}
			var tracks = upgrades.get(weapon_id, {})
			for track in UPGRADE_TRACKS:
				var lv = tracks.get(track, 0) if tracks is Dictionary else 0
				weapon_upgrades[weapon_id][track] = clampi(int(lv), 0, MAX_WEAPON_UPGRADE_LEVEL) if (lv is int or lv is float) else 0

	# Outpost
	outpost_levels = {}
	var levels = config.get_value("outpost", "levels", {})
	if levels is Dictionary:
		for facility in OUTPOST_FACILITIES:
			var lv = levels.get(facility, 0)
			outpost_levels[facility] = clampi(int(lv), 0, MAX_OUTPOST_UPGRADE_LEVEL) if (lv is int or lv is float) else 0
	_init_default_upgrades()

	# Settings
	saved_master_volume = _read_float(config, "settings", "master_volume", 1.0)
	saved_sfx_volume = _read_float(config, "settings", "sfx_volume", 1.0)
	saved_music_volume = _read_float(config, "settings", "music_volume", 0.7)
	saved_haptics_enabled = _read_bool(config, "settings", "haptics_enabled", true)
	saved_screen_shake = _read_bool(config, "settings", "screen_shake", true)
	saved_blood_full = _read_bool(config, "settings", "blood_full", true)

	# Stats
	total_kills = _read_int(config, "stats", "total_kills", 0, 0, 999999999)
	total_missions_completed = _read_int(config, "stats", "total_missions_completed", 0, 0, 999999999)
	total_extractions = _read_int(config, "stats", "total_extractions", 0, 0, 999999999)

	_refund_unreleased_purchases()
	game_loaded.emit()


const BLOOD_DECALS_FULL := 120
const BLOOD_DECALS_LOW := 40


func get_blood_decal_limit() -> int:
	return BLOOD_DECALS_FULL if saved_blood_full else BLOOD_DECALS_LOW


## For the hub's "something is ready" dots.
func can_afford_armory_upgrade() -> bool:
	var goal := get_next_armory_goal()
	return not goal.is_empty() and survival_coins >= int(goal["cost"])


func can_afford_skill() -> bool:
	for skill_id in IMPLEMENTED_SKILLS:
		var data: Dictionary = SKILLS_DATA.get(skill_id, {})
		if (not is_skill_unlocked(skill_id) and clearance_level >= int(data.get("level_req", 1))
				and research_cores >= int(data.get("cost_rc", 0))):
			return true
	return false


func get_outpost_upgrade_cost(facility: String) -> Vector2i:
	var lv := get_outpost_level(facility)
	return Vector2i((lv + 1) * 400, (lv + 1) * 2)


func can_afford_outpost_upgrade() -> bool:
	for facility in OUTPOST_FACILITIES:
		if get_outpost_level(facility) >= MAX_OUTPOST_UPGRADE_LEVEL:
			continue
		var cost := get_outpost_upgrade_cost(facility)
		if survival_coins >= cost.x and research_cores >= cost.y:
			return true
	return false


func is_sector_playable(sector_id: int) -> bool:
	return sector_id in PLAYABLE_SECTORS


func _refund_unreleased_purchases() -> void:
	for weapon_id in WEAPON_IDS:
		if weapon_id in IMPLEMENTED_WEAPONS:
			continue
		for track in UPGRADE_TRACKS:
			var lv: int = weapon_upgrades[weapon_id][track]
			if lv > 0:
				pending_refund_sc += int(WEAPON_UPGRADE_COST_STEP * lv * (lv + 1) * 0.5)
				weapon_upgrades[weapon_id][track] = 0
	for skill_id in unlocked_skills.keys():
		if not (skill_id in IMPLEMENTED_SKILLS):
			pending_refund_rc += int(SKILLS_DATA.get(skill_id, {}).get("cost_rc", 0))
			unlocked_skills.erase(skill_id)
	for slot in range(2):
		if not is_skill_unlocked(equipped_skills[slot]):
			equipped_skills[slot] = ""
	survival_coins += pending_refund_sc
	research_cores += pending_refund_rc


func _try_load_config(path: String) -> ConfigFile:
	if not FileAccess.file_exists(path):
		return null
	var config := ConfigFile.new()
	var err := config.load_encrypted_pass(path, SAVE_KEY)
	if err != OK:
		push_warning("[GameManager] Failed to load %s: %s" % [path, error_string(err)])
		return null
	return config


func _read_int(config: ConfigFile, section: String, key: String, default: int, min_v: int, max_v: int) -> int:
	var v = config.get_value(section, key, default)
	if v is int or v is float:
		return clampi(int(v), min_v, max_v)
	return default


func _read_float(config: ConfigFile, section: String, key: String, default: float) -> float:
	var v = config.get_value(section, key, default)
	if v is int or v is float:
		return clampf(float(v), 0.0, 1.0)
	return default


func _read_bool(config: ConfigFile, section: String, key: String, default: bool) -> bool:
	var v = config.get_value(section, key, default)
	return v if v is bool else default


func _read_string(config: ConfigFile, section: String, key: String, default: String) -> String:
	var v = config.get_value(section, key, default)
	return v if v is String else default


func reset_save() -> void:
	for path in [SAVE_PATH, SAVE_TMP_PATH, SAVE_BACKUP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	survival_coins = 0
	research_cores = 0
	clearance_level = 1
	clearance_xp = 0
	has_completed_tutorial = false
	highest_sector_unlocked = 1
	sectors_cleared.clear()
	intel_found.clear()
	unlocked_skills.clear()
	equipped_skills = ["", ""]
	weapon_upgrades.clear()
	outpost_levels.clear()
	total_kills = 0
	total_missions_completed = 0
	total_extractions = 0
	run_active = false
	_init_default_upgrades()
	save_game()
