extends SceneTree

const Evidence = preload("res://tools/visual_evidence_harness.gd")
const GAME_SCREEN = preload("res://scenes/app/GameScreen.tscn")
const SessionSettings = preload("res://scripts/game/session_settings.gd")
const Types = preload("res://scripts/chess/chess_types.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var settings := SessionSettings.DEFAULTS.duplicate(true)
	settings.campaign_enabled = false
	settings.campaign_cinematics_enabled = false
	settings.spectator_enabled = false
	assert(SessionSettings.save_values(settings) == OK)
	var game = GAME_SCREEN.instantiate()
	root.add_child(game)
	var deadline := Time.get_ticks_msec() + 12000
	while (game.controller == null or game.screen_phase != game.ScreenPhase.PLAYING or game.get_node("UI/ArenaIntro").visible) and Time.get_ticks_msec() < deadline:
		await process_frame
	game.computer_enabled = false
	game._invalidate_engine_work()
	game.get_node("Camera3D").snap_to_side(Types.WHITE, 0.0)
	while game.engine != null and game.engine.has_pending_request() and Time.get_ticks_msec() < deadline:
		await process_frame
	var harness := Evidence.new("/tmp/cac-visual-evidence-contract", "test", Vector2i(1280, 720))
	var failures := harness.gameplay_errors(game, Types.STARTING_FEN, 0, 32)
	assert(failures.is_empty(), "A settled start fixture must satisfy the visual evidence contract: %s" % [failures])
	game.get_node("CampaignCinematic/Overlay").visible = true
	failures = harness.gameplay_errors(game, Types.STARTING_FEN, 0, 32)
	assert("cinematic overlay is visible" in failures, "The fixture contract must reject mislabeled gameplay while a cinematic overlay is visible.")
	game.get_node("CampaignCinematic/Overlay").visible = false
	game.get_node("UI/ArenaIntro").visible = true
	failures = harness.gameplay_errors(game, Types.STARTING_FEN, 0, 32)
	assert("arena intro overlay is visible" in failures, "The fixture contract must reject gameplay while the arena title card is visible.")
	game.get_node("UI/ArenaIntro").visible = false
	failures = harness.gameplay_errors(game, Types.STARTING_FEN, 2, 32)
	assert(failures.any(func(message): return "move history" in message), "The fixture contract must reject an unproven 0 -> 1 -> 2 engine history.")
	game.get_node("Camera3D").current = false
	failures = harness.gameplay_errors(game, Types.STARTING_FEN, 0, 32)
	assert("board camera is not active" in failures, "The fixture contract must reject gameplay without the board camera.")
	game.queue_free()
	await process_frame
	print("PASS: visual evidence fixtures accept settled gameplay and reject cinematic, history, and camera mismatches.")
	quit(0)
