class_name PseudoMoveGenerator
extends RefCounted

const Types = preload("res://scripts/chess/chess_types.gd")
const Move = preload("res://scripts/chess/chess_move.gd")


static func generate(state) -> Array:
	var moves: Array = []
	for square in Types.BOARD_SIZE:
		var piece: int = state.get_piece(square)
		if Types.piece_side(piece) != state.side_to_move:
			continue
		match Types.piece_type(piece):
			Types.PAWN: _generate_pawn_moves(state, square, moves)
			Types.KNIGHT: _generate_leaper_moves(state, square, moves, [[1, 2], [2, 1], [2, -1], [1, -2], [-1, -2], [-2, -1], [-2, 1], [-1, 2]])
			Types.BISHOP: _generate_slider_moves(state, square, moves, [[1, 1], [1, -1], [-1, -1], [-1, 1]])
			Types.ROOK: _generate_slider_moves(state, square, moves, [[1, 0], [-1, 0], [0, 1], [0, -1]])
			Types.QUEEN: _generate_slider_moves(state, square, moves, [[1, 1], [1, -1], [-1, -1], [-1, 1], [1, 0], [-1, 0], [0, 1], [0, -1]])
			Types.KING:
				_generate_leaper_moves(state, square, moves, [[1, 1], [1, 0], [1, -1], [0, -1], [-1, -1], [-1, 0], [-1, 1], [0, 1]])
				_generate_castle_candidates(state, square, moves)
	return moves


static func _generate_pawn_moves(state, square: int, moves: Array) -> void:
	var side: int = state.side_to_move
	var file: int = Types.file_of(square)
	var rank: int = Types.rank_of(square)
	var direction: int = side
	var start_rank: int = 1 if side == Types.WHITE else 6
	var promotion_rank: int = 7 if side == Types.WHITE else 0
	var one_step: int = Types.square_from_file_rank(file, rank + direction)
	if one_step != Types.NO_SQUARE and state.get_piece(one_step) == Types.EMPTY:
		_append_pawn_move(moves, square, one_step, promotion_rank)
		var two_step: int = Types.square_from_file_rank(file, rank + direction * 2)
		if rank == start_rank and state.get_piece(two_step) == Types.EMPTY:
			moves.append(Move.create(square, two_step))
	for file_delta in [-1, 1]:
		var target: int = Types.square_from_file_rank(file + file_delta, rank + direction)
		if target == Types.NO_SQUARE:
			continue
		if Types.piece_side(state.get_piece(target)) == -side:
			_append_pawn_move(moves, square, target, promotion_rank)
		elif target == state.en_passant_square and state.get_piece(target - 8 * side) == -side * Types.PAWN:
			var move = Move.create(square, target)
			move.is_en_passant = true
			moves.append(move)


static func _append_pawn_move(moves: Array, from: int, to: int, promotion_rank: int) -> void:
	if Types.rank_of(to) == promotion_rank:
		for promotion in [Types.QUEEN, Types.ROOK, Types.BISHOP, Types.KNIGHT]:
			moves.append(Move.create(from, to, promotion))
	else:
		moves.append(Move.create(from, to))


static func _generate_leaper_moves(state, square: int, moves: Array, offsets: Array) -> void:
	var own_side: int = state.side_to_move
	for offset in offsets:
		var target: int = Types.square_from_file_rank(Types.file_of(square) + offset[0], Types.rank_of(square) + offset[1])
		if target != Types.NO_SQUARE and Types.piece_side(state.get_piece(target)) != own_side and Types.piece_type(state.get_piece(target)) != Types.KING:
			moves.append(Move.create(square, target))


static func _generate_slider_moves(state, square: int, moves: Array, directions: Array) -> void:
	var own_side: int = state.side_to_move
	for direction in directions:
		var file: int = Types.file_of(square) + direction[0]
		var rank: int = Types.rank_of(square) + direction[1]
		while true:
			var target: int = Types.square_from_file_rank(file, rank)
			if target == Types.NO_SQUARE:
				break
			var target_piece: int = state.get_piece(target)
			if Types.piece_side(target_piece) == own_side:
				break
			if Types.piece_type(target_piece) != Types.KING:
				moves.append(Move.create(square, target))
			if target_piece != Types.EMPTY:
				break
			file += direction[0]
			rank += direction[1]


static func _generate_castle_candidates(state, square: int, moves: Array) -> void:
	var kingside_right := Types.CASTLE_WHITE_KINGSIDE if state.side_to_move == Types.WHITE else Types.CASTLE_BLACK_KINGSIDE
	var queenside_right := Types.CASTLE_WHITE_QUEENSIDE if state.side_to_move == Types.WHITE else Types.CASTLE_BLACK_QUEENSIDE
	var rank := 0 if state.side_to_move == Types.WHITE else 7
	if square != Types.square_from_file_rank(4, rank):
		return
	if state.castling_rights & kingside_right and state.get_piece(Types.square_from_file_rank(7, rank)) == state.side_to_move * Types.ROOK and state.get_piece(Types.square_from_file_rank(5, rank)) == Types.EMPTY and state.get_piece(Types.square_from_file_rank(6, rank)) == Types.EMPTY:
		var king_side = Move.create(square, Types.square_from_file_rank(6, rank))
		king_side.is_castle = true
		moves.append(king_side)
	if state.castling_rights & queenside_right and state.get_piece(Types.square_from_file_rank(0, rank)) == state.side_to_move * Types.ROOK and state.get_piece(Types.square_from_file_rank(1, rank)) == Types.EMPTY and state.get_piece(Types.square_from_file_rank(2, rank)) == Types.EMPTY and state.get_piece(Types.square_from_file_rank(3, rank)) == Types.EMPTY:
		var queen_side = Move.create(square, Types.square_from_file_rank(2, rank))
		queen_side.is_castle = true
		moves.append(queen_side)
