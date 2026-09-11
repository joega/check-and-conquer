extends SceneTree
const ChessGame = preload("res://scripts/chess/chess_game.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var game = ChessGame.new()
	for uci in ["e2e4", "e7e5", "g1f3", "b8c6", "f1c4", "g8f6", "e1g1"]:
		assert(game.try_uci(uci) != null, "Expected legal scripted move: %s" % uci)
	assert(game.state.get_piece(6) == 6 and game.state.get_piece(5) == 4, "Castled king and rook must occupy g1/f1.")
	print("PASS: scripted local game through castling.")
	quit()
