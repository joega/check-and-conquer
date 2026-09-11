class_name ChessTypes
extends RefCounted

const BOARD_SIZE := 64
const NO_SQUARE := -1

const WHITE := 1
const BLACK := -1

const EMPTY := 0
const PAWN := 1
const KNIGHT := 2
const BISHOP := 3
const ROOK := 4
const QUEEN := 5
const KING := 6

const CASTLE_WHITE_KINGSIDE := 1
const CASTLE_WHITE_QUEENSIDE := 2
const CASTLE_BLACK_KINGSIDE := 4
const CASTLE_BLACK_QUEENSIDE := 8

const STARTING_FEN := "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"


static func is_valid_square(square: int) -> bool:
	return square >= 0 and square < BOARD_SIZE


static func file_of(square: int) -> int:
	return square % 8


static func rank_of(square: int) -> int:
	return square / 8


static func square_from_file_rank(file: int, rank: int) -> int:
	if file < 0 or file > 7 or rank < 0 or rank > 7:
		return NO_SQUARE
	return rank * 8 + file


static func square_from_name(name: String) -> int:
	if name.length() != 2:
		return NO_SQUARE
	var file := name.unicode_at(0) - "a".unicode_at(0)
	var rank := name.unicode_at(1) - "1".unicode_at(0)
	return square_from_file_rank(file, rank)


static func square_name(square: int) -> String:
	if not is_valid_square(square):
		return "-"
	return "%s%s" % [char("a".unicode_at(0) + file_of(square)), rank_of(square) + 1]


static func piece_side(piece: int) -> int:
	if piece > 0:
		return WHITE
	if piece < 0:
		return BLACK
	return EMPTY


static func piece_type(piece: int) -> int:
	return abs(piece)


static func piece_from_fen(symbol: String) -> int:
	const SYMBOLS := {
		"P": PAWN, "N": KNIGHT, "B": BISHOP, "R": ROOK, "Q": QUEEN, "K": KING,
		"p": -PAWN, "n": -KNIGHT, "b": -BISHOP, "r": -ROOK, "q": -QUEEN, "k": -KING,
	}
	return SYMBOLS.get(symbol, EMPTY)


static func piece_to_fen(piece: int) -> String:
	const SYMBOLS := {
		PAWN: "P", KNIGHT: "N", BISHOP: "B", ROOK: "R", QUEEN: "Q", KING: "K",
		-PAWN: "p", -KNIGHT: "n", -BISHOP: "b", -ROOK: "r", -QUEEN: "q", -KING: "k",
	}
	return SYMBOLS.get(piece, "")
