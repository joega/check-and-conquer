extends SceneTree

const GAME_SCREEN = preload("res://scenes/app/GameScreen.tscn")
const SessionSettings = preload("res://scripts/game/session_settings.gd")
const MoveResult = preload("res://scripts/chess/move_result.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var values := SessionSettings.DEFAULTS.duplicate(true)
	values.selected_arena_id = "forest_ruins"
	values.campaign_snapshot = {
		"current_arena_id": "forest_ruins",
		"unlocked_ids": ["mountain_fortress", "arcane_sky_citadel", "frozen_keep", "lava_forge", "forest_ruins"],
		"completed_ids": ["mountain_fortress", "arcane_sky_citadel", "frozen_keep", "lava_forge"],
	}
	assert(SessionSettings.save_values(values) == OK)
	var screen = GAME_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	screen.get_node("CampaignCinematic").skip()
	while screen.screen_phase != screen.ScreenPhase.PLAYING:
		await process_frame
	var result = MoveResult.new()
	result.is_checkmate = true
	screen.controller.game.state.side_to_move = -screen.player_side
	assert(screen._record_campaign_victory_if_earned(result), "The final eligible win must persist exactly once.")
	assert(screen.campaign.campaign_complete() and screen._terminal_cinematic_kind(result, true) == "conquest")
	assert(not screen._record_campaign_victory_if_earned(result), "A completed campaign must reject a repeat save.")
	assert(screen._terminal_cinematic_kind(result, false) == "victory", "A repeat final win must use ordinary victory, never conquest.")
	screen.queue_free()
	await process_frame
	print("PASS: only a newly earned final campaign victory selects conquest; repeat wins preserve completion and use ordinary victory.")
	quit(0)
