class_name TurnController
extends Node

const ChessGame = preload("res://scripts/chess/chess_game.gd")

enum Phase { READY, PLAYER_INPUT, PRESENTING_MOVE, ENGINE_THINKING, GAME_OVER }

var game = ChessGame.new()
var phase := Phase.READY

func start() -> void:
	phase = Phase.PLAYER_INPUT

func submit_uci(uci: String):
	if phase != Phase.PLAYER_INPUT: return null
	var result = game.try_uci(uci)
	if result == null: return null
	phase = Phase.GAME_OVER if result.game_result != "ongoing" else Phase.PRESENTING_MOVE
	return result

func presentation_finished() -> void:
	if phase == Phase.PRESENTING_MOVE: phase = Phase.PLAYER_INPUT


func begin_engine_turn() -> bool:
	if phase != Phase.PLAYER_INPUT or game.game_result() != "ongoing":
		return false
	phase = Phase.ENGINE_THINKING
	return true


func submit_engine_uci(uci: String):
	if phase != Phase.ENGINE_THINKING:
		return null
	var result = game.try_uci(uci)
	if result == null:
		return null
	phase = Phase.GAME_OVER if result.game_result != "ongoing" else Phase.PRESENTING_MOVE
	return result


func engine_failed() -> void:
	if phase == Phase.ENGINE_THINKING:
		phase = Phase.PLAYER_INPUT


func undo(plies: int = 1) -> int:
	if phase != Phase.PLAYER_INPUT:
		return 0
	var undone := 0
	while undone < plies and not game.undo_last_move().is_empty():
		undone += 1
	return undone
