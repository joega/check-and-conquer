extends SceneTree

const GAME_SCREEN = preload("res://scenes/app/GameScreen.tscn")
const SessionSettings = preload("res://scripts/game/session_settings.gd")
const MoveResult = preload("res://scripts/chess/move_result.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _assert_terminal_kind("defeat", true, true)
	await _assert_terminal_kind("draw", false, false)
	await _assert_terminal_kind("victory", true, false)
	print("PASS: authoritative terminal facts select defeat, draw, and repeat-victory sequences without changing campaign progress.")
	quit(0)


func _assert_terminal_kind(expected_kind: String, checkmate: bool, human_loses: bool) -> void:
	assert(SessionSettings.save_values(SessionSettings.DEFAULTS) == OK)
	var screen = GAME_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	screen.get_node("CampaignCinematic").skip()
	var deadline := Time.get_ticks_msec() + 3000
	while screen.screen_phase != screen.ScreenPhase.PLAYING and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(screen.screen_phase == screen.ScreenPhase.PLAYING)
	var result = MoveResult.new()
	result.game_result = "checkmate" if checkmate else "draw_threefold_repetition"
	result.is_checkmate = checkmate
	screen.controller.phase = screen.controller.Phase.GAME_OVER
	if checkmate:
		# A stale/current-arena mismatch makes this an ordinary repeat win, proving
		# playback selection does not depend on a fresh unlock.
		screen.campaign.current_arena_id = "arcane_sky_citadel"
		screen.controller.game.state.side_to_move = screen.player_side if human_loses else -screen.player_side
	var before_snapshot: Dictionary = screen.campaign.to_snapshot()
	screen._after_presentation(result, false)
	deadline = Time.get_ticks_msec() + 1000
	while screen.screen_phase != screen.ScreenPhase.OUTRO and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(screen.screen_phase == screen.ScreenPhase.OUTRO, "A campaign %s must enter an outro after terminal presentation settles." % expected_kind)
	var title: Label = screen.get_node("CampaignCinematic/Overlay/SpeechBubble/Content/Title")
	var expected_title: String = {"defeat": "THE ROAD REMAINS", "draw": "THE ROAD REMAINS CONTESTED", "victory": "THE FIRST OATH"}[expected_kind]
	deadline = Time.get_ticks_msec() + 1000
	while title.text != expected_title and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(title.text == expected_title, "Terminal %s must select its authored sequence." % expected_kind)
	assert(screen.campaign.to_snapshot() == before_snapshot, "Defeat, draw, and repeat victory must not unlock or persist campaign progress.")
	screen.get_node("CampaignCinematic").skip()
	deadline = Time.get_ticks_msec() + 3000
	while screen.screen_phase != screen.ScreenPhase.RESULTS and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(screen.screen_phase == screen.ScreenPhase.RESULTS and screen.get_node("UI/GameOverPanel").visible)
	screen.queue_free()
	await process_frame
