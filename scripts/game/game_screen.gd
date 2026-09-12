extends Node3D
const ChessGame = preload("res://scripts/chess/chess_game.gd")
const TurnController = preload("res://scripts/game/turn_controller.gd")
const Types = preload("res://scripts/chess/chess_types.gd")
const Mapper = preload("res://scripts/presentation/board_mapper.gd")
const StockfishAdapter = preload("res://scripts/engine/stockfish_adapter.gd")
const ChoreographyResolver = preload("res://scripts/presentation/capture_choreography_resolver.gd")
const SessionSettings = preload("res://scripts/game/session_settings.gd")
const CampaignProgress = preload("res://scripts/game/campaign_progress.gd")
const ArenaCatalog = preload("res://scripts/presentation/arena_catalog.gd")
const CinematicCatalog = preload("res://scripts/presentation/campaign_cinematic_catalog.gd")
const LegalMoveGenerator = preload("res://scripts/chess/legal_move_generator.gd")
const SETTINGS_MENU_NODES := [
	"Move", "Submit", "CameraDebug", "Spectator", "Difficulty", "Promotion", "PlayerSide", "AnimationSpeed",
	"CameraShake", "BeginnerCoach", "CampaignCinematics", "MasterVolume", "Fullscreen", "ResetView", "EngineLog", "Restart", "Undo", "Pause", "Back", "CameraHelp",
	"MenuHeading", "DifficultyCaption", "PlayerCaption", "PromotionCaption", "SpeedCaption", "ViewCaption", "VolumeCaption", "DifficultyReadout",
]
const CAPTURE_HIDDEN_UI_NODES := ["Settings"]
const POST_LOADING_HUD_NODES := ["Status", "ArenaTitle", "Settings", "Hint"]
const CINEMATIC_HIDDEN_UI_NODES := ["Status", "ArenaTitle", "Settings", "Hint", "QuickResetView", "OutcomeBanner"]
var controller
var selected_square := Types.NO_SQUARE
var engine
var computer_enabled := true
var spectator_enabled := false
var engine_request_pending := false
var hint_request_pending := false
var _outcome_banner_tween: Tween
var beginner_coach_enabled := true
var engine_configured := false
var difficulty_index := 0
var player_side := Types.WHITE
var capture_impact_position := Vector3.ZERO
var replay_index := -1
var settings: Dictionary = SessionSettings.DEFAULTS.duplicate()
var campaign: RefCounted
var arena_id := "mountain_fortress"
var campaign_enabled := true
var match_paused := false
var surrendering := false
enum ScreenPhase { INITIALIZING, INTRO, PLAYING, OUTRO, RESULTS, LEAVING }
var screen_phase := ScreenPhase.INITIALIZING
var _match_generation := 0
var _engine_request: Dictionary = {}
const ENGINE_MOVE_TIME_MS := 500
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_set_loading_hud_visible(false)
	$UI/LoadingOverlay.visible = true
	call_deferred("_initialize_game")


func _process(_delta: float) -> void:
	if $UI/CameraDebug.visible:
		$UI/CameraDebug.text = $Camera3D.debug_readout()


