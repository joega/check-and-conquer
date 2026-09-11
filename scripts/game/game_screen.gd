extends Node3D
const ChessGame = preload("res://scripts/chess/chess_game.gd")
const TurnController = preload("res://scripts/game/turn_controller.gd")
const Types = preload("res://scripts/chess/chess_types.gd")
const Mapper = preload("res://scripts/presentation/board_mapper.gd")
const StockfishAdapter = preload("res://scripts/engine/stockfish_adapter.gd")
const ChoreographyResolver = preload("res://scripts/presentation/capture_choreography_resolver.gd")
const SessionSettings = preload("res://scripts/game/session_settings.gd")
const NOVICE_DIFFICULTY = preload("res://data/difficulty/novice.tres")
const MASTER_DIFFICULTY = preload("res://data/difficulty/master.tres")
const SETTINGS_MENU_NODES := [
	"Computer", "Difficulty", "Promotion", "PlayerSide", "AnimationSpeed",
	"CameraShake", "MasterVolume", "Fullscreen", "ResetView", "EngineLog",
]
var controller
var selected_square := Types.NO_SQUARE
var engine
var computer_enabled := true
var engine_request_pending := false
var engine_configured := false
var difficulty = NOVICE_DIFFICULTY
var player_side := Types.WHITE
var capture_impact_position := Vector3.ZERO
var settings: Dictionary = SessionSettings.DEFAULTS.duplicate()
const ENGINE_MOVE_TIME_MS := 500
func _ready() -> void:
	controller = TurnController.new()
	add_child(controller)
	controller.start()
	$Camera3D.snap_to_side(Types.WHITE, 0.0)
	$BoardPresenter.rebuild_from_state(controller.game.state)
	$UI/Submit.pressed.connect(_submit)
	$UI/Restart.pressed.connect(_restart)
	$UI/Back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/app/Main.tscn"))
	$UI/Settings.pressed.connect(_toggle_settings_menu)
	$UI/Fullscreen.pressed.connect(_toggle_fullscreen)
	$UI/ResetView.pressed.connect($Camera3D.reset_view)
	$UI/GameOverPanel/Content/RestartGame.pressed.connect(_restart)
	$UI/GameOverPanel/Content/Menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/app/Main.tscn"))
	$UI/Undo.pressed.connect(_undo)
	$UI/Skip.pressed.connect($BattleDirector.request_skip)
	$BattleDirector.impact_landed.connect(_show_capture_impact)
	for label in ["Novice", "Master"]:
		$UI/Difficulty.add_item(label)
	for label in ["Play White", "Play Black"]:
		$UI/PlayerSide.add_item(label)
	for label in ["Cinematic captures", "Quick captures"]:
		$UI/AnimationSpeed.add_item(label)
	for label in ["Queen", "Rook", "Bishop", "Knight"]:
		$UI/Promotion.add_item(label)
	$UI/Promotion.select(0)
	_load_settings()
	_set_settings_menu_visible(false)
	$UI/Computer.toggled.connect(_set_computer_enabled)
	$UI/Difficulty.item_selected.connect(_set_difficulty)
	$UI/PlayerSide.item_selected.connect(_set_player_side)
	$UI/AnimationSpeed.item_selected.connect(_set_capture_speed)
	$UI/CameraShake.toggled.connect(_set_camera_shake)
	$UI/MasterVolume.value_changed.connect(_set_master_volume)
	engine = StockfishAdapter.new()
	add_child(engine)
	engine.uci_ready.connect(_on_engine_ready)
	engine.bestmove_received.connect(_on_engine_bestmove)
	engine.engine_error.connect(_on_engine_error)
	engine.engine_line.connect(_on_engine_line)
	if computer_enabled and not engine.start():
		computer_enabled = false
		$UI/Computer.button_pressed = false

func _exit_tree() -> void:
	if engine != null:
		engine.shutdown()

func _restart() -> void:
	controller.queue_free()
	controller = TurnController.new()
	add_child(controller)
	controller.start()
	selected_square = Types.NO_SQUARE
	$ChessBoard.set_highlights(Types.NO_SQUARE, [])
	$BoardPresenter.rebuild_from_state(controller.game.state)
	$UI/Submit.disabled = false
	$UI/GameOverPanel.visible = false
	$UI/Status.text = "White to move"
	$Camera3D.snap_to_side(Types.WHITE, 0.0)
	if computer_enabled:
		engine.new_game()
	engine_request_pending = false
	if computer_enabled and player_side == Types.BLACK:
		_request_engine_move()

func _undo() -> void:
	var plies := 2 if computer_enabled and controller.game.move_history.size() >= 2 else 1
	var undone: int = controller.undo(plies)
	if undone == 0:
		$UI/Status.text = "Undo is available between moves."
		return
	selected_square = Types.NO_SQUARE
	$ChessBoard.set_highlights(Types.NO_SQUARE, [])
	$BoardPresenter.rebuild_from_state(controller.game.state)
	$UI/Move.clear()
	$UI/Submit.disabled = false
	$UI/Status.text = "%d move%s undone. %s to move" % [undone, "s" if undone != 1 else "", "White" if controller.game.state.side_to_move == Types.WHITE else "Black"]
	$Camera3D.snap_to_side(controller.game.state.side_to_move)

