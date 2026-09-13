extends SceneTree

const ChessGame = preload("res://scripts/chess/chess_game.gd")
const Presenter = preload("res://scripts/presentation/board_presenter.gd")
const Types = preload("res://scripts/chess/chess_types.gd")
const Mapper = preload("res://scripts/presentation/board_mapper.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var quiet_game = ChessGame.new()
	var quiet_result = quiet_game.try_uci("e2e3")
	var ep_game = ChessGame.new()
	for uci in ["e2e4", "a7a6", "e4e5", "d7d5"]:
		assert(ep_game.try_uci(uci) != null)
	var ep_result = ep_game.try_uci("e5d6")
	var presenter = Presenter.new()
	root.add_child(presenter)
	presenter.rebuild_from_state(ChessGame.new().state)
	await process_frame
	var walking_pawn = presenter.actors[Types.square_from_name("e2")]
	presenter.call_deferred("present_quiet_move", quiet_result)
	await process_frame
	await process_frame
	await create_timer(0.08).timeout
	assert(walking_pawn.current_semantic_state() == &"locomotion.walk.forward", "Quiet root movement must visibly play the normalized walk clip rather than slide in idle.")
	assert(walking_pawn.last_travel_stride_cycles > 1.0, "A four-metre quiet move must advance more than one calibrated gait cycle.")
	await create_timer(0.7).timeout
	assert(walking_pawn.current_semantic_state() == walking_pawn.battle_stance_state(), "Quiet movement must return to that character's battle stance once it reaches the authoritative destination.")
	assert(is_equal_approx(walking_pawn.animation_speed_multiplier(), 1.0), "Locomotion cadence must not leak into the actor's idle or combat animation speed.")
	# Rebuild the position immediately before the committed en-passant result.
	var before_ep = ChessGame.new()
	for uci in ["e2e4", "a7a6", "e4e5", "d7d5"]:
		before_ep.try_uci(uci)
	presenter.rebuild_from_state(before_ep.state)
	await process_frame
	await presenter.present_quiet_move(ep_result)
	assert(not presenter.actors.has(Types.square_from_name("d5")))
	assert(presenter.actors.has(Types.square_from_name("d6")))
	assert(presenter.actors[Types.square_from_name("d6")].global_position.is_equal_approx(Mapper.square_to_world(Types.square_from_name("d6"))))
	var promotion_game = ChessGame.new("7k/P7/8/8/8/8/8/7K w - - 0 1")
	presenter.rebuild_from_state(ChessGame.new("7k/P7/8/8/8/8/8/7K w - - 0 1").state)
	await process_frame
	var promotion = promotion_game.try_uci("a7a8q")
	await presenter.present_quiet_move(promotion)
	assert(presenter.actors[Types.square_from_name("a8")].archetype == Types.QUEEN)
	assert(presenter.actors[Types.square_from_name("a8")].global_position.is_equal_approx(Mapper.square_to_world(Types.square_from_name("a8"))))
	var promotion_capture_game = ChessGame.new("1r5k/P7/8/8/8/8/8/7K w - - 0 1")
	presenter.rebuild_from_state(ChessGame.new("1r5k/P7/8/8/8/8/8/7K w - - 0 1").state)
	await process_frame
	var promotion_capture = promotion_capture_game.try_uci("a7b8r")
	await presenter.present_quiet_move(promotion_capture)
	assert(presenter.actors.size() == 3 and presenter.actors[Types.square_from_name("b8")].archetype == Types.ROOK)
	assert(presenter.actors[Types.square_from_name("b8")].global_position.is_equal_approx(Mapper.square_to_world(Types.square_from_name("b8"))))
	presenter.queue_free()
	print("PASS: en-passant and promotion actors settle on authoritative squares.")
	quit(0)