func _initialize_game() -> void:
	# Give the scene one rendered frame with the loading card before the 32
	# character rigs, animation libraries, and Stockfish adapter initialize.
	await get_tree().process_frame
	controller = TurnController.new()
	add_child(controller)
	$Camera3D.snap_to_side(Types.WHITE, 0.0)
	$BoardPresenter.rebuild_from_state(controller.game.state)
	$UI/Submit.pressed.connect(_submit)
	$UI/Restart.pressed.connect(_restart)
	$UI/Back.pressed.connect(_surrender_and_return)
	$UI/Pause.pressed.connect(_pause_match)
	$UI/PauseOverlay/Content/Resume.pressed.connect(_resume_match)
	$UI/PauseOverlay/Content/Quit.pressed.connect(_quit_from_pause)
	$UI/Settings.pressed.connect(_toggle_settings_menu)
	$UI/Hint.pressed.connect(_request_hint)
	$CampaignCinematic.get_node("Overlay/Skip").pressed.connect($CampaignCinematic.skip)
	$UI/Fullscreen.pressed.connect(_toggle_fullscreen)
	$UI/ResetView.pressed.connect($Camera3D.reset_view)
	$UI/QuickResetView.pressed.connect($Camera3D.reset_view)
	$Camera3D.view_modified.connect(_set_quick_reset_visible)
	$UI/GameOverPanel/Content/RestartGame.pressed.connect(_restart)
	$UI/GameOverPanel/Content/Menu.pressed.connect(_return_to_campaign)
	$UI/GameOverPanel/Content/CopyPGN.pressed.connect(_copy_pgn)
	$UI/GameOverPanel/Content/Review.pressed.connect(_begin_review)
	$UI/GameOverPanel/Content/Previous.pressed.connect(func(): _show_review_position(replay_index - 1))
	$UI/GameOverPanel/Content/Next.pressed.connect(func(): _show_review_position(replay_index + 1))
	$UI/GameOverPanel/Content/ReturnFinal.pressed.connect(_return_to_final_position)
	$UI/Undo.pressed.connect(_undo)
	$BattleDirector.impact_landed.connect(_show_capture_impact)
	$BattleDirector.weapon_impact.connect($ArenaAudioDirector.play_weapon_impact)
	$BoardPresenter.piece_landed.connect($ArenaAudioDirector.play_piece_land)
	for label in ["Beginner", "Adventurer", "Champion", "Master"]:
		$UI/Difficulty.add_item(label)
	for label in ["Play White", "Play Black"]:
		$UI/PlayerSide.add_item(label)
	for label in ["Cinematic captures", "Quick captures"]:
		$UI/AnimationSpeed.add_item(label)
	for label in ["Queen", "Rook", "Bishop", "Knight"]:
		$UI/Promotion.add_item(label)
	$UI/Promotion.select(0)
	_load_settings()
	$BattlefieldEnvironment.apply_arena(arena_id)
	$ArenaAudioDirector.set_arena(arena_id)
	# The horn is an arena-entry punctuation, leaving the campaign theme to
	# establish the Warpath screen without competing with it.
	$ArenaEntryHorn.play()
	$UI/ArenaTitle.text = "%s  —  %s" % [ArenaCatalog.definition(arena_id).chapter, ArenaCatalog.definition(arena_id).title]
	$Camera3D.snap_to_side(player_side, 0.0)
	_set_settings_menu_visible(false)
	$UI/Spectator.toggled.connect(_set_spectator_enabled)
	$UI/Difficulty.item_selected.connect(_set_difficulty)
	$UI/PlayerSide.item_selected.connect(_set_player_side)
	$UI/AnimationSpeed.item_selected.connect(_set_capture_speed)
	$UI/CameraShake.toggled.connect(_set_camera_shake)
	$UI/BeginnerCoach.toggled.connect(_set_beginner_coach_enabled)
	$UI/CampaignCinematics.toggled.connect(_set_campaign_cinematics_enabled)
	$UI/MasterVolume.value_changed.connect(_set_master_volume)
	engine = StockfishAdapter.new()
	add_child(engine)
	engine.uci_ready.connect(_on_engine_ready)
	engine.bestmove_received.connect(_on_engine_bestmove)
	engine.engine_error.connect(_on_engine_error)
	engine.engine_line.connect(_on_engine_line)
	if computer_enabled and not engine.start():
		computer_enabled = false
	$UI/LoadingOverlay.visible = false
	_set_loading_hud_visible(true)
	_update_coach_prompt()
	await _begin_match()


func _begin_match() -> void:
	var show_cinematic := campaign_enabled and not spectator_enabled and bool(settings.get("campaign_cinematics_enabled", true)) and CinematicCatalog.sequence_for(arena_id, "intro") != null
	if show_cinematic:
		screen_phase = ScreenPhase.INTRO
		_set_cinematic_hud_visible(true)
		var speakers: Dictionary = $GrandmasterCeremony.prepare($BoardPresenter, player_side)
		var run_id: int = $CampaignCinematic.play_sequence(CinematicCatalog.sequence_for(arena_id, "intro"), player_side, speakers, $GrandmasterCeremony)
		var completion: Array = await $CampaignCinematic.finished
		_set_cinematic_hud_visible(false)
		if completion.is_empty() or int(completion[0]) != run_id or not is_instance_valid(controller):
			return
	else:
		_play_arena_intro()
	_reset_match_presentation()
	controller.start()
	screen_phase = ScreenPhase.PLAYING
	$Camera3D.snap_to_side(player_side, 0.0)
	if computer_enabled and (spectator_enabled or player_side == Types.BLACK):
		_request_engine_move()
	else:
		_update_coach_prompt()


