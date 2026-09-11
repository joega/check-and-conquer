class_name ChessMove
extends RefCounted

const Types = preload("res://scripts/chess/chess_types.gd")

var from_square := Types.NO_SQUARE
var to_square := Types.NO_SQUARE
var promotion_piece_type := Types.EMPTY
var is_en_passant := false
var is_castle := false


static func create(from: int, to: int, promotion := Types.EMPTY):
	var move = load("res://scripts/chess/chess_move.gd").new()
	move.from_square = from
	move.to_square = to
	move.promotion_piece_type = promotion
	return move


func to_uci() -> String:
	var value := Types.square_name(from_square) + Types.square_name(to_square)
	const PROMOTIONS := {Types.QUEEN: "q", Types.ROOK: "r", Types.BISHOP: "b", Types.KNIGHT: "n"}
	return value + PROMOTIONS.get(promotion_piece_type, "")
