extends SceneTree

const BoardState = preload("res://scripts/chess/board_state.gd")
const Legal = preload("res://scripts/chess/legal_move_generator.gd")
const Result = preload("res://scripts/chess/game_result.gd")


func _init() -> void:
	call_deferred("_run")


func _perft(state, depth: int) -> int:
	if depth == 0: return 1
	var nodes := 0
	for move in Legal.generate(state):
		var next = state.copy()
		next.apply_move(move)
		nodes += _perft(next, depth - 1)
	return nodes


func _run() -> void:
	var state = BoardState.starting_position()
	assert(Legal.generate(state).size() == 20)
	assert(_perft(state, 2) == 400)
	assert(_perft(state, 3) == 8902)
	assert(_perft(state, 4) == 197281)
	var castle_state = BoardState.from_fen("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
	var castles = Legal.generate(castle_state).filter(func(move): return move.is_castle)
	assert(castles.size() == 2, "Both white castling candidates must be legal on an empty home rank.")
	var pinned = BoardState.from_fen("4r2k/8/8/8/8/8/4R3/4K3 w - - 0 1")
	assert(Legal.generate(pinned).filter(func(move): return move.from_square == 12 and move.to_square != 4).all(func(move): return move.to_square % 8 == 4), "Pinned rook must not expose its king.")
	assert(Result.status(BoardState.from_fen("7k/5Q2/7K/8/8/8/8/8 b - - 0 1")) == "stalemate")
	assert(Result.status(BoardState.from_fen("7k/6Q1/7K/8/8/8/8/8 b - - 0 1")) == "checkmate")
	assert(Result.status(BoardState.from_fen("7k/8/8/8/8/8/8/7K w - - 0 1")) == "draw_insufficient_material")
	assert(Result.status(BoardState.from_fen("7k/8/8/8/5b2/8/8/2B4K w - - 0 1")) == "draw_insufficient_material", "Same-colour bishops cannot produce mate.")
	var castle_through_check = BoardState.from_fen("4kr2/8/8/8/8/8/8/4K2R w K - 0 1")
	assert(Legal.generate(castle_through_check).filter(func(move): return move.is_castle).is_empty(), "King cannot castle through an attacked square.")
	var ep_pin = BoardState.from_fen("k3r3/8/8/3pP3/8/8/8/4K3 w - d6 0 1")
	assert(Legal.generate(ep_pin).filter(func(move): return move.is_en_passant).is_empty(), "En-passant cannot expose the moving side's king.")
	var king_target = BoardState.from_fen("4k3/4R3/8/8/8/8/8/K7 w - - 0 1")
	assert(Legal.generate(king_target).filter(func(move): return move.to_uci() == "e7e8").is_empty(), "Kings are never capturable chess targets.")
	print("PASS: legal move generation through perft depth 4.")
	quit(0)