func _play_arena_intro() -> void:
	var arena := ArenaCatalog.definition(arena_id)
	$UI/ArenaIntro/Panel/Content/Chapter.text = str(arena.chapter).to_upper()
	$UI/ArenaIntro/Panel/Content/Title.text = str(arena.title)
	$UI/ArenaIntro/Panel/Content/Challenge.text = "%s  ·  %s" % [str(arena.opponent), str(arena.intro)]
	$UI/ArenaIntro.visible = true
	$UI/ArenaIntro.modulate.a = 0.0
	var reveal := create_tween()
	reveal.tween_property($UI/ArenaIntro, "modulate:a", 1.0, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	reveal.tween_interval(2.2)
	reveal.tween_property($UI/ArenaIntro, "modulate:a", 0.0, 0.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	reveal.tween_callback(func(): $UI/ArenaIntro.visible = false)


func _set_loading_hud_visible(visible: bool) -> void:
	if not visible:
		# Settings fields are direct UI siblings (rather than children of the
		# SettingsPanel), so hiding only the panel still lets them bleed through
		# the deliberately translucent loading shade.  Loading owns this canvas:
		# hide every sibling except itself until initialization is complete.
		for child in $UI.get_children():
			if child != $UI/LoadingOverlay and child is CanvasItem:
				child.visible = false
		return
	for node_name in POST_LOADING_HUD_NODES:
		$UI.get_node(node_name).visible = true

func _exit_tree() -> void:
	get_tree().paused = false
	_invalidate_engine_work()
	if has_node("CampaignCinematic"):
		$CampaignCinematic.cancel()
	if engine != null:
		engine.shutdown()


func _pause_match() -> void:
	if screen_phase != ScreenPhase.PLAYING or surrendering or controller == null or controller.phase != TurnController.Phase.PLAYER_INPUT:
		$UI/Status.text = "Pause is available between moves."
		return
	match_paused = true
	_set_settings_menu_visible(false)
	$UI/PauseOverlay.visible = true
	$Camera3D.set_controls_enabled(false)
	get_tree().paused = true


func _resume_match() -> void:
	if not match_paused:
		return
	get_tree().paused = false
	match_paused = false
	$UI/PauseOverlay.visible = false
	$Camera3D.set_controls_enabled(true)


func _quit_from_pause() -> void:
	_resume_match()
	_surrender_and_return()


func _surrender_and_return() -> void:
	if surrendering or screen_phase != ScreenPhase.PLAYING:
		return
	if match_paused:
		_resume_match()
	surrendering = true
	screen_phase = ScreenPhase.LEAVING
	_invalidate_engine_work()
	$UI/PauseOverlay.visible = false
	_set_settings_menu_visible(false)
	$Camera3D.set_controls_enabled(false)
	if controller != null:
		controller.phase = TurnController.Phase.GAME_OVER
	if engine != null:
		engine.stop_thinking()
	$UI/Status.text = "Your army surrenders the arena…"
	var survivors: Array = $BoardPresenter.actors.values()
	survivors.sort_custom(func(a, b): return a.global_position.z < b.global_position.z)
	var longest_fall := 0.0
	var victory_style := 0
	for actor in survivors:
		if actor == null or not is_instance_valid(actor):
			continue
		if actor.side == player_side:
			actor.play_state(&"death.backward_01")
			longest_fall = maxf(longest_fall, actor.state_duration(&"death.backward_01"))
		else:
			actor.celebrate_victory(victory_style)
			victory_style += 1
	await get_tree().create_timer(longest_fall + 0.18).timeout
	_return_to_campaign()

func _restart() -> void:
	if screen_phase == ScreenPhase.INTRO or screen_phase == ScreenPhase.OUTRO:
		return
	_invalidate_engine_work()
	controller.queue_free()
	controller = TurnController.new()
	add_child(controller)
	controller.start()
	selected_square = Types.NO_SQUARE
	$ChessBoard.set_highlights(Types.NO_SQUARE, [])
	$ChessBoard.clear_hint()
	$ChessBoard.clear_last_move()
	$BoardPresenter.set_selected_square(Types.NO_SQUARE)
	$BoardPresenter.rebuild_from_state(controller.game.state)
	$UI/Submit.disabled = spectator_enabled
	$UI/GameOverPanel.visible = false
	replay_index = -1
	$UI/Status.text = "White to move"
	_update_coach_prompt()
	$Camera3D.snap_to_side(player_side, 0.0)
	screen_phase = ScreenPhase.PLAYING
	if computer_enabled:
		engine.new_game()
	if computer_enabled and (spectator_enabled or player_side == Types.BLACK):
		_request_engine_move()

func _undo() -> void:
	if screen_phase != ScreenPhase.PLAYING:
		return
	_invalidate_engine_work()
	var plies := 2 if computer_enabled and controller.game.move_history.size() >= 2 else 1
	var undone: int = controller.undo(plies)
	if undone == 0:
		$UI/Status.text = "Undo is available between moves."
		return
	selected_square = Types.NO_SQUARE
	$ChessBoard.set_highlights(Types.NO_SQUARE, [])
	$ChessBoard.clear_hint()
	$ChessBoard.clear_last_move()
	$BoardPresenter.set_selected_square(Types.NO_SQUARE)
	$BoardPresenter.rebuild_from_state(controller.game.state)
	$UI/Move.clear()
	$UI/Submit.disabled = false
	$UI/Status.text = "%d move%s undone. %s to move" % [undone, "s" if undone != 1 else "", "White" if controller.game.state.side_to_move == Types.WHITE else "Black"]
	$Camera3D.snap_to_side(player_side)

func _submit() -> void:
	if screen_phase != ScreenPhase.PLAYING or match_paused or surrendering:
		return
	if spectator_enabled:
		$UI/Status.text = "Spectating Stockfish versus Stockfish."
		return
	$ChessBoard.clear_hint()
	if controller.game.state.side_to_move != player_side:
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
			_set_capture_ui_visible(false)
			# Keep the capture in the player's chosen board view. The battle remains
			# readable through actor choreography and impact effects without taking
			# over the camera or zooming the board out from under the player.
			await $BattleDirector.play_capture(attacker, victim, Mapper.square_to_world(result.to_square))
			$BoardPresenter.settle_capture(result)
			_set_capture_ui_visible(true)
		else:
			await $BoardPresenter.present_quiet_move(result)
	else:
		await $BoardPresenter.present_quiet_move(result)
	$UI/Move.clear()

func _show_capture_impact() -> void:
	$ImpactFlash.global_position = capture_impact_position
	$ImpactSparks.global_position = capture_impact_position
	$ImpactSparks.emitting = true
	$ImpactSparks.restart()
	$ImpactFlash.light_energy = 10.0
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


func _set_quick_reset_visible(is_modified: bool) -> void:
	$UI/QuickResetView.visible = is_modified


func _record_campaign_victory_if_earned(result) -> bool:
	# Checkmate leaves the losing side to move. Only a human player win in the
	# selected, current campaign arena can unlock the next location.
	if not campaign_enabled or campaign == null or spectator_enabled or not result.is_checkmate:
		return false
	if controller.game.state.side_to_move == player_side:
		return false
	if not campaign.mark_victory(arena_id):
		return false
	settings.campaign_snapshot = campaign.to_snapshot()
	settings.selected_arena_id = campaign.current_arena()
	_save_settings()
	return true


func _return_to_campaign() -> void:
	get_tree().change_scene_to_file("res://scenes/app/CampaignMap.tscn")

func _after_presentation(result, was_engine_move: bool) -> void:
	if not $BoardPresenter.matches_state(controller.game.state):
		$BoardPresenter.rebuild_from_state(controller.game.state)
	controller.presentation_finished()
	_show_last_move_trail(result)
	if result.game_result != "ongoing":
		var campaign_victory := _record_campaign_victory_if_earned(result)
		var outcome := _outcome_copy(result, campaign_victory)
		if result.is_checkmate:
			# Chess state has already selected the result. The winning army's brief
			# acknowledgement is presentation-only and cannot affect settlement.
			$BoardPresenter.celebrate_victory_for_side(-controller.game.state.side_to_move)
		var terminal_kind := _terminal_cinematic_kind(result, campaign_victory)
		_present_terminal_result.call_deferred(outcome, terminal_kind)
	else:
		var side_name := "White" if controller.game.state.side_to_move == Types.WHITE else "Black"
		$UI/Status.text = "%s to move%s" % [side_name, " — Check!" if result.gives_check else ""]
	$ChessBoard.set_highlights(Types.NO_SQUARE, [])
	if result.gives_check:
		$BoardPresenter.show_check_on_side(controller.game.state.side_to_move)
		if result.game_result == "ongoing":
			_show_outcome_banner("CHECK!", Color(1.0, 0.30, 0.12), 1.55)
			if beginner_coach_enabled and controller.game.state.side_to_move == player_side:
				$UI/Status.text = "Your king is in check — move, block, or capture the threat!"
	else:
		$BoardPresenter.clear_check_indicator()
	# Keep a player's deliberate framing throughout both quiet moves and captures.
	# The default read remains available through the compact Reset view control.
	if result.game_result == "ongoing" and not result.is_capture and $Camera3D.is_default_view():
		$Camera3D.snap_to_side(player_side)
	if computer_enabled and (spectator_enabled or not was_engine_move) and result.game_result == "ongoing":
		_request_engine_move()
	elif result.game_result == "ongoing":
		_update_coach_prompt()


func _terminal_cinematic_kind(result, campaign_victory := false) -> String:
	if result.is_checkmate:
		if controller.game.state.side_to_move != player_side:
			return "conquest" if campaign_victory and campaign != null and campaign.campaign_complete() else "victory"
		return "defeat"
	return "draw"


func _present_terminal_result(outcome: Dictionary, terminal_kind := "") -> void:
	if screen_phase == ScreenPhase.LEAVING or controller == null:
		return
	var show_cinematic := campaign_enabled and not spectator_enabled and bool(settings.get("campaign_cinematics_enabled", true)) and not terminal_kind.is_empty()
	if show_cinematic:
		screen_phase = ScreenPhase.OUTRO
		_set_cinematic_hud_visible(true)
		var sequence: Resource = CinematicCatalog.terminal_sequence_for(arena_id, terminal_kind)
		var speakers: Dictionary = $GrandmasterCeremony.speakers_for_current_board($BoardPresenter, player_side)
		var run_id: int = $CampaignCinematic.play_sequence(sequence, player_side, speakers)
		var completion: Array = await $CampaignCinematic.finished
		_set_cinematic_hud_visible(false)
		if completion.is_empty() or int(completion[0]) != run_id or screen_phase != ScreenPhase.OUTRO:
			return
	screen_phase = ScreenPhase.RESULTS
	$UI/Status.text = outcome.status
	$UI/Submit.disabled = true
	$UI/GameOverPanel.visible = true
	$UI/GameOverPanel/Content/Title.text = outcome.title
	$UI/GameOverPanel/Content/Title.add_theme_color_override("font_color", outcome.color)
	$UI/GameOverPanel/Content/Result.text = outcome.detail
	_show_outcome_banner(outcome.title, outcome.color, 3.0)
	$UI/GameOverPanel/Content/Review.visible = controller.game.move_history.size() > 0
	$UI/GameOverPanel/Content/Previous.visible = false
	$UI/GameOverPanel/Content/Next.visible = false
	$UI/GameOverPanel/Content/ReturnFinal.visible = false


func _show_last_move_trail(result) -> void:
	# Remain available throughout the player's decision, until replaced or reset.
	$ChessBoard.show_last_move(result.from_square, result.to_square)




func _request_hint() -> void:
	if screen_phase != ScreenPhase.PLAYING:
		return
	if not beginner_coach_enabled:
		return
	if controller == null or spectator_enabled or controller.phase != TurnController.Phase.PLAYER_INPUT or controller.game.state.side_to_move != player_side:
		$UI/Status.text = "Hints are ready when it is your turn."
		return
	if engine == null or not engine.is_ready_for_requests():
		$UI/Status.text = "Coach is preparing a hint…"
		return
	_engine_request = {"generation": _match_generation, "kind": "hint", "fen": controller.game.state.to_fen()}
	hint_request_pending = engine.request_move(str(_engine_request.fen), 180)
	if hint_request_pending:
		$UI/Hint.disabled = true
		$UI/Status.text = "Coach is scouting the board…"
	else:
		_engine_request.clear()


func _show_hint(uci: String) -> void:
	if uci.length() < 4:
		return
	var from_square := Types.square_from_name(uci.substr(0, 2))
	var to_square := Types.square_from_name(uci.substr(2, 2))
	if from_square == Types.NO_SQUARE or to_square == Types.NO_SQUARE:
		return
	$ChessBoard.show_hint(from_square, to_square)
	var capture := Types.piece_side(controller.game.state.get_piece(to_square)) == -player_side
	$UI/Status.text = "Hint: try %s → %s%s" % [Types.square_name(from_square), Types.square_name(to_square), " — you can capture there!" if capture else "."]


func _update_coach_prompt() -> void:
	$UI/Hint.visible = beginner_coach_enabled and not spectator_enabled
	$UI/Hint.disabled = not beginner_coach_enabled or controller == null or controller.phase != TurnController.Phase.PLAYER_INPUT or controller.game.state.side_to_move != player_side
	if beginner_coach_enabled and controller != null and controller.phase == TurnController.Phase.PLAYER_INPUT and controller.game.state.side_to_move == player_side and selected_square == Types.NO_SQUARE:
		$UI/Status.text = "Your turn — choose a piece, then a glowing green square."


func _set_beginner_coach_enabled(enabled: bool) -> void:
	beginner_coach_enabled = enabled
	settings.beginner_coach_enabled = enabled
	if not enabled:
		$ChessBoard.clear_hint()
	_update_coach_prompt()
	_save_settings()


func _set_campaign_cinematics_enabled(enabled: bool) -> void:
	settings.campaign_cinematics_enabled = enabled
	_save_settings()


func _outcome_copy(result, campaign_victory: bool) -> Dictionary:
	if spectator_enabled:
		var watched_result: String = result.game_result.replace("_", " ").capitalize()
		if result.is_checkmate:
			watched_result = "%s wins by checkmate" % ("Black" if controller.game.state.side_to_move == Types.WHITE else "White")
		return {"title": "SPECTATOR MATCH COMPLETE", "detail": "%s\nWatched matches do not unlock campaign arenas." % watched_result, "status": "%s — spectator match; no campaign progress." % watched_result, "color": Color(0.70, 0.82, 1.0)}
	if campaign_victory and campaign != null and campaign.campaign_complete():
		return {"title": "CAMPAIGN CONQUERED!", "detail": "The Final Grove is yours.\nEvery arena has fallen.", "status": "Campaign conquered! The Final Grove is yours.", "color": Color(1.0, 0.78, 0.26)}
	if campaign_victory:
		return {"title": "VICTORY!", "detail": "%s secured\nNext: %s" % [ArenaCatalog.definition(arena_id).title, ArenaCatalog.definition(campaign.current_arena()).title], "status": "Victory! %s secured." % ArenaCatalog.definition(arena_id).title, "color": Color(1.0, 0.78, 0.26)}
	if result.is_checkmate:
		var human_won: bool = controller.game.state.side_to_move != player_side
		return {"title": "CHECKMATE — VICTORY!" if human_won else "CHECKMATE — DEFEAT", "detail": "Your army has conquered the board." if human_won else "The opposing king holds the board this time.", "status": "Checkmate — victory!" if human_won else "Checkmate — defeat.", "color": Color(1.0, 0.78, 0.26) if human_won else Color(1.0, 0.36, 0.25)}
	if result.is_stalemate:
		return {"title": "STALEMATE", "detail": "Neither army can make a legal move.", "status": "Stalemate.", "color": Color(0.70, 0.82, 1.0)}
	return {"title": "DRAW", "detail": result.game_result.replace("_", " ").capitalize(), "status": "Game over: %s" % result.game_result.replace("_", " "), "color": Color(0.70, 0.82, 1.0)}


func _show_outcome_banner(message: String, color: Color, duration_s: float) -> void:
	var banner := $UI/OutcomeBanner
	if _outcome_banner_tween != null and _outcome_banner_tween.is_valid():
		_outcome_banner_tween.kill()
	banner.text = message
	banner.add_theme_color_override("font_color", color)
	banner.visible = true
	banner.modulate.a = 0.0
	_outcome_banner_tween = create_tween()
	_outcome_banner_tween.tween_property(banner, "modulate:a", 1.0, 0.16)
	_outcome_banner_tween.tween_interval(duration_s)
	_outcome_banner_tween.tween_property(banner, "modulate:a", 0.0, 0.35)
	_outcome_banner_tween.tween_callback(func(): banner.visible = false)


func _reset_match_presentation() -> void:
	# The cinematic HUD owns the outcome label while it is active.  A label
	# authored with placeholder text must never become a gameplay announcement
	# when that HUD is restored; chess state remains the only source of checks.
	$BoardPresenter.clear_check_indicator()
	if _outcome_banner_tween != null and _outcome_banner_tween.is_valid():
		_outcome_banner_tween.kill()
	_outcome_banner_tween = null
	$UI/OutcomeBanner.visible = false
	$UI/OutcomeBanner.modulate.a = 0.0

func _request_engine_move() -> void:
	if screen_phase != ScreenPhase.PLAYING:
		return
	if not controller.begin_engine_turn():
		return
	$UI/Status.text = "Stockfish is thinking…"
	_engine_request = {"generation": _match_generation, "kind": "move", "fen": controller.game.state.to_fen()}
	if not engine.is_ready_for_requests():
		engine_request_pending = true
		$UI/Status.text = "Stockfish is initializing…"
		return
	if not engine.request_move(str(_engine_request.fen), ENGINE_MOVE_TIME_MS):
		_engine_request.clear()
		controller.engine_failed()

func _on_engine_ready(_engine_name: String) -> void:
	if not engine_configured:
		engine_configured = true
		_apply_difficulty()
		if spectator_enabled and screen_phase == ScreenPhase.PLAYING:
			_request_engine_move()
		return
	if engine_request_pending and not _engine_request.is_empty() and int(_engine_request.generation) == _match_generation and screen_phase == ScreenPhase.PLAYING and controller != null and controller.phase == TurnController.Phase.ENGINE_THINKING:
		engine_request_pending = false
		if not engine.request_move(str(_engine_request.fen), ENGINE_MOVE_TIME_MS):
			_engine_request.clear()
			controller.engine_failed()
		return
	if computer_enabled and controller != null:
		$UI/Status.text = "White to move"

func _on_engine_bestmove(uci: String) -> void:
	if _engine_request.is_empty() or int(_engine_request.get("generation", -1)) != _match_generation or str(_engine_request.get("fen", "")) != controller.game.state.to_fen():
		return
	var request_kind := str(_engine_request.kind)
	_engine_request.clear()
	if request_kind == "hint":
		hint_request_pending = false
		$UI/Hint.disabled = false
		if screen_phase == ScreenPhase.PLAYING and controller.phase == TurnController.Phase.PLAYER_INPUT and controller.game.state.side_to_move == player_side:
			_show_hint(uci)
		return
	if request_kind != "move" or screen_phase != ScreenPhase.PLAYING or controller == null or controller.phase != TurnController.Phase.ENGINE_THINKING:
		return
	var result = controller.submit_engine_uci(uci)
	if result == null:
		_on_engine_error("Stockfish returned an invalid move: %s" % uci)
		return
	await _present_result(result)
	_after_presentation(result, true)

func _on_engine_error(message: String) -> void:
	if not _engine_request.is_empty() and int(_engine_request.get("generation", -1)) != _match_generation:
		return
	if str(_engine_request.get("kind", "")) == "hint":
		_engine_request.clear()
		hint_request_pending = false
		$UI/Hint.disabled = false
		$UI/Status.text = "Coach could not find a hint right now."
		return
	if _engine_request.is_empty() and engine_configured:
		return
	_engine_request.clear()
	engine_request_pending = false
	controller.engine_failed()
	computer_enabled = false
	spectator_enabled = false
	$UI/Spectator.button_pressed = false
	$UI/Status.text = "Stockfish unavailable: %s" % message

func _on_engine_line(line: String) -> void:
	var log: RichTextLabel = $UI/EngineLog
	log.append_text("%s\n" % line)
	while log.get_line_count() > 6:
		log.remove_paragraph(0)

func _set_spectator_enabled(enabled: bool) -> void:
	spectator_enabled = enabled
	if spectator_enabled:
		computer_enabled = true
		if engine != null and not engine.is_running() and not engine.start():
			spectator_enabled = false
			$UI/Spectator.button_pressed = false
			$UI/Status.text = "Spectator mode requires Stockfish."
	settings.spectator_enabled = spectator_enabled
	_save_settings()
	_restart()


func _invalidate_engine_work() -> void:
	_match_generation += 1
	engine_request_pending = false
	hint_request_pending = false
	_engine_request.clear()
	if has_node("UI/Hint"):
		$UI/Hint.disabled = false
	if engine != null:
		engine.cancel_request()

func _set_difficulty(index: int) -> void:
	difficulty_index = clampi(index, 0, CampaignProgress.DIFFICULTY_PROFILES.size() - 1)
	if engine != null and engine.is_ready_for_requests():
		_apply_difficulty()
	settings.difficulty_index = difficulty_index
	_update_difficulty_readout()
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
	if screen_phase != ScreenPhase.PLAYING or match_paused or surrendering:
		return
	_set_settings_menu_visible(not $UI/SettingsPanel.visible)


func _set_settings_menu_visible(visible: bool) -> void:
	$UI/SettingsPanel.visible = visible
	for node_name in SETTINGS_MENU_NODES:
		$UI.get_node(node_name).visible = visible
	$UI/Settings.text = "Close menu" if visible else "Menu"


func _set_capture_ui_visible(visible: bool) -> void:
	if not visible:
		_set_settings_menu_visible(false)
	else:
		# Returning from a battle should restore the clear board-first view rather
		# than reopening whichever controls happened to be visible before it.
		_set_settings_menu_visible(false)
	for node_name in CAPTURE_HIDDEN_UI_NODES:
		$UI.get_node(node_name).visible = visible


func _set_cinematic_hud_visible(visible: bool) -> void:
	_set_settings_menu_visible(false)
	for node_name in CINEMATIC_HIDDEN_UI_NODES:
		# Outcome text is transient and must be explicitly requested by a chess
		# result.  Restoring the general HUD must not reveal its placeholder text.
		$UI.get_node(node_name).visible = false if node_name == "OutcomeBanner" else not visible
	if not visible:
		_update_coach_prompt()

func _load_settings() -> void:
	settings = SessionSettings.load_values()
	difficulty_index = clampi(int(settings.get("difficulty_index", 0)), 0, CampaignProgress.DIFFICULTY_PROFILES.size() - 1)
	var player_index := clampi(int(settings.get("player_side_index", 0)), 0, 1)
	var speed_index := clampi(int(settings.get("capture_speed_index", 0)), 0, 1)
	computer_enabled = true
	settings.computer_enabled = true
	spectator_enabled = bool(settings.get("spectator_enabled", false))
	beginner_coach_enabled = bool(settings.get("beginner_coach_enabled", true))
	if spectator_enabled:
		computer_enabled = true
	player_side = Types.WHITE if player_index == 0 else Types.BLACK
	$BattleDirector.playback_speed = 1.0 if speed_index == 0 else 2.0
	$CameraDirector.shake_enabled = bool(settings.get("camera_shake", true))
	var volume_db := clampf(float(settings.get("master_volume_db", 0.0)), -40.0, 0.0)
	AudioServer.set_bus_volume_db(0, volume_db)
	$UI/Spectator.button_pressed = spectator_enabled
	$UI/Difficulty.select(difficulty_index)
	$UI/PlayerSide.select(player_index)
	$UI/AnimationSpeed.select(speed_index)
	$UI/CameraShake.button_pressed = $CameraDirector.shake_enabled
	$UI/BeginnerCoach.button_pressed = beginner_coach_enabled
	$UI/CampaignCinematics.button_pressed = bool(settings.get("campaign_cinematics_enabled", true))
	$UI/MasterVolume.value = volume_db
	_apply_fullscreen(bool(settings.get("fullscreen", false)))
	campaign = CampaignProgress.new(settings.get("campaign_snapshot", {}))
	campaign_enabled = bool(settings.get("campaign_enabled", true))
	arena_id = str(settings.get("selected_arena_id", campaign.current_arena()))
	# Practice deliberately permits every presentation-only arena, including
	# locked campaign locations. Campaign routing remains validated as before.
	if campaign_enabled and not campaign.is_unlocked(arena_id):
		arena_id = campaign.current_arena()
		settings.selected_arena_id = arena_id
	if not arena_id in ArenaCatalog.ARENAS:
		arena_id = campaign.current_arena()
		settings.selected_arena_id = arena_id
	_update_difficulty_readout()

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
	var profile := CampaignProgress.difficulty_profile(difficulty_index, arena_id)
	engine.configure_difficulty(int(profile.skill), int(profile.elo))


func _update_difficulty_readout() -> void:
	if campaign == null:
		return
	var profile := CampaignProgress.difficulty_profile(difficulty_index, arena_id)
	var arena_number := CampaignProgress.ARENA_IDS.find(arena_id) + 1
	var mode_label := "Campaign opponent" if campaign_enabled else "Practice opponent"
	$UI/DifficultyReadout.text = "%s: %s  ·  %d Elo  ·  Arena %d of %d" % [mode_label, profile.name, profile.elo, arena_number, CampaignProgress.ARENA_IDS.size()]

func _unhandled_input(event: InputEvent) -> void:
	if $CampaignCinematic.is_active() and event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_SPACE):
		$CampaignCinematic.skip()
		get_viewport().set_input_as_handled()
		return
	if screen_phase != ScreenPhase.PLAYING:
		return
	if match_paused or surrendering:
		return
	if spectator_enabled:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT): return
	var origin: Vector3 = $Camera3D.project_ray_origin(event.position)
	var direction: Vector3 = $Camera3D.project_ray_normal(event.position)
	if is_zero_approx(direction.y): return
	var point: Vector3 = origin + direction * (-origin.y / direction.y)
	var square: int = Mapper.world_to_square(point)
	if square == Types.NO_SQUARE: return
	if selected_square == Types.NO_SQUARE:
		if controller.game.state.side_to_move != player_side:
			return
		if Types.piece_side(controller.game.state.get_piece(square)) == controller.game.state.side_to_move:
			selected_square = square
			$BoardPresenter.set_selected_square(square)
			var destinations: Array = []
			for move in controller.game.legal_moves():
				if move.from_square == square: destinations.append(move.to_square)
			$ChessBoard.set_highlights(selected_square, destinations)
			$ChessBoard.clear_hint()
			if beginner_coach_enabled and LegalMoveGenerator.is_square_attacked(controller.game.state, square, -player_side):
				$UI/Status.text = "That piece is under attack — choose a glowing green square."
			else:
				$UI/Status.text = "Selected %s — choose a glowing green square." % Types.square_name(square)
	else:
		var uci := Types.square_name(selected_square) + Types.square_name(square)
		if Types.piece_type(controller.game.state.get_piece(selected_square)) == Types.PAWN and Types.rank_of(square) in [0, 7]:
			uci += ["q", "r", "b", "n"][$UI/Promotion.selected]
		$UI/Move.text = uci
		selected_square = Types.NO_SQUARE
		$ChessBoard.set_highlights(Types.NO_SQUARE, [])
		$BoardPresenter.set_selected_square(Types.NO_SQUARE)
		_submit()


