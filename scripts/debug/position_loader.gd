extends Node3D
const BoardState = preload("res://scripts/chess/board_state.gd")
const Presenter = preload("res://scripts/presentation/board_presenter.gd")
func _ready() -> void:
	var presenter = Presenter.new()
	presenter.name = "ActorProjection"
	add_child(presenter)
	$UI/Load.pressed.connect(func(): presenter.rebuild_from_state(BoardState.from_fen($UI/FEN.text)))
	presenter.rebuild_from_state(BoardState.starting_position())
