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
	var board = lab.get_node("BoardPresenter")
	assert(board.actor_count() == 32, "The lab must project its immutable opening FEN through the real BoardPresenter.")
	assert(lab.has_node("ChessBoard") and lab.has_node("BattlefieldEnvironment") and lab.has_node("GrandmasterCeremony"))
	assert(lab.get_node("UI/Controls/Fixture").item_count == 2, "The lab must offer an explicit settled-position fixture.")
	lab._play()
	var deadline := Time.get_ticks_msec() + 1500
	while not lab.get_node("CampaignCinematic").is_active() and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(lab.get_node("CampaignCinematic").is_active(), "Play must start the real Mountain Fortress intro.")
	deadline = Time.get_ticks_msec() + 500
	while not lab.get_node("UI/Cue").text.contains("I · THE FIRST GATE") and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(lab.get_node("UI/Cue").text.contains("I · THE FIRST GATE"), "The active cue must be visible in the debug UI.")
	var visible_kings := 0
	for actor in board.actors.values():
		if actor.visible and actor.archetype == 6:
			visible_kings += 1
	assert(visible_kings == 2 and lab.get_node("GrandmasterCeremony/Grandmaster").visible, "The lab intro must stage both real kings and the Grandmaster.")
	await create_timer(1.25).timeout
	for actor in board.actors.values():
		if actor.archetype == 6:
			assert(is_equal_approx(actor.global_position.z, -6.5) and is_equal_approx(absf(actor.global_position.x), 3.2), "Normal-speed lab travel must reach the real parley markers.")
			assert(actor.current_semantic_state() == &"idle.neutral", "Arrived lab kings must stop their actual walk clip.")
	lab.get_node("CampaignCinematic").skip()
	deadline = Time.get_ticks_msec() + 2000
	while lab.get_node("CampaignCinematic").is_active() and Time.get_ticks_msec() < deadline:
		await process_frame
	assert(not lab.get_node("CampaignCinematic").is_active())
	assert(board.matches_state(BoardState.from_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")), "Skip must restore the immutable authoritative projection.")
	lab._fixture_name = "Settled victory"
	await lab._rebuild_fixture()
	assert(board.actor_count() == 3, "The victory fixture must be a real sparse, settled board projection.")
	lab.queue_free()
	await process_frame
	print("PASS: Cinematic Lab uses real Mountain ceremony actors and immutable opening/victory board fixtures.")
	quit(0)
