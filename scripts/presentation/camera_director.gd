class_name CameraDirector
extends Node

## Keeps board framing as the default and temporarily stages a readable capture
## shot. It holds no chess state and can always return to the saved board view.

@export_node_path("Camera3D") var camera_path: NodePath
@export var shake_enabled := true
@export var shake_strength := 0.12
@export var capture_height_m := 8.0

var _camera: Camera3D
var _board_transform: Transform3D


func _ready() -> void:
	_camera = get_node(camera_path) as Camera3D
	_board_transform = _camera.global_transform


func begin_capture(_attacker, victim) -> void:
	if _camera == null:
		return
	_board_transform = _camera.global_transform
	_set_board_controls_enabled(false)
	# The fight lands at the victim's committed destination, rather than midway
	# between the pre-approach pieces. Center that exact impact point so the
	# attack remains at screen center as the attacker closes the distance.
	var action_target: Vector3 = victim.global_position + Vector3.UP * 0.95
	# A fixed overhead shot keeps both fighters visible even when the surrounding
	# board is crowded. It deliberately does not inherit the player's orbit/zoom.
	var shot_position := action_target + Vector3(0.18, capture_height_m, 0.24)
	var capture_transform := _look_transform(shot_position, action_target)
	var tween := create_tween()
	tween.tween_property(_camera, "global_transform", capture_transform, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func return_to_board() -> Tween:
	var tween := create_tween()
	tween.tween_property(_camera, "global_transform", _board_transform, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func(): _set_board_controls_enabled(true))
	return tween


func shake_on_impact() -> void:
	if _camera == null or not shake_enabled:
		return
	var original: Transform3D = _camera.global_transform
	var offset := Vector3(shake_strength, shake_strength * 0.45, -shake_strength * 0.35)
	var tween := create_tween()
	tween.tween_property(_camera, "global_position", original.origin + offset, 0.035)
	tween.tween_property(_camera, "global_transform", original, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _look_transform(position: Vector3, target: Vector3) -> Transform3D:
	var rig := Node3D.new()
	add_child(rig)
	rig.global_position = position
	rig.look_at(target, Vector3.UP)
	var result := rig.global_transform
	rig.queue_free()
	return result


func _set_board_controls_enabled(enabled: bool) -> void:
	if _camera != null and _camera.has_method("set_controls_enabled"):
		_camera.set_controls_enabled(enabled)
