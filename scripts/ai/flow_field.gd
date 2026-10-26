extends Node
class_name FlowField
## FlowField.gd
## Shared pathfinding for the horde. One breadth-first search from the player's
## cell over the sector's walkable grid (exported by tools/level_design) gives every
## cell its step distance to the player; each zombie just walks downhill. Cost is
## independent of horde size, and the search is spread over several frames so it
## never spikes a frame on mobile. Cells connect when the floor height difference is
## small (stairs yes, drops no); diagonals need both side cells open (no corner cutting).

static var instance: FlowField = null

const REBUILD_INTERVAL := 0.25   # seconds between searches when the player moves cells
const CELLS_PER_FRAME := 1500     # time-slicing budget: a full search takes ~8 frames
const MAX_STEP_HEIGHT := 0.45
const DX := [1, -1, 0, 0, 1, 1, -1, -1]
const DZ := [0, 0, 1, -1, 1, -1, 1, -1]

var x0: float = 0.0
var z0: float = 0.0
var cell: float = 0.5
var w: int = 0
var h: int = 0
var heights := PackedFloat32Array()  # floor height per cell, -1 = not walkable
var dist := PackedInt32Array()       # published distances (-1 = unreached)

var _build := PackedInt32Array()     # distances of the search in progress
var _queue := PackedInt32Array()
var _head: int = 0
var _tail: int = 0
var _building: bool = false
var _build_start: int = -1
var _published_start: int = -1
var _timer: float = 0.0
var _player: Node3D = null


func setup(nav: Dictionary) -> void:
	x0 = float(nav["x0"])
	z0 = float(nav["z0"])
	cell = float(nav["cell"])
	w = int(nav["w"])
	h = int(nav["h"])
	var rows: Array = nav["rows"]
	heights.resize(w * h)
	for j in range(h):
		var row: String = rows[j]
		for i in range(w):
			var c := row.unicode_at(i)
			heights[j * w + i] = -1.0 if c == 46 else float(c - 48) / 10.0
	dist.resize(w * h)
	dist.fill(-1)
	_build.resize(w * h)
	_queue.resize(w * h)


func _enter_tree() -> void:
	instance = self


func _exit_tree() -> void:
	if instance == self:
		instance = null


func _process(delta: float) -> void:
	if w == 0:
		return
	if _building:
		_continue_search()
		return
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
		if not _player:
			return
	_timer -= delta
	if _timer > 0.0:
		return
	var start := _nearest_walkable(_player.global_position)
	if start < 0 or start == _published_start:
		return
	_timer = REBUILD_INTERVAL
	_begin_search(start)


func _begin_search(start: int) -> void:
	_build.fill(-1)
	_build[start] = 0
	_queue[0] = start
	_head = 0
	_tail = 1
	_build_start = start
	_building = true
	_continue_search()


@warning_ignore("integer_division")
func _continue_search() -> void:
	var budget := CELLS_PER_FRAME
	while _head < _tail and budget > 0:
		budget -= 1
		var c := _queue[_head]
		_head += 1
		var d := _build[c]
		var ci := c % w
		var cj := c / w
		for k in range(8):
			var ni: int = ci + DX[k]
			var nj: int = cj + DZ[k]
			if ni < 0 or nj < 0 or ni >= w or nj >= h:
				continue
			var n := nj * w + ni
			if _build[n] >= 0 or not _passable(c, ci, cj, ni, nj, k):
				continue
			_build[n] = d + 1
			_queue[_tail] = n
			_tail += 1
	if _head >= _tail:
		# Search finished: publish it (swap buffers so zombies never see a half-built field)
		var tmp := dist
		dist = _build
		_build = tmp
		_published_start = _build_start
		_building = false


## Can a zombie step from cell (ci, cj) to neighbour (ni, nj) in direction k?
func _passable(c: int, ci: int, cj: int, ni: int, nj: int, k: int) -> bool:
	var hc := heights[c]
	var hn := heights[nj * w + ni]
	if hn < 0.0 or absf(hn - hc) > MAX_STEP_HEIGHT:
		return false
	if k >= 4:  # diagonal: both side cells must be open too
		var ha := heights[cj * w + ni]
		var hb := heights[nj * w + ci]
		if ha < 0.0 or hb < 0.0 or absf(ha - hc) > MAX_STEP_HEIGHT or absf(hb - hc) > MAX_STEP_HEIGHT:
			return false
	return true


