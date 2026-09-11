class_name BattleDirector
extends Node

const Types = preload("res://scripts/chess/chess_types.gd")
const ARROW_SCENE = preload("res://assets/weapons/quaternius/Arrow.fbx")
const RANGED_PROJECTILE_SCALE := 0.42

signal presentation_finished
signal impact_landed
signal victim_death_finished
signal weapon_impact(kind: StringName)

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
	var attack_state: StringName = attacker.capture_attack_state(choreography.attacker_clip)
	attacker.play_state(attack_state)
	_spawn_weapon_swing(attacker)
	await _wait_or_skip(choreography.impact_time_s / playback_speed)
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	victim.play_state(_resolve_victim_hit_clip(attacker, victim))
	impact_landed.emit()
	_spawn_role_impact(attacker, victim.global_position + Vector3.UP * 0.95)
	weapon_impact.emit(_melee_sound_for(attacker))
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
		weapon_impact.emit(_melee_sound_for(attacker))
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
	await _walk_winner_to_destination(attacker, destination)
	_finish_capture(attacker, victim, destination)


func _play_queen_arcane_capture(attacker, victim, destination: Vector3) -> void:
	attacker.face_world_position(victim.global_position)
	victim.face_world_position(attacker.global_position)
	attacker.play_state(&"attack.spell.shot_01")
	weapon_impact.emit(&"arcane_cast")
	# The cast and arrival are separate presentation beats. Signature queen
	# captures intentionally retain both so the spell reads as a command followed
	# by its destructive payoff.
	impact_landed.emit()
	await _wait_or_skip(0.24 / playback_speed)
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	var bolt := Node3D.new()
	bolt.name = "QueenArcaneBolt"
	add_child(bolt)
	var bolt_core := MeshInstance3D.new()
	bolt_core.name = "FireCore"
	var bolt_mesh := SphereMesh.new()
	bolt_mesh.radius = 0.24
	bolt_mesh.height = 0.48
	bolt_core.mesh = bolt_mesh
	var bolt_material := StandardMaterial3D.new()
	bolt_material.albedo_color = Color(1.0, 0.31, 0.08)
	bolt_material.emission_enabled = true
	bolt_material.emission = Color(1.0, 0.08, 0.01)
	bolt_material.emission_energy_multiplier = 6.0
	bolt_core.material_override = bolt_material
	bolt.add_child(bolt_core)
	var halo := MeshInstance3D.new()
	halo.name = "FireHalo"
	var halo_mesh := TorusMesh.new()
	halo_mesh.inner_radius = 0.25
	halo_mesh.outer_radius = 0.33
	halo_mesh.rings = 8
	halo_mesh.ring_segments = 16
	halo.mesh = halo_mesh
	halo.rotation.x = PI * 0.5
	halo.material_override = bolt_material
	bolt.add_child(halo)
	var bolt_light := OmniLight3D.new()
	bolt_light.name = "FireLight"
	bolt_light.light_color = Color(1.0, 0.22, 0.05)
	bolt_light.light_energy = 4.0
	bolt_light.omni_range = 5.0
	bolt.add_child(bolt_light)
	for shard_index in 4:
		var shard := MeshInstance3D.new()
		shard.name = "FireShard%02d" % shard_index
		var shard_mesh := SphereMesh.new()
		shard_mesh.radius = 0.07
		shard_mesh.height = 0.14
		shard.mesh = shard_mesh
		var angle := TAU * float(shard_index) / 4.0
		shard.position = Vector3(cos(angle) * 0.42, sin(angle * 2.0) * 0.20, sin(angle) * 0.42)
		shard.material_override = bolt_material
		bolt.add_child(shard)
	var launch: Vector3 = attacker.global_position + Vector3.UP * 1.7
	var impact: Vector3 = victim.global_position + Vector3.UP * 1.2
	bolt.global_position = launch
	var flight := create_tween()
	flight.tween_property(bolt, "global_position", impact, 0.30 / playback_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	flight.parallel().tween_property(bolt, "scale", Vector3.ONE * 1.8, 0.30 / playback_speed)
	flight.parallel().tween_property(halo, "rotation:y", TAU * 3.0, 0.30 / playback_speed)
	while flight.is_running() and not _skip_requested:
		await get_tree().process_frame
		_spawn_projectile_trail(bolt.global_position, Color(1.0, 0.18, 0.04))
	bolt.queue_free()
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	_spawn_elemental_impact(impact, Color(1.0, 0.15, 0.03), Color(1.0, 0.48, 0.08))
	_spawn_role_impact(attacker, impact)
	victim.play_state(_resolve_victim_hit_clip(attacker, victim))
	impact_landed.emit()
	weapon_impact.emit(&"arcane_impact")
	await _wait_or_skip(0.12 / playback_speed)
	last_victim_death_clip = _resolve_victim_death_clip(attacker, victim)
	victim.play_state(last_victim_death_clip)
	await _wait_or_skip(victim.state_duration(last_victim_death_clip) / playback_speed)
	victim_death_finished.emit()
	await _walk_winner_to_destination(attacker, destination)
	_finish_capture(attacker, victim, destination)


func _play_rook_wall_capture(attacker, victim, destination: Vector3) -> void:
	attacker.face_world_position(victim.global_position)
	victim.face_world_position(attacker.global_position)
	attacker.play_state(&"attack.push.guard_01")
	_spawn_weapon_swing(attacker)
	await _wait_or_skip(0.22 / playback_speed)
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	var origin: Vector3 = attacker.global_position + Vector3.UP * 1.55
	var target: Vector3 = victim.global_position + Vector3.UP * 1.10
	var volley := _spawn_rook_brick_volley(origin, target)
	weapon_impact.emit(&"wall_slam")
	await _wait_or_skip(0.42 / playback_speed)
	volley.queue_free()
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	victim.play_state(_resolve_victim_hit_clip(attacker, victim))
	impact_landed.emit()
	_spawn_role_impact(attacker, target)
	weapon_impact.emit(&"hammer_impact")
	await _wait_or_skip(0.12 / playback_speed)
	last_victim_death_clip = _resolve_victim_death_clip(attacker, victim)
	victim.play_state(last_victim_death_clip)
	await _wait_or_skip(victim.state_duration(last_victim_death_clip) / playback_speed)
	victim_death_finished.emit()
	await _walk_winner_to_destination(attacker, destination)
	_finish_capture(attacker, victim, destination)


func _spawn_rook_brick_volley(origin: Vector3, target: Vector3) -> Node3D:
	# The rook now hurls a visible, heavy stack of masonry. Individual blocks
	# arc toward the victim and make the lane attack instantly legible.
	var volley := Node3D.new()
	volley.name = "RookBrickVolley"
	add_child(volley)
	var direction := (target - origin).normalized()
	var right := direction.cross(Vector3.UP).normalized()
	for index in 8:
		var brick := MeshInstance3D.new()
		brick.name = "ThrownBrick_%02d" % index
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.52, 0.30, 0.72)
		brick.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.34, 0.16, 0.065).lerp(Color(0.55, 0.25, 0.08), float(index % 3) * 0.10)
		material.metallic = 0.06
		material.roughness = 0.84
		brick.material_override = material
		volley.add_child(brick)
		var spread_x := float((index % 4) - 1.5) * 0.22
		var spread_y := float(index / 4) * 0.24
		brick.global_position = origin + right * spread_x + Vector3.UP * spread_y
		brick.rotation = Vector3(float(index) * 0.31, float(index) * 0.57, float(index) * 0.19)
		var impact_spread := right * (float((index % 3) - 1) * 0.28) + Vector3.UP * (float(index % 2) * 0.22)
		var apex := brick.global_position.lerp(target + impact_spread, 0.48) + Vector3.UP * (0.85 + float(index % 3) * 0.14)
		var flight := create_tween()
		flight.tween_property(brick, "global_position", apex, 0.17 / playback_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		flight.tween_property(brick, "global_position", target + impact_spread, 0.25 / playback_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		flight.parallel().tween_property(brick, "rotation", brick.rotation + Vector3(5.0, 7.0, 4.0), 0.42 / playback_speed)
	return volley


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
	# Imported weapon meshes are authored in centimetre-like source units. A
	# compact, explicit scale keeps this projectile character-sized instead of
	# letting a bishop's arrow fill the capture camera.
	arrow.scale = Vector3.ONE * RANGED_PROJECTILE_SCALE
	weapon_impact.emit(&"arrow_release")
	var frost_light := OmniLight3D.new()
	frost_light.name = "FrostArrowLight"
	frost_light.light_color = Color(0.32, 0.78, 1.0)
	frost_light.light_energy = 2.2
	frost_light.omni_range = 3.5
	arrow.add_child(frost_light)
	var flight := create_tween()
	flight.tween_property(arrow, "global_position", impact, 0.34 / playback_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	while flight.is_running() and not _skip_requested:
		await get_tree().process_frame
		_spawn_projectile_trail(arrow.global_position, Color(0.32, 0.80, 1.0))
	arrow.queue_free()
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	_spawn_elemental_impact(impact, Color(0.22, 0.72, 1.0), Color(0.66, 0.92, 1.0))
	_spawn_role_impact(attacker, impact)
	victim.play_state(_resolve_victim_hit_clip(attacker, victim))
	impact_landed.emit()
	weapon_impact.emit(&"arrow_impact")
	await _wait_or_skip(0.14 / playback_speed)
	last_victim_death_clip = _resolve_victim_death_clip(attacker, victim)
	victim.play_state(last_victim_death_clip)
	await _wait_or_skip(victim.state_duration(last_victim_death_clip) / playback_speed)
	victim_death_finished.emit()
	await _walk_winner_to_destination(attacker, destination)
	_finish_capture(attacker, victim, destination)


func request_skip() -> void:
	if _running:
		_skip_requested = true


func _spawn_elemental_impact(position: Vector3, core_color: Color, spark_color: Color) -> void:
	var burst := Node3D.new()
	burst.name = "ElementalImpact"
	add_child(burst)
	burst.global_position = position
	var material := StandardMaterial3D.new()
	material.albedo_color = core_color
	material.emission_enabled = true
	material.emission = spark_color
	material.emission_energy_multiplier = 5.0
	var flash := MeshInstance3D.new()
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.32
	flash_mesh.height = 0.64
	flash.mesh = flash_mesh
	flash.material_override = material
	burst.add_child(flash)
	var light := OmniLight3D.new()
	light.light_color = spark_color
	light.light_energy = 5.0
	light.omni_range = 5.5
	burst.add_child(light)
	var burst_tween := create_tween()
	burst_tween.tween_property(flash, "scale", Vector3.ONE * 4.2, 0.22 / playback_speed)
	burst_tween.parallel().tween_property(light, "light_energy", 0.0, 0.22 / playback_speed)
	burst_tween.tween_callback(burst.queue_free)


func _spawn_projectile_trail(position: Vector3, color: Color) -> void:
	# A short-lived glow records projectile travel without littering the impact
	# square with repeated explosions before the shot has actually arrived.
	var trail := MeshInstance3D.new()
	trail.name = "ProjectileTrail"
	var mesh := SphereMesh.new()
	mesh.radius = 0.055
	mesh.height = 0.11
	mesh.radial_segments = 8
	mesh.rings = 4
	trail.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 4.0
	trail.material_override = material
	add_child(trail)
	trail.global_position = position
	var tween := create_tween()
	tween.tween_property(trail, "scale", Vector3.ONE * 2.6, 0.16 / playback_speed)
	tween.parallel().tween_property(trail, "transparency", 1.0, 0.16 / playback_speed)
	tween.tween_callback(trail.queue_free)


func _spawn_role_impact(attacker, position: Vector3) -> void:
	# A class-colored impact stamp makes the decisive moment legible from the
	# player's board view, while every mesh is short-lived and has no gameplay
	# collision or state responsibility.
	var color := Color(1.0, 0.72, 0.20)
	var shard_count := 5
	match attacker.archetype:
		Types.PAWN:
			color = Color(0.95, 0.89, 0.66)
			shard_count = 7
		Types.KNIGHT:
			color = Color(0.30, 0.78, 1.0)
			shard_count = 6
		Types.BISHOP:
			color = Color(0.45, 0.86, 1.0)
			shard_count = 8
		Types.ROOK:
			color = Color(1.0, 0.34, 0.08)
			shard_count = 10
		Types.QUEEN:
			color = Color(0.94, 0.24, 1.0)
			shard_count = 9
		Types.KING:
			color = Color(1.0, 0.78, 0.18)
			shard_count = 8
	var impact := Node3D.new()
	impact.name = "RoleImpact_%s" % _archetype_name(attacker.archetype)
	add_child(impact)
	impact.global_position = position
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 4.8
	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.18
	ring_mesh.outer_radius = 0.25
	ring_mesh.rings = 8
	ring_mesh.ring_segments = 20
	ring.mesh = ring_mesh
	ring.material_override = material
	ring.rotation.x = PI * 0.5
	impact.add_child(ring)
	var impact_tween := create_tween()
	impact_tween.tween_property(ring, "scale", Vector3.ONE * 3.2, 0.28 / playback_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	impact_tween.parallel().tween_property(ring, "transparency", 1.0, 0.28 / playback_speed)
	for index in shard_count:
		var shard := MeshInstance3D.new()
		shard.name = "ImpactShard_%02d" % index
		var shard_mesh := SphereMesh.new()
		shard_mesh.radius = 0.035 + float(index % 3) * 0.012
		shard_mesh.height = shard_mesh.radius * 2.0
		shard.mesh = shard_mesh
		shard.material_override = material
		impact.add_child(shard)
		var angle := TAU * float(index) / float(shard_count) + 0.18 * float(attacker.archetype)
		var destination := Vector3(cos(angle), 0.20 + float(index % 2) * 0.18, sin(angle)) * (0.55 + float(index % 3) * 0.12)
		var shard_tween := create_tween()
		shard_tween.tween_property(shard, "position", destination, 0.30 / playback_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		shard_tween.parallel().tween_property(shard, "transparency", 1.0, 0.30 / playback_speed)
	impact_tween.tween_callback(impact.queue_free)


func _archetype_name(archetype: int) -> String:
	return ["Unknown", "Pawn", "Knight", "Bishop", "Rook", "Queen", "King"][clampi(archetype, 0, Types.KING)]


func _spawn_weapon_swing(attacker) -> void:
	# A short-lived, role-colored afterimage gives the imported weapon motions a
	# readable arc at board scale without altering the actor's rig or root.
	var color := Color(1.0, 0.72, 0.20)
	var count := 1
	match attacker.archetype:
		Types.PAWN:
			color = Color(0.92, 0.86, 0.66)
			count = 2
		Types.KNIGHT:
			color = Color(0.36, 0.76, 1.0)
		Types.ROOK:
			color = Color(1.0, 0.42, 0.12)
		Types.KING:
			color = Color(1.0, 0.78, 0.22)
	for index in count:
		var arc := MeshInstance3D.new()
		arc.name = "WeaponSwingArc%02d" % index
		var mesh := TorusMesh.new()
		mesh.inner_radius = 0.34 + index * 0.12
		mesh.outer_radius = 0.39 + index * 0.12
		mesh.rings = 8
		mesh.ring_segments = 20
		arc.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 4.2
		arc.material_override = material
		add_child(arc)
		arc.global_position = attacker.global_position + Vector3.UP * (1.25 + index * 0.18) - attacker.global_transform.basis.z * 0.52
		arc.global_rotation = Vector3(PI * 0.5, attacker.global_rotation.y + index * 0.35, 0.0)
		arc.scale = Vector3.ONE * 0.35
		var swing := create_tween()
		swing.tween_property(arc, "scale", Vector3.ONE * 1.75, 0.18 / playback_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		swing.parallel().tween_property(arc, "transparency", 1.0, 0.18 / playback_speed)
		swing.tween_callback(arc.queue_free)


func _melee_sound_for(attacker) -> StringName:
	match attacker.archetype:
		Types.PAWN:
			return &"dual_sword_impact"
		Types.KNIGHT:
			return &"spear_impact"
		Types.ROOK:
			return &"hammer_impact"
		Types.KING:
			return &"royal_blade_impact"
	return &"sword_impact"


func _move_actor(actor, target: Vector3, duration: float) -> void:
	var tween = actor.move_to_world_position(target, duration)
	while tween.is_running():
		if _skip_requested:
			tween.kill()
			actor.global_position = target
			return
		await get_tree().process_frame


func _walk_winner_to_destination(attacker, destination: Vector3) -> void:
	if _skip_requested:
		return
	var distance: float = attacker.global_position.distance_to(destination)
	if distance < 0.03:
		return
	attacker.face_world_position(destination)
	var duration := clampf(distance / 7.0, 0.24, 1.0) / playback_speed
	var walk_duration := maxf(attacker.state_duration(&"locomotion.walk.forward"), 0.01)
	attacker.set_animation_speed(walk_duration / duration)
	attacker.play_state(&"locomotion.walk.forward")
	await _move_actor(attacker, destination, duration)


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
	attacker.start_battle_stance()
	_running = false
	_active_attacker = null
	_active_victim = null
	presentation_finished.emit()
