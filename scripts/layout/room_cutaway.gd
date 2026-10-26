extends Node3D
class_name RoomCutaway
## RoomCutaway.gd
## An enterable room built by LayoutBuilder. While the player is inside (doorway
## included), the roof and the camera-side (south/east) walls fade out so the
## high isometric camera can see in; the far walls and a knee-high stub of the
## near walls stay. Zombies entering don't trigger it.

const FADE_TIME := 0.25

var pieces: Array[GeometryInstance3D] = []
var _player_inside: bool = false
var _tween: Tween = null


func setup(volume: Area3D, cutaway_pieces: Array[GeometryInstance3D]) -> void:
	pieces = cutaway_pieces
	volume.body_entered.connect(_on_body_entered)
	volume.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body is Player and not _player_inside:
		_player_inside = true
		_fade(true)


func _on_body_exited(body: Node3D) -> void:
	if body is Player and _player_inside:
		_player_inside = false
		_fade(false)


func _fade(hide_pieces: bool) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	for piece in pieces:
		if not is_instance_valid(piece):
			continue
		if not hide_pieces:
			piece.visible = true
		_tween.tween_property(piece, "transparency", 1.0 if hide_pieces else 0.0, FADE_TIME)
	if hide_pieces:
		# Fully hidden pieces also stop casting shadows, so the interior is lit
		_tween.chain().tween_callback(func():
			for piece in pieces:
				if is_instance_valid(piece):
					piece.visible = false
		)
