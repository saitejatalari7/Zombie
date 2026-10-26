extends Node
## AudioManager.gd — Global Autoload
## Centralized audio playback with pooled AudioStreamPlayer nodes and haptic feedback.
## Supports SFX categories, volume control, and Android vibration.

# ─── Constants ─────────────────────────────────────────────────────────────────
const SFX_POOL_SIZE := 16       # Max simultaneous SFX voices
const MUSIC_FADE_DURATION := 1.5  # Seconds for music crossfade

## Audio bus names (configure these in Godot's Audio tab)
const BUS_MASTER := "Master"
const BUS_SFX := "SFX"
const BUS_MUSIC := "Music"
const BUS_UI := "UI"

## Haptic vibration durations (ms) — tuned for Android
const HAPTIC_LIGHT := 15        # UI tap
const HAPTIC_MEDIUM := 30       # Bullet hit confirm
const HAPTIC_HEAVY := 60        # Explosion, boss hit
const HAPTIC_DEATH := 120       # Player death

# ─── SFX Registry ─────────────────────────────────────────────────────────────
## Map of sound names → resource paths. Add entries as audio files are created.
## These are stubs — replace paths with actual .ogg/.wav files when available.
var sfx_registry: Dictionary = {
	# Weapons
	"gun_fire": "res://assets/audio/sfx/gun_fire.ogg",
	"gun_reload": "res://assets/audio/sfx/gun_reload.ogg",
	"shotgun_fire": "res://assets/audio/sfx/shotgun_fire.ogg",
	"smg_fire": "res://assets/audio/sfx/smg_fire.ogg",
	"rocket_fire": "res://assets/audio/sfx/rocket_fire.ogg",
	"rocket_explode": "res://assets/audio/sfx/rocket_explode.ogg",
	
	# Impacts
	"bullet_impact_flesh": "res://assets/audio/sfx/bullet_impact_flesh.ogg",
	"bullet_impact_wall": "res://assets/audio/sfx/bullet_impact_wall.ogg",
	"shell_casing_drop": "res://assets/audio/sfx/shell_casing_drop.ogg",
	
	# Molotov & Fire
	"molotov_throw": "res://assets/audio/sfx/molotov_throw.ogg",
	"molotov_shatter": "res://assets/audio/sfx/molotov_shatter.ogg",
	"fire_loop": "res://assets/audio/sfx/fire_loop.ogg",
	
	# Zombies
	"zombie_groan": "res://assets/audio/sfx/zombie_groan.ogg",
	"zombie_hit": "res://assets/audio/sfx/zombie_hit.ogg",
	"zombie_death": "res://assets/audio/sfx/zombie_death.ogg",
	"zombie_runner_scream": "res://assets/audio/sfx/zombie_runner_scream.ogg",
	"boss_roar": "res://assets/audio/sfx/boss_roar.ogg",
	
	# Player
	"player_footstep": "res://assets/audio/sfx/player_footstep.ogg",
	"player_hurt": "res://assets/audio/sfx/player_hurt.ogg",
	"player_death": "res://assets/audio/sfx/player_death.ogg",
	
	# Power-ups & Pickups
	"powerup_pickup": "res://assets/audio/sfx/powerup_pickup.ogg",
	"hyper_burst_activate": "res://assets/audio/sfx/hyper_burst_activate.ogg",
	
	# UI
	"ui_click": "res://assets/audio/sfx/ui_click.ogg",
	"ui_confirm": "res://assets/audio/sfx/ui_confirm.ogg",
	"ui_back": "res://assets/audio/sfx/ui_back.ogg",
	"mission_complete": "res://assets/audio/sfx/mission_complete.ogg",
	"mission_failed": "res://assets/audio/sfx/mission_failed.ogg",
	"extraction_countdown": "res://assets/audio/sfx/extraction_countdown.ogg",
}

# ─── Settings ──────────────────────────────────────────────────────────────────
var master_volume: float = 1.0:
	set(value):
		master_volume = clampf(value, 0.0, 1.0)
		_apply_bus_volume(BUS_MASTER, master_volume)
		_sync_to_gm()

var sfx_volume: float = 1.0:
	set(value):
		sfx_volume = clampf(value, 0.0, 1.0)
		_apply_bus_volume(BUS_SFX, sfx_volume)
		_sync_to_gm()

var music_volume: float = 0.7:
	set(value):
		music_volume = clampf(value, 0.0, 1.0)
		_apply_bus_volume(BUS_MUSIC, music_volume)
		_sync_to_gm()

var haptics_enabled: bool = true:
	set(value):
		haptics_enabled = value
		_sync_to_gm()

func _sync_to_gm() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and "saved_master_volume" in gm:
		gm.saved_master_volume = master_volume
		gm.saved_sfx_volume = sfx_volume
		gm.saved_music_volume = music_volume
		gm.saved_haptics_enabled = haptics_enabled


# ─── Internal ──────────────────────────────────────────────────────────────────
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0
var _music_player: AudioStreamPlayer = null
var _loaded_cache: Dictionary = {}  # path → AudioStream

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Ensure audio buses exist (SFX, Music, UI) — create them if they don't
	_ensure_audio_buses()
	
	# Create SFX player pool
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_sfx_pool.append(player)
	
	# Create dedicated music player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC
	add_child(_music_player)
	
	# Apply saved volumes
	_apply_bus_volume(BUS_MASTER, master_volume)
	_apply_bus_volume(BUS_SFX, sfx_volume)
	_apply_bus_volume(BUS_MUSIC, music_volume)
	
	print("[AudioManager] Ready — SFX pool: %d voices" % SFX_POOL_SIZE)


