class_name BattleDirector
extends Node

const Types = preload("res://scripts/chess/chess_types.gd")
const ARROW_SCENE = preload("res://assets/weapons/quaternius/Arrow.fbx")
const RANGED_PROJECTILE_SCALE := 0.42
const TRAIL_SPACING_M := 0.18
const TRAIL_MAX_PER_PROJECTILE := 24
const TRAIL_LIFETIME_S := 0.16

signal presentation_finished
signal presentation_cancelled
signal presentation_stage(stage: StringName)
signal impact_landed
signal victim_death_finished
signal weapon_impact(kind: StringName)

@export var choreography: Resource
@export var playback_speed := 1.0

var _running := false
var _skip_requested := false
var _active_playback_speed := 1.0
var _active_attacker
var _active_victim
var _active_destination := Vector3.ZERO
var last_victim_death_clip: StringName = &""
var last_stage: StringName = &""
var stage_history: Array[StringName] = []
var last_weapon_contact_distance_m := INF
var _temporary_effects: Array[Node] = []
var _trail_mesh: SphereMesh
var _trail_materials: Dictionary = {}


func play_capture(attacker, victim, destination: Vector3) -> void:
	if _running:
		return
	_running = true
	_skip_requested = false
	_active_playback_speed = maxf(playback_speed, 0.1)
	stage_history.clear()
	last_weapon_contact_distance_m = INF
	_stage(&"anticipation")
	_active_attacker = attacker
	_active_victim = victim
	_active_destination = destination
	attacker.set_animation_speed(_active_playback_speed)
	victim.set_animation_speed(_active_playback_speed)
	if choreography.delivery == "arrow":
		await _play_bishop_ranged_capture(attacker, victim, destination)
		return
	if choreography.delivery == "hammer_smash":
		await _play_rook_hammer_capture(attacker, victim, destination)
		return
	if choreography.delivery == "arcane_bolt":
		await _play_queen_arcane_capture(attacker, victim, destination)
		return
	# Stage on the incoming side of the victim, including en passant where the
	# victim's square and the final domain destination are different.
	var approach_direction: Vector3 = attacker.global_position - victim.global_position
	approach_direction.y = 0.0
	if approach_direction.length_squared() < 0.000001:
		approach_direction = Vector3.BACK
	var approach_position: Vector3 = victim.global_position + approach_direction.normalized() * choreography.anchor_separation_m
	approach_position.y = attacker.global_position.y
	victim.face_world_position(attacker.global_position)
	_stage(&"approach")
	await _move_actor(attacker, approach_position, _scaled(choreography.approach_duration_s))
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	_stage(&"plant")
	weapon_impact.emit(&"approach_step")
	await _wait_or_skip(_scaled(choreography.plant_duration_s))
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	attacker.face_world_position(victim.global_position)
	var attack_state: StringName = attacker.capture_attack_state(choreography.attacker_clip)
	_stage(&"strike")
	attacker.play_state(attack_state)
	# Keep the short afterimage alive across contact, rather than spending it
	# during the windup. Both waits honor the same skip path as the attack.
	var swing_lead_s := minf(0.09, maxf(choreography.impact_time_s, 0.0))
	await _wait_or_skip(_scaled(maxf(choreography.impact_time_s - swing_lead_s, 0.0)))
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	_spawn_weapon_swing(attacker)
	await _wait_or_skip(_scaled(swing_lead_s))
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	# Evaluate the exact authored impact pose before measuring contact. Frame
	# cadence can otherwise leave an accelerated clip on either side of contact.
	# Hold it for one process frame so Skeleton3D and its bone attachments commit
	# the sampled transforms before the weapon bounds are queried.
	attacker.sample_active_animation_at(choreography.impact_time_s)
	attacker.set_animation_paused(true)
	await get_tree().process_frame
	if _skip_requested:
		attacker.set_animation_paused(false)
		_finish_capture(attacker, victim, destination)
		return
	victim.play_state(_resolve_victim_hit_clip(attacker, victim))
	_record_weapon_contact(attacker, victim)
	attacker.set_animation_paused(false)
	_spawn_role_impact(attacker, victim.global_position + Vector3.UP * 0.95)
	weapon_impact.emit(_melee_sound_for(attacker))
	impact_landed.emit()
	_stage(&"reaction")
	await _wait_or_skip(_scaled(0.16))
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	var elapsed_before_death: float = choreography.impact_time_s + 0.16
	if not choreography.attacker_followup_clip.is_empty():
		_stage(&"followup")
		attacker.play_state(choreography.attacker_followup_clip)
		await _wait_or_skip(_scaled(choreography.followup_time_s))
		if _skip_requested:
			_finish_capture(attacker, victim, destination)
			return
		impact_landed.emit()
		weapon_impact.emit(_melee_sound_for(attacker))
		var followup_settle_s := 0.10
		await _wait_or_skip(_scaled(followup_settle_s))
		if _skip_requested:
			_finish_capture(attacker, victim, destination)
			return
		elapsed_before_death += choreography.followup_time_s + followup_settle_s
	last_victim_death_clip = _resolve_victim_death_clip(attacker, victim)
	_stage(&"death")
	victim.play_state(last_victim_death_clip)
	var death_duration: float = _scaled(victim.state_duration(last_victim_death_clip))
	var cleanup_duration := maxf(death_duration, _scaled(choreography.cleanup_time_s - elapsed_before_death))
	await _wait_or_skip(cleanup_duration)
	victim_death_finished.emit()
	await _settle_and_recover(attacker, destination)
	_finish_capture(attacker, victim, destination)


