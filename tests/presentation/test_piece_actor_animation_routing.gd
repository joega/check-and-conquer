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
	for semantic_id in ual1_states:
		_assert_routes_to(actor, semantic_id, actor._animation_player, actor._animation_player_2)
	for semantic_id in ual2_states:
		_assert_routes_to(actor, semantic_id, actor._animation_player_2, actor._animation_player)
	actor.set_animation_speed(1.75)
	assert(is_equal_approx(actor._animation_player.speed_scale, 1.75))
	assert(is_equal_approx(actor._animation_player_2.speed_scale, 1.75))
	actor.play_state(&"stance.guard_01")
	actor.set_animation_paused(true)
	assert(actor.is_animation_paused(), "Pause state must describe the active UAL2 player.")
	actor.set_animation_paused(false)
	assert(not actor.is_animation_paused())
	actor.play_state(&"locomotion.walk.forward")
	actor.play_state(&"test.missing_state")
	assert(actor.current_semantic_state() == &"idle.neutral", "Missing semantic requests must report their neutral fallback.")
	assert(actor._animation_player.current_animation == &"Idle", "Missing requests must stop locomotion with a known neutral clip.")
	assert(not actor._animation_player_2.is_playing(), "Fallback must stop the inactive library too.")
	assert(actor.state_duration(&"test.missing_state") == 0.0, "Unknown semantic requests have no invented duration.")
	actor.queue_free()
	await process_frame
	print("PASS: PieceActor routes semantic clips to their supplying UAL player and falls back safely.")
	quit(0)


func _assert_routes_to(actor, semantic_id: StringName, expected: AnimationPlayer, inactive: AnimationPlayer) -> void:
	assert(actor.supports_state(semantic_id), "Expected imported clip is missing: %s" % semantic_id)
	actor.play_state(semantic_id)
	assert(actor.current_semantic_state() == semantic_id)
	assert(expected.current_animation == actor._clip_for_state(semantic_id), "Semantic state must play from its owning animation library.")
	assert(not inactive.is_playing(), "Switching animation libraries must stop the previous player.")
