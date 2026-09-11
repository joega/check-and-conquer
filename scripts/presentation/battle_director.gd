class_name BattleDirector
extends Node

signal presentation_finished
signal impact_landed
signal victim_death_finished

@export var choreography: Resource
@export var playback_speed := 1.0

var _running := false
var _skip_requested := false
var _active_attacker
var _active_victim
var _active_destination := Vector3.ZERO
var last_victim_death_clip: StringName = &""


func play_capture(attacker, victim, destination: Vector3) -> void:
	if _running:
		return
	_running = true
	_skip_requested = false
	_active_attacker = attacker
	_active_victim = victim
	_active_destination = destination
	attacker.set_animation_speed(playback_speed)
	victim.set_animation_speed(playback_speed)
	var approach_position: Vector3 = destination - Vector3.FORWARD * choreography.anchor_separation_m
	attacker.face_world_position(victim.global_position)
	victim.face_world_position(attacker.global_position)
	attacker.play_state(&"locomotion.walk.forward")
	await _move_actor(attacker, approach_position, choreography.approach_duration_s / playback_speed)
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	attacker.face_world_position(victim.global_position)
	attacker.play_state(choreography.attacker_clip)
	await _wait_or_skip(choreography.impact_time_s / playback_speed)
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	victim.play_state(_resolve_victim_hit_clip(attacker, victim))
	impact_landed.emit()
	await _wait_or_skip(0.16 / playback_speed)
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	var elapsed_before_death: float = choreography.impact_time_s + 0.16
	if not choreography.attacker_followup_clip.is_empty():
		attacker.play_state(choreography.attacker_followup_clip)
		await _wait_or_skip(choreography.followup_time_s / playback_speed)
		if _skip_requested:
			_finish_capture(attacker, victim, destination)
			return
		impact_landed.emit()
		var followup_settle_s := 0.10
		await _wait_or_skip(followup_settle_s / playback_speed)
		if _skip_requested:
			_finish_capture(attacker, victim, destination)
			return
		elapsed_before_death += choreography.followup_time_s + followup_settle_s
	last_victim_death_clip = _resolve_victim_death_clip(attacker, victim)
	victim.play_state(last_victim_death_clip)
	var death_duration: float = victim.state_duration(last_victim_death_clip) / playback_speed
	var cleanup_duration := maxf(death_duration, (choreography.cleanup_time_s - elapsed_before_death) / playback_speed)
	await _wait_or_skip(cleanup_duration)
	victim_death_finished.emit()
	_finish_capture(attacker, victim, destination)


func request_skip() -> void:
	if _running:
		_skip_requested = true


func _move_actor(actor, target: Vector3, duration: float) -> void:
	var tween = actor.move_to_world_position(target, duration)
	while tween.is_running():
		if _skip_requested:
			tween.kill()
			actor.global_position = target
			return
		await get_tree().process_frame


func _resolve_victim_hit_clip(attacker, victim) -> StringName:
	var candidates: Array[StringName] = choreography.victim_hit_variants.duplicate()
	if candidates.is_empty():
		candidates.append(choreography.victim_hit_clip)
	var start_index: int = posmod(int(attacker.archetype) * 7 + int(victim.archetype) * 13, candidates.size())
	for offset in candidates.size():
		var clip: StringName = candidates[(start_index + offset) % candidates.size()]
		if victim.supports_state(clip):
			return clip
	return choreography.victim_hit_clip


func _resolve_victim_death_clip(attacker, victim) -> StringName:
	var candidates: Array[StringName] = choreography.victim_death_variants.duplicate()
	if candidates.is_empty():
		candidates.append(choreography.victim_death_clip)
	var start_index: int = posmod(int(attacker.archetype) * 11 + int(victim.archetype) * 17, candidates.size())
	for offset in candidates.size():
		var clip: StringName = candidates[(start_index + offset) % candidates.size()]
		if victim.supports_state(clip):
			return clip
	return choreography.victim_death_clip


func _wait_or_skip(duration: float) -> void:
	var remaining := duration
	while remaining > 0.0 and not _skip_requested:
		await get_tree().process_frame
		remaining -= get_process_delta_time()


func _finish_capture(attacker, victim, destination: Vector3) -> void:
	victim.visible = false
	attacker.global_position = destination
	attacker.restore_board_facing()
	attacker.set_animation_speed(1.0)
	victim.set_animation_speed(1.0)
	attacker.play_state(&"idle.neutral")
	_running = false
	_active_attacker = null
	_active_victim = null
	presentation_finished.emit()
