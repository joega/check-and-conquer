extends SceneTree

## Rendered audit, isolated from player saves by the XDG paths in the documented command.
const Evidence = preload("res://tools/visual_evidence_harness.gd")
const SessionSettings = preload("res://scripts/game/session_settings.gd")
const Types = preload("res://scripts/chess/chess_types.gd")
const ArenaCatalog = preload("res://scripts/presentation/arena_catalog.gd")

var output_dir := "/tmp/cac-visual-audit"
var revision := "working-tree"
var expected_size := Vector2i(1280, 720)
var evidence
var audit_scene: Node

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		output_dir = args[0]
	if args.size() > 1:
		revision = args[1]
	if args.size() > 2:
		expected_size = _parse_size(args[2])
	call_deferred("_run")

func _parse_size(value: String) -> Vector2i:
	var fields := value.to_lower().split("x", false)
	assert(fields.size() == 2 and fields[0].is_valid_int() and fields[1].is_valid_int(), "Size must be WIDTHxHEIGHT.")
	return Vector2i(int(fields[0]), int(fields[1]))


func _shot(label: String, fixture: Dictionary = {}) -> void:
	await evidence.capture(self, label, fixture)

func _scene(path: String, configure: Callable = Callable()):
	if audit_scene != null:
		audit_scene.queue_free()
		await process_frame
	var scene = load(path).instantiate()
	if configure.is_valid():
		configure.call(scene)
	evidence.viewport.add_child(scene)
	audit_scene = scene
	await process_frame
	return scene


func _configure_game_fixture(game) -> void:
	game.campaign_enabled = false
	game.arena_id = "mountain_fortress"


func _wait_for_gameplay(game, expected_history: int, description: String) -> void:
	await evidence.wait_until(self, func():
		return game.controller != null \
			and game.screen_phase == game.ScreenPhase.PLAYING \
			and game.controller.phase == game.controller.Phase.PLAYER_INPUT \
			and game.controller.game.move_history.size() == expected_history \
			and not game.get_node("UI/ArenaIntro").visible \
			and not game.engine_request_pending \
			and not game.hint_request_pending \
			and game._engine_request.is_empty() \
			and game.engine != null \
			and not game.engine.has_pending_request()
	, description, 20000)

