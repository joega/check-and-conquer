extends SceneTree

const LAB_SCENE = preload("res://scenes/debug/DebugCinematicLab.tscn")
const CINEMATIC = preload("res://scenes/presentation/CampaignCinematic.tscn")
const BoardCamera = preload("res://scripts/presentation/board_camera_controller.gd")
const BoardState = preload("res://scripts/chess/board_state.gd")

const OPENING_FEN := "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lab = LAB_SCENE.instantiate()
	root.add_child(lab)
	await process_frame
	await process_frame
	for delay_s in [0.15, 1.35, 2.5]:
		lab._play()
		await create_timer(delay_s).timeout
		lab.get_node("CampaignCinematic").skip()
		await _assert_restored(lab, "Skip after %.2fs" % delay_s)
		# Existing actor travel lasted at most 1.1 seconds. A later callback must
		# not resume a cancelled root movement after cleanup.
		var homes := _actor_transforms(lab.get_node("BoardPresenter"))
		await create_timer(1.35).timeout
		_assert_transforms(lab.get_node("BoardPresenter"), homes, "Cancelled roots must stay settled after their former travel duration.")
	# Replay cancels the first run without sending its stale completion, then the
	# second Skip performs the one visible handoff.
	var completions := [0]
	lab.get_node("CampaignCinematic").finished.connect(func(_run_id, _reason): completions[0] += 1)
	lab._play()
	await create_timer(0.12).timeout
	lab._play() # guarded while active; use the director directly to exercise replay.
	lab.get_node("CampaignCinematic").play_mountain_intro(1, lab.get_node("GrandmasterCeremony").prepare(lab.get_node("BoardPresenter"), 1), lab.get_node("GrandmasterCeremony"))
	await create_timer(0.12).timeout
	lab.get_node("CampaignCinematic").skip()
	await _assert_restored(lab, "Replay")
	lab.get_node("CampaignCinematic").skip()
	await process_frame
	assert(completions[0] == 1, "Replay plus Skip must emit only the active run's completion.")
	# Accelerated director timing reaches its late return/materialization cues,
	# while Ceremony keeps its actor travel on real tweens. Both paths must still
	# restore exactly when interrupted.
	lab._start_sequence(10.0)
	await create_timer(1.4).timeout
	assert(lab.get_node("CampaignCinematic").is_active(), "Late Skip fixture must still be active during materialization.")
	lab.get_node("CampaignCinematic").skip()
	await _assert_restored(lab, "Late Skip during materialization")
	lab._start_sequence(10.0)
	await create_timer(1.4).timeout
	lab._reset()
	await _assert_restored(lab, "Reset during return/materialization")
	# Teardown calls the same cleanup path and cannot leave borrowed roots moving.
	lab._play()
	await create_timer(0.18).timeout
	lab.get_node("CampaignCinematic").queue_free()
	await process_frame
	assert(lab.get_node("BoardPresenter").matches_state(BoardState.from_fen(OPENING_FEN)), "Director teardown must restore the authoritative board projection.")
	lab.queue_free()
	await process_frame
	await _assert_async_missing_overlay()
	print("PASS: cinematic cancellation, replay, reset, teardown, and asynchronous fallback preserve actor and camera ownership.")
	quit(0)


func _assert_restored(lab, label: String) -> void:
	var deadline := Time.get_ticks_msec() + 1500
	while lab.get_node("CampaignCinematic").is_active() and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not lab.get_node("CampaignCinematic").is_active(), "%s did not settle the cinematic." % label)
	assert(lab.get_node("BoardCamera").controls_enabled() and lab.get_node("BoardCamera").current, "%s did not restore board-camera ownership." % label)
	assert(lab.get_node("BoardPresenter").matches_state(BoardState.from_fen(OPENING_FEN)), "%s did not restore the authoritative board projection." % label)


func _actor_transforms(board) -> Dictionary:
	var result := {}
	for square in board.actors:
		result[square] = board.actors[square].global_transform
	return result


func _assert_transforms(board, expected: Dictionary, message: String) -> void:
	for square in expected:
		assert(board.actors[square].global_transform.is_equal_approx(expected[square]), message)


func _assert_async_missing_overlay() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var board_camera := BoardCamera.new()
	board_camera.name = "BoardCamera"
	board_camera.current = true
	stage.add_child(board_camera)
	var cinematic = CINEMATIC.instantiate()
	cinematic.board_camera_path = NodePath("../BoardCamera")
	cinematic.cinematic_camera_path = NodePath("CinematicCamera")
	cinematic.overlay_path = NodePath("MissingOverlay")
	stage.add_child(cinematic)
	await process_frame
	var returned_from_play := [false]
	var emitted_after_return := [false]
	cinematic.finished.connect(func(_run_id, _reason): emitted_after_return[0] = returned_from_play[0])
	cinematic.play_mountain_intro(1)
	returned_from_play[0] = true
	var deadline := Time.get_ticks_msec() + 500
	while not emitted_after_return[0] and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(emitted_after_return[0], "Missing-overlay fallback must complete asynchronously after the caller can await it.")
	assert(board_camera.controls_enabled() and board_camera.current)
	stage.queue_free()
