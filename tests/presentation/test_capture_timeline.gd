extends SceneTree

const ActorScene = preload("res://scenes/actors/PieceActor.tscn")
const AudioDirector = preload("res://scripts/presentation/arena_audio_director.gd")
const BattleDirector = preload("res://scripts/presentation/battle_director.gd")
const Resolver = preload("res://scripts/presentation/capture_choreography_resolver.gd")
const Types = preload("res://scripts/chess/chess_types.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle := BattleDirector.new()
	battle.choreography = Resolver.resolve(Types.PAWN)
	var audio := AudioDirector.new()
	root.add_child(audio)
	root.add_child(battle)
	battle.weapon_impact.connect(audio.play_weapon_impact)
	battle.presentation_cancelled.connect(audio.stop_combat_sfx)
	var attacker = ActorScene.instantiate()
	var victim = ActorScene.instantiate()
	attacker.position = Vector3(0.0, 0.0, 3.0)
	victim.position = Vector3(0.0, 0.0, -3.0)
	root.add_child(attacker)
	root.add_child(victim)
	await process_frame

	# A complete accelerated capture preserves the authored stage order and emits
	# one planted approach cue plus one pawn contact cue.
	battle.playback_speed = 8.0
	await battle.play_capture(attacker, victim, victim.global_position)
	_assert_subsequence(battle.stage_history, [&"anticipation", &"approach", &"plant", &"strike", &"reaction", &"death", &"settlement", &"recovery", &"finished"])
	assert(audio.played_sfx_kinds.count(&"approach_step") == 1)
	assert(audio.played_sfx_kinds.count(&"dual_sword_impact") == 1, "Pawn contact must produce exactly one impact sound.")
	assert(
		battle.last_weapon_contact_distance_m <= battle.choreography.contact_radius_m,
		"Pawn weapon contact %.3fm exceeds the %.3fm choreography radius." % [
			battle.last_weapon_contact_distance_m,
			battle.choreography.contact_radius_m,
		]
	)
	assert(attacker.global_position.is_equal_approx(Vector3(0.0, 0.0, -3.0)) and not victim.visible)

	# Playback speed is latched per capture. A settings change during strike is
	# applied to the next capture, never half-way through the active timeline.
	_reset_pair(attacker, victim)
	battle.playback_speed = 4.0
	var changed_speed := [false]
	var speed_change = func(stage: StringName):
		if stage == &"strike" and not changed_speed[0]:
			changed_speed[0] = true
			battle.playback_speed = 0.25
			assert(is_equal_approx(battle.active_playback_speed(), 4.0))
	battle.presentation_stage.connect(speed_change)
	await battle.play_capture(attacker, victim, victim.global_position)
	battle.presentation_stage.disconnect(speed_change)
	assert(changed_speed[0] and is_equal_approx(battle.active_playback_speed(), 4.0))
	_reset_pair(attacker, victim)
	battle.play_capture(attacker, victim, victim.global_position)
	await process_frame
	assert(is_equal_approx(battle.active_playback_speed(), 0.25), "The next capture must latch the updated speed.")
	battle.request_skip()
	await battle.presentation_finished

	# Skip before contact suppresses reaction, impact audio, and delayed effects.
	_reset_pair(attacker, victim)
	audio.played_sfx_kinds.clear()
	battle.playback_speed = 8.0
	var skip_before = func(stage: StringName):
		if stage == &"strike":
			battle.request_skip()
	battle.presentation_stage.connect(skip_before)
	await battle.play_capture(attacker, victim, victim.global_position)
	battle.presentation_stage.disconnect(skip_before)
	assert(not battle.stage_history.has(&"reaction"))
	assert(audio.played_sfx_kinds.count(&"dual_sword_impact") == 0)
	assert(battle.active_temporary_effect_count() == 0)

	# Skip during reaction and recovery both settle exactly, stop active SFX,
	# and prevent later cues from leaking out of the cancelled timeline.
	for skip_stage in [&"reaction", &"recovery"]:
		_reset_pair(attacker, victim)
		audio.played_sfx_kinds.clear()
		var cue_count_at_skip := [0]
		var skip_at_stage = func(stage: StringName):
			if stage == skip_stage:
				cue_count_at_skip[0] = audio.played_sfx_kinds.size()
				battle.request_skip()
		battle.presentation_stage.connect(skip_at_stage)
		await battle.play_capture(attacker, victim, victim.global_position)
		battle.presentation_stage.disconnect(skip_at_stage)
		await create_timer(0.20).timeout
		assert(audio.played_sfx_kinds.size() == cue_count_at_skip[0], "Cancellation must suppress delayed audio after %s." % skip_stage)
		for player in audio._sfx_players:
			assert(not player.playing, "Cancellation must stop an already playing combat stream after %s." % skip_stage)
		assert(attacker.global_position.is_equal_approx(Vector3(0.0, 0.0, -3.0)) and not victim.visible)
		assert(battle.active_temporary_effect_count() == 0 and not battle._running)

	battle.queue_free()
	audio.queue_free()
	attacker.queue_free()
	victim.queue_free()
	await process_frame
	print("PASS: shared capture timeline latches speed and cancels cleanly before impact, during reaction, and during recovery.")
	quit(0)


func _reset_pair(attacker, victim) -> void:
	attacker.cancel_presentation_motion()
	victim.cancel_presentation_motion()
	attacker.global_position = Vector3(0.0, 0.0, 3.0)
	victim.global_position = Vector3(0.0, 0.0, -3.0)
	attacker.visible = true
	victim.visible = true
	attacker.start_battle_stance()
	victim.start_battle_stance()


func _assert_subsequence(actual: Array[StringName], expected: Array[StringName]) -> void:
	var next_index := 0
	for stage in actual:
		if next_index < expected.size() and stage == expected[next_index]:
			next_index += 1
	assert(next_index == expected.size(), "Missing ordered timeline stages: %s in %s" % [expected, actual])
