extends SceneTree

const CINEMATIC = preload("res://scenes/presentation/CampaignCinematic.tscn")
const BoardCamera = preload("res://scripts/presentation/board_camera_controller.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var stage := Node3D.new()
	root.add_child(stage)
	var board_camera := BoardCamera.new()
	board_camera.name = "BoardCamera"
	board_camera.position = Vector3(24, 28, 28)
	board_camera.current = true
	stage.add_child(board_camera)
	var cinematic = CINEMATIC.instantiate()
	cinematic.name = "CampaignCinematic"
	cinematic.board_camera_path = NodePath("../BoardCamera")
	cinematic.cinematic_camera_path = NodePath("CinematicCamera")
	cinematic.overlay_path = NodePath("Overlay")
	stage.add_child(cinematic)
	await process_frame
	var bubble := cinematic.get_node("Overlay/SpeechBubble") as PanelContainer
	var bubble_style := bubble.get_theme_stylebox("panel") as StyleBoxFlat
	assert(bubble_style != null and bubble_style.bg_color.a >= 0.94, "Dialogue needs an opaque reading surface over every panorama.")
	cinematic._set_cue("THE GATEKEEPER", "Gatekeeper", "Test", "")
	assert(not cinematic.get_node("Overlay/SpeechBubble/Content/Speaker").visible, "A character-name title must suppress the duplicate speaker row.")
	cinematic._set_cue("OBJECTIVE", "Grandmaster", "Test", "")
	assert(cinematic.get_node("Overlay/SpeechBubble/Content/Speaker").visible, "Objective cues must retain useful speaker identity.")
	var original_transform := board_camera.global_transform
	assert(board_camera.controls_enabled(), "The board camera must begin interactive.")
	cinematic.playback_speed = 100.0
	var completions := [0]
	cinematic.finished.connect(func(_run_id, _reason): completions[0] += 1)
	for cycle in 20:
		var run_id: int = cinematic.play_mountain_intro(1 if cycle % 2 == 0 else -1)
		assert(cinematic.is_active() and not board_camera.controls_enabled(), "A cinematic must own camera/input while its timeline runs.")
		var completion: Array = await cinematic.finished
		assert(int(completion[0]) == run_id and completion[1] == "completed", "Every cinematic run must complete exactly once.")
		assert(not cinematic.is_active() and board_camera.controls_enabled(), "Completion must return camera/input ownership.")
		assert(board_camera.current and board_camera.global_transform.is_equal_approx(original_transform), "Cinematics must preserve the player's board view without drift.")
	await process_frame
	assert(completions[0] == 20, "Twenty deterministic replay cycles must not duplicate continuations (got %d)." % completions[0])
	var speakers := {}
	for speaker_id in ["grandmaster", "gatekeeper", "commander"]:
		var actor := Node3D.new()
		stage.add_child(actor)
		speakers[speaker_id] = actor
	speakers.grandmaster.position = Vector3(19.0, 0.7, 0.0)
	speakers.gatekeeper.position = Vector3(-3.2, 0.0, -6.5)
	speakers.commander.position = Vector3(3.2, 0.0, -6.5)
	# Sample the actual timeline throughout each cue, including the first frame,
	# so a camera that only reaches the speaker after her line cannot pass.
	cinematic.playback_speed = 10.0
	for human_side in [1, -1]:
		cinematic.play_mountain_intro(human_side, speakers)
		await _assert_grandmaster_framing(cinematic, speakers.grandmaster, ["I · THE FIRST GATE", "OBJECTIVE"])
		cinematic.play_mountain_victory(human_side, speakers)
		await _assert_grandmaster_framing(cinematic, speakers.grandmaster, ["FORTRESS SECURED"])
	cinematic.playback_speed = 100.0
	var skip_run: int = cinematic.play_mountain_victory(1)
	await process_frame
	cinematic.call_deferred("skip")
	var skipped: Array = await cinematic.finished
	assert(int(skipped[0]) == skip_run and skipped[1] == "skipped", "Skip must use the same restoration path as normal completion.")
	assert(board_camera.controls_enabled() and board_camera.current, "Skip must not leave input or the cinematic camera stuck.")
	stage.queue_free()
	print("PASS: Grandmaster dialogue framing, cinematic camera, skip, and 20-cycle reset are deterministic.")
	quit(0)


func _assert_grandmaster_framing(cinematic: Node, grandmaster: Node3D, expected_titles: Array) -> void:
	var camera: Camera3D = cinematic.get_node("CinematicCamera")
	var title: Label = cinematic.get_node("Overlay/SpeechBubble/Content/Title")
	var speaker: Label = cinematic.get_node("Overlay/SpeechBubble/Content/Speaker")
	var observed := {}
	while cinematic.is_active():
		if speaker.text == "Grandmaster":
			observed[title.text] = true
			assert(camera.is_position_in_frustum(grandmaster.global_position), "Grandmaster's seat must be visible throughout %s." % title.text)
			assert(camera.is_position_in_frustum(grandmaster.global_position + Vector3.UP * 4.4), "Grandmaster's head must be visible from the first frame of %s." % title.text)
		await process_frame
	for expected_title in expected_titles:
		assert(observed.has(expected_title), "The camera regression must observe the %s dialogue cue." % expected_title)
