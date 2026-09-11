class_name BoardState
extends RefCounted

const Types = preload("res://scripts/chess/chess_types.gd")

var squares: Array[int] = []
var side_to_move := Types.WHITE
var castling_rights := 0
var en_passant_square := Types.NO_SQUARE
var halfmove_clock := 0
var fullmove_number := 1


func _init() -> void:
	squares.resize(Types.BOARD_SIZE)
	squares.fill(Types.EMPTY)


static func starting_position():
	return from_fen(Types.STARTING_FEN)


static func from_fen(fen: String):
	var fields := fen.strip_edges().split(" ", false)
	assert(fields.size() == 6, "FEN must have six fields.")
	var state = load("res://scripts/chess/board_state.gd").new()
	var ranks := fields[0].split("/", false)
	assert(ranks.size() == 8, "FEN must have eight ranks.")
	for fen_rank in ranks.size():
		var file := 0
		for symbol in ranks[fen_rank]:
			if symbol >= "1" and symbol <= "8":
				file += int(symbol)
			else:
				var piece := Types.piece_from_fen(symbol)
				assert(piece != Types.EMPTY, "FEN contains an invalid piece symbol.")
				assert(file < 8, "FEN rank overflows the board.")
				state.squares[Types.square_from_file_rank(file, 7 - fen_rank)] = piece
				file += 1
		assert(file == 8, "FEN rank must contain eight files.")
	assert(fields[1] == "w" or fields[1] == "b", "FEN side-to-move must be w or b.")
	state.side_to_move = Types.WHITE if fields[1] == "w" else Types.BLACK
	state.castling_rights = _castling_rights_from_fen(fields[2])
	state.en_passant_square = Types.NO_SQUARE if fields[3] == "-" else Types.square_from_name(fields[3])
	assert(fields[3] == "-" or state.en_passant_square != Types.NO_SQUARE, "FEN en-passant square is invalid.")
	state.halfmove_clock = int(fields[4])
	state.fullmove_number = int(fields[5])
	assert(state.halfmove_clock >= 0 and state.fullmove_number >= 1, "FEN move counters are invalid.")
	return state


func to_fen() -> String:
	var rank_fields: Array[String] = []
	for rank in range(7, -1, -1):
		var empty_count := 0
		var rank_field := ""
		for file in 8:
			var piece := squares[Types.square_from_file_rank(file, rank)]
			if piece == Types.EMPTY:
				empty_count += 1
			else:
				if empty_count > 0:
					rank_field += str(empty_count)
					empty_count = 0
				rank_field += Types.piece_to_fen(piece)
		if empty_count > 0:
			rank_field += str(empty_count)
		rank_fields.append(rank_field)
	return "%s %s %s %s %d %d" % [
		"/".join(rank_fields),
		"w" if side_to_move == Types.WHITE else "b",
		_castling_rights_to_fen(castling_rights),
		Types.square_name(en_passant_square),
		halfmove_clock,
		fullmove_number,
	]


func get_piece(square: int) -> int:
	assert(Types.is_valid_square(square), "Square is outside the board.")
	return squares[square]


func set_piece(square: int, piece: int) -> void:
	assert(Types.is_valid_square(square), "Square is outside the board.")
	assert(abs(piece) <= Types.KING, "Piece value is invalid.")
	squares[square] = piece


func copy():
	var result = load("res://scripts/chess/board_state.gd").new()
	result.squares = squares.duplicate()
	result.side_to_move = side_to_move
	result.castling_rights = castling_rights
	result.en_passant_square = en_passant_square
	result.halfmove_clock = halfmove_clock
	result.fullmove_number = fullmove_number
	return result


func apply_move(move) -> void:
	var piece := get_piece(move.from_square)
	var moving_piece_type := Types.piece_type(piece)
	var moving_side := Types.piece_side(piece)
	assert(moving_side == side_to_move, "Move side does not match side to move.")
	var captured_piece := get_piece(move.to_square)
	set_piece(move.from_square, Types.EMPTY)
	if move.is_en_passant:
		var capture_square: int = move.to_square - 8 * moving_side
		captured_piece = get_piece(capture_square)
		set_piece(capture_square, Types.EMPTY)
	if move.is_castle:
		var rook_from: int = move.from_square + (3 if move.to_square > move.from_square else -4)
		var rook_to: int = move.from_square + (1 if move.to_square > move.from_square else -1)
		set_piece(rook_to, get_piece(rook_from))
		set_piece(rook_from, Types.EMPTY)
	if move.promotion_piece_type != Types.EMPTY:
		piece = moving_side * move.promotion_piece_type
	set_piece(move.to_square, piece)
	_update_castling_rights(move.from_square, move.to_square, piece, captured_piece)
	en_passant_square = Types.NO_SQUARE
	if Types.piece_type(piece) == Types.PAWN and abs(move.to_square - move.from_square) == 16:
		en_passant_square = move.from_square + 8 * moving_side
	halfmove_clock = 0 if moving_piece_type == Types.PAWN or captured_piece != Types.EMPTY else halfmove_clock + 1
	if moving_side == Types.BLACK:
		fullmove_number += 1
	side_to_move = -side_to_move


func _update_castling_rights(from: int, to: int, piece: int, captured_piece: int) -> void:
	if Types.piece_type(piece) == Types.KING:
		castling_rights &= ~(Types.CASTLE_WHITE_KINGSIDE | Types.CASTLE_WHITE_QUEENSIDE) if Types.piece_side(piece) == Types.WHITE else ~(Types.CASTLE_BLACK_KINGSIDE | Types.CASTLE_BLACK_QUEENSIDE)
	for square in [from, to]:
		match square:
			0: castling_rights &= ~Types.CASTLE_WHITE_QUEENSIDE
			7: castling_rights &= ~Types.CASTLE_WHITE_KINGSIDE
			56: castling_rights &= ~Types.CASTLE_BLACK_QUEENSIDE
			63: castling_rights &= ~Types.CASTLE_BLACK_KINGSIDE


static func _castling_rights_from_fen(value: String) -> int:
	if value == "-":
		return 0
	var rights := 0
	for symbol in value:
		match symbol:
			"K": rights |= Types.CASTLE_WHITE_KINGSIDE
			"Q": rights |= Types.CASTLE_WHITE_QUEENSIDE
			"k": rights |= Types.CASTLE_BLACK_KINGSIDE
			"q": rights |= Types.CASTLE_BLACK_QUEENSIDE
			_: assert(false, "FEN castling field is invalid.")
	return rights


static func _castling_rights_to_fen(rights: int) -> String:
	var value := ""
	if rights & Types.CASTLE_WHITE_KINGSIDE: value += "K"
	if rights & Types.CASTLE_WHITE_QUEENSIDE: value += "Q"
	if rights & Types.CASTLE_BLACK_KINGSIDE: value += "k"
	if rights & Types.CASTLE_BLACK_QUEENSIDE: value += "q"
	return value if not value.is_empty() else "-"