## Direction (flat, normalized) a zombie at `from` should walk to reach the player,
## or Vector3.ZERO when there's no path information (caller falls back to direct chase).
@warning_ignore("integer_division")
func get_direction(from: Vector3) -> Vector3:
	if _published_start < 0:
		return Vector3.ZERO
	var c := _nearest_reached(from)
	if c < 0:
		return Vector3.ZERO
	var first := _downhill(c)
	if first == c:
		return Vector3.ZERO
	# Look one cell further only when the path runs straight; at a turn (door
	# frames, wall corners) aim at the next cell so the zombie doesn't clip the corner.
	var aim := first
	var second := _downhill(first)
	if second != first and second - first == first - c:
		aim = second
	var target := _cell_center(aim)
	var dir := Vector3(target.x - from.x, 0.0, target.z - from.z)
	return dir.normalized() if dir.length_squared() > 0.0001 else Vector3.ZERO


## The neighbouring cell with the smallest distance to the player (or c itself).
@warning_ignore("integer_division")
func _downhill(c: int) -> int:
	var best := c
	var best_d := dist[c]
	var ci := c % w
	var cj := c / w
	for k in range(8):
		var ni: int = ci + DX[k]
		var nj: int = cj + DZ[k]
		if ni < 0 or nj < 0 or ni >= w or nj >= h:
			continue
		var n := nj * w + ni
		var nd := dist[n]
		if nd >= 0 and nd < best_d and _passable(c, ci, cj, ni, nj, k):
			best = n
			best_d = nd
	return best


## A walkable floor point min_r..max_r from `around` (flat distance) that a zombie can walk
## to it from (it is on the current field). Used to make hive defenders flank the player.
## Returns null when nothing fits after a few tries.
func flank_point(around: Vector3, min_r: float, max_r: float) -> Variant:
	for attempt in range(14):
		var a := randf() * TAU
		var r := randf_range(min_r, max_r)
		var probe := around + Vector3(cos(a), 0.0, sin(a)) * r
		var c := _cell_index(probe)
		if c < 0 or heights[c] < 0.0 or dist[c] < 0:
			continue
		# Path length bound: no flanker that would have to walk around half the map
		if float(dist[c]) * cell > max_r * 2.2:
			continue
		var pos := _cell_center(c)
		pos.y = heights[c]
		return pos
	return null


func _cell_index(pos: Vector3) -> int:
	var i := int(floor((pos.x - x0) / cell))
	var j := int(floor((pos.z - z0) / cell))
	if i < 0 or j < 0 or i >= w or j >= h:
		return -1
	return j * w + i


@warning_ignore("integer_division")
func _cell_center(c: int) -> Vector3:
	return Vector3(x0 + (float(c % w) + 0.5) * cell, 0.0, z0 + (float(c / w) + 0.5) * cell)


## The walkable cell under `pos`, or the closest one within 2 cells (spawn markers,
## knockback and wall-hugging can leave a body just off the grid).
func _nearest_walkable(pos: Vector3) -> int:
	return _nearest_matching(pos, false)


func _nearest_reached(pos: Vector3) -> int:
	return _nearest_matching(pos, true)


func _nearest_matching(pos: Vector3, need_dist: bool) -> int:
	var c := _cell_index(pos)
	if c >= 0 and heights[c] >= 0.0 and (not need_dist or dist[c] >= 0):
		return c
	var i0 := int(floor((pos.x - x0) / cell))
	var j0 := int(floor((pos.z - z0) / cell))
	var best := -1
	var best_d2 := INF
	for r in range(1, 3):
		for dj in range(-r, r + 1):
			for di in range(-r, r + 1):
				var i := i0 + di
				var j := j0 + dj
				if i < 0 or j < 0 or i >= w or j >= h:
					continue
				var n := j * w + i
				if heights[n] < 0.0 or (need_dist and dist[n] < 0):
					continue
				if absf(heights[n] - pos.y) > 1.5:
					continue
				var d2 := float(di * di + dj * dj)
				if d2 < best_d2:
					best_d2 = d2
					best = n
		if best >= 0:
			return best
	return -1
