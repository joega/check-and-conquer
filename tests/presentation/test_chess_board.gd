extends SceneTree

const BOARD_SCENE = preload("res://scenes/board/ChessBoard.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var board = BOARD_SCENE.instantiate()
	root.add_child(board)
	await process_frame
	assert(board.tiles.size() == 64, "The visible board must retain all 64 clickable squares.")
	assert(board.coordinate_label_count() == 16, "Board-edge coordinates must provide every file and rank without covering actors.")
	assert(board.get_node_or_null("Coordinate_a") != null and board.get_node_or_null("Coordinate_8") != null, "Board coordinates must include standard chess file and rank labels.")
	assert(board.get_node_or_null("BoardPedestal") != null, "The playable grid must sit on a physical board pedestal.")
	var rail_count := 0
	var rune_count := 0
	for child in board.get_children():
		if child.name.begins_with("BoardBronzeRail"): rail_count += 1
		if child.name.begins_with("BoardCornerRune"): rune_count += 1
	assert(rail_count == 4 and rune_count == 4, "The board altar must retain its complete frame and four corner runes.")
	board.queue_free()
	print("PASS: chess board exposes square coordinates without changing tile mapping.")
	quit()
