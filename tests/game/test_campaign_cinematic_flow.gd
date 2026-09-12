extends SceneTree

const GAME_SCREEN = preload("res://scenes/app/GameScreen.tscn")
const SessionSettings = preload("res://scripts/game/session_settings.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	assert(SessionSettings.save_values(SessionSettings.DEFAULTS) == OK)
	var screen = GAME_SCREEN.instantiate()
	root.add_child(screen)
	assert(screen.get_node("UI/LoadingOverlay").visible and not screen.get_node("UI/Settings").visible and not screen.get_node("UI/Hint").visible, "The loading card must be the only player-facing UI before match initialization.")
	for child in screen.get_node("UI").get_children():
		if child != screen.get_node("UI/LoadingOverlay") and child is CanvasItem:
			assert(not child.visible, "No gameplay or settings control may render beneath the loading card.")
	await process_frame
	await process_frame
	assert(screen.screen_phase == screen.ScreenPhase.INTRO and screen.controller.phase == screen.controller.Phase.READY, "Campaign intro must hold chess in READY before its cinematic handoff.")
	assert(not screen.get_node("UI/Status").visible and not screen.get_node("UI/Settings").visible and not screen.get_node("UI/Hint").visible, "Story playback must own the HUD and hide gameplay controls.")
	assert(screen.get_node("CampaignCinematic/Overlay/Skip").visible, "Story playback must expose its Skip control.")
	assert(screen.has_node("GrandmasterCeremony/Grandmaster") and screen.get_node("BoardPresenter").actor_count() == 32, "The Grandmaster must remain on a dedicated dais, outside the authoritative 32-piece board projection.")
	var initial_fen: String = screen.controller.game.state.to_fen()
	screen.get_node("UI/Move").text = "e2e4"
	await screen._submit()
	assert(screen.controller.game.state.to_fen() == initial_fen, "Move input must not mutate chess state during the intro.")
	screen.get_node("CampaignCinematic").call_deferred("skip")
	var deadline := Time.get_ticks_msec() + 3000
	while screen.screen_phase != screen.ScreenPhase.PLAYING and Time.get_ticks_msec() < deadline:
		await create_timer(0.01).timeout
	assert(screen.screen_phase == screen.ScreenPhase.PLAYING and screen.controller.phase == screen.controller.Phase.PLAYER_INPUT, "Skip must hand off exactly once to the first player turn.")
	assert(screen.get_node("Camera3D").controls_enabled(), "Skipping an intro must restore board camera input.")
	assert(screen.get_node("UI/Status").visible and screen.get_node("UI/Settings").visible and screen.get_node("UI/Hint").visible, "Story handoff must restore normal HUD ownership.")
	screen._toggle_settings_menu()
	assert(screen.get_node("UI/CampaignCinematics").visible and screen.get_node("UI/CampaignCinematics").button_pressed, "Match Settings must expose the persisted cinematic preference.")
	screen._set_campaign_cinematics_enabled(false)
	assert(screen.settings.campaign_cinematics_enabled == false)
	screen._restart()
	assert(screen.screen_phase == screen.ScreenPhase.PLAYING and not screen.get_node("CampaignCinematic").is_active(), "Restart must immediately bypass a newly disabled cinematic preference.")
	screen._set_campaign_cinematics_enabled(true)
	screen._present_terminal_result.call_deferred({"title": "VICTORY!", "detail": "Mountain Fortress secured", "status": "Victory!", "color": Color.GOLD}, "victory")
	await process_frame
	assert(screen.screen_phase == screen.ScreenPhase.OUTRO and not screen.get_node("UI/GameOverPanel").visible, "A campaign victory must hold results until its outro finishes.")
	screen.get_node("CampaignCinematic").call_deferred("skip")
	deadline = Time.get_ticks_msec() + 3000
	while screen.screen_phase != screen.ScreenPhase.RESULTS and Time.get_ticks_msec() < deadline:
		await create_timer(0.01).timeout
	assert(screen.screen_phase == screen.ScreenPhase.RESULTS and screen.get_node("UI/GameOverPanel").visible, "Victory Skip must restore ownership then open the existing result/review panel.")
	screen.queue_free()
	print("PASS: campaign cinematic intro blocks chess and safely hands off after Skip.")
	quit(0)
