extends SceneTree

## Rendered audit, isolated from player saves by the XDG paths in the documented command.
var output_dir := "/tmp/cac-visual-audit"

func _init() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		output_dir = OS.get_cmdline_user_args()[0]
	call_deferred("_run")

func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(output_dir.path_join(label + ".png"))
	assert(error == OK)
	print("SCREENSHOT: ", label)

func _scene(path: String):
	if current_scene != null:
		current_scene.queue_free()
		await process_frame
	var scene = load(path).instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(2.0).timeout
	return scene

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	await _scene("res://scenes/app/CampaignMap.tscn")
	await _shot("01-campaign")
	var game = await _scene("res://scenes/app/GameScreen.tscn")
	await create_timer(3.0).timeout
	await _shot("02-board")
	game.get_node("ChessBoard").set_highlights(12, [20, 28])
	await _shot("03-selection")
	game.get_node("ChessBoard").set_highlights(-1, [])
	game.get_node("UI/Move").text = "e2e4"
	game._submit()
	await create_timer(5.0).timeout
	assert(game.controller.game.state.side_to_move == 1)
	await _shot("04-engine-reply")
	game._set_settings_menu_visible(true)
	await _shot("05-settings")
	game._set_settings_menu_visible(false)
	for arena_id in ["mountain_fortress", "arcane_sky_citadel", "frozen_keep", "lava_forge", "forest_ruins"]:
		game.get_node("BattlefieldEnvironment").apply_arena(arena_id)
		for side in [1, -1]:
			game.get_node("Camera3D").snap_to_side(side, 0.0)
			await create_timer(0.2).timeout
			await _shot("arena-%s-%d" % [arena_id, side])
	var loader = await _scene("res://scenes/debug/DebugPositionLoader.tscn")
	loader.load_fen(loader.PRESETS["Capture framing"])
	await _shot("06-position-loader")
	var browser = await _scene("res://scenes/debug/DebugAnimationBrowser.tscn")
	for index in range(6):
		browser._select_archetype(index)
		browser.get_node("UI/Margin/Controls/Archetype").select(index)
		await process_frame
		browser._reset()
		await _shot("07-role-%d-idle" % index)
		browser._play(&"locomotion.walk.forward", "Walk")
		await create_timer(0.25).timeout
		await _shot("07-role-%d-walk" % index)
		browser._play_primary_attack()
		await create_timer(0.35).timeout
		await _shot("07-role-%d-contact" % index)
		browser._actor.side = -1
		browser._actor.restore_board_facing()
		await _shot("07-role-%d-black-view" % index)
		browser._actor.side = 1
		browser._actor.restore_board_facing()
	var lab = await _scene("res://scenes/debug/DebugCombatLab.tscn")
	await _shot("08-combat-ready")
	lab._play_capture()
	await lab.get_node("BattleDirector").impact_landed
	await _shot("09-combat-impact")
	await lab.get_node("BattleDirector").presentation_finished
	await _shot("10-combat-settled")
	lab._reset_lab()
	await _shot("11-combat-reset")
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
		await _shot("12-spell-%d-impact" % spell_role)
		await lab.get_node("BattleDirector").presentation_finished
		lab._reset_lab()
		await process_frame
	quit()
