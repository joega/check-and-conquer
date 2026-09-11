extends SceneTree
const Types = preload("res://scripts/chess/chess_types.gd")
const Mapper = preload("res://scripts/presentation/board_mapper.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	for square in Types.BOARD_SIZE:
		assert(Mapper.world_to_square(Mapper.square_to_world(square)) == square)
	assert(Mapper.world_to_square(Vector3(16.1, 0, 0)) == Types.NO_SQUARE)
	assert(Mapper.square_to_world(Types.square_from_name("a1")).distance_to(Mapper.square_to_world(Types.square_from_name("b1"))) == Mapper.SQUARE_SIZE_M)
	print("PASS: board-square world mapping.")
	quit()
