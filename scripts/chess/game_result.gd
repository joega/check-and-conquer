class_name GameResult
extends RefCounted

const Types = preload("res://scripts/chess/chess_types.gd")
const Legal = preload("res://scripts/chess/legal_move_generator.gd")

static func status(state) -> String:
	var legal_moves = Legal.generate(state)
	if legal_moves.is_empty():
		return "checkmate" if Legal._is_in_check(state, state.side_to_move) else "stalemate"
	if _insufficient_material(state): return "draw_insufficient_material"
	if state.halfmove_clock >= 100: return "draw_fifty_move"
	return "ongoing"

static func is_threefold_repetition(position_keys: Array[String], current_key: String) -> bool:
	var occurrences := 0
	for key in position_keys:
		if key == current_key: occurrences += 1
	return occurrences >= 3

static func _insufficient_material(state) -> bool:
	var minors: Array[Dictionary] = []
	for square in Types.BOARD_SIZE:
		var piece: int = state.get_piece(square)
		var type := Types.piece_type(piece)
		if type in [Types.PAWN, Types.ROOK, Types.QUEEN]: return false
		if type in [Types.BISHOP, Types.KNIGHT]:
			minors.append({"piece": piece, "square": square})
	if minors.size() <= 1:
		return true
	# Opposing minor pieces can act as legal blockers in a mating position, so
	# K+N versus K+N (and mixed bishop/knight endings) is not dead merely
	# because neither side can force mate. Only all-bishop material confined to
	# one board colour is inherently incapable of ever mating.
	var bishop_colour := -1
	for minor in minors:
		if Types.piece_type(minor.piece) != Types.BISHOP:
			return false
		var colour: int = (Types.file_of(minor.square) + Types.rank_of(minor.square)) % 2
		if bishop_colour == -1:
			bishop_colour = colour
		elif bishop_colour != colour:
			return false
	return true
