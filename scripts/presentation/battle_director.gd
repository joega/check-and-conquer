class_name BattleDirector
extends Node

const Types = preload("res://scripts/chess/chess_types.gd")
const ARROW_SCENE = preload("res://assets/weapons/quaternius/Arrow.fbx")

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
	if choreography.delivery == "arrow":
		await _play_bishop_ranged_capture(attacker, victim, destination)
		return
	if choreography.delivery == "wall_crush":
		await _play_rook_wall_capture(attacker, victim, destination)
		return
	if choreography.delivery == "arcane_bolt":
		await _play_queen_arcane_capture(attacker, victim, destination)
		return
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


func _play_queen_arcane_capture(attacker, victim, destination: Vector3) -> void:
	attacker.face_world_position(victim.global_position)
	victim.face_world_position(attacker.global_position)
	attacker.play_state(&"attack.spell.shot_01")
	impact_landed.emit()
	await _wait_or_skip(0.24 / playback_speed)
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	var bolt := MeshInstance3D.new()
	bolt.name = "QueenArcaneBolt"
	var bolt_mesh := SphereMesh.new()
	bolt_mesh.radius = 0.18
	bolt_mesh.height = 0.36
	bolt.mesh = bolt_mesh
	var bolt_material := StandardMaterial3D.new()
	bolt_material.albedo_color = Color(0.78, 0.28, 1.0)
	bolt_material.emission_enabled = true
	bolt_material.emission = Color(0.72, 0.12, 1.0)
	bolt_material.emission_energy_multiplier = 4.0
	bolt.material_override = bolt_material
	add_child(bolt)
	var launch: Vector3 = attacker.global_position + Vector3.UP * 1.7
	var impact: Vector3 = victim.global_position + Vector3.UP * 1.2
	bolt.global_position = launch
	var flight := create_tween()
	flight.tween_property(bolt, "global_position", impact, 0.30 / playback_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	flight.parallel().tween_property(bolt, "scale", Vector3.ONE * 1.8, 0.30 / playback_speed)
	while flight.is_running() and not _skip_requested:
		await get_tree().process_frame
	bolt.queue_free()
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	victim.play_state(_resolve_victim_hit_clip(attacker, victim))
	impact_landed.emit()
	await _wait_or_skip(0.12 / playback_speed)
	last_victim_death_clip = _resolve_victim_death_clip(attacker, victim)
	victim.play_state(last_victim_death_clip)
	await _wait_or_skip(victim.state_duration(last_victim_death_clip) / playback_speed)
	victim_death_finished.emit()
	_finish_capture(attacker, victim, destination)


func _play_rook_wall_capture(attacker, victim, destination: Vector3) -> void:
	attacker.face_world_position(victim.global_position)
	victim.face_world_position(attacker.global_position)
	attacker.play_state(&"attack.push.guard_01")
	await _wait_or_skip(0.22 / playback_speed)
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	var origin: Vector3 = attacker.global_position
	var target: Vector3 = victim.global_position
	var direction := target - origin
	direction.y = 0.0
	var distance := maxf(direction.length(), 0.1)
	var wall := MeshInstance3D.new()
	wall.name = "RookCrushWall"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.35, 3.2, 1.0)
	wall.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.28, 0.34, 0.42)
	material.metallic = 0.22
	material.roughness = 0.68
	wall.material_override = material
	add_child(wall)
	wall.global_position = origin.lerp(target, 0.5) + Vector3.UP * 1.55
	wall.look_at(target, Vector3.UP, true)
	wall.scale = Vector3(1.0, 1.0, 0.06)
	impact_landed.emit()
	var grow := create_tween()
	grow.tween_property(wall, "scale", Vector3(1.0, 1.0, distance + 0.75), 0.34 / playback_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	while grow.is_running() and not _skip_requested:
		await get_tree().process_frame
	wall.queue_free()
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	victim.play_state(_resolve_victim_hit_clip(attacker, victim))
	impact_landed.emit()
	await _wait_or_skip(0.12 / playback_speed)
	last_victim_death_clip = _resolve_victim_death_clip(attacker, victim)
	victim.play_state(last_victim_death_clip)
	await _wait_or_skip(victim.state_duration(last_victim_death_clip) / playback_speed)
	victim_death_finished.emit()
	_finish_capture(attacker, victim, destination)


func _play_bishop_ranged_capture(attacker, victim, destination: Vector3) -> void:
	attacker.face_world_position(victim.global_position)
	victim.face_world_position(attacker.global_position)
	attacker.play_state(&"attack.spell.shot_01")
	await _wait_or_skip(0.28 / playback_speed)
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	var arrow := ARROW_SCENE.instantiate() as Node3D
	arrow.name = "BishopArrowProjectile"
	add_child(arrow)
	var launch: Vector3 = attacker.global_position + Vector3.UP * 1.8
	var impact: Vector3 = victim.global_position + Vector3.UP * 1.15
	arrow.global_position = launch
	arrow.look_at(impact, Vector3.UP, true)
	arrow.scale = Vector3.ONE * 12.0
	var flight := create_tween()
	flight.tween_property(arrow, "global_position", impact, 0.34 / playback_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	while flight.is_running() and not _skip_requested:
		await get_tree().process_frame
	arrow.queue_free()
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	victim.play_state(_resolve_victim_hit_clip(attacker, victim))
	impact_landed.emit()
	await _wait_or_skip(0.14 / playback_speed)
	last_victim_death_clip = _resolve_victim_death_clip(attacker, victim)
	victim.play_state(last_victim_death_clip)
	await _wait_or_skip(victim.state_duration(last_victim_death_clip) / playback_speed)
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
