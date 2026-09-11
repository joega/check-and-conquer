extends SceneTree

const Types = preload("res://scripts/chess/chess_types.gd")
const BoardState = preload("res://scripts/chess/board_state.gd")
const Generator = preload("res://scripts/chess/pseudo_move_generator.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	assert(Generator.generate(BoardState.starting_position()).size() == 20, "Start position must have 20 pseudo-legal moves.")
	var promotion_state = BoardState.from_fen("7k/P7/8/8/8/8/7p/7K w - - 0 1")
	var promotion_moves = Generator.generate(promotion_state).filter(func(move): return move.from_square == Types.square_from_name("a7"))
	assert(promotion_moves.size() == 4, "Pawn promotion must generate Q/R/B/N choices.")
	var ep_state = BoardState.from_fen("7k/8/8/3pP3/8/8/8/7K w - d6 0 1")
	var ep_moves = Generator.generate(ep_state).filter(func(move): return move.is_en_passant)
	assert(ep_moves.size() == 1 and ep_moves[0].to_uci() == "e5d6", "En-passant candidate must be generated.")
	print("PASS: pseudo-legal move generation.")
	quit(0)
