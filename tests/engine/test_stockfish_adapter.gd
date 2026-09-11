extends SceneTree

const Adapter = preload("res://scripts/engine/stockfish_adapter.gd")
const ChessGame = preload("res://scripts/chess/chess_game.gd")

var adapter
var did_ready := false
var received_move := ""
var failure := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	adapter = Adapter.new()
	root.add_child(adapter)
	adapter.uci_ready.connect(func(_name): did_ready = true)
	adapter.bestmove_received.connect(func(uci): received_move = uci)
	adapter.engine_error.connect(func(message): failure = message)
	assert(adapter.start())
	var deadline := Time.get_ticks_msec() + 8000
	while not did_ready and failure.is_empty() and Time.get_ticks_msec() < deadline:
		await create_timer(0.02).timeout
	assert(failure.is_empty(), failure)
	assert(did_ready, "Stockfish did not complete its UCI handshake.")
	# Keep the sequential legality gate tolerant of a heavily loaded CI host;
	# the explicit timeout case below verifies supervision separately.
	adapter.response_timeout_padding_ms = 10000
	var game = ChessGame.new()
	for turn in 100:
		received_move = ""
		assert(adapter.request_move(game.state.to_fen(), 1))
		deadline = Time.get_ticks_msec() + 15000
		while received_move.is_empty() and failure.is_empty() and Time.get_ticks_msec() < deadline:
			await create_timer(0.005).timeout
		assert(failure.is_empty(), failure)
		assert(received_move.length() in [4, 5], "Stockfish did not return a UCI move on turn %d." % (turn + 1))
		assert(game.try_uci(received_move) != null, "Stockfish returned an illegal move on turn %d: %s" % [turn + 1, received_move])
	failure = ""
	# A UCI engine may validly return a move much sooner than its requested
	# movetime, so force only the adapter's deadline state for this supervision
	# branch. The 100 moves above remain a real-process integration gate.
	adapter._thinking = true
	adapter._thinking_deadline_ms = Time.get_ticks_msec() - 1000
	adapter._process(0.0)
	assert(failure == "Stockfish move request timed out.", "Engine timeout must produce a recoverable error.")
	adapter.shutdown()
	print("PASS: Stockfish UCI subprocess completed 100 legal sequential moves and recovers from timeout.")
	quit(0)
