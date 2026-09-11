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
	assert(board.get_node_or_null("LevitationRing") == null, "The physical grand-terrace arena must not retain the earlier floating-altar effect.")
	var rail_count := 0
	var rune_count := 0
	for child in board.get_children():
		if child.name.begins_with("BoardBronzeRail"): rail_count += 1
		if child.name.begins_with("BoardCornerRune"): rune_count += 1
	assert(rail_count == 4 and rune_count == 4, "The board altar must retain its complete frame and four corner runes.")
	board.set_highlights(12, [20, 28])
	assert(board.get_node_or_null("LegalMoveMarker_20") != null and board.get_node_or_null("LegalMoveMarker_28") != null, "Every legal destination must receive an obvious raised green move marker.")
	assert((board.tiles[20].material_override as StandardMaterial3D).emission_energy_multiplier <= 0.18, "Legal squares must retain tonal range beneath explicit move markers.")
	assert(board.get_node_or_null("SelectedMarker_12") != null, "Selection has a perimeter distinct from legal destination rings.")
	board.show_last_move(52, 36)
	assert((board.tiles[52].material_override as StandardMaterial3D).emission_enabled, "The opponent source square must remain visible briefly after a move.")
	board.show_hint(12, 28)
	assert(board.get_node_or_null("HintMarker_12") != null and board.get_node_or_null("SelectedMarker_12") == null, "Hint perimeter must take priority over selection without stacking geometry.")
	board.clear_hint()
	board.set_highlights(-1, [])
	await process_frame
	assert(board.get_node_or_null("LegalMoveMarker_20") == null, "Clearing selection must remove destination markers.")
	assert(board.get_node_or_null("LastMoveMarker_52") != null, "Clearing selection must preserve the last move during decision time.")
	board.clear_last_move()
	assert(board.get_node_or_null("LastMoveMarker_52") == null, "Reset removes stale last-move markers immediately.")
	board.queue_free()
	print("PASS: chess board exposes square coordinates without changing tile mapping.")
	quit()
