extends SceneTree

const Battle = preload("res://scripts/presentation/battle_director.gd")
const Resolver = preload("res://scripts/presentation/capture_choreography_resolver.gd")
const Types = preload("res://scripts/chess/chess_types.gd")
const Actor = preload("res://scenes/actors/PieceActor.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle := Battle.new()
	battle.choreography = Resolver.resolve(Types.PAWN)
	battle.playback_speed = 2.0
	root.add_child(battle)
	var attacker = Actor.instantiate()
	var victim = Actor.instantiate()
	root.add_child(attacker)
	root.add_child(victim)
	await process_frame
	var contact_positions: Array[Vector3] = []
	var weapon_cues: Array[StringName] = []
	var cue_counts_at_skip: Array[int] = []
	battle.weapon_impact.connect(func(kind: StringName): weapon_cues.append(kind))
	battle.impact_landed.connect(func():
		contact_positions.append(attacker.global_position)
		assert(attacker.current_semantic_state() == battle.choreography.attacker_clip, "Authored attack must survive until contact.")
		assert(battle.last_weapon_contact_distance_m <= battle.choreography.contact_radius_m, "Equipped weapon must cross the victim contact zone (distance %.3f m, radius %.3f m)." % [battle.last_weapon_contact_distance_m, battle.choreography.contact_radius_m])
		assert(battle.find_children("WeaponSwingArc*", "MeshInstance3D", false, false).is_empty(), "Pawn contact must leave the equipped daggers visible instead of covering them with a proxy swing torus.")
		cue_counts_at_skip.append(weapon_cues.size())
		battle.request_skip()
	)
	# Twenty replays cover eight approach directions, with a destination distinct
	# from the victim to exercise en-passant-style visual staging and settlement.
	for replay in 20:
		var angle := TAU * float(replay % 8) / 8.0
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		victim.visible = true
		victim.global_position = Vector3(3.0, 0.0, -2.0)
		attacker.global_position = victim.global_position + direction * 6.0
		attacker.start_battle_stance()
		var destination: Vector3 = victim.global_position + Vector3(0.0, 0.0, 1.0)
		var expected_anchor: Vector3 = victim.global_position + direction * battle.choreography.anchor_separation_m
		await battle.play_capture(attacker, victim, destination)
		assert(contact_positions.size() == replay + 1, "Each replay must reach exactly one contact.")
		assert(weapon_cues.size() == cue_counts_at_skip.back(), "No combat cue may be emitted after contact cancellation.")
		assert(contact_positions.back().is_equal_approx(expected_anchor), "Contact must stay on the incoming side of the victim.")
		assert(attacker.global_position.is_equal_approx(destination) and not victim.visible, "Skip after contact must settle exactly.")
		assert(not battle._running, "Replay must never leave battle running.")
		await create_timer(0.12).timeout
	# An overlapping initial position must still produce a finite anchor.
	victim.visible = true
	attacker.global_position = Vector3.ZERO
	victim.global_position = Vector3.ZERO
	await battle.play_capture(attacker, victim, Vector3.ZERO)
	assert(contact_positions.back().is_equal_approx(Vector3.BACK * battle.choreography.anchor_separation_m))
	# A skip during windup must not emit contact or leave a delayed swing behind.
	victim.visible = true
	attacker.global_position = Vector3(0.0, 0.0, 6.0)
	var count_before := contact_positions.size()
	battle.play_capture(attacker, victim, Vector3.ZERO)
	while attacker.current_semantic_state() != battle.choreography.attacker_clip:
		await process_frame
	battle.request_skip()
	await battle.presentation_finished
	assert(contact_positions.size() == count_before, "Skipping windup must suppress its hit.")
	assert(attacker.global_position.is_equal_approx(Vector3.ZERO))
	# Every melee archetype honors supported authored clips across stance seeds.
	for archetype in [Types.PAWN, Types.KNIGHT, Types.ROOK, Types.KING]:
		attacker.archetype = archetype
		for seed in 8:
			attacker._stance_seed = seed
			var clip: StringName = Resolver.resolve(archetype).attacker_clip
			assert(attacker.supports_state(clip))
			assert(attacker.capture_attack_state(clip) == clip)
	battle.queue_free()
	attacker.queue_free()
	victim.queue_free()
	await process_frame
	print("PASS: melee approach directions, authored clips, contact swings, coincident fallback and skip settlement across twenty replays.")
	quit(0)
