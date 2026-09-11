class_name StockfishAdapter
extends Node

## Owns one unmodified UCI engine process. The process pipes are polled from
## Godot's main loop, keeping the UI responsive while an engine is thinking.

const Uci = preload("res://scripts/engine/uci_protocol.gd")

signal uci_ready(engine_name: String)
signal bestmove_received(uci: String)
signal engine_error(message: String)
signal engine_line(line: String)

@export_file var executable_path := "res://third_party/stockfish/linux-x86_64/stockfish/stockfish-linux-x86-64-universal"
@export var response_timeout_padding_ms := 2500

var _stdio: FileAccess
var _stderr: FileAccess
var _pid := -1
var _engine_name := ""
var _awaiting_uciok := false
var _awaiting_readyok := false
var _thinking := false
var _thinking_deadline_ms := 0


func start() -> bool:
	if is_running():
		return true
	var absolute_path := resolved_executable_path()
	if absolute_path.is_empty():
		engine_error.emit("Stockfish executable was not found: %s" % executable_path)
		return false
	var process: Dictionary = OS.execute_with_pipe(absolute_path, [], false)
	if process.is_empty() or not process.has("stdio"):
		engine_error.emit("Could not start Stockfish at %s" % executable_path)
		return false
	_stdio = process.stdio
	_stderr = process.stderr
	_pid = int(process.pid)
	_awaiting_uciok = true
	_send("uci")
	return true


func is_running() -> bool:
	return _pid > 0 and _stdio != null


func is_ready_for_requests() -> bool:
	return is_running() and not _awaiting_uciok and not _awaiting_readyok


## Development runs use the project copy. Linux exports place the executable
## beside the game because a file inside a PCK cannot be launched as a process.
func resolved_executable_path() -> String:
	var bundled_path := OS.get_executable_path().get_base_dir().path_join("stockfish/stockfish-linux-x86-64-universal")
	if FileAccess.file_exists(bundled_path):
		return bundled_path
	if FileAccess.file_exists(executable_path):
		return ProjectSettings.globalize_path(executable_path)
	return ""


func request_move(fen: String, movetime_ms: int) -> bool:
	if not is_running() or _awaiting_uciok or _awaiting_readyok:
		engine_error.emit("Stockfish is not ready for a move request.")
		return false
	if _thinking:
		engine_error.emit("Stockfish is already thinking.")
		return false
	_thinking = true
	_thinking_deadline_ms = Time.get_ticks_msec() + max(movetime_ms + response_timeout_padding_ms, 1000)
	_send(Uci.position_command(fen))
	_send(Uci.go_movetime_command(movetime_ms))
	return true


func configure_difficulty(skill_level: int, elo: int = 1320) -> void:
	if not is_running():
		return
	_send("setoption name Skill Level value %d" % clampi(skill_level, 0, 20))
	if skill_level < 20:
		_send("setoption name UCI_LimitStrength value true")
		_send("setoption name UCI_Elo value %d" % clampi(elo, 1320, 3190))
	else:
		_send("setoption name UCI_LimitStrength value false")
	_send("isready")
	_awaiting_readyok = true


func new_game() -> void:
	if not is_running():
		return
	stop_thinking()
	_send("ucinewgame")
	_send("isready")
	_awaiting_readyok = true


func stop_thinking() -> void:
	if is_running() and _thinking:
		_send("stop")
	_thinking = false
	_thinking_deadline_ms = 0


func shutdown() -> void:
	if is_running():
		_send("quit")
		OS.kill(_pid)
	_stdio = null
	_stderr = null
	_pid = -1
	_thinking = false


func _exit_tree() -> void:
	shutdown()


func _process(_delta: float) -> void:
	_read_available(_stdio)
	_read_available(_stderr)
	if _thinking and Time.get_ticks_msec() > _thinking_deadline_ms:
		stop_thinking()
		engine_error.emit("Stockfish move request timed out.")


func _send(command: String) -> void:
	_stdio.store_line(command)
	_stdio.flush()


func _read_available(pipe: FileAccess) -> void:
	if pipe == null:
		return
	while true:
		var line := pipe.get_line().strip_edges()
		if line.is_empty():
			return
		_handle_line(line)


func _handle_line(line: String) -> void:
	engine_line.emit(line)
	if line.begins_with("id name "):
		_engine_name = line.trim_prefix("id name ")
	if line == "uciok":
		_awaiting_uciok = false
		_awaiting_readyok = true
		_send("isready")
		return
	if line == "readyok":
		_awaiting_readyok = false
		uci_ready.emit(_engine_name)
		return
	var move := Uci.parse_bestmove(line)
	if not move.is_empty():
		_thinking = false
		_thinking_deadline_ms = 0
		bestmove_received.emit(move)
