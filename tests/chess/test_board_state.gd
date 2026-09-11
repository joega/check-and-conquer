extends SceneTree

const Types = preload("res://scripts/chess/chess_types.gd")
const BoardStateScript = preload("res://scripts/chess/board_state.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var state = BoardStateScript.starting_position()
	assert(state.to_fen() == Types.STARTING_FEN, "Starting-position FEN must roundtrip.")
	assert(state.get_piece(Types.square_from_name("a1")) == Types.ROOK)
	assert(state.get_piece(Types.square_from_name("e1")) == Types.KING)
	assert(state.get_piece(Types.square_from_name("a8")) == -Types.ROOK)
	assert(state.get_piece(Types.square_from_name("e8")) == -Types.KING)
	assert(state.get_piece(Types.square_from_name("e4")) == Types.EMPTY)
	var fen := "r3k2r/ppp2ppp/2n5/3pP3/8/2N5/PPP2PPP/R3K2R b KQkq e3 17 42"
	assert(BoardStateScript.from_fen(fen).to_fen() == fen, "Complete FEN state must roundtrip.")
	assert(Types.square_name(Types.square_from_name("h8")) == "h8")
	assert(Types.square_from_name("i9") == Types.NO_SQUARE)
	print("PASS: board state and FEN roundtrip.")
	quit(0)
