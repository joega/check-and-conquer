extends SceneTree

const GAME_SCREEN = preload("res://scenes/app/GameScreen.tscn")
const SessionSettings = preload("res://scripts/game/session_settings.gd")
const MoveResult = preload("res://scripts/chess/move_result.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	assert(SessionSettings.save_values(SessionSettings.DEFAULTS) == OK)
	var screen = GAME_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var entry_horn := screen.get_node("ArenaEntryHorn") as AudioStreamPlayer
	assert(entry_horn.stream is AudioStreamMP3 and entry_horn.playing, "Entering a chess arena must trigger the war-horn cue.")
	assert(screen.arena_id == "mountain_fortress" and screen.get_node("BattlefieldEnvironment").arena_id == "mountain_fortress", "A fresh match must stage the first campaign arena.")
	assert("Mountain Fortress Terrace" in screen.get_node("UI/ArenaTitle").text, "The active arena must be visible in the in-game HUD.")
	assert("Mountain Fortress Terrace" in screen.get_node("UI/ArenaIntro/Panel/Content/Title").text and "Gatekeeper" in screen.get_node("UI/ArenaIntro/Panel/Content/Challenge").text, "Entering an arena must present its chapter, identity, and opponent challenge.")
	assert(not screen.get_node("UI/SettingsPanel").visible and not screen.get_node("UI/Spectator").visible, "Configuration controls must begin condensed in the settings menu.")
	assert(screen.beginner_coach_enabled and screen.get_node("UI/Hint").visible, "Beginner Coach must begin enabled with a visible hint action.")
	screen.capture_impact_position = Vector3(2.0, 1.0, -3.0)
	screen._show_capture_impact()
	var impact_sparks: GPUParticles3D = screen.get_node("ImpactSparks")
	assert(impact_sparks.emitting and impact_sparks.global_position.is_equal_approx(screen.capture_impact_position), "Capture impacts must restart a visible spark burst at the committed contact point.")
	screen._toggle_settings_menu()
	assert(screen.get_node("UI/SettingsPanel").visible and screen.get_node("UI/Spectator").visible, "Settings must reveal grouped configuration controls, including spectator mode, on demand.")
	var settings_panel := screen.get_node("UI/SettingsPanel") as Control
	for node_name in ["Restart", "Undo", "Pause", "Back", "Difficulty", "PlayerSide", "Promotion", "Spectator", "AnimationSpeed", "CameraShake", "BeginnerCoach", "Fullscreen", "ResetView", "MasterVolume", "EngineLog"]:
		assert(settings_panel.get_global_rect().encloses((screen.get_node("UI/%s" % node_name) as Control).get_global_rect()), "Every settings control must fit inside the compact settings panel.")
	for left_right in [["Restart", "Undo"], ["Undo", "Pause"], ["Pause", "Back"], ["Difficulty", "PlayerSide"], ["PlayerSide", "Promotion"], ["Promotion", "Spectator"]]:
		assert(not (screen.get_node("UI/%s" % left_right[0]) as Control).get_global_rect().intersects((screen.get_node("UI/%s" % left_right[1]) as Control).get_global_rect()), "Settings row controls must not overlap.")
	screen._toggle_settings_menu()
	screen._pause_match()
	assert(screen.match_paused and paused and screen.get_node("UI/PauseOverlay").visible, "The in-game menu must offer a working pause state.")
	screen._resume_match()
	assert(not screen.match_paused and not paused and not screen.get_node("UI/PauseOverlay").visible, "Resuming must restore board input and normal simulation.")
	assert(screen.computer_enabled, "The playable screen should enable Stockfish by default.")
	screen.get_node("UI/Move").text = "e2e4"
	await screen._submit()
	var deadline := Time.get_ticks_msec() + 12000
	while (screen.controller.game.move_history.size() < 2 or screen.controller.phase != screen.controller.Phase.PLAYER_INPUT) and Time.get_ticks_msec() < deadline:
		await create_timer(0.02).timeout
	assert(screen.controller.game.move_history.size() == 2, "A player move must receive one Stockfish response.")
	assert(screen.controller.phase == screen.controller.Phase.PLAYER_INPUT, "Input must unlock after the engine move is presented.")
	screen._request_hint()
	deadline = Time.get_ticks_msec() + 6000
	while screen.hint_request_pending and Time.get_ticks_msec() < deadline:
		await create_timer(0.02).timeout
	assert(not screen.hint_request_pending and screen.get_node("ChessBoard")._hint_squares.size() == 2, "Coach must use the real Stockfish process to return a concrete legal source and destination.")
	assert("Hint:" in screen.get_node("UI/Status").text, "Coach must explain the highlighted suggestion in plain language.")
	screen._set_beginner_coach_enabled(false)
	assert(not screen.get_node("UI/Hint").visible and screen.get_node("ChessBoard")._hint_squares.is_empty(), "Players must be able to disable Beginner Coach and clear its board guidance.")
	screen._set_beginner_coach_enabled(true)
	assert("bestmove" in screen.get_node("UI/EngineLog").get_parsed_text(), "The screen must expose recent Stockfish UCI output for diagnosis.")
	assert(screen.get_node("BoardPresenter").actor_count() == 32, "The board projection must remain synchronized after engine play.")
	screen._set_spectator_enabled(true)
	deadline = Time.get_ticks_msec() + 12000
	while screen.controller.game.move_history.size() < 2 and Time.get_ticks_msec() < deadline:
		await create_timer(0.02).timeout
	assert(screen.spectator_enabled and screen.controller.game.move_history.size() >= 2, "Spectator mode must autonomously stage legal Stockfish moves for both sides.")
	assert(screen.get_node("UI/Submit").disabled, "Spectator mode must lock human move submission while engines take both turns.")
	screen._set_spectator_enabled(false)
	screen._set_player_side(1)
	deadline = Time.get_ticks_msec() + 12000
	while screen.controller.game.move_history.size() < 1 and Time.get_ticks_msec() < deadline:
		await create_timer(0.02).timeout
	assert(screen.controller.game.move_history.size() == 1, "Stockfish must make the opening move when the player chooses Black.")
	assert(screen.controller.game.state.side_to_move == -1, "Black must receive input after Stockfish's White opener.")
	assert(screen.get_node("Camera3D").focused_side() == screen.player_side, "Choosing Black must keep the board camera behind Black even after Stockfish's White opener.")
	screen._set_player_side(0)
	screen._restart()
	screen.get_node("UI/Move").text = "e2e4"
	await screen._submit()
	deadline = Time.get_ticks_msec() + 12000
	while screen.controller.game.move_history.size() < 2 and Time.get_ticks_msec() < deadline:
		await create_timer(0.02).timeout
	assert(screen.controller.game.move_history.size() >= 2, "Player-versus-Stockfish must receive an engine response.")
	screen._show_review_position(0)
	assert(screen.replay_index == 0 and screen.get_node("BoardPresenter").matches_state(screen.controller.game.state_history[0]), "Review must rebuild the initial authoritative position.")
	screen._show_review_position(1)
	assert(screen.replay_index == 1 and screen.get_node("BoardPresenter").matches_state(screen.controller.game.state_history[1]), "Review must rebuild each committed ply.")
	screen._return_to_final_position()
	assert(screen.replay_index == -1 and screen.get_node("BoardPresenter").matches_state(screen.controller.game.state), "Leaving review must restore the final authoritative position.")
	assert("1. e4" in screen._copy_pgn(), "Completed player-versus-Stockfish moves must prepare portable PGN.")
	screen._restart()
	var board_camera = screen.get_node("Camera3D")
	var capture_ui_is_clean := [false]
	screen.get_node("BattleDirector").impact_landed.connect(func():
		capture_ui_is_clean[0] = not screen.get_node("UI/Move").visible and not screen.has_node("UI/Skip")
	)
	screen._set_camera_shake(false)
	screen.computer_enabled = false
	for uci in ["e2e4", "d7d5"]:
		var result = screen.controller.submit_uci(uci)
		assert(result != null, "The capture fixture must submit each legal move directly to the authoritative controller.")
		await screen._present_result(result)
		screen._after_presentation(result, false)
	board_camera.zoom_by(1.7)
	board_camera.orbit_by(0.7, -0.12)
	assert(screen.get_node("UI/QuickResetView").visible, "Manual camera changes must reveal the compact Reset view control.")
	var board_camera_transform: Transform3D = board_camera.global_transform
	var capture_result = screen.controller.submit_uci("e4d5")
	assert(capture_result != null, "The capture fixture must submit the final legal capture.")
	await screen._present_result(capture_result)
	screen._after_presentation(capture_result, false)
	screen.computer_enabled = true
	assert(screen.get_node("BoardPresenter").matches_state(screen.controller.game.state), "Capture presentation must settle on the committed board state.")
	assert(&"dual_sword_impact" in screen.get_node("ArenaAudioDirector").played_sfx_kinds, "Pawn captures must emit a weapon-specific dual-sword impact sound.")
	assert(capture_ui_is_clean[0] and not screen.get_node("UI/Move").visible, "Capture cinematics must leave the board-first HUD clean without a battle-skip control.")
	assert(board_camera.global_transform.is_equal_approx(board_camera_transform), "Capture presentation must preserve a manually chosen board view without zooming or snapping.")
	assert(board_camera.focused_side() == screen.player_side, "The preserved board view must remain associated with the human player's side.")
	assert(not screen.has_node("UI/Skip"), "Players should watch the complete battle; Skip battle must not be present in the game HUD.")
	var check_result := MoveResult.new()
	check_result.is_checkmate = true
	screen.controller.game.state.side_to_move = -screen.player_side
	var victory_copy: Dictionary = screen._outcome_copy(check_result, false)
	assert("VICTORY" in victory_copy.title, "Checkmate must clearly distinguish a player victory from a generic game-over state.")
	screen.controller.game.state.side_to_move = screen.player_side
	var defeat_copy: Dictionary = screen._outcome_copy(check_result, false)
	assert("DEFEAT" in defeat_copy.title, "Checkmate must clearly distinguish a player defeat.")
	screen._show_outcome_banner("CHECK!", Color.WHITE, 0.01)
	assert(screen.get_node("UI/OutcomeBanner").visible, "Checks and final outcomes need a prominent board-facing callout.")
	board_camera.reset_view()
	assert(not screen.get_node("UI/QuickResetView").visible, "Reset view must hide after restoring the default board framing.")
	assert(is_zero_approx(screen.get_node("ImpactFlash").light_energy), "Impact flash must clean up after a capture.")
	var campaign_win = MoveResult.new()
	campaign_win.is_checkmate = true
	screen.spectator_enabled = false
	screen.controller.game.state.side_to_move = -1
	assert(screen._record_campaign_victory_if_earned(campaign_win), "A human checkmate at the current arena must unlock the next campaign location.")
	assert(screen.campaign.current_arena() == "arcane_sky_citadel", "Campaign victory must advance from Mountain Fortress Terrace to Arcane Sky Citadel.")
	assert(not screen._record_campaign_victory_if_earned(campaign_win), "The same arena victory cannot unlock multiple campaign locations.")
	screen._set_capture_speed(1)
	screen._set_camera_shake(false)
	screen._set_master_volume(-8.0)
	screen.queue_free()
	await process_frame
	var restored_screen = GAME_SCREEN.instantiate()
	root.add_child(restored_screen)
	await process_frame
	await process_frame
	assert(restored_screen.computer_enabled, "Stockfish-only V1 must ignore an older saved local-play preference.")
	assert(restored_screen.get_node("UI/AnimationSpeed").selected == 1, "Capture-speed preference must survive a relaunch.")
	assert(not restored_screen.get_node("CameraDirector").shake_enabled, "Camera-shake preference must survive a relaunch.")
	assert(is_equal_approx(AudioServer.get_bus_volume_db(0), -8.0), "Master-volume preference must survive a relaunch.")
	restored_screen.queue_free()
	await process_frame
	var arena_session := SessionSettings.DEFAULTS.duplicate()
	arena_session.selected_arena_id = "arcane_sky_citadel"
	arena_session.campaign_snapshot = {
		"current_arena_id": "arcane_sky_citadel",
		"unlocked_ids": ["mountain_fortress", "arcane_sky_citadel"],
		"completed_ids": ["mountain_fortress"],
	}
	assert(SessionSettings.save_values(arena_session) == OK)
	var arcane_screen = GAME_SCREEN.instantiate()
	root.add_child(arcane_screen)
	await process_frame
	await process_frame
	assert(arcane_screen.arena_id == "arcane_sky_citadel" and arcane_screen.get_node("BattlefieldEnvironment").arena_id == "arcane_sky_citadel", "A campaign-selected arena must apply its own presentation environment to the match.")
	assert("Arcane Sky Citadel" in arcane_screen.get_node("UI/ArenaTitle").text, "The selected arena identity must appear in the match HUD.")
	assert("Sky Seer" in arcane_screen.get_node("UI/ArenaIntro/Panel/Content/Challenge").text, "Each arena intro must introduce its own campaign opponent.")
	arcane_screen.queue_free()
	await process_frame
	var practice_session := SessionSettings.DEFAULTS.duplicate()
	practice_session.selected_arena_id = "lava_forge"
	practice_session.campaign_enabled = false
	assert(SessionSettings.save_values(practice_session) == OK)
	var practice_screen = GAME_SCREEN.instantiate()
	root.add_child(practice_screen)
	await process_frame
	await process_frame
	assert(practice_screen.arena_id == "lava_forge" and practice_screen.get_node("BattlefieldEnvironment").arena_id == "lava_forge", "Practice must allow any selected arena even while it remains campaign-locked.")
	practice_screen.queue_free()
	await process_frame
	assert(SessionSettings.save_values(SessionSettings.DEFAULTS) == OK)
	var surrender_screen = GAME_SCREEN.instantiate()
	root.add_child(surrender_screen)
	await process_frame
	await process_frame
	surrender_screen._surrender_and_return()
	await process_frame
	var surrendering_count := 0
	var victorious_count := 0
	for actor in surrender_screen.get_node("BoardPresenter").actors.values():
		if actor.side == surrender_screen.player_side:
			assert(actor.current_semantic_state() == &"death.backward_01", "Only the human player's army should fall after surrendering.")
			surrendering_count += 1
		else:
			assert(actor.current_semantic_state() != &"death.backward_01", "The victorious army must stay standing after a surrender.")
			victorious_count += 1
	assert(surrender_screen.surrendering and surrendering_count > 0 and victorious_count > 0, "Surrendering must animate the human army falling while the opposing army celebrates.")
	surrender_screen.queue_free()
	print("PASS: playable screen completes a player move and Stockfish response.")
	quit(0)
