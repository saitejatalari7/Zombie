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
signal game_saved()
signal game_loaded()

# ─── Constants ─────────────────────────────────────────────────────────────────
const SAVE_PATH := "user://protocol_crimson_save.dat"
const SAVE_KEY := "CR1MS0N_PR0T0C0L_K3Y"

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
var in_run_kills: Dictionary = {
	"shambler": 0,
	"runner": 0,
	"crimson_boss": 0
}

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_init_default_upgrades()
	load_game()
	_apply_loaded_settings()
	print("[GameManager] Ready — Clearance Lv.%d | Vault SC: %d | Vault RC: %d" % [
		clearance_level, survival_coins, research_cores
	])


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
func start_mission_run() -> void:
	in_run_sc = 0
	in_run_rc = 0
	in_run_kills["shambler"] = 0
	in_run_kills["runner"] = 0
	in_run_kills["crimson_boss"] = 0
	in_run_loot_changed.emit(in_run_sc, in_run_rc)


func record_kill(enemy_type: String) -> void:
	total_kills += 1
	var bounty := 0
	match enemy_type:
		"shambler":
			bounty = 1
		"runner":
			bounty = 5
		"crimson_boss":
			bounty = 100
	
	if in_run_kills.has(enemy_type):
		in_run_kills[enemy_type] += 1
	else:
		in_run_kills[enemy_type] = 1
	
	in_run_sc += bounty
	in_run_loot_changed.emit(in_run_sc, in_run_rc)


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
	var kept_loot := int(unbanked_sc * 0.3)
	add_coins(kept_loot)
	
	in_run_sc = 0
	in_run_rc = 0
	save_game()
	return kept_loot


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
	if clearance_level >= 41:
		highest_sector_unlocked = 4
	elif clearance_level >= 26:
		highest_sector_unlocked = 3
	elif clearance_level >= 11:
		highest_sector_unlocked = 2
	else:
		highest_sector_unlocked = 1


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
func save_game() -> void:
	sync_settings_from_managers()
	
	var config := ConfigFile.new()

	# Economy
	config.set_value("economy", "survival_coins", survival_coins)
	config.set_value("economy", "research_cores", research_cores)

	# Progression
	config.set_value("progression", "clearance_level", clearance_level)
	config.set_value("progression", "clearance_xp", clearance_xp)
	config.set_value("progression", "has_completed_tutorial", has_completed_tutorial)
	config.set_value("progression", "highest_sector_unlocked", highest_sector_unlocked)

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

	var err := config.save_encrypted_pass(SAVE_PATH, SAVE_KEY)
	if err == OK:
		game_saved.emit()
	else:
		push_warning("[GameManager] Failed to save game: %s" % error_string(err))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var config := ConfigFile.new()
	var err := config.load_encrypted_pass(SAVE_PATH, SAVE_KEY)
	if err != OK:
		push_warning("[GameManager] Failed to load save: %s" % error_string(err))
		return

	# Economy
	survival_coins = config.get_value("economy", "survival_coins", 0)
	research_cores = config.get_value("economy", "research_cores", 0)

	# Progression
	clearance_level = config.get_value("progression", "clearance_level", 1)
	clearance_xp = config.get_value("progression", "clearance_xp", 0)
	has_completed_tutorial = config.get_value("progression", "has_completed_tutorial", false)
	highest_sector_unlocked = config.get_value("progression", "highest_sector_unlocked", 1)

	# Skills
	unlocked_skills = config.get_value("skills", "unlocked_skills", {})
	equipped_skills[0] = config.get_value("skills", "equipped_skills_0", "")
	equipped_skills[1] = config.get_value("skills", "equipped_skills_1", "")

	# Weapon upgrades
	weapon_upgrades = config.get_value("weapons", "upgrades", {})
	_init_default_upgrades()

	# Outpost
	outpost_levels = config.get_value("outpost", "levels", {})

	# Settings
	saved_master_volume = config.get_value("settings", "master_volume", 1.0)
	saved_sfx_volume = config.get_value("settings", "sfx_volume", 1.0)
	saved_music_volume = config.get_value("settings", "music_volume", 0.7)
	saved_haptics_enabled = config.get_value("settings", "haptics_enabled", true)
	saved_is_portrait = config.get_value("settings", "is_portrait", true)

	# Stats
	total_kills = config.get_value("stats", "total_kills", 0)
	total_missions_completed = config.get_value("stats", "total_missions_completed", 0)
	total_extractions = config.get_value("stats", "total_extractions", 0)

	game_loaded.emit()


func reset_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	survival_coins = 0
	research_cores = 0
	clearance_level = 1
	clearance_xp = 0
	has_completed_tutorial = false
	highest_sector_unlocked = 1
	unlocked_skills.clear()
	equipped_skills = ["", ""]
	weapon_upgrades.clear()
	outpost_levels.clear()
	total_kills = 0
	total_missions_completed = 0
	total_extractions = 0
	_init_default_upgrades()
	save_game()
