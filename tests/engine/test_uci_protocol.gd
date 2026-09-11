extends SceneTree
const Uci = preload("res://scripts/engine/uci_protocol.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	assert(Uci.parse_bestmove("bestmove e2e4 ponder e7e5") == "e2e4")
	assert(Uci.parse_bestmove("bestmove (none)") == "")
	assert(Uci.position_command("8/8/8/8/8/8/8/K6k w - - 0 1").begins_with("position fen "))
	assert(Uci.go_movetime_command(0) == "go movetime 1")
	print("PASS: UCI protocol formatting and parsing.")
	quit()
