class_name ChessGame
extends RefCounted

const Types = preload("res://scripts/chess/chess_types.gd")
const BoardState = preload("res://scripts/chess/board_state.gd")
const Legal = preload("res://scripts/chess/legal_move_generator.gd")
const Result = preload("res://scripts/chess/game_result.gd")
const MoveResult = preload("res://scripts/chess/move_result.gd")

var state
var move_history: Array = []
var position_keys: Array[String] = []
var state_history: Array = []


func _init(starting_fen := "") -> void:
	state = BoardState.starting_position() if starting_fen.is_empty() else BoardState.from_fen(starting_fen)
	position_keys = [_position_key()]
	state_history = [state.copy()]


func legal_moves() -> Array:
	return Legal.generate(state)


func try_uci(uci: String):
	if uci.length() not in [4, 5]: return null
	var from := Types.square_from_name(uci.left(2))
	var to := Types.square_from_name(uci.substr(2, 2))
	if from == Types.NO_SQUARE or to == Types.NO_SQUARE: return null
	for move in legal_moves():
		if move.to_uci() == uci:
			var result = MoveResult.new()
			result.uci = uci
			result.from_square = from
			result.to_square = to
			result.before_fen = state.to_fen()
			result.moving_piece = state.get_piece(from)
			result.captured_piece = state.get_piece(to)
			result.is_castle = move.is_castle
			result.is_en_passant = move.is_en_passant
			result.en_passant_capture_square = to - 8 * state.side_to_move if move.is_en_passant else Types.NO_SQUARE
			if move.is_en_passant:
				result.captured_piece = state.get_piece(result.en_passant_capture_square)
			result.is_capture = result.captured_piece != Types.EMPTY
			result.is_promotion = move.promotion_piece_type != Types.EMPTY
			result.promotion_piece_type = move.promotion_piece_type
			if move.is_castle:
				result.rook_from = from + (3 if to > from else -4)
				result.rook_to = from + (1 if to > from else -1)
			state.apply_move(move)
			move_history.append(uci)
			position_keys.append(_position_key())
			state_history.append(state.copy())
			result.game_result = game_result()
			result.gives_check = Legal._is_in_check(state, state.side_to_move)
			result.is_checkmate = result.game_result == "checkmate"
			result.is_stalemate = result.game_result == "stalemate"
			result.after_fen = state.to_fen()
			return result
	return null


func undo_last_move() -> String:
	if move_history.is_empty() or state_history.size() <= 1:
		return ""
	var undone: String = move_history.pop_back()
	state_history.pop_back()
	state = state_history.back().copy()
	position_keys.pop_back()
	return undone


func game_result() -> String:
	if Result.is_threefold_repetition(position_keys, _position_key()): return "draw_threefold_repetition"
	return Result.status(state)


func _position_key() -> String:
	var fields: PackedStringArray = state.to_fen().split(" ")
	# FIDE repetition treats the en-passant field as relevant only when an
	# en-passant capture is actually available in this position.
	var en_passant := "-"
	for move in Legal.generate(state):
		if move.is_en_passant:
			en_passant = fields[3]
			break
	return "%s %s %s %s" % [fields[0], fields[1], fields[2], en_passant]
