class_name LegalMoveGenerator
extends RefCounted

const Types = preload("res://scripts/chess/chess_types.gd")
const Pseudo = preload("res://scripts/chess/pseudo_move_generator.gd")


static func generate(state) -> Array:
	var legal: Array = []
	for move in Pseudo.generate(state):
		if move.is_castle and (_is_in_check(state, state.side_to_move) or _castle_crosses_attack(state, move)):
			continue
		var next_state = state.copy()
		next_state.apply_move(move)
		if not _is_in_check(next_state, state.side_to_move):
			legal.append(move)
	return legal


static func _castle_crosses_attack(state, move) -> bool:
	var through_square: int = move.from_square + (1 if move.to_square > move.from_square else -1)
	return _is_attacked(state, through_square, -state.side_to_move)


static func _is_in_check(state, side: int) -> bool:
	var king_square := Types.NO_SQUARE
	for square in Types.BOARD_SIZE:
		if state.get_piece(square) == side * Types.KING:
			king_square = square
			break
	return king_square == Types.NO_SQUARE or _is_attacked(state, king_square, -side)


## Presentation may ask for a plain-language coaching warning, but the chess
## domain remains the sole authority for whether a square is attacked.
static func is_square_attacked(state, square: int, by_side: int) -> bool:
	return _is_attacked(state, square, by_side)


static func _is_attacked(state, square: int, by_side: int) -> bool:
	for from in Types.BOARD_SIZE:
		var piece: int = state.get_piece(from)
		if Types.piece_side(piece) != by_side:
			continue
		var df: int = abs(Types.file_of(from) - Types.file_of(square))
		var dr: int = Types.rank_of(square) - Types.rank_of(from)
		match Types.piece_type(piece):
			Types.PAWN:
				if abs(Types.file_of(from) - Types.file_of(square)) == 1 and dr == by_side: return true
			Types.KNIGHT:
				if (df == 1 and abs(dr) == 2) or (df == 2 and abs(dr) == 1): return true
			Types.KING:
				if max(df, abs(dr)) == 1: return true
			Types.BISHOP, Types.ROOK, Types.QUEEN:
				if _slider_attacks(state, from, square, Types.piece_type(piece)): return true
	return false


static func _slider_attacks(state, from: int, target: int, type: int) -> bool:
	var dx: int = Types.file_of(target) - Types.file_of(from)
	var dy: int = Types.rank_of(target) - Types.rank_of(from)
	var diagonal: bool = abs(dx) == abs(dy) and dx != 0
	var straight: bool = (dx == 0) != (dy == 0)
	if not ((type == Types.BISHOP and diagonal) or (type == Types.ROOK and straight) or (type == Types.QUEEN and (diagonal or straight))): return false
	var step_x: int = sign(dx)
	var step_y: int = sign(dy)
	var file: int = Types.file_of(from) + step_x
	var rank: int = Types.rank_of(from) + step_y
	while Types.square_from_file_rank(file, rank) != target:
		if state.get_piece(Types.square_from_file_rank(file, rank)) != Types.EMPTY: return false
		file += step_x
		rank += step_y
	return true
