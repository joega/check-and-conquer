class_name CinematicDirector
extends Node

const CinematicCatalog = preload("res://scripts/presentation/campaign_cinematic_catalog.gd")

## Owns a short, presentation-only campaign sequence.  It never receives chess
## state and emits exactly one completion for each run, including Skip/fallback.

signal finished(run_id: int, reason: String)

@export_node_path("BoardCameraController") var board_camera_path: NodePath
@export_node_path("Camera3D") var cinematic_camera_path: NodePath
@export_node_path("Control") var overlay_path: NodePath
@export var playback_speed := 1.0

const WATCHDOG_GRACE_S := 1.5

var _board_camera: BoardCameraController
var _cinematic_camera: Camera3D
var _overlay: Control
var _tween: Tween
var _shot_tween: Tween
var _watchdog: Tween
var _run_id := 0
var _active := false
var _saved_controls := true
var _speakers: Dictionary = {}
var _speaker_actor: Node3D
var _ceremony


func _ready() -> void:
	_board_camera = get_node_or_null(board_camera_path) as BoardCameraController
	_cinematic_camera = get_node_or_null(cinematic_camera_path) as Camera3D
	_overlay = get_node_or_null(overlay_path) as Control
	if _cinematic_camera != null:
		_cinematic_camera.current = false
	if _overlay != null:
		_overlay.visible = false


func _exit_tree() -> void:
	cancel()


func is_active() -> bool:
	return _active


func play_mountain_intro(human_side: int, speakers: Dictionary = {}, ceremony = null) -> int:
	return play_sequence(CinematicCatalog.sequence_for("mountain_fortress", "intro"), human_side, speakers, ceremony)


func play_mountain_victory(human_side: int, speakers: Dictionary = {}) -> int:
	return play_sequence(CinematicCatalog.sequence_for("mountain_fortress", "victory"), human_side, speakers)


func play_sequence(sequence: Resource, human_side: int, speakers: Dictionary = {}, ceremony = null) -> int:
	_speakers = speakers
	_ceremony = ceremony
	return _begin(sequence.outcome if sequence != null else &"fallback", human_side, sequence)


func skip() -> void:
	if _active:
		_complete("skipped")


func cancel() -> void:
	if _active:
		_complete("cancelled", false)


func _begin(_kind: StringName, human_side: int, sequence: Resource = null) -> int:
	cancel()
	_run_id += 1
	_active = true
	_saved_controls = _board_camera.controls_enabled() if _board_camera != null else true
	if _board_camera != null:
		_board_camera.set_controls_enabled(false)
	if sequence == null or _cinematic_camera == null or _overlay == null:
		# Completion must be asynchronous: GameScreen installs its await after the
		# play call returns, and a synchronous fallback would strand that await.
		call_deferred("_complete_if_current", _run_id, "fallback")
		return _run_id
	_cinematic_camera.current = true
	_overlay.visible = true
	_overlay.modulate.a = 1.0
	_tween = create_tween()
	_tween.set_speed_scale(maxf(playback_speed, 0.01))
	_watchdog = create_tween()
	var declared_duration := _sequence_duration(sequence)
	_watchdog.tween_interval(declared_duration / maxf(playback_speed, 0.01) + WATCHDOG_GRACE_S)
	_watchdog.tween_callback(_complete_if_current.bind(_run_id, "watchdog"))
	_run_sequence(sequence, human_side)
	return _run_id


func _run_sequence(sequence: Resource, human_side: int) -> void:
	var run_id := _run_id
	for cue in sequence.cues:
		_tween.tween_callback(func(): _play_cue_if_current(run_id, cue, human_side))
		_tween.tween_interval(cue.hold_s)
		if not cue.after_action.is_empty():
			_tween.tween_callback(func(): _run_stage_action_if_current(run_id, cue.after_action))
	if sequence.final_hold_s > 0.0:
		_tween.tween_interval(sequence.final_hold_s)
	_tween.tween_callback(_complete_if_current.bind(run_id, "completed"))


func _play_cue_if_current(run_id: int, cue: Resource, human_side: int) -> void:
	if not _active or run_id != _run_id:
		return
	_run_stage_action(cue.stage_action)
	var shot_position: Vector3 = cue.shot_position
	# Victory's one existing side-dependent shot stays data-authored while its
	# sign is resolved from the immutable human-side fact at playback.
	if cue.cue_id == "mountain.victory_gatekeeper":
		shot_position.x *= human_side
	_shot(shot_position, cue.shot_target, cue.shot_duration_s)
	_set_cue(cue.title, cue.speaker_label, cue.body, cue.speaker_id)


