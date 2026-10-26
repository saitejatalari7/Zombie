extends RefCounted
## Generated from tools/level_design/layouts/s2_overpass.py by build_layouts.py. Do not edit by hand:
## change the layout there and re-run it so the camera and walkability checks run again.

const PLAN := {
	"sector": {
		"id": 2,
		"name": "SECTOR 02: TRANSIT GRID",
		"bounds": [
			-40,
			-50,
			80,
			86
		],
		"layout": "s2_overpass"
	},
	"floors": [
		{
			"name": "Street",
			"x0": -34,
			"x1": 34,
			"z0": 10,
			"z1": 32,
			"y": 0.0
		},
		{
			"name": "Deck",
			"x0": -34,
			"x1": 34,
			"z0": -14,
			"z1": 2,
			"y": 3.2
		},
		{
			"name": "Highway",
			"x0": -34,
			"x1": 34,
			"z0": -40,
			"z1": -22,
			"y": 6.4
		}
	],
	"stairs": [
		{
			"name": "StairSW",
			"x0": -26,
			"x1": -20,
			"z0": 2,
			"z1": 10,
			"y0": 0.0,
			"y1": 3.2
		},
		{
			"name": "StairSE",
			"x0": 20,
			"x1": 26,
			"z0": 2,
			"z1": 10,
			"y0": 0.0,
			"y1": 3.2
		},
		{
			"name": "StairNW",
			"x0": -20,
			"x1": -14,
			"z0": -22,
			"z1": -14,
			"y0": 3.2,
			"y1": 6.4
		},
		{
			"name": "StairNE",
			"x0": 28,
			"x1": 34,
			"z0": -22,
			"z1": -14,
			"y0": 3.2,
			"y1": 6.4
		}
	],
	"blocks": [
		{
			"name": "Skyline",
			"x0": -40,
			"x1": 40,
			"z0": -50,
			"z1": -40,
			"base": 0.0,
			"height": 16.0,
			"target": 16.0,
			"kind": "building"
		},
		{
			"name": "WestBack",
			"x0": -40,
			"x1": -34,
			"z0": -40,
			"z1": 36,
			"base": 0.0,
			"height": 12.0,
			"target": 12.0,
			"kind": "building"
		},
		{
			"name": "EastBack",
			"x0": 34,
			"x1": 40,
			"z0": -40,
			"z1": 36,
			"base": 0.0,
			"height": 1.2,
			"target": 1.2,
			"kind": "wall"
		},
		{
			"name": "EmbankSW",
			"x0": -34,
			"x1": -26,
			"z0": 2,
			"z1": 10,
			"base": 0.0,
			"height": 3.2,
			"target": 3.2,
			"kind": "retaining"
		},
		{
			"name": "EmbankSM",
			"x0": -20,
			"x1": 20,
			"z0": 2,
			"z1": 10,
			"base": 0.0,
			"height": 3.2,
			"target": 3.2,
			"kind": "retaining"
		},
		{
			"name": "EmbankSE",
			"x0": 26,
			"x1": 34,
			"z0": 2,
			"z1": 10,
			"base": 0.0,
			"height": 3.2,
			"target": 3.2,
			"kind": "retaining"
		},
		{
			"name": "EmbankNW",
			"x0": -34,
			"x1": -20,
			"z0": -22,
			"z1": -14,
			"base": 0.0,
			"height": 6.4,
			"target": 6.4,
			"kind": "retaining"
		},
		{
			"name": "EmbankNM",
			"x0": -14,
			"x1": 28,
			"z0": -22,
			"z1": -14,
			"base": 0.0,
			"height": 6.4,
			"target": 6.4,
			"kind": "retaining"
		},
		{
			"name": "SouthWall",
			"x0": -40,
			"x1": 40,
			"z0": 32,
			"z1": 36,
			"base": 0.0,
			"height": 1.0,
			"target": 1.0,
			"kind": "wall"
		},
		{
			"name": "StreetBagsW",
			"x0": -14,
			"x1": -11,
			"z0": 20,
			"z1": 21,
			"base": 0.0,
			"height": 1.0,
			"target": 1.0,
			"kind": "cover"
		},
		{
			"name": "StreetBagsE",
			"x0": 10,
			"x1": 13,
			"z0": 22,
			"z1": 23,
			"base": 0.0,
			"height": 1.0,
			"target": 1.0,
			"kind": "cover"
		},
		{
			"name": "BusShelter",
			"x0": -6,
			"x1": 6,
			"z0": -2,
			"z1": -0.5,
			"base": 3.2,
			"height": 1.0,
			"target": 1.0,
			"kind": "cover"
		},
		{
			"name": "DeckPlanter",
			"x0": 12,
			"x1": 16,
			"z0": -10,
			"z1": -7,
			"base": 3.2,
			"height": 0.8,
			"target": 0.8,
			"kind": "planter"
		},
		{
			"name": "Tanker",
			"x0": -2,
			"x1": 12,
			"z0": -35,
			"z1": -31,
			"base": 6.4,
			"height": 1.2,
			"target": 1.2,
			"kind": "containers"
		},
		{
			"name": "MedianW",
			"x0": -30,
			"x1": -18,
			"z0": -27,
			"z1": -26.5,
			"base": 6.4,
			"height": 0.9,
			"target": 0.9,
			"kind": "cover"
		},
		{
			"name": "MedianE",
			"x0": 16,
			"x1": 28,
			"z0": -27,
			"z1": -26.5,
			"base": 6.4,
			"height": 0.9,
			"target": 0.9,
			"kind": "cover"
		}
	],
	"rooms": [
		{
			"name": "TollBooth",
			"x0": -34,
			"x1": -22,
			"z0": -14,
			"z1": -4,
			"base": 3.2,
			"height": 3.4,
			"doors": [
				{
					"side": "south",
					"at": -28.0,
					"width": 3.0
				},
				{
					"side": "east",
					"at": -9.0,
					"width": 2.6
				}
			]
		}
	],
	"barriers": [
		{
			"kind": "rail",
			"x0": -34.0,
			"x1": -20.0,
			"z0": -22.0,
			"z1": -22.0,
			"y": 6.4
		},
		{
			"kind": "rail",
			"x0": -14.0,
			"x1": 28.0,
			"z0": -22.0,
			"z1": -22.0,
			"y": 6.4
		},
		{
			"kind": "rail",
			"x0": -34.0,
			"x1": -26.0,
			"z0": 2.0,
			"z1": 2.0,
			"y": 3.2
		},
		{
			"kind": "rail",
			"x0": -20.0,
			"x1": 20.0,
			"z0": 2.0,
			"z1": 2.0,
			"y": 3.2
		},
		{
			"kind": "rail",
			"x0": 26.0,
			"x1": 34.0,
			"z0": 2.0,
			"z1": 2.0,
			"y": 3.2
		},
		{
			"kind": "rail",
			"x0": 34.0,
			"x1": 34.0,
			"z0": -40.0,
			"z1": -22.0,
			"y": 6.4
		},
		{
			"kind": "rail",
			"x0": 34.0,
			"x1": 34.0,
			"z0": -22.0,
			"z1": -21.5,
			"y": 6.3
		},
		{
			"kind": "rail",
			"x0": 34.0,
			"x1": 34.0,
			"z0": -21.5,
			"z1": -21.0,
			"y": 6.1
		},
		{
			"kind": "rail",
			"x0": 34.0,
			"x1": 34.0,
			"z0": -21.0,
			"z1": -20.5,
			"y": 5.9
		},
		{
			"kind": "rail",
			"x0": 34.0,
			"x1": 34.0,
			"z0": -20.5,
			"z1": -20.0,
			"y": 5.7
		},
		{
			"kind": "rail",
			"x0": 34.0,
			"x1": 34.0,
			"z0": -20.0,
			"z1": -19.5,
			"y": 5.5
		},
		{
			"kind": "rail",
			"x0": 34.0,
			"x1": 34.0,
			"z0": -19.5,
			"z1": -19.0,
			"y": 5.3
		},
		{
			"kind": "rail",
			"x0": 34.0,
			"x1": 34.0,
			"z0": -19.0,
			"z1": -18.5,
			"y": 5.1
		},
		{
			"kind": "rail",
			"x0": 34.0,
			"x1": 34.0,
			"z0": -18.5,
			"z1": -18.0,
			"y": 4.9
		},
		{
			"kind": "rail",
			"x0": 34.0,
			"x1": 34.0,
			"z0": -18.0,
			"z1": -17.5,
			"y": 4.7
		},
		{
			"kind": "rail",
			"x0": 34.0,
			"x1": 34.0,
			"z0": -17.5,
			"z1": -17.0,
			"y": 4.5
		},
		{
			"kind": "rail",
			"x0": 34.0,
			"x1": 34.0,
			"z0": -17.0,
			"z1": -16.5,
			"y": 4.3
		},
		{
			"kind": "rail",
			"x0": 34.0,
			"x1": 34.0,
			"z0": -16.5,
			"z1": -16.0,
			"y": 4.1
		},
		{
			"kind": "rail",
			"x0": 34.0,
			"x1": 34.0,
			"z0": -16.0,
			"z1": -15.5,
			"y": 3.9
		},
		{
			"kind": "rail",
			"x0": 34.0,
			"x1": 34.0,
			"z0": -15.5,
			"z1": -15.0,
			"y": 3.7
		},
		{
			"kind": "rail",
			"x0": 34.0,
			"x1": 34.0,
			"z0": -15.0,
			"z1": -14.5,
			"y": 3.5
		},
		{
			"kind": "rail",
			"x0": 34.0,
			"x1": 34.0,
			"z0": -14.5,
			"z1": -14.0,
			"y": 3.3
		},
		{
			"kind": "rail",
			"x0": 34.0,
			"x1": 34.0,
			"z0": -14.0,
			"z1": 2.0,
			"y": 3.2
		},
		{
			"kind": "blocker",
			"x0": -34.0,
			"x1": 34.0,
			"z0": 32.0,
			"z1": 32.0,
			"y": 0.0
		},
		{
			"kind": "blocker",
			"x0": -30.0,
			"x1": -30.0,
			"z0": -27.0,
			"z1": -26.5,
			"y": 6.4
		},
		{
			"kind": "blocker",
			"x0": -30.0,
			"x1": -18.0,
			"z0": -27.0,
			"z1": -27.0,
			"y": 6.4
		},
		{
			"kind": "blocker",
			"x0": 16.0,
			"x1": 28.0,
			"z0": -27.0,
			"z1": -27.0,
			"y": 6.4
		},
		{
			"kind": "blocker",
			"x0": -30.0,
			"x1": -18.0,
			"z0": -26.5,
			"z1": -26.5,
			"y": 6.4
		},
		{
			"kind": "blocker",
			"x0": 16.0,
			"x1": 28.0,
			"z0": -26.5,
			"z1": -26.5,
			"y": 6.4
		},
		{
			"kind": "blocker",
			"x0": -26.0,
			"x1": -26.0,
			"z0": 2.0,
			"z1": 2.5,
			"y": 3.1
		},
		{
			"kind": "blocker",
			"x0": -26.0,
			"x1": -26.0,
			"z0": 2.5,
			"z1": 3.0,
			"y": 2.9
		},
		{
			"kind": "blocker",
			"x0": -26.0,
			"x1": -26.0,
			"z0": 3.0,
			"z1": 3.5,
			"y": 2.7
		},
		{
			"kind": "blocker",
			"x0": -26.0,
			"x1": -26.0,
			"z0": 3.5,
			"z1": 4.0,
			"y": 2.5
		},
		{
			"kind": "blocker",
			"x0": -26.0,
			"x1": -26.0,
			"z0": 4.0,
			"z1": 4.5,
			"y": 2.3
		},
		{
			"kind": "blocker",
			"x0": -26.0,
			"x1": -26.0,
			"z0": 4.5,
			"z1": 5.0,
			"y": 2.1
		},
		{
			"kind": "blocker",
			"x0": -26.0,
			"x1": -26.0,
			"z0": 5.0,
			"z1": 5.5,
			"y": 1.9
		},
		{
			"kind": "blocker",
			"x0": -20.0,
			"x1": -20.0,
			"z0": 2.0,
			"z1": 2.5,
			"y": 3.1
		},
		{
			"kind": "blocker",
			"x0": -20.0,
			"x1": -20.0,
			"z0": 2.5,
			"z1": 3.0,
			"y": 2.9
		},
		{
			"kind": "blocker",
			"x0": -20.0,
			"x1": -20.0,
			"z0": 3.0,
			"z1": 3.5,
			"y": 2.7
		},
		{
			"kind": "blocker",
			"x0": -20.0,
			"x1": -20.0,
			"z0": 3.5,
			"z1": 4.0,
			"y": 2.5
		},
		{
			"kind": "blocker",
			"x0": -20.0,
			"x1": -20.0,
			"z0": 4.0,
			"z1": 4.5,
			"y": 2.3
		},
		{
			"kind": "blocker",
			"x0": -20.0,
			"x1": -20.0,
			"z0": 4.5,
			"z1": 5.0,
			"y": 2.1
		},
		{
			"kind": "blocker",
			"x0": -20.0,
			"x1": -20.0,
			"z0": 5.0,
			"z1": 5.5,
			"y": 1.9
		},
		{
			"kind": "blocker",
			"x0": -20.0,
			"x1": -20.0,
			"z0": -22.0,
			"z1": -21.5,
			"y": 6.3
		},
		{
			"kind": "blocker",
			"x0": -20.0,
			"x1": -20.0,
			"z0": -21.5,
			"z1": -21.0,
			"y": 6.1
		},
		{
			"kind": "blocker",
			"x0": -20.0,
			"x1": -20.0,
			"z0": -21.0,
			"z1": -20.5,
			"y": 5.9
		},
		{
			"kind": "blocker",
			"x0": -20.0,
			"x1": -20.0,
			"z0": -20.5,
			"z1": -20.0,
			"y": 5.7
		},
		{
			"kind": "blocker",
			"x0": -20.0,
			"x1": -20.0,
			"z0": -20.0,
			"z1": -19.5,
			"y": 5.5
		},
		{
			"kind": "blocker",
			"x0": -20.0,
			"x1": -20.0,
			"z0": -19.5,
			"z1": -19.0,
			"y": 5.3
		},
		{
			"kind": "blocker",
			"x0": -20.0,
			"x1": -20.0,
			"z0": -19.0,
			"z1": -18.5,
			"y": 5.1
		},
		{
			"kind": "blocker",
			"x0": -18.0,
			"x1": -18.0,
			"z0": -27.0,
			"z1": -26.5,
			"y": 6.4
		},
		{
			"kind": "blocker",
			"x0": -14.0,
			"x1": -14.0,
			"z0": -22.0,
			"z1": -21.5,
			"y": 6.3
		},
		{
			"kind": "blocker",
			"x0": -14.0,
			"x1": -14.0,
			"z0": -21.5,
			"z1": -21.0,
			"y": 6.1
		},
		{
			"kind": "blocker",
			"x0": -14.0,
			"x1": -14.0,
			"z0": -21.0,
			"z1": -20.5,
			"y": 5.9
		},
		{
			"kind": "blocker",
			"x0": -14.0,
			"x1": -14.0,
			"z0": -20.5,
			"z1": -20.0,
			"y": 5.7
		},
		{
			"kind": "blocker",
			"x0": -14.0,
			"x1": -14.0,
			"z0": -20.0,
			"z1": -19.5,
			"y": 5.5
		},
		{
			"kind": "blocker",
			"x0": -14.0,
			"x1": -14.0,
			"z0": -19.5,
			"z1": -19.0,
			"y": 5.3
		},
		{
			"kind": "blocker",
			"x0": -14.0,
			"x1": -14.0,
			"z0": -19.0,
			"z1": -18.5,
			"y": 5.1
		},
		{
			"kind": "blocker",
			"x0": -14.0,
			"x1": -14.0,
			"z0": 20.0,
			"z1": 21.0,
			"y": 0.0
		},
		{
			"kind": "blocker",
			"x0": -14.0,
			"x1": -11.0,
			"z0": 20.0,
			"z1": 20.0,
			"y": 0.0
		},
		{
			"kind": "blocker",
			"x0": -14.0,
			"x1": -11.0,
			"z0": 21.0,
			"z1": 21.0,
			"y": 0.0
		},
		{
			"kind": "blocker",
			"x0": -11.0,
			"x1": -11.0,
			"z0": 20.0,
			"z1": 21.0,
			"y": 0.0
		},
		{
			"kind": "blocker",
			"x0": -6.0,
			"x1": -6.0,
			"z0": -2.0,
			"z1": -0.5,
			"y": 3.2
		},
		{
			"kind": "blocker",
			"x0": -6.0,
			"x1": 6.0,
			"z0": -2.0,
			"z1": -2.0,
			"y": 3.2
		},
		{
			"kind": "blocker",
			"x0": -6.0,
			"x1": 6.0,
			"z0": -0.5,
			"z1": -0.5,
			"y": 3.2
		},
		{
			"kind": "blocker",
			"x0": -2.0,
			"x1": -2.0,
			"z0": -35.0,
			"z1": -31.0,
			"y": 6.4
		},
		{
			"kind": "blocker",
			"x0": -2.0,
			"x1": 12.0,
			"z0": -35.0,
			"z1": -35.0,
			"y": 6.4
		},
		{
			"kind": "blocker",
			"x0": -2.0,
			"x1": 12.0,
			"z0": -31.0,
			"z1": -31.0,
			"y": 6.4
		},
		{
			"kind": "blocker",
			"x0": 6.0,
			"x1": 6.0,
			"z0": -2.0,
			"z1": -0.5,
			"y": 3.2
		},
		{
			"kind": "blocker",
			"x0": 10.0,
			"x1": 10.0,
			"z0": 22.0,
			"z1": 23.0,
			"y": 0.0
		},
		{
			"kind": "blocker",
			"x0": 10.0,
			"x1": 13.0,
			"z0": 22.0,
			"z1": 22.0,
			"y": 0.0
		},
		{
			"kind": "blocker",
			"x0": 10.0,
			"x1": 13.0,
			"z0": 23.0,
			"z1": 23.0,
			"y": 0.0
		},
		{
			"kind": "blocker",
			"x0": 12.0,
			"x1": 12.0,
			"z0": -10.0,
			"z1": -7.0,
			"y": 3.2
		},
		{
			"kind": "blocker",
			"x0": 12.0,
			"x1": 12.0,
			"z0": -35.0,
			"z1": -31.0,
			"y": 6.4
		},
		{
			"kind": "blocker",
			"x0": 12.0,
			"x1": 16.0,
			"z0": -10.0,
			"z1": -10.0,
			"y": 3.2
		},
		{
			"kind": "blocker",
			"x0": 12.0,
			"x1": 16.0,
			"z0": -7.0,
			"z1": -7.0,
			"y": 3.2
		},
		{
			"kind": "blocker",
			"x0": 13.0,
			"x1": 13.0,
			"z0": 22.0,
			"z1": 23.0,
			"y": 0.0
		},
		{
			"kind": "blocker",
			"x0": 16.0,
			"x1": 16.0,
			"z0": -27.0,
			"z1": -26.5,
			"y": 6.4
		},
		{
			"kind": "blocker",
			"x0": 16.0,
			"x1": 16.0,
			"z0": -10.0,
			"z1": -7.0,
			"y": 3.2
		},
		{
			"kind": "blocker",
			"x0": 20.0,
			"x1": 20.0,
			"z0": 2.0,
			"z1": 2.5,
			"y": 3.1
		},
		{
			"kind": "blocker",
			"x0": 20.0,
			"x1": 20.0,
			"z0": 2.5,
			"z1": 3.0,
			"y": 2.9
		},
		{
			"kind": "blocker",
			"x0": 20.0,
			"x1": 20.0,
			"z0": 3.0,
			"z1": 3.5,
			"y": 2.7
		},
		{
			"kind": "blocker",
			"x0": 20.0,
			"x1": 20.0,
			"z0": 3.5,
			"z1": 4.0,
			"y": 2.5
		},
		{
			"kind": "blocker",
			"x0": 20.0,
			"x1": 20.0,
			"z0": 4.0,
			"z1": 4.5,
			"y": 2.3
		},
		{
			"kind": "blocker",
			"x0": 20.0,
			"x1": 20.0,
			"z0": 4.5,
			"z1": 5.0,
			"y": 2.1
		},
		{
			"kind": "blocker",
			"x0": 20.0,
			"x1": 20.0,
			"z0": 5.0,
			"z1": 5.5,
			"y": 1.9
		},
		{
			"kind": "blocker",
			"x0": 26.0,
			"x1": 26.0,
			"z0": 2.0,
			"z1": 2.5,
			"y": 3.1
		},
		{
			"kind": "blocker",
			"x0": 26.0,
			"x1": 26.0,
			"z0": 2.5,
			"z1": 3.0,
			"y": 2.9
		},
		{
			"kind": "blocker",
			"x0": 26.0,
			"x1": 26.0,
			"z0": 3.0,
			"z1": 3.5,
			"y": 2.7
		},
		{
			"kind": "blocker",
			"x0": 26.0,
			"x1": 26.0,
			"z0": 3.5,
			"z1": 4.0,
			"y": 2.5
		},
		{
			"kind": "blocker",
			"x0": 26.0,
			"x1": 26.0,
			"z0": 4.0,
			"z1": 4.5,
			"y": 2.3
		},
		{
			"kind": "blocker",
			"x0": 26.0,
			"x1": 26.0,
			"z0": 4.5,
			"z1": 5.0,
			"y": 2.1
		},
		{
			"kind": "blocker",
			"x0": 26.0,
			"x1": 26.0,
			"z0": 5.0,
			"z1": 5.5,
			"y": 1.9
		},
		{
			"kind": "blocker",
			"x0": 28.0,
			"x1": 28.0,
			"z0": -27.0,
			"z1": -26.5,
			"y": 6.4
		},
		{
			"kind": "blocker",
			"x0": 28.0,
			"x1": 28.0,
			"z0": -22.0,
			"z1": -21.5,
			"y": 6.3
		},
		{
			"kind": "blocker",
			"x0": 28.0,
			"x1": 28.0,
			"z0": -21.5,
			"z1": -21.0,
			"y": 6.1
		},
		{
			"kind": "blocker",
			"x0": 28.0,
			"x1": 28.0,
			"z0": -21.0,
			"z1": -20.5,
			"y": 5.9
		},
		{
			"kind": "blocker",
			"x0": 28.0,
			"x1": 28.0,
			"z0": -20.5,
			"z1": -20.0,
			"y": 5.7
		},
		{
			"kind": "blocker",
			"x0": 28.0,
			"x1": 28.0,
			"z0": -20.0,
			"z1": -19.5,
			"y": 5.5
		},
		{
			"kind": "blocker",
			"x0": 28.0,
			"x1": 28.0,
			"z0": -19.5,
			"z1": -19.0,
			"y": 5.3
		},
		{
			"kind": "blocker",
			"x0": 28.0,
			"x1": 28.0,
			"z0": -19.0,
			"z1": -18.5,
			"y": 5.1
		},
		{
			"kind": "blocker",
			"x0": 34.0,
			"x1": 34.0,
			"z0": 10.0,
			"z1": 32.0,
			"y": 0.0
		}
	],
	"props": [
		{
			"type": "car_a",
			"pos": [
				-22,
				0,
				16
			],
			"yaw": 80
		},
		{
			"type": "car_b",
			"pos": [
				-2,
				0,
				26
			],
			"yaw": 95
		},
		{
			"type": "car_c",
			"pos": [
				18,
				0,
				17
			],
			"yaw": 260
		},
		{
			"type": "car_a",
			"pos": [
				28,
				0,
				27
			],
			"yaw": 100
		},
		{
			"type": "car_b",
			"pos": [
				-8,
				3.2,
				-6
			],
			"yaw": 10
		},
		{
			"type": "car_c",
			"pos": [
				24,
				3.2,
				-4
			],
			"yaw": 200
		},
		{
			"type": "car_a",
			"pos": [
				-24,
				6.4,
				-33
			],
			"yaw": 85
		},
		{
			"type": "car_b",
			"pos": [
				20,
				6.4,
				-36
			],
			"yaw": 95
		},
		{
			"type": "car_c",
			"pos": [
				-12,
				6.4,
				-24
			],
			"yaw": 270
		},
		{
			"type": "jersey",
			"pos": [
				-4,
				6.4,
				-24
			],
			"yaw": 0
		},
		{
			"type": "jersey",
			"pos": [
				0,
				6.4,
				-24.3
			],
			"yaw": 6
		},
		{
			"type": "jersey",
			"pos": [
				16,
				6.4,
				-31
			],
			"yaw": 90
		},
		{
			"type": "lamp",
			"pos": [
				-30,
				0,
				31
			],
			"yaw": 0
		},
		{
			"type": "lamp",
			"pos": [
				30,
				0,
				31
			],
			"yaw": 0
		},
		{
			"type": "lamp",
			"pos": [
				0,
				6.4,
				-39
			],
			"yaw": 0
		},
		{
			"type": "pole",
			"pos": [
				-16,
				0,
				11
			],
			"yaw": 0
		},
		{
			"type": "pole",
			"pos": [
				16,
				0,
				11
			],
			"yaw": 0
		},
		{
			"type": "crate",
			"pos": [
				30,
				3.2,
				-12
			],
			"yaw": 10
		},
		{
			"type": "crate",
			"pos": [
				-30,
				6.4,
				-38
			],
			"yaw": -20
		}
	],
	"markers": {
		"PlayerSpawn": [
			[
				0,
				0.3,
				28
			]
		],
		"ExtractionZone": [
			[
				24,
				6.4,
				-32
			]
		],
		"ObjectiveSpawns": [
			[
				10,
				3.5,
				-4
			],
			[
				-28,
				3.5,
				-9
			],
			[
				-10,
				6.7,
				-31
			]
		],
		"ZombieSpawners": [
			[
				-32,
				0.3,
				20
			],
			[
				32,
				0.3,
				20
			],
			[
				31,
				3.5,
				-8
			],
			[
				-30,
				3.5,
				-10
			],
			[
				-30,
				6.7,
				-30
			],
			[
				30,
				6.7,
				-37
			],
			[
				12,
				3.5,
				0
			]
		],
		"OpeningMob": [
			[
				-6,
				0.3,
				16
			],
			[
				6,
				0.3,
				15
			],
			[
				0,
				0.3,
				13
			],
			[
				-12,
				0.3,
				14
			],
			[
				12,
				0.3,
				14
			]
		],
		"PickupSpawns": [
			[
				-20,
				0.3,
				24
			],
			[
				20,
				3.5,
				-10
			],
			[
				0,
				6.7,
				-37
			]
		],
		"BloodDecor": [
			[
				4,
				0.05,
				20
			],
			[
				-14,
				3.25,
				-6
			],
			[
				10,
				6.45,
				-28
			]
		],
		"StepMarkers": [
			[
				8.0,
				3.2,
				-6.0
			],
			[
				-28.0,
				3.2,
				-9.0
			],
			[
				-10.0,
				6.4,
				-31.0
			]
		],
		"IntelSpots": [
			[
				-32.5,
				3.5,
				-12.5
			],
			[
				14.0,
				6.7,
				-33.0
			],
			[
				32.0,
				0.3,
				30.0
			]
		],
		"HiveSites": [
			[
				-30.75,
				6.4,
				-33.75
			],
			[
				30.25,
				3.2,
				-7.75
			],
			[
				7.25,
				6.4,
				-37.75
			],
			[
				-31.75,
				0.0,
				12.25
			],
			[
				-3.75,
				3.2,
				-5.75
			],
			[
				32.25,
				0.0,
				24.25
			]
		]
	},
	"marker_names": {
		"ZombieSpawners": [
			"StreetWest",
			"StreetEast",
			"TerraceDeckEast",
			"DoorTollBooth",
			"TerraceHighwayWest",
			"TerraceHighwayEast",
			"TerraceDeckMid"
		],
		"OpeningMob": [
			"Shambler1",
			"Shambler2",
			"Runner1",
			"Shambler3",
			"Runner2"
		],
		"ObjectiveSpawns": [
			"Deck",
			"TollBooth",
			"Highway"
		],
		"PickupSpawns": [
			"StreetPickup",
			"DeckPickup",
			"HighwayPickup"
		],
		"BloodDecor": [
			"Pool1",
			"Pool2",
			"Pool3"
		],
		"StepMarkers": [
			"RampNest",
			"TollRadio",
			"OverpassHold"
		],
		"IntelSpots": [
			"IntelTollBooth",
			"IntelTanker",
			"IntelBillboard"
		],
		"HiveSites": [
			"HiveL_1",
			"HiveL_2",
			"HiveM_3",
			"HiveM_4",
			"HiveM_5",
			"HiveS_6"
		]
	},
	"nav": {
		"x0": -45.0,
		"z0": -55.0,
		"cell": 0.5,
		"w": 180,
		"h": 192,
		"rows": [
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"......................pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......................",
			"......................ppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp..ppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......................",
			"......................pppppp..ppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp..ppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......................",
			"......................pppppp....pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......................",
			"......................pppppp....pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......................",
			"......................pppppppp..ppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......ppppppppppppppppppppppppp......................",
			"......................ppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......ppppppppppppppppppppppppp......................",
			"......................ppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......ppppppppppppppppppppppppp......................",
			"......................ppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......ppppppppppppppppppppppppp......................",
			"......................ppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......ppppppppppppppppppppppppp......................",
			"......................pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp............................ppppppppppppp......ppppppppppppppppppppppppp......................",
			"......................pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp............................pppppppppppppppppppppppppppppppppppppppppppp......................",
			"......................pppppppppppppppp.......ppppppppppppppppppppppppppppppppppppppppp............................pppppppppppppppppppppppppppppppppppppppppppp......................",
			"......................ppppppppppppppp........ppppppppppppppppppppppppppppppppppppppppp............................pppppppppppppppppppppppppppppppppppppppppppp......................",
			"......................ppppppppppppppp........ppppppppppppppppppppppppppppppppppppppppp............................pppppppppppppppppppppppppppppppppppppppppppp......................",
			"......................ppppppppppppppppp......ppppppppppppppppppppppppppppppppppppppppp............................ppppppp..ppppppppppppppppppppppppppppppppppp......................",
			"......................pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp............................ppppppp..ppppppppppppppppppppppppppppppppppp......................",
			"......................pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp............................ppppppp..ppppppppppppppppppppppppppppppppppp......................",
			"......................ppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp..ppppppppppppppppppppppppppppppppppp......................",
			"......................ppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp..ppppppppppppppppppppppppppppppppppp......................",
			"......................ppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp..ppppppppppppppppppppppppppppppppppp......................",
			"......................pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......................",
			"......................pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......................",
			"......................pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......................",
			"......................pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......................",
			"......................pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......................",
			"......................pppppppp........................pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp........................pppppppppppp......................",
			"......................pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......................",
			"......................pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......................",
			"......................pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......................",
			"......................pppppppppppppppppppppppppppppppppppppppppp....pppppppppppppppppppp.....ppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......................",
			"......................pppppppppppppppppppppppppppppppppppppppppp....ppppppppppp......pp......ppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......................",
			"......................pppppppppppppppppppppppppppppppppppppppppp....ppppppppppp......pp...pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......................",
			"......................pppppppppppppppppppppppppppppppppppppppppp....pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......................",
			"......................pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......................",
			"......................pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp......................",
			"..................................................oooooooooooo....................................................................................oooooooooooo......................",
			"..................................................mmmmmmmmmmmm....................................................................................mmmmmmmmmmmm......................",
			"..................................................kkkkkkkkkkkk....................................................................................kkkkkkkkkkkk......................",
			"..................................................iiiiiiiiiiii....................................................................................iiiiiiiiiiii......................",
			"..................................................gggggggggggg....................................................................................gggggggggggg......................",
			"..................................................eeeeeeeeeeee....................................................................................eeeeeeeeeeee......................",
			"..................................................cccccccccccc....................................................................................cccccccccccc......................",
			"..................................................aaaaaaaaaaaa....................................................................................aaaaaaaaaaaa......................",
			"..................................................____________....................................................................................____________......................",
			"..................................................]]]]]]]]]]]]....................................................................................]]]]]]]]]]]]......................",
			"..................................................[[[[[[[[[[[[....................................................................................[[[[[[[[[[[[......................",
			"..................................................YYYYYYYYYYYY....................................................................................YYYYYYYYYYYY......................",
			"..................................................WWWWWWWWWWWW....................................................................................WWWWWWWWWWWW......................",
			"..................................................UUUUUUUUUUUU....................................................................................UUUUUUUUUUUU......................",
			"..................................................SSSSSSSSSSSS....................................................................................SSSSSSSSSSSS......................",
			"..................................................QQQQQQQQQQQQ....................................................................................QQQQQQQQQQQQ......................",
			"..............................................PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP......................",
			".......................PPPPPPPPPPPPPPPPPPPPPP.PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP......................",
			".......................PPPPPPPPPPPPPPPPPPPPPP.PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP..PPPPPP......................",
			".......................PPPPPPPPPPPPPPPPPPPPPP.PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP....PPPPPP......................",
			".......................PPPPPPPPPPPPPPPPPPPPPP.PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP....PPPPPP......................",
			".......................PPPPPPPPPPPPPPPPPPPPPP.PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP..PPPPPPPP......................",
			".......................PPPPPPPPPPPPPPPPPPPPPP.PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP......................",
			".......................PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP......................",
			".......................PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP........PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP......................",
			".......................PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP........PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP......................",
			".......................PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP........PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP......................",
			".......................PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP........PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP......................",
			".......................PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP........PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP......................",
			".......................PPPPPPPPPPPPPPPPPPPPPP.PPPPPPPPPPPPPPPPPPPPPPPPPP.....PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP........PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP......................",
			".......................PPPPPPPPPPPPPPPPPPPPPP.PPPPPPPPPPPPPPPPPPPPPPPP.......PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP......................",
			".......................PPPPPPPPPPPPPPPPPPPPPP.PPPPPPPPPPPPPPPPPPPPPPPPP......PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP......................",
			".......................PPPPPPPPPPPPPPPPPPPPPP.PPPPPPPPPPPPPPPPPPPPPPPPP......PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP......................",
			".......................PPPPPPPPPPPPPPPPPPPPPP.PPPPPPPPPPPPPPPPPPPPPPPPP.......PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP.PPPPPPPPPPPPPPPPPPP......................",
			".......................PPPPPPPPPPPPPPPPPPPPPP.PPPPPPPPPPPPPPPPPPPPPPPPP.....PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP...PPPPPPPPPPPPPPPPPPP......................",
			"...............................PPPPPP.........PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP....PPPPPPPPPPPPPPPPPP......................",
			"......................PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP....PPPPPPPPPPPPPPPPPP......................",
			"......................PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP...PPPPPPPPPPPPPPPPPP......................",
			"......................PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP.PPPPPPPPPPPPPPPPPPPP......................",
			"......................PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP......................",
			"......................PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP........................PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP......................",
			"......................PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP........................PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP......................",
			"......................PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP........................PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP......................",
			"......................PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP......................",
			"......................PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP......................",
			"......................PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP......................",
			"......................PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP......................",
			"......................PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP......................",
			"......................................OOOOOOOOOOOO................................................................................OOOOOOOOOOOO......................................",
			"......................................MMMMMMMMMMMM................................................................................MMMMMMMMMMMM......................................",
			"......................................KKKKKKKKKKKK................................................................................KKKKKKKKKKKK......................................",
			"......................................IIIIIIIIIIII................................................................................IIIIIIIIIIII......................................",
			"......................................GGGGGGGGGGGG................................................................................GGGGGGGGGGGG......................................",
			"......................................EEEEEEEEEEEE................................................................................EEEEEEEEEEEE......................................",
			"......................................CCCCCCCCCCCC................................................................................CCCCCCCCCCCC......................................",
			"......................................AAAAAAAAAAAA................................................................................AAAAAAAAAAAA......................................",
			"......................................????????????................................................................................????????????......................................",
			"......................................============................................................................................============......................................",
			"......................................;;;;;;;;;;;;................................................................................;;;;;;;;;;;;......................................",
			"......................................999999999999................................................................................999999999999......................................",
			"......................................777777777777................................................................................777777777777......................................",
			"......................................555555555555................................................................................555555555555......................................",
			"......................................333333333333................................................................................333333333333......................................",
			"......................................111111111111................................................................................111111111111......................................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................00000000000000000000000000000000000..00000000000000000000000000000000000000000000000000000000000000..00000000000000000000000000000000000......................",
			"......................00000000000000000000000000000000000..00000000000000000000000000000000000000000000000000000000000000..00000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................00000000000000000000..000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................00000000000000000000.......0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000........0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000........000000000000000000000000000000000000000000000000000000000000000000000000000...0000000000000000000000000000000......................",
			"......................0000000000000000000000....0000000000000000000000000000000000000000000000000000000000000000000000000000....000000000000000000000000000000......................",
			"......................000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000....000000000000000000000000000000......................",
			"......................000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000....000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000......000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000......000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000......000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000......000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000......000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000......00000000000000000000000000000000000000000000000000000......0000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000......0000000000000000000000000000000000000000000000000000........000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000......0000000000000000000000000000000000000000000000000000........000000000......................",
			"......................000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......0000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"......................0000000..0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000..0000000......................",
			"......................0000000..0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000..0000000......................",
			"......................0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000......................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"....................................................................................................................................................................................",
			"...................................................................................................................................................................................."
		]
	}
}