func _play_queen_arcane_capture(attacker, victim, destination: Vector3) -> void:
	attacker.face_world_position(victim.global_position)
	victim.face_world_position(attacker.global_position)
	attacker.play_state(attacker.capture_attack_state(choreography.attacker_clip))
	_stage(&"strike")
	weapon_impact.emit(&"arcane_cast")
	# Casting is an anticipation cue. The impact signal is reserved for the
	# projectile reaching the victim contact zone.
	await _wait_or_skip(_scaled(0.24))
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
	_stage(&"delivery")
	flight.tween_property(bolt, "global_position", impact, _scaled(0.30)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	flight.parallel().tween_property(bolt, "scale", Vector3.ONE * 1.8, _scaled(0.30))
	flight.parallel().tween_property(halo, "rotation:y", TAU * 3.0, _scaled(0.30))
	var trail_state := {"last_position": launch, "emitted": 0}
	while flight.is_running() and not _skip_requested:
		await get_tree().process_frame
		_emit_projectile_trail(trail_state, bolt.global_position, Color(1.0, 0.18, 0.04))
	bolt.queue_free()
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	_spawn_elemental_impact(impact, Color(1.0, 0.15, 0.03), Color(1.0, 0.48, 0.08))
	_spawn_role_impact(attacker, impact)
	victim.play_state(_resolve_victim_hit_clip(attacker, victim))
	last_weapon_contact_distance_m = 0.0
	weapon_impact.emit(&"arcane_impact")
	impact_landed.emit()
	_stage(&"reaction")
	await _wait_or_skip(_scaled(0.12))
	await _play_delivery_followup(attacker, victim, impact)
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	last_victim_death_clip = _resolve_victim_death_clip(attacker, victim)
	_stage(&"death")
	victim.play_state(last_victim_death_clip)
	await _wait_or_skip(_scaled(victim.state_duration(last_victim_death_clip)))
	victim_death_finished.emit()
	await _settle_and_recover(attacker, destination)
	_finish_capture(attacker, victim, destination)


func _play_rook_hammer_capture(attacker, victim, destination: Vector3) -> void:
	attacker.face_world_position(victim.global_position)
	victim.face_world_position(attacker.global_position)
	var approach_direction: Vector3 = attacker.global_position - victim.global_position
	approach_direction.y = 0.0
	if approach_direction.length_squared() < 0.000001:
		approach_direction = Vector3.BACK
	var approach_position: Vector3 = victim.global_position + approach_direction.normalized() * choreography.anchor_separation_m
	approach_position.y = attacker.global_position.y
	_stage(&"approach")
	await _move_actor(attacker, approach_position, _scaled(choreography.approach_duration_s))
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	_stage(&"plant")
	weapon_impact.emit(&"approach_step")
	await _wait_or_skip(_scaled(choreography.plant_duration_s))
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	attacker.face_world_position(victim.global_position)
	_stage(&"strike")
	attacker.play_state(attacker.capture_attack_state(choreography.attacker_clip))
	# The impact is aligned to the authored overhead descent, not to the old
	# masonry volley. This keeps the visible hammer, audio, victim reaction and
	# contact marker on a single readable beat.
	await _wait_or_skip(_scaled(choreography.impact_time_s))
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	victim.play_state(_resolve_victim_hit_clip(attacker, victim))
	_record_weapon_contact(attacker, victim)
	_spawn_weapon_swing(attacker)
	_spawn_role_impact(attacker, victim.global_position + Vector3.UP * 1.0)
	weapon_impact.emit(&"hammer_impact")
	impact_landed.emit()
	_stage(&"reaction")
	await _wait_or_skip(_scaled(0.12))
	await _play_delivery_followup(attacker, victim, victim.global_position + Vector3.UP * 1.0)
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	last_victim_death_clip = _resolve_victim_death_clip(attacker, victim)
	_stage(&"death")
	victim.play_state(last_victim_death_clip)
	await _wait_or_skip(_scaled(victim.state_duration(last_victim_death_clip)))
	victim_death_finished.emit()
	await _settle_and_recover(attacker, destination)
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
		flight.tween_property(brick, "global_position", apex, _scaled(0.17)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		flight.tween_property(brick, "global_position", target + impact_spread, _scaled(0.25)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		flight.parallel().tween_property(brick, "rotation", brick.rotation + Vector3(5.0, 7.0, 4.0), _scaled(0.42))
	return volley


func _play_bishop_ranged_capture(attacker, victim, destination: Vector3) -> void:
	attacker.face_world_position(victim.global_position)
	victim.face_world_position(attacker.global_position)
	_stage(&"strike")
	attacker.play_state(attacker.capture_attack_state(choreography.attacker_clip))
	# Release timing is authored with the Bishop's local bow/arrow timeline.
	await _wait_or_skip(_scaled(0.32))
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	attacker.release_authored_projectile()
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
	_stage(&"delivery")
	var frost_light := OmniLight3D.new()
	frost_light.name = "FrostArrowLight"
	frost_light.light_color = Color(0.32, 0.78, 1.0)
	frost_light.light_energy = 2.2
	frost_light.omni_range = 3.5
	arrow.add_child(frost_light)
	var flight := create_tween()
	flight.tween_property(arrow, "global_position", impact, _scaled(0.34)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var trail_state := {"last_position": launch, "emitted": 0}
	while flight.is_running() and not _skip_requested:
		await get_tree().process_frame
		_emit_projectile_trail(trail_state, arrow.global_position, Color(0.32, 0.80, 1.0))
	arrow.queue_free()
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	_spawn_elemental_impact(impact, Color(0.22, 0.72, 1.0), Color(0.66, 0.92, 1.0))
	_spawn_role_impact(attacker, impact)
	victim.play_state(_resolve_victim_hit_clip(attacker, victim))
	last_weapon_contact_distance_m = 0.0
	weapon_impact.emit(&"arrow_impact")
	impact_landed.emit()
	_stage(&"reaction")
	await _wait_or_skip(_scaled(0.14))
	await _play_delivery_followup(attacker, victim, impact)
	if _skip_requested:
		_finish_capture(attacker, victim, destination)
		return
	last_victim_death_clip = _resolve_victim_death_clip(attacker, victim)
	_stage(&"death")
	victim.play_state(last_victim_death_clip)
	await _wait_or_skip(_scaled(victim.state_duration(last_victim_death_clip)))
	victim_death_finished.emit()
	await _settle_and_recover(attacker, destination)
	_finish_capture(attacker, victim, destination)


func request_skip() -> void:
	if _running and not _skip_requested:
		_skip_requested = true
		presentation_cancelled.emit()


func active_playback_speed() -> float:
	return _active_playback_speed


func active_temporary_effect_count() -> int:
	_temporary_effects = _temporary_effects.filter(func(effect): return is_instance_valid(effect) and not effect.is_queued_for_deletion())
	return _temporary_effects.size()


func _register_temporary_effect(effect: Node) -> void:
	_temporary_effects.append(effect)


func _clear_temporary_effects() -> void:
	for effect in _temporary_effects:
		if is_instance_valid(effect):
			effect.queue_free()
	_temporary_effects.clear()


func _play_delivery_followup(attacker, victim, impact_position: Vector3) -> void:
	# Special delivery paths (arrow, wall, arcane) return early from the generic
	# choreography flow, so they explicitly honor the same optional second beat.
	if choreography.attacker_followup_clip.is_empty() or _skip_requested:
		return
	_stage(&"followup")
	attacker.face_world_position(victim.global_position)
	attacker.play_state(choreography.attacker_followup_clip)
	await _wait_or_skip(_scaled(choreography.followup_time_s))
	if _skip_requested:
		return
	_spawn_role_impact(attacker, impact_position)
	weapon_impact.emit(_melee_sound_for(attacker))
	impact_landed.emit()
	await _wait_or_skip(_scaled(0.10))


func _spawn_elemental_impact(position: Vector3, core_color: Color, spark_color: Color) -> void:
	var burst := Node3D.new()
	burst.name = "ElementalImpact"
	add_child(burst)
	_register_temporary_effect(burst)
	burst.global_position = position
	var material := StandardMaterial3D.new()
	material.albedo_color = core_color
	material.emission_enabled = true
	material.emission = spark_color
	material.emission_energy_multiplier = 5.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var flash := MeshInstance3D.new()
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.18
	flash_mesh.height = 0.36
	flash.mesh = flash_mesh
	flash.material_override = material
	burst.add_child(flash)
	var light := OmniLight3D.new()
	light.light_color = spark_color
	light.light_energy = 2.2
	light.omni_range = 3.0
	burst.add_child(light)
	var burst_tween := create_tween()
	# Keep the contact core smaller than a torso and fade it immediately; the
	# surrounding role shards provide the wider read without replacing a victim.
	burst_tween.tween_property(flash, "scale", Vector3.ONE * 2.4, _scaled(0.16))
	burst_tween.parallel().tween_property(flash, "transparency", 1.0, _scaled(0.16))
	burst_tween.parallel().tween_property(light, "light_energy", 0.0, _scaled(0.16))
	burst_tween.tween_callback(burst.queue_free)


func _emit_projectile_trail(state: Dictionary, position: Vector3, color: Color) -> void:
	# Sampling travelled distance, rather than frames, makes trail density stable
	# at 0.25x/1x/2x and across rendering frame rates.
	var previous: Vector3 = state.last_position
	var distance := previous.distance_to(position)
	while distance >= TRAIL_SPACING_M and int(state.emitted) < TRAIL_MAX_PER_PROJECTILE:
		previous = previous.lerp(position, TRAIL_SPACING_M / distance)
		_spawn_projectile_trail(previous, color)
		state.emitted = int(state.emitted) + 1
		distance = previous.distance_to(position)
	state.last_position = previous


func _spawn_projectile_trail(position: Vector3, color: Color) -> void:
	# A short-lived glow records projectile travel without littering the impact
	# square with repeated explosions before the shot has actually arrived.
	var trail := MeshInstance3D.new()
	trail.name = "ProjectileTrail"
	if _trail_mesh == null:
		_trail_mesh = SphereMesh.new()
		_trail_mesh.radius = 0.055
		_trail_mesh.height = 0.11
		_trail_mesh.radial_segments = 8
		_trail_mesh.rings = 4
	trail.mesh = _trail_mesh
	var material: StandardMaterial3D = _trail_materials.get(color, null)
	if material == null:
		material = StandardMaterial3D.new()
		material.albedo_color = color
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 4.0
		_trail_materials[color] = material
	trail.material_override = material
	add_child(trail)
	_register_temporary_effect(trail)
	trail.global_position = position
	var tween := create_tween()
	tween.tween_property(trail, "scale", Vector3.ONE * 2.2, _scaled(TRAIL_LIFETIME_S))
	tween.parallel().tween_property(trail, "transparency", 1.0, _scaled(TRAIL_LIFETIME_S))
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
	_register_temporary_effect(impact)
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
	impact_tween.tween_property(ring, "scale", Vector3.ONE * 3.2, _scaled(0.28)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	impact_tween.parallel().tween_property(ring, "transparency", 1.0, _scaled(0.28))
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
		shard_tween.tween_property(shard, "position", destination, _scaled(0.30)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		shard_tween.parallel().tween_property(shard, "transparency", 1.0, _scaled(0.30))
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
			# The equipped daggers now enter the measured contact zone. A proxy
			# torus covered that actual intersection in slow-motion review.
			count = 0
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
		_register_temporary_effect(arc)
		arc.global_position = attacker.global_position + Vector3.UP * (1.25 + index * 0.18) - attacker.global_transform.basis.z * 0.52
		arc.global_rotation = Vector3(PI * 0.5, attacker.global_rotation.y + index * 0.35, 0.0)
		arc.scale = Vector3.ONE * 0.35
		var swing := create_tween()
		swing.tween_property(arc, "scale", Vector3.ONE * 1.75, _scaled(0.18)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		swing.parallel().tween_property(arc, "transparency", 1.0, _scaled(0.18))
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
	actor.turn_toward_world_position(target, _scaled(actor.turn_duration_toward(target)))
	while actor.is_presentation_turning():
		if _skip_requested:
			actor.cancel_presentation_motion()
			actor.global_position = target
			return
		await get_tree().process_frame
	var tween = actor.move_to_world_position(target, duration)
	while tween.is_running():
		if _skip_requested:
			actor.cancel_presentation_motion()
			actor.global_position = target
			return
		await get_tree().process_frame


func _walk_winner_to_destination(attacker, destination: Vector3) -> void:
	if _skip_requested:
		return
	var distance: float = attacker.global_position.distance_to(destination)
	if distance < 0.03:
		return
	var duration: float = _scaled(attacker.travel_duration_for_distance(distance, 7.0))
	await _move_actor(attacker, destination, duration)


func _settle_and_recover(attacker, destination: Vector3) -> void:
	_stage(&"settlement")
	await _walk_winner_to_destination(attacker, destination)
	if _skip_requested:
		return
	_stage(&"recovery")
	attacker.recover_after_capture()
	await _wait_or_skip(_scaled(choreography.recovery_duration_s))


func _scaled(duration_s: float) -> float:
	return maxf(duration_s, 0.0) / _active_playback_speed


func _stage(stage: StringName) -> void:
	last_stage = stage
	stage_history.append(stage)
	presentation_stage.emit(stage)


func _record_weapon_contact(attacker, victim) -> void:
	var contact_point: Vector3 = victim.global_position + Vector3.UP * choreography.contact_height_m
	last_weapon_contact_distance_m = attacker.weapon_contact_distance_to(contact_point)


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
	_clear_temporary_effects()
	attacker.cancel_presentation_motion()
	victim.cancel_presentation_motion()
	victim.visible = false
	attacker.global_position = destination
	attacker.restore_board_facing()
	attacker.set_animation_speed(1.0)
	victim.set_animation_speed(1.0)
	attacker.start_battle_stance()
	_stage(&"finished")
	_running = false
	_active_attacker = null
	_active_victim = null
	presentation_finished.emit()


func _exit_tree() -> void:
	if _running and not _skip_requested:
		presentation_cancelled.emit()
	_clear_temporary_effects()
