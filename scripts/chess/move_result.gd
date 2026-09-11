class_name MoveResult
extends RefCounted

## Immutable-in-practice facts emitted by the authoritative chess domain after a
## legal move has been committed. Presentation consumes these facts and never
## re-derives capture, castle, or promotion rules from visual actors.

const Types = preload("res://scripts/chess/chess_types.gd")

var uci := ""
var from_square := Types.NO_SQUARE
var to_square := Types.NO_SQUARE
var moving_piece := Types.EMPTY
var captured_piece := Types.EMPTY
var is_capture := false
var is_castle := false
var rook_from := Types.NO_SQUARE
var rook_to := Types.NO_SQUARE
var is_en_passant := false
var en_passant_capture_square := Types.NO_SQUARE
var is_promotion := false
var promotion_piece_type := Types.EMPTY
var gives_check := false
var is_checkmate := false
var is_stalemate := false
var game_result := "ongoing"
var before_fen := ""
var after_fen := ""