func _submit() -> void:
	if computer_enabled and controller.game.state.side_to_move != player_side:
		$UI/Status.text = "Stockfish is thinking."
		return
	var result = controller.submit_uci($UI/Move.text.strip_edges().to_lower())
	if result == null:
		$UI/Status.text = "Illegal move or presentation in progress."
		return
	await _present_result(result)
	_after_presentation(result, false)

func _present_result(result) -> void:
	$UI/Status.text = "Presenting %s" % result.uci
	if result.is_capture:
		$BattleDirector.choreography = ChoreographyResolver.resolve_matchup(Types.piece_type(result.moving_piece), Types.piece_type(result.captured_piece))
		var victim_square: int = result.en_passant_capture_square if result.is_en_passant else result.to_square
		var attacker = $BoardPresenter.actors.get(result.from_square)
		var victim = $BoardPresenter.actors.get(victim_square)
		if attacker != null and victim != null:
			capture_impact_position = victim.global_position + Vector3.UP * 1.0
			$UI/Skip.visible = true
			$CameraDirector.begin_capture(attacker, victim)
			await $BattleDirector.play_capture(attacker, victim, Mapper.square_to_world(result.to_square))
			$BoardPresenter.settle_capture(result)
			await $CameraDirector.return_to_board().finished
			$UI/Skip.visible = false
		else:
			await $BoardPresenter.present_quiet_move(result)
	else:
		await $BoardPresenter.present_quiet_move(result)
	$UI/Move.clear()

func _show_capture_impact() -> void:
	$ImpactFlash.global_position = capture_impact_position
	$ImpactFlash.light_energy = 10.0
	$ImpactAudio.play_impact()
	$CameraDirector.shake_on_impact()
	var tween := create_tween()
	tween.tween_property($ImpactFlash, "light_energy", 0.0, 0.18)

func _set_master_volume(decibels: float) -> void:
	AudioServer.set_bus_volume_db(0, decibels)
	settings.master_volume_db = decibels
	_save_settings()

func _set_camera_shake(enabled: bool) -> void:
	$CameraDirector.shake_enabled = enabled
	settings.camera_shake = enabled
	_save_settings()

func _after_presentation(result, was_engine_move: bool) -> void:
	if not $BoardPresenter.matches_state(controller.game.state):
		$BoardPresenter.rebuild_from_state(controller.game.state)
	controller.presentation_finished()
	if result.game_result != "ongoing":
		$UI/Status.text = "Game over: %s" % result.game_result.replace("_", " ")
		$UI/Submit.disabled = true
		$UI/GameOverPanel.visible = true
		$UI/GameOverPanel/Content/Result.text = "Game over\n%s" % result.game_result.replace("_", " ").capitalize()
	else:
		var side_name := "White" if controller.game.state.side_to_move == Types.WHITE else "Black"
		$UI/Status.text = "%s to move%s" % [side_name, " — Check!" if result.gives_check else ""]
	$ChessBoard.set_highlights(Types.NO_SQUARE, [])
	if result.game_result == "ongoing":
		$Camera3D.snap_to_side(controller.game.state.side_to_move)
	if computer_enabled and not was_engine_move and result.game_result == "ongoing":
		_request_engine_move()

func _request_engine_move() -> void:
	if not controller.begin_engine_turn():
		return
	$UI/Status.text = "Stockfish is thinking…"
	if not engine.is_ready_for_requests():
		engine_request_pending = true
		$UI/Status.text = "Stockfish is initializing…"
		return
	if not engine.request_move(controller.game.state.to_fen(), ENGINE_MOVE_TIME_MS):
		controller.engine_failed()

func _on_engine_ready(_engine_name: String) -> void:
	if not engine_configured:
		engine_configured = true
		_apply_difficulty()
		return
	if engine_request_pending and controller != null and controller.phase == TurnController.Phase.ENGINE_THINKING:
		engine_request_pending = false
		if not engine.request_move(controller.game.state.to_fen(), ENGINE_MOVE_TIME_MS):
			controller.engine_failed()
		return
	if computer_enabled and controller != null:
		$UI/Status.text = "White to move"

func _on_engine_bestmove(uci: String) -> void:
	if controller == null or controller.phase != TurnController.Phase.ENGINE_THINKING:
		return
	var result = controller.submit_engine_uci(uci)
	if result == null:
		_on_engine_error("Stockfish returned an invalid move: %s" % uci)
		return
	await _present_result(result)
	_after_presentation(result, true)

func _on_engine_error(message: String) -> void:
	engine_request_pending = false
	controller.engine_failed()
	computer_enabled = false
	$UI/Computer.button_pressed = false
	$UI/Status.text = "Computer unavailable: %s. Local play remains available." % message

func _on_engine_line(line: String) -> void:
	var log: RichTextLabel = $UI/EngineLog
	log.append_text("%s\n" % line)
	while log.get_line_count() > 6:
		log.remove_paragraph(0)