func _run() -> void:
	evidence = Evidence.new(output_dir, revision, expected_size)
	await evidence.configure_window(self)
	var fixture_settings := SessionSettings.DEFAULTS.duplicate(true)
	fixture_settings.campaign_enabled = false
	fixture_settings.campaign_cinematics_enabled = false
	fixture_settings.selected_arena_id = "mountain_fortress"
	fixture_settings.player_side_index = 0
	fixture_settings.capture_speed_index = 0
	fixture_settings.spectator_enabled = false
	fixture_settings.beginner_coach_enabled = false
	fixture_settings.fullscreen = false
	assert(SessionSettings.save_values(fixture_settings) == OK, "Could not save isolated audit settings.")
	var campaign_map = await _scene("res://scenes/app/CampaignMap.tscn")
	campaign_map.set_campaign_snapshot({
		"current_arena_id": "forest_ruins",
		"unlocked_ids": ["mountain_fortress", "arcane_sky_citadel", "frozen_keep", "lava_forge", "forest_ruins"],
		"completed_ids": ["mountain_fortress", "arcane_sky_citadel", "frozen_keep", "lava_forge", "forest_ruins"],
	})
	await process_frame
	await _shot("01-campaign-conquered", {"fixture": "campaign", "arena": "forest_ruins", "seed": 88421})
	var game = await _scene("res://scenes/app/GameScreen.tscn", _configure_game_fixture)
	await _wait_for_gameplay(game, 0, "settled starting gameplay fixture")
	game.computer_enabled = true
	game.player_side = Types.WHITE
	game.get_node("BattleDirector").playback_speed = 1.0
	game.get_node("BoardPresenter")._ambient_rng.seed = 88421
	game.get_node("BoardPresenter")._ambient_motion_timer_s = 9999.0
	game.get_node("Camera3D").snap_to_side(Types.WHITE, 0.0)
	var start_fixture: Dictionary = evidence.assert_gameplay(game, Types.STARTING_FEN, 0, 32)
	start_fixture.merge({"fixture": "starting_board", "arena": "mountain_fortress", "side": "white", "seed": 88421, "animation_speed": 1.0, "cinematic_mode": "disabled"})
	await _shot("02-board", start_fixture)
	game.get_node("ChessBoard").set_highlights(12, [20, 28])
	await _shot("03-selection", start_fixture.merged({"fixture": "selection", "selected_square": "e2", "legal_targets": ["e3", "e4"]}, true))
	game.get_node("ChessBoard").set_highlights(-1, [])
	game.get_node("UI/Move").text = "e2e4"
	game._submit()
	await evidence.wait_until(self, func(): return game.controller != null and game.controller.game.move_history.size() >= 1, "accepted e2e4 history transition", 10000)
	evidence.mark_event("history_advanced", "engine_reply", 0.0, {"from": 0, "to": 1, "move": "e2e4"})
	await _wait_for_gameplay(game, 2, "legal Stockfish reply and settled projection")
	evidence.mark_event("history_advanced", "engine_reply", 0.0, {"from": 1, "to": 2, "move": game.controller.game.move_history[1]})
	var engine_fixture: Dictionary = evidence.assert_gameplay(game, "", 2, 32)
	engine_fixture.merge({"fixture": "engine_reply", "history_transition": [0, 1, 2], "arena": "mountain_fortress", "side": "white", "seed": 88421, "animation_speed": 1.0, "cinematic_mode": "disabled"})
	await _shot("04-engine-reply", engine_fixture)
	game._set_settings_menu_visible(true)
	await _shot("05-settings", engine_fixture.merged({"fixture": "settings"}, true))
	game._set_settings_menu_visible(false)
	for arena_id in ["mountain_fortress", "arcane_sky_citadel", "frozen_keep", "lava_forge", "forest_ruins"]:
		game.arena_id = arena_id
		game.get_node("BattlefieldEnvironment").apply_arena(arena_id)
		game.get_node("UI/ArenaTitle").text = "%s  —  %s" % [ArenaCatalog.definition(arena_id).chapter, ArenaCatalog.definition(arena_id).title]
		for side in [1, -1]:
			game.get_node("Camera3D").snap_to_side(side, 0.0)
			await process_frame
			await _shot("arena-%s-%d" % [arena_id, side], engine_fixture.merged({"fixture": "arena", "arena": arena_id, "side": "white" if side > 0 else "black", "hud_title": game.get_node("UI/ArenaTitle").text}, true))
	var loader = await _scene("res://scenes/debug/DebugPositionLoader.tscn")
	loader.load_fen(loader.PRESETS["Capture framing"])
	assert(loader.get_node("BoardPresenter").matches_state(loader.current_state), "Position Loader projection must match its FEN.")
	await _shot("06-position-loader", {"fixture": "position_loader", "fen": loader.current_state.to_fen(), "actor_count": loader.get_node("BoardPresenter").actor_count(), "seed": 88421})
	var browser = await _scene("res://scenes/debug/DebugAnimationBrowser.tscn")
	for index in range(6):
		browser._select_archetype(index)
		browser.get_node("UI/Margin/Controls/Archetype").select(index)
		await process_frame
		browser._reset()
		await _shot("07-role-%d-idle" % index, {"fixture": "animation_browser", "archetype_index": index, "semantic_state": "stance.idle", "sample_kind": "settled"})
		browser._play(&"locomotion.walk.forward", "Walk")
		await create_timer(0.25).timeout
		await _shot("07-role-%d-walk" % index, {"fixture": "animation_browser", "archetype_index": index, "semantic_state": "locomotion.walk.forward", "sample_kind": "timed_pose", "sample_time_s": 0.25})
		browser._play_primary_attack()
		await create_timer(0.35).timeout
		await _shot("07-role-%d-attack-timed-pose" % index, {"fixture": "animation_browser", "archetype_index": index, "semantic_state": str(browser._actor.current_semantic_state()), "sample_kind": "timed_pose", "sample_time_s": 0.35, "claim": "No contact claim; use Combat Lab impact event for contact evidence."})
		if index == 3:
			browser._play_recovery()
			await create_timer(0.16).timeout
			await _shot("07-role-%d-capture-recovery" % index, {"fixture": "animation_browser", "archetype_index": index, "semantic_state": "reaction.capture_recover", "sample_kind": "timed_pose", "sample_time_s": 0.16})
			browser._play_victory()
			await create_timer(0.16).timeout
			await _shot("07-role-%d-victory" % index, {"fixture": "animation_browser", "archetype_index": index, "semantic_state": "reaction.victory", "sample_kind": "timed_pose", "sample_time_s": 0.16})
		browser._actor.side = -1
		browser._actor.restore_board_facing()
		await _shot("07-role-%d-black-view" % index, {"fixture": "animation_browser", "archetype_index": index, "side": "black", "sample_kind": "settled"})
		browser._actor.side = 1
		browser._actor.restore_board_facing()
	var lab = await _scene("res://scenes/debug/DebugCombatLab.tscn")
	lab.get_node("BattleDirector").playback_speed = 1.0
	await _shot("08-combat-ready", {"fixture": "combat_lab", "attacker": "pawn", "victim": "pawn", "event": "ready", "animation_speed": 1.0})
	lab._play_capture()
	await lab.get_node("BattleDirector").impact_landed
	evidence.mark_event("impact_landed", "pawn_vs_pawn", 0.0)
	await _shot("09-combat-impact", {"fixture": "combat_lab", "attacker": "pawn", "victim": "pawn", "event": "impact_landed", "animation_speed": 1.0})
	await lab.get_node("BattleDirector").presentation_finished
	await _shot("10-combat-settled", {"fixture": "combat_lab", "attacker": "pawn", "victim": "pawn", "event": "presentation_finished", "animation_speed": 1.0})
	lab._reset_lab()
	await _shot("11-combat-reset", {"fixture": "combat_lab", "attacker": "pawn", "victim": "pawn", "event": "reset", "animation_speed": 1.0})
	lab._preview_recovery()
	await create_timer(0.16).timeout
	await _shot("11b-combat-recovery", {"fixture": "combat_lab", "event": "recovery_timed_pose", "sample_time_s": 0.16})
	lab._preview_victory()
	await create_timer(0.16).timeout
	await _shot("11c-combat-victory", {"fixture": "combat_lab", "event": "victory_timed_pose", "sample_time_s": 0.16})
	lab._reset_lab()
	await process_frame
	# Explicit spell captures exercise the visual changes rather than relying on
	# the default melee lab pairing.
	for spell_role in [2, 4]:
		lab._select_attacker(spell_role)
		lab._select_victim(0)
		lab.get_node("UI/Margin/Controls/AttackerArchetype").select(spell_role)
		lab.get_node("UI/Margin/Controls/VictimArchetype").select(0)
		await process_frame
		lab._play_capture()
		await lab.get_node("BattleDirector").impact_landed
		evidence.mark_event("impact_landed", "spell_%d" % spell_role, 0.0)
		await _shot("12-spell-%d-impact" % spell_role, {"fixture": "combat_lab", "attacker_archetype": spell_role, "victim": "pawn", "event": "impact_landed", "animation_speed": 1.0})
		await lab.get_node("BattleDirector").presentation_finished
		lab._reset_lab()
		await process_frame
	evidence.write_manifest("manifest.json", {
		"tool": "capture_visual_audit.gd",
		"baseline_manifest": "artifacts/presentation_overhaul/baseline/visual-%dx%d/manifest.json" % [expected_size.x, expected_size.y],
		"settings": fixture_settings,
		"assertions": [
			"starting board has exact start FEN, 32 actors, PLAYING/PLAYER_INPUT, board camera, no cinematic overlay",
			"engine fixture advances history 0 -> 1 -> 2 and ends settled with no pending engine request",
			"role attack images are timed pose samples; combat contact images use impact_landed",
		],
	})
	quit(evidence.exit_code())
