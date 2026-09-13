extends SceneTree

const ACTOR_SCENE = preload("res://scenes/actors/PieceActor.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var actor = ACTOR_SCENE.instantiate()
	root.add_child(actor)
	await process_frame
	var ual1_states: Array[StringName] = [
		&"idle.neutral",
		&"locomotion.walk.forward",
		&"attack.sword.slash_01",
	]
	var ual2_states: Array[StringName] = [
		&"idle.watch_01",
		&"combat.idle.sword_01",
		&"attack.sword.heavy_combo_01",
		&"attack.sword.dash_01",
		&"stance.guard_01",
		&"recovery.capture_ready_01",
	]
	assert(actor.animation_mixer_count() == 1, "Compatible libraries must share one blending owner.")
	assert(actor._animation_player.has_animation_library(&"ual1") and actor._animation_player.has_animation_library(&"ual2"), "The blending owner must namespace both imported libraries.")
	for semantic_id in ual1_states:
		_assert_routes_to(actor, semantic_id, "ual1")
	for semantic_id in ual2_states:
		_assert_routes_to(actor, semantic_id, "ual2")
	actor.set_animation_speed(1.75)
	assert(is_equal_approx(actor._animation_player.speed_scale, 1.75))
	actor.play_state(&"stance.guard_01")
	assert(actor.last_transition_duration() > 0.0, "Cross-library semantic changes must request a native blend.")
	actor.set_animation_paused(true)
	assert(actor.is_animation_paused(), "Pause state must describe the active UAL2 player.")
	actor.set_animation_paused(false)
	assert(not actor.is_animation_paused())
	actor.play_state(&"locomotion.walk.forward")
	actor.play_state(&"test.missing_state")
	assert(actor.current_semantic_state() == &"idle.neutral", "Missing semantic requests must report their neutral fallback.")
	assert(actor.active_animation_name() == &"ual1/Idle", "Missing requests must blend to a known neutral clip.")
	assert(actor.state_duration(&"test.missing_state") == 0.0, "Unknown semantic requests have no invented duration.")
	actor.queue_free()
	await process_frame
	print("PASS: PieceActor routes namespaced semantic clips through one blending owner and falls back safely.")
	quit(0)


func _assert_routes_to(actor, semantic_id: StringName, expected_namespace: String) -> void:
	assert(actor.supports_state(semantic_id), "Expected imported clip is missing: %s" % semantic_id)
	actor.play_state(semantic_id)
	assert(actor.current_semantic_state() == semantic_id)
	assert(str(actor.active_animation_name()).begins_with(expected_namespace + "/"), "Semantic state must play from its namespaced source library.")
	assert(actor.active_source_clip() == actor._clip_for_state(semantic_id), "Semantic state must retain its source clip identity.")