func _set_computer_enabled(enabled: bool) -> void:
	computer_enabled = enabled
	if enabled and engine != null and not engine.is_running():
		if not engine.start():
			computer_enabled = false
			$UI/Computer.button_pressed = false
	if not enabled and controller.phase == TurnController.Phase.ENGINE_THINKING:
		engine_request_pending = false
		engine.stop_thinking()
		controller.engine_failed()
	$UI/Status.text = "White to move" if controller.game.state.side_to_move == Types.WHITE else "Black to move"
	settings.computer_enabled = computer_enabled
	_save_settings()

func _set_difficulty(index: int) -> void:
	difficulty = NOVICE_DIFFICULTY if index == 0 else MASTER_DIFFICULTY
	if engine != null and engine.is_ready_for_requests():
		_apply_difficulty()
	settings.difficulty_index = index
	_save_settings()

func _set_player_side(index: int) -> void:
	player_side = Types.WHITE if index == 0 else Types.BLACK
	settings.player_side_index = index
	_save_settings()
	_restart()

func _set_capture_speed(index: int) -> void:
	$BattleDirector.playback_speed = 1.0 if index == 0 else 2.0
	settings.capture_speed_index = index
	_save_settings()


func _toggle_settings_menu() -> void:
	_set_settings_menu_visible(not $UI/SettingsPanel.visible)


func _set_settings_menu_visible(visible: bool) -> void:
	$UI/SettingsPanel.visible = visible
	for node_name in SETTINGS_MENU_NODES:
		$UI.get_node(node_name).visible = visible
	$UI/Settings.text = "Close settings" if visible else "Settings"

func _load_settings() -> void:
	settings = SessionSettings.load_values()
	var difficulty_index := clampi(int(settings.get("difficulty_index", 0)), 0, 1)
	var player_index := clampi(int(settings.get("player_side_index", 0)), 0, 1)
	var speed_index := clampi(int(settings.get("capture_speed_index", 0)), 0, 1)
	computer_enabled = bool(settings.get("computer_enabled", true))
	difficulty = NOVICE_DIFFICULTY if difficulty_index == 0 else MASTER_DIFFICULTY
	player_side = Types.WHITE if player_index == 0 else Types.BLACK
	$BattleDirector.playback_speed = 1.0 if speed_index == 0 else 2.0
	$CameraDirector.shake_enabled = bool(settings.get("camera_shake", true))
	var volume_db := clampf(float(settings.get("master_volume_db", 0.0)), -40.0, 0.0)
	AudioServer.set_bus_volume_db(0, volume_db)
	$UI/Computer.button_pressed = computer_enabled
	$UI/Difficulty.select(difficulty_index)
	$UI/PlayerSide.select(player_index)
	$UI/AnimationSpeed.select(speed_index)
	$UI/CameraShake.button_pressed = $CameraDirector.shake_enabled
	$UI/MasterVolume.value = volume_db
	_apply_fullscreen(bool(settings.get("fullscreen", false)))

func _save_settings() -> void:
	SessionSettings.save_values(settings)

func _toggle_fullscreen() -> void:
	var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	_apply_fullscreen(not fullscreen)
	settings.fullscreen = not fullscreen
	_save_settings()

func _apply_fullscreen(fullscreen: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	$UI/Fullscreen.text = "Windowed" if fullscreen else "Fullscreen"

func _apply_difficulty() -> void:
	var skill: int = 20
	var elo: int = 3190
	if bool(difficulty.get_meta("uci_limit_strength", false)):
		skill = 0
		elo = int(difficulty.get_meta("uci_elo", 1350))
	engine.configure_difficulty(skill, elo)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT): return
	var origin: Vector3 = $Camera3D.project_ray_origin(event.position)
	var direction: Vector3 = $Camera3D.project_ray_normal(event.position)
	if is_zero_approx(direction.y): return
	var point: Vector3 = origin + direction * (-origin.y / direction.y)
	var square: int = Mapper.world_to_square(point)
	if square == Types.NO_SQUARE: return
	if selected_square == Types.NO_SQUARE:
		if computer_enabled and controller.game.state.side_to_move != player_side:
			return
		if Types.piece_side(controller.game.state.get_piece(square)) == controller.game.state.side_to_move:
			selected_square = square
			var destinations: Array = []
			for move in controller.game.legal_moves():
				if move.from_square == square: destinations.append(move.to_square)
			$ChessBoard.set_highlights(selected_square, destinations)
			$UI/Status.text = "Selected %s" % Types.square_name(square)
	else:
		var uci := Types.square_name(selected_square) + Types.square_name(square)
		if Types.piece_type(controller.game.state.get_piece(selected_square)) == Types.PAWN and Types.rank_of(square) in [0, 7]:
			uci += ["q", "r", "b", "n"][$UI/Promotion.selected]
		$UI/Move.text = uci
		selected_square = Types.NO_SQUARE
		$ChessBoard.set_highlights(Types.NO_SQUARE, [])
		_submit()
