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
			"id": "s1_sweep",
			"job": "kill_quota",
			"title": "SECTOR 01: QUARANTINE SWEEP",
			"desc": "Residential block overrun. Thin the infected inside the cordon, then call evac from the upper terrace.",
			"type": "TYPE: SWEEP & CLEAR",
			"threat": "THREAT: LOW [SHAMBLERS]",
			"payout_sc": 350,
			"payout_rc": 1,
			"xp": 120,
			"kills_required": 25,
			"is_night": false,
		},
		{
			"id": "s1_recovery",
			"job": "asset_recovery",
			"title": "SECTOR 01: FLIGHT RECORDER RECOVERY",
			"desc": "Retrieve the encrypted flight recorder from the quarantine zone and extract before runner swarms corner you. Carrying it slows you down and draws the runners.",
			"type": "TYPE: ASSET RECOVERY",
			"threat": "THREAT: LOW [RUNNERS HUNT CARRIER]",
			"payout_sc": 420,
			"payout_rc": 2,
			"xp": 150,
			"kills_required": 0,
			"is_night": false,
		},
	],
	2: [
		{
			"id": "s2_rescue",
			"job": "kill_quota",
			"title": "SECTOR 02: COMMERCIAL TRANSIT RESCUE",
			"desc": "Locate barricaded survivor medic in transit terminal. Escort VIP to helipad across high-density runner corridors.",
			"type": "TYPE: VIP ESCORT",
			"threat": "THREAT: MEDIUM [RUNNERS]",
			"payout_sc": 600,
			"payout_rc": 2,
			"xp": 260,
			"kills_required": 35,
			"is_night": false,
		},
	],
	3: [
		{
			"id": "s3_purge",
			"job": "kill_quota",
			"title": "SECTOR 03: BLACKOUT SILO PURGE",
			"desc": "Night Operations mandatory. Restore power to emergency generators using gun torch, purge Crimson Boss, extract via flare.",
			"type": "TYPE: NIGHT PURGE",
			"threat": "THREAT: SEVERE [NIGHT OPS]",
			"payout_sc": 950,
			"payout_rc": 3,
			"xp": 450,
			"kills_required": 45,
			"is_night": true,
		},
	],
	4: [
		{
			"id": "s4_harvest",
			"job": "kill_quota",
			"title": "SECTOR 04: CRIMSON BIO-COMPLEX",
			"desc": "Infiltrate deep containment lab. Plant centrifuge extractors on biomass nodes, defend against 3-wave containment breach, harvest cores.",
			"type": "TYPE: BIO-LAB HARVEST",
			"threat": "THREAT: CRITICAL [BOSS BREACH]",
			"payout_sc": 1500,
			"payout_rc": 6,
			"xp": 700,
			"kills_required": 60,
			"is_night": false,
		},
	],
}

## Paired operative skills (Design Doc Section 5)
const SKILLS_DATA: Dictionary = {
	"blood_siphon": {
		"name": "BLOOD SIPHON",
		"pair": "crimson_berserker",
		"desc": "+25% Fire Rate when standing in fresh blood pools.",
		"cost_rc": 5,
		"level_req": 2,
	},
	"hemorrhage_rounds": {
		"name": "HEMORRHAGE ROUNDS",
		"pair": "crimson_berserker",
		"desc": "Zombies burst into 2x wider blood pools on death.",
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
const PLAYABLE_SECTORS: Array[int] = [1]
const IMPLEMENTED_WEAPONS: Array[String] = ["assault_carbine"]
const IMPLEMENTED_SKILLS: Array[String] = []
const WEAPON_UPGRADE_COST_STEP := 150  # Tier N costs N * 150 SC (matches the Armory)

## Per-kill bounty (SC, unbanked until extraction) and XP.
const KILL_REWARDS: Dictionary = {
	"shambler": {"sc": 1, "xp": 2},
	"runner": {"sc": 5, "xp": 4},
	"tank": {"sc": 25, "xp": 15},
}

## Clearance level each Sector unlocks at (index = sector id).
const SECTOR_UNLOCK_LEVELS: Array[int] = [0, 1, 11, 26, 41]

const COMMS_PAYOUT_BONUS_PER_TIER := 0.15  # +15% contract SC per Comms Array tier
const MEDBAY_HEALTH_PER_TIER := 20.0       # +20 starting armor/HP per Medbay tier
const EVAC_HOLD_BASE := 20.0               # Seconds to hold the LZ before evac arrives
const HELIPAD_EVAC_REDUCTION_PER_TIER := 3.0 # Tactical Helipad: -3 s per tier
const EVAC_HOLD_MIN := 8.0
const FIRST_CLEAR_MULTIPLIER := 2          # First successful extraction per sector pays double
const FAILURE_LOOT_KEPT := 0.3             # KIA keeps 30% of unbanked SC
const FAILURE_XP_KEPT := 0.5               # KIA keeps 50% of combat XP

const XP_PER_LEVEL: Array[int] = [
	0,    # Level 0 → 1 (Escape sequence / tutorial completion)
	100,  # Level 1 → 2
	150,  # Level 2 → 3
	220,  # Level 3 → 4
	300,  # Level 4 → 5
	400,  # Level 5 → 6
	520,  # Level 6 → 7
	660,  # Level 7 → 8
	820,  # Level 8 → 9
	1000, # Level 9 → 10
]

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
var saved_is_portrait: bool = true

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
	var index := mini(clearance_level, XP_PER_LEVEL.size() - 1)
	if clearance_level >= XP_PER_LEVEL.size():
		return XP_PER_LEVEL[-1] + (clearance_level - XP_PER_LEVEL.size() + 1) * 200
	return XP_PER_LEVEL[index]


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
	for s in range(1, SECTOR_UNLOCK_LEVELS.size()):
		if level >= SECTOR_UNLOCK_LEVELS[s]:
			sector = s
	return sector


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
	
	var om = get_node_or_null("/root/OrientationManager")
	if om:
		saved_is_portrait = om.is_portrait


func _apply_loaded_settings() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.master_volume = saved_master_volume
		am.sfx_volume = saved_sfx_volume
		am.music_volume = saved_music_volume
		am.haptics_enabled = saved_haptics_enabled
	
	var om = get_node_or_null("/root/OrientationManager")
	if om:
		om.is_portrait = saved_is_portrait


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
	config.set_value("settings", "is_portrait", saved_is_portrait)

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
	_update_sector_unlock()
	sectors_cleared = {}
	var cleared = config.get_value("progression", "sectors_cleared", {})
	if cleared is Dictionary:
		for k in cleared:
			if cleared[k] == true:
				sectors_cleared[str(k)] = true

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
	saved_is_portrait = _read_bool(config, "settings", "is_portrait", true)

	# Stats
	total_kills = _read_int(config, "stats", "total_kills", 0, 0, 999999999)
	total_missions_completed = _read_int(config, "stats", "total_missions_completed", 0, 0, 999999999)
	total_extractions = _read_int(config, "stats", "total_extractions", 0, 0, 999999999)

	_refund_unreleased_purchases()
	game_loaded.emit()


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