func _begin_review() -> void:
	if controller == null or controller.game.state_history.size() <= 1:
		return
	_show_review_position(0)


func _show_review_position(index: int) -> void:
	if controller == null:
		return
	replay_index = clampi(index, 0, controller.game.state_history.size() - 1)
	$BoardPresenter.rebuild_from_state(controller.game.state_history[replay_index])
	$ChessBoard.set_highlights(Types.NO_SQUARE, [])
	$ChessBoard.clear_hint()
	$ChessBoard.clear_last_move()
	$UI/GameOverPanel/Content/Review.visible = false
	$UI/GameOverPanel/Content/Previous.visible = replay_index > 0
	$UI/GameOverPanel/Content/Next.visible = replay_index < controller.game.move_history.size()
	$UI/GameOverPanel/Content/ReturnFinal.visible = replay_index != controller.game.move_history.size()
	var move_text := "Initial position" if replay_index == 0 else "%d. %s" % [replay_index, controller.game.san_history[replay_index - 1]]
	$UI/Status.text = "Reviewing %s" % move_text
	$Camera3D.snap_to_side(player_side)


func _return_to_final_position() -> void:
	if controller == null:
		return
	replay_index = -1
	$BoardPresenter.rebuild_from_state(controller.game.state)
	$UI/GameOverPanel/Content/Review.visible = controller.game.move_history.size() > 0
	$UI/GameOverPanel/Content/Previous.visible = false
	$UI/GameOverPanel/Content/Next.visible = false
	$UI/GameOverPanel/Content/ReturnFinal.visible = false
	$UI/Status.text = "Game over: %s" % controller.game.game_result().replace("_", " ")
	$Camera3D.snap_to_side(player_side)




func _copy_pgn() -> String:
	if controller == null or controller.game.move_history.is_empty():
		return ""
	var pgn: String = controller.game.to_pgn()
	if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		DisplayServer.clipboard_set(pgn)
		$UI/Status.text = "PGN copied to clipboard."
	else:
		$UI/Status.text = "PGN prepared for copy."
	return pgn
