extends SceneTree

const LAB_SCENE = preload("res://scenes/debug/DebugCinematicLab.tscn")
const BoardState = preload("res://scripts/chess/board_state.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lab = LAB_SCENE.instantiate()
	root.add_child(lab)
	await process_frame
	await process_frame
	for arena_id in ["arcane_sky_citadel", "frozen_keep", "lava_forge", "forest_ruins"]:
		lab._arena_id = arena_id
		lab.get_node("BattlefieldEnvironment").apply_arena(arena_id)
		assert(lab.get_node("BattlefieldEnvironment").arena_id == arena_id)
		for fixture_name in ["Opening formation", "Settled victory"]:
			for human_side in [1, -1]:
				for outcome in ["intro", "victory", "defeat", "draw", "conquest"]:
					if outcome == "conquest" and arena_id != "forest_ruins":
						continue
					await _assert_skip_restoration(lab, fixture_name, human_side, outcome, outcome == "intro")
	lab.queue_free()
	await process_frame
	print("PASS: Arcane, Frozen, Lava, and Forest Lab matrix covers both sides, all delivered outcomes, sparse boards, and early/late skip restoration.")
	quit(0)


func _assert_skip_restoration(lab: Node, fixture_name: String, human_side: int, outcome: String, late_skip: bool) -> void:
	lab._fixture_name = fixture_name
	lab._human_side = human_side
	lab._outcome = outcome
	lab.get_node("CampaignCinematic").playback_speed = 40.0
	lab._play()
	var cinematic = lab.get_node("CampaignCinematic")
	var deadline := Time.get_ticks_msec() + 1200
	while not cinematic.is_active() and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(cinematic.is_active(), "Arcane %s must start for %s on %s." % [outcome, human_side, fixture_name])
	if late_skip:
		await create_timer(0.25).timeout
	else:
		await process_frame
	cinematic.skip()
	deadline = Time.get_ticks_msec() + 1500
	while cinematic.is_active() and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not cinematic.is_active(), "Arcane %s Skip must release cinematic ownership." % outcome)
	assert(lab.get_node("BoardPresenter").matches_state(BoardState.from_fen(lab.FIXTURES[fixture_name])), "Arcane %s Skip must restore the authoritative %s projection." % [outcome, fixture_name])