func _run_stage_action_if_current(run_id: int, action: String) -> void:
	if _active and run_id == _run_id:
		_run_stage_action(action)


func _run_stage_action(action: String) -> void:
	if _ceremony == null:
		return
	match action:
		"seating_and_approach":
			_ceremony.begin_grandmaster_seating()
			_ceremony.bring_kings_to_parley()
		"return": _ceremony.return_kings_to_board()
		"formation_restore": _ceremony.settle_board_formation()


func _sequence_duration(sequence: Resource) -> float:
	if sequence == null:
		return 0.0
	var duration: float = sequence.final_hold_s
	for cue in sequence.cues:
		duration += cue.hold_s
	return duration


func _shot(position: Vector3, target: Vector3, duration: float) -> void:
	if _cinematic_camera == null:
		return
	var destination := Transform3D(Basis.looking_at(target - position, Vector3.UP), position)
	if _shot_tween != null and _shot_tween.is_valid():
		_shot_tween.kill()
	if duration <= 0.0:
		_cinematic_camera.global_transform = destination
		_shot_tween = null
		return
	_shot_tween = create_tween()
	_shot_tween.set_speed_scale(maxf(playback_speed, 0.01))
	_shot_tween.tween_property(_cinematic_camera, "global_transform", destination, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _set_cue(title: String, speaker: String, body: String, speaker_id: String) -> void:
	if _overlay == null:
		return
	_speaker_actor = _speakers.get(speaker_id) as Node3D
	if _ceremony != null:
		if speaker_id == "gatekeeper" or speaker_id == "commander":
			_ceremony.set_dialogue_speaker(_speaker_actor)
	var bubble: Control = _overlay.get_node("SpeechBubble")
	bubble.get_node("Content/Title").text = title
	bubble.get_node("Content/Speaker").text = speaker
	bubble.get_node("Content/Body").text = body
	bubble.visible = true


func _process(_delta: float) -> void:
	if not _active or _overlay == null:
		return
	var bubble: Control = _overlay.get_node_or_null("SpeechBubble")
	if bubble == null:
		return
	if _speaker_actor == null:
		var viewport_size := get_viewport().get_visible_rect().size
		bubble.position = Vector2((viewport_size.x - bubble.size.x) * 0.5, 36.0)
		bubble.visible = true
		return
	if _speaker_actor == null or not is_instance_valid(_speaker_actor) or _cinematic_camera == null or _cinematic_camera.is_position_behind(_speaker_actor.global_position):
		bubble.visible = false
		return
	var head_height := 5.3 if _speaker_actor == _speakers.get("grandmaster") else 3.3
	var screen_point := _cinematic_camera.unproject_position(_speaker_actor.global_position + Vector3.UP * head_height)
	var viewport_size := get_viewport().get_visible_rect().size
	bubble.position = Vector2(clampf(screen_point.x - bubble.size.x * 0.5, 20.0, viewport_size.x - bubble.size.x - 20.0), clampf(screen_point.y - bubble.size.y - 32.0, 20.0, viewport_size.y - bubble.size.y - 20.0))


func _complete(reason: String, notify := true) -> void:
	if not _active:
		return
	var completed_run := _run_id
	_active = false
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	if _shot_tween != null and _shot_tween.is_valid():
		_shot_tween.kill()
	_shot_tween = null
	if _watchdog != null and _watchdog.is_valid():
		_watchdog.kill()
	_watchdog = null
	if _overlay != null:
		_overlay.visible = false
		_overlay.get_node("SpeechBubble").visible = false
	_speaker_actor = null
	if _ceremony != null:
		_ceremony.cleanup()
	_ceremony = null
	if _cinematic_camera != null:
		_cinematic_camera.current = false
	if _board_camera != null:
		_board_camera.current = true
		_board_camera.set_controls_enabled(_saved_controls)
	if notify:
		finished.emit(completed_run, reason)


func _complete_if_current(expected_run: int, reason: String) -> void:
	if _active and expected_run == _run_id:
		_complete(reason)
