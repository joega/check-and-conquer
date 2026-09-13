extends SceneTree

const ACTOR_SCENE = preload("res://scenes/actors/PieceActor.tscn")
const BoardState = preload("res://scripts/chess/board_state.gd")
const ChessGame = preload("res://scripts/chess/chess_game.gd")
const Presenter = preload("res://scripts/presentation/board_presenter.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var actor = ACTOR_SCENE.instantiate()
	root.add_child(actor)
	await process_frame
	assert(actor.animation_mixer_count() == 1)
	assert(actor.battle_stance_loops() and not actor.is_animation_paused(), "The repaired neutral idle must remain a continuous loop.")

	var short_duration: float = actor.travel_duration_for_distance(4.0)
	var long_duration: float = actor.travel_duration_for_distance(12.0)
	assert(long_duration > short_duration and long_duration <= 4.0, "Long travel must receive bounded extra time instead of stretching one cycle.")
	actor.move_to_world_position(Vector3(4.0, 0.0, 0.0), short_duration)
	var short_cycles: float = actor.last_travel_stride_cycles
	await create_timer(short_duration * 0.16).timeout
	var start_fraction: float = actor.global_position.x / 4.0
	assert(start_fraction < 0.16, "The root must accelerate into travel instead of starting at full velocity.")
	await _wait_for_motion(actor)
	assert(actor.global_position.is_equal_approx(Vector3(4.0, 0.0, 0.0)), "Travel must settle on the exact requested root position.")

	actor.global_position = Vector3.ZERO
	actor.move_to_world_position(Vector3(12.0, 0.0, 0.0), long_duration)
	assert(is_equal_approx(actor.last_travel_stride_cycles / short_cycles, 3.0), "Stride cycles must scale with world distance.")
	await create_timer(long_duration * 0.84).timeout
	var remaining_fraction: float = (12.0 - actor.global_position.x) / 12.0
	assert(remaining_fraction < 0.16, "The root must enter a planted deceleration phase near arrival.")
	await _wait_for_motion(actor)
	assert(actor.global_position.is_equal_approx(Vector3(12.0, 0.0, 0.0)))

	actor.global_position = Vector3.ZERO
	actor.move_to_world_position(Vector3(8.0, 0.0, 0.0), 1.0)
	await create_timer(0.18).timeout
	actor.set_animation_paused(true)
	var paused_position: Vector3 = actor.global_position
	await create_timer(0.22).timeout
	assert(actor.global_position.is_equal_approx(paused_position), "Pause must stop both skeletal playback and root travel.")
	actor.set_animation_paused(false)
	await _wait_for_motion(actor)
	assert(actor.global_position.is_equal_approx(Vector3(8.0, 0.0, 0.0)), "Resume must complete the same exact travel target.")

	actor.global_position = Vector3.ZERO
	actor.rotation.y = 3.05
	var desired_yaw := -3.05
	var facing_target := Vector3(sin(desired_yaw), 0.0, cos(desired_yaw))
	actor.turn_toward_world_position(facing_target, 0.24)
	await create_timer(0.12).timeout
	assert(absf(actor.rotation.y) > 2.9, "Shortest-yaw turning must cross the PI seam instead of spinning through the front.")
	await _wait_for_turn(actor)
	assert(absf(wrapf(actor.rotation.y - desired_yaw, -PI, PI)) < 0.01, "Animated facing must end at the requested yaw.")

	actor.global_position = Vector3.ZERO
	actor.move_to_world_position(Vector3(10.0, 0.0, 0.0), 1.4)
	await create_timer(0.16).timeout
	actor.cancel_presentation_motion()
	var cancelled_position: Vector3 = actor.global_position
	await create_timer(0.30).timeout
	assert(not actor.is_presentation_moving() and actor.global_position.is_equal_approx(cancelled_position), "Cancellation must prevent stale movement callbacks from mutating the actor.")

	var presenter = Presenter.new()
	root.add_child(presenter)
	presenter.rebuild_from_state(BoardState.starting_position())
	await process_frame
	var old_actor = presenter.actors[12]
	var game = ChessGame.new()
	var result = game.try_uci("e2e4")
	presenter.call_deferred("present_quiet_move", result)
	await create_timer(0.10).timeout
	var replacement_state = BoardState.from_fen("8/8/8/8/8/8/8/K6k w - - 0 1")
	presenter.rebuild_from_state(replacement_state)
	await process_frame
	await create_timer(0.80).timeout
	assert(not is_instance_valid(old_actor), "Rebuild must retire the moving projection actor.")
	assert(presenter.matches_state(replacement_state), "A stale move coroutine must not alter the rebuilt projection.")

	presenter.queue_free()
	actor.queue_free()
	await process_frame
	print("PASS: continuous locomotion, shortest-yaw facing, pause, cancellation, and replacement settle exactly.")
	quit(0)


func _wait_for_motion(actor) -> void:
	var deadline := Time.get_ticks_msec() + 5000
	while actor.is_presentation_moving() and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not actor.is_presentation_moving(), "Movement must complete inside the bounded deadline.")


func _wait_for_turn(actor) -> void:
	var deadline := Time.get_ticks_msec() + 2000
	while actor.is_presentation_turning() and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not actor.is_presentation_turning(), "Facing must complete inside the bounded deadline.")
