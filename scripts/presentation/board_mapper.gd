class_name BoardMapper
extends RefCounted

const Types = preload("res://scripts/chess/chess_types.gd")
## Four metres per square gives each animated actor enough physical room to be
## readable, while the mapping remains the single source of board scale.
const SQUARE_SIZE_M := 4.0
const BOARD_SIZE_M := SQUARE_SIZE_M * 8.0

static func square_to_world(square: int, square_size := SQUARE_SIZE_M) -> Vector3:
	assert(Types.is_valid_square(square))
	return Vector3((Types.file_of(square) - 3.5) * square_size, 0.0, (Types.rank_of(square) - 3.5) * square_size)

static func world_to_square(world: Vector3, square_size := SQUARE_SIZE_M) -> int:
	var file := floori(world.x / square_size + 4.0)
	var rank := floori(world.z / square_size + 4.0)
	return Types.square_from_file_rank(file, rank)
