extends SceneTree

const Catalog = preload("res://scripts/presentation/campaign_cinematic_catalog.gd")
const CINEMATIC = preload("res://scenes/presentation/CampaignCinematic.tscn")
const BoardCamera = preload("res://scripts/presentation/board_camera_controller.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var intro: Resource = Catalog.sequence_for("mountain_fortress", "intro")
	assert(intro != null and intro.sequence_id == "mountain_fortress.intro")
	assert(intro.arena_id == "mountain_fortress" and intro.outcome == "intro")
	assert(intro.cues.size() == 4 and is_equal_approx(_duration(intro), 15.3))
	assert(_cue_values(intro, "speaker_id") == ["grandmaster", "gatekeeper", "commander", "grandmaster"])
	assert(_cue_values(intro, "stage_action") == ["seating_and_approach", "", "", "return"])
	assert(_cue_values(intro, "after_action") == ["", "", "", "formation_restore"])
	var victory: Resource = Catalog.sequence_for("mountain_fortress", "victory")
	assert(victory != null and victory.sequence_id == "mountain_fortress.victory")
	assert(victory.cues.size() == 2 and is_equal_approx(_duration(victory), 10.7))
	var defeat: Resource = Catalog.terminal_sequence_for("mountain_fortress", "defeat")
	var draw: Resource = Catalog.terminal_sequence_for("mountain_fortress", "draw")
	assert(defeat.sequence_id == "shared.defeat" and is_equal_approx(_duration(defeat), 6.25))
	assert(draw.sequence_id == "shared.draw" and is_equal_approx(_duration(draw), 5.25))
	var arcane_intro: Resource = Catalog.sequence_for("arcane_sky_citadel", "intro")
	var arcane_victory: Resource = Catalog.sequence_for("arcane_sky_citadel", "victory")
	var arcane_defeat: Resource = Catalog.terminal_sequence_for("arcane_sky_citadel", "defeat")
	assert(arcane_intro.cues.size() == 4 and is_equal_approx(_duration(arcane_intro), 19.8))
	assert(_cue_values(arcane_intro, "cue_id") == ["arcane.opening", "arcane.guardian", "arcane.commander", "arcane.objective"])
	assert(arcane_victory.cues.size() == 2 and arcane_defeat.sequence_id == "arcane_sky_citadel.defeat")
	assert(Catalog.sequence_for("unknown", "intro") == null, "Unavailable arena/outcome pairs must have no authored sequence.")
	await _assert_missing_data_falls_back()
	print("PASS: Campaign cinematic catalog declares Mountain sequence identity, ordered cues, and safe missing-data fallback.")
	quit(0)


func _duration(sequence: Resource) -> float:
	var total: float = sequence.final_hold_s
	for cue in sequence.cues:
		total += cue.hold_s
	return total


func _cue_values(sequence: Resource, property: String) -> Array:
	var values: Array = []
	for cue in sequence.cues:
		values.append(cue.get(property))
	return values


func _assert_missing_data_falls_back() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var board_camera := BoardCamera.new()
	board_camera.name = "BoardCamera"
	stage.add_child(board_camera)
	var cinematic := CINEMATIC.instantiate()
	cinematic.board_camera_path = NodePath("../BoardCamera")
	cinematic.cinematic_camera_path = NodePath("CinematicCamera")
	cinematic.overlay_path = NodePath("Overlay")
	stage.add_child(cinematic)
	await process_frame
	var run_id: int = cinematic.play_sequence(Catalog.sequence_for("unknown", "intro"), 1)
	assert(cinematic.is_active(), "Fallback completion must stay asynchronous for callers that await it.")
	var completion: Array = await cinematic.finished
	assert(int(completion[0]) == run_id and completion[1] == "fallback")
	assert(not cinematic.is_active() and board_camera.controls_enabled())
	stage.queue_free()
	await process_frame