# ─── Public API: SFX ──────────────────────────────────────────────────────────
## Play a registered SFX by name. Returns the AudioStreamPlayer used, or null if not found.
func play_sfx(sfx_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> AudioStreamPlayer:
	if not sfx_registry.has(sfx_name):
		push_warning("[AudioManager] SFX '%s' not found in registry." % sfx_name)
		return null
	
	var path: String = sfx_registry[sfx_name]
	var stream := _get_cached_stream(path)
	if stream == null:
		return null
	
	var player := _get_next_sfx_player()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()
	return player


## Play SFX with slight random pitch variation (great for gunshots, impacts)
func play_sfx_varied(sfx_name: String, volume_db: float = 0.0, pitch_range: float = 0.1) -> AudioStreamPlayer:
	var pitch := 1.0 + randf_range(-pitch_range, pitch_range)
	return play_sfx(sfx_name, volume_db, pitch)


## Play a raw AudioStream directly (for dynamically loaded sounds)
func play_stream(stream: AudioStream, volume_db: float = 0.0, bus: String = BUS_SFX) -> AudioStreamPlayer:
	var player := _get_next_sfx_player()
	player.stream = stream
	player.volume_db = volume_db
	player.bus = bus
	player.play()
	return player


# ─── Public API: 3D Positional Audio ──────────────────────────────────────────
## Creates a one-shot 3D audio player at a world position. Auto-frees after playback.
func play_sfx_at_position(sfx_name: String, position: Vector3, volume_db: float = 0.0) -> void:
	if not sfx_registry.has(sfx_name):
		return
	
	var path: String = sfx_registry[sfx_name]
	var stream := _get_cached_stream(path)
	if stream == null:
		return
	
	var player_3d := AudioStreamPlayer3D.new()
	player_3d.stream = stream
	player_3d.volume_db = volume_db
	player_3d.bus = BUS_SFX
	player_3d.global_position = position
	player_3d.max_distance = 50.0
	player_3d.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	add_child(player_3d)
	player_3d.play()
	player_3d.finished.connect(player_3d.queue_free)


# ─── Public API: Music ─────────────────────────────────────────────────────────
func play_music(stream_path: String, fade_in: bool = true) -> void:
	var stream := _get_cached_stream(stream_path)
	if stream == null:
		return
	
	if _music_player.playing and fade_in:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, MUSIC_FADE_DURATION)
		tween.tween_callback(func():
			_music_player.stream = stream
			_music_player.volume_db = 0.0
			_music_player.play()
		)
	else:
		_music_player.stream = stream
		_music_player.volume_db = 0.0
		_music_player.play()


func stop_music(fade_out: bool = true) -> void:
	if not _music_player.playing:
		return
	
	if fade_out:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, MUSIC_FADE_DURATION)
		tween.tween_callback(_music_player.stop)
	else:
		_music_player.stop()


func is_music_playing() -> bool:
	return _music_player.playing


# ─── Public API: Haptics ───────────────────────────────────────────────────────
func haptic_light() -> void:
	_vibrate(HAPTIC_LIGHT)


func haptic_medium() -> void:
	_vibrate(HAPTIC_MEDIUM)


func haptic_heavy() -> void:
	_vibrate(HAPTIC_HEAVY)


func haptic_death() -> void:
	_vibrate(HAPTIC_DEATH)


func haptic_custom(duration_ms: int) -> void:
	_vibrate(duration_ms)


# ─── Public API: Volume Settings ───────────────────────────────────────────────
func set_master_volume(linear: float) -> void:
	master_volume = linear


func set_sfx_volume(linear: float) -> void:
	sfx_volume = linear


func set_music_volume(linear: float) -> void:
	music_volume = linear


func set_haptics_enabled(enabled: bool) -> void:
	haptics_enabled = enabled


# ─── Internal Helpers ──────────────────────────────────────────────────────────
func _get_next_sfx_player() -> AudioStreamPlayer:
	var player := _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % SFX_POOL_SIZE
	# Stop currently playing sound in this slot to reuse it
	if player.playing:
		player.stop()
	return player


func _get_cached_stream(path: String) -> AudioStream:
	if _loaded_cache.has(path):
		return _loaded_cache[path]
	
	if not ResourceLoader.exists(path):
		# Silently return null for missing audio files (stubs)
		return null
	
	var stream := load(path) as AudioStream
	if stream:
		_loaded_cache[path] = stream
	return stream


func _vibrate(duration_ms: int) -> void:
	if haptics_enabled:
		Input.vibrate_handheld(duration_ms)


func _apply_bus_volume(bus_name: String, linear: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return
	# Convert linear (0.0–1.0) to dB. Mute at 0.
	if linear <= 0.0:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear))


func _ensure_audio_buses() -> void:
	# Create SFX, Music, UI buses if they don't already exist
	for bus_name in [BUS_SFX, BUS_MUSIC, BUS_UI]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, BUS_MASTER)
			print("[AudioManager] Created audio bus: %s" % bus_name)
