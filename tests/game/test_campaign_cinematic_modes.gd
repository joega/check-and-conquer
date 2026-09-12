extends SceneTree

const GAME_SCREEN = preload("res://scenes/app/GameScreen.tscn")
const SessionSettings = preload("res://scripts/game/session_settings.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var practice := SessionSettings.DEFAULTS.duplicate()
	practice.campaign_enabled = false
	practice.campaign_cinematics_enabled = true
	practice.selected_arena_id = "lava_forge"
	var practice_screen = await _spawn(practice)
	assert(practice_screen.screen_phase == practice_screen.ScreenPhase.PLAYING and not practice_screen.get_node("CampaignCinematic").is_active(), "Practice must bypass campaign cinematics.")
	practice_screen.queue_free()
	await process_frame
	var spectator := SessionSettings.DEFAULTS.duplicate()
	spectator.spectator_enabled = true
	spectator.campaign_cinematics_enabled = true
	var spectator_screen = await _spawn(spectator)
	assert(spectator_screen.screen_phase == spectator_screen.ScreenPhase.PLAYING and not spectator_screen.get_node("CampaignCinematic").is_active(), "Spectator matches must bypass campaign cinematics.")
	spectator_screen.queue_free()
	await process_frame
	var black := SessionSettings.DEFAULTS.duplicate()
	black.player_side_index = 1
	black.campaign_cinematics_enabled = true
	var black_screen = await _spawn(black)
	assert(black_screen.screen_phase == black_screen.ScreenPhase.INTRO)
	black_screen.get_node("CampaignCinematic").skip()
	var deadline := Time.get_ticks_msec() + 12000
	while black_screen.controller.game.move_history.size() < 1 and Time.get_ticks_msec() < deadline:
		await create_timer(0.02).timeout
	assert(black_screen.controller.game.move_history.size() == 1, "Black must receive exactly one Stockfish opening search after intro handoff.")
	await create_timer(0.5).timeout
	assert(black_screen.controller.game.move_history.size() == 1 and not black_screen.engine_request_pending, "Engine-ready timing before or after intro may not duplicate Black's opening search.")
	black_screen.queue_free()
	await process_frame
	print("PASS: practice/spectator bypass cinematics and Black receives one post-intro opening search.")
	quit(0)


func _spawn(settings: Dictionary):
	assert(SessionSettings.save_values(settings) == OK)
	var screen = GAME_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	return screen
