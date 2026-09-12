extends SceneTree

const GAME_SCREEN = preload("res://scenes/app/GameScreen.tscn")
const SessionSettings = preload("res://scripts/game/session_settings.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var values := SessionSettings.DEFAULTS.duplicate(true)
	values.selected_arena_id = "arcane_sky_citadel"
	values.campaign_snapshot = {
		"current_arena_id": "arcane_sky_citadel",
		"unlocked_ids": ["mountain_fortress", "arcane_sky_citadel"],
		"completed_ids": ["mountain_fortress"],
	}
	assert(SessionSettings.save_values(values) == OK)
	var screen = GAME_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	assert(screen.arena_id == "arcane_sky_citadel" and screen.screen_phase == screen.ScreenPhase.INTRO, "An unlocked Arcane campaign entry must select its authored intro.")
	var title: Label = screen.get_node("CampaignCinematic/Overlay/SpeechBubble/Content/Title")
	var deadline := Time.get_ticks_msec() + 1000
	while title.text != "II · THE CLOUD ROAD" and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(title.text == "II · THE CLOUD ROAD")
	screen.get_node("CampaignCinematic").skip()
	deadline = Time.get_ticks_msec() + 3000
	while screen.screen_phase != screen.ScreenPhase.PLAYING and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(screen.screen_phase == screen.ScreenPhase.PLAYING and screen.controller.phase == screen.controller.Phase.PLAYER_INPUT)
	screen.queue_free()
	await process_frame
	print("PASS: Arcane campaign entry selects its authored intro and safely hands off after Skip.")
	quit(0)
