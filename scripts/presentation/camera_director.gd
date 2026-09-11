class_name CameraDirector
extends Node

## Adds optional impact polish while preserving the player's board camera.
## Capture choreography is readable from the current player-selected view.

@export_node_path("Camera3D") var camera_path: NodePath
@export var shake_enabled := true
@export var shake_strength := 0.12

var _camera: Camera3D


func _ready() -> void:
	_camera = get_node(camera_path) as Camera3D


func shake_on_impact() -> void:
	if _camera == null or not shake_enabled:
		return
	var original: Transform3D = _camera.global_transform
	var offset := Vector3(shake_strength, shake_strength * 0.45, -shake_strength * 0.35)
	var tween := create_tween()
	tween.tween_property(_camera, "global_position", original.origin + offset, 0.035)
	tween.tween_property(_camera, "global_transform", original, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
