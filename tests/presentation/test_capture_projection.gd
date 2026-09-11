extends SceneTree
const Game = preload("res://scripts/chess/chess_game.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var game = Game.new()
	assert(game.try_uci("e2e4") != null)
	assert(game.try_uci("d7d5") != null)
	var result = game.try_uci("e4d5")
	assert(result.is_capture and result.captured_piece == -1)
	assert(game.state.get_piece(result.to_square) == 1)
	print("PASS: committed capture result is ready for battle presentation.")
	quit()
