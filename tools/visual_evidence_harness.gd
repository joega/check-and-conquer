class_name VisualEvidenceHarness
extends RefCounted

## Shared contract for rendered evidence tools.  A screenshot is only recorded
## after its fixture invariants pass, and every file is described in a manifest.

var output_dir: String
var revision: String
var expected_size: Vector2i
var captures: Array[Dictionary] = []
var events: Array[Dictionary] = []
var viewport: SubViewport
var failed := false
var failures: Array[String] = []
var print_captures := true


func _init(target_dir: String, source_revision: String, target_size: Vector2i) -> void:
	output_dir = target_dir
	revision = source_revision
	expected_size = target_size
	_require(not output_dir.is_empty(), "Visual evidence requires an output directory.")
	_require(not revision.is_empty(), "Visual evidence requires an explicit source revision.")
	_require(expected_size.x > 0 and expected_size.y > 0, "Visual evidence requires an explicit output size.")
	_require(DirAccess.make_dir_recursive_absolute(output_dir) == OK, "Could not create visual evidence directory.")


func configure_window(tree: SceneTree) -> void:
	# Desktop compositors are allowed to tile or maximize the process window.
	# Render the evidence scene in an explicit-size GPU viewport so the requested
	# image dimensions and camera aspect are independent of window-manager policy.
	viewport = SubViewport.new()
	viewport.name = "EvidenceViewport"
	viewport.size = expected_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.handle_input_locally = true
	tree.root.add_child(viewport)
	for _frame in 3:
		await tree.process_frame
	var actual := Vector2i(viewport.get_texture().get_size())
	_require(actual == expected_size, "Requested %s render, received %s." % [expected_size, actual])


func wait_until(tree: SceneTree, predicate: Callable, description: String, timeout_ms := 15000) -> void:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while not predicate.call() and Time.get_ticks_msec() < deadline:
		await tree.process_frame
	_require(predicate.call(), "Timed out waiting for %s after %d ms." % [description, timeout_ms])


func gameplay_errors(game, expected_fen: String, expected_history: int, expected_actors: int, require_engine_idle := true) -> Array[String]:
	var failures: Array[String] = []
	if game == null or not is_instance_valid(game):
		return ["game fixture is missing"]
	if game.controller == null:
		return ["turn controller is missing"]
	if game.screen_phase != game.ScreenPhase.PLAYING:
		failures.append("screen phase is %s rather than PLAYING" % game.screen_phase)
	if game.controller.phase != game.controller.Phase.PLAYER_INPUT:
		failures.append("turn phase is %s rather than PLAYER_INPUT" % game.controller.phase)
	if game.controller.game.move_history.size() != expected_history:
		failures.append("move history is %d rather than %d" % [game.controller.game.move_history.size(), expected_history])
	if not expected_fen.is_empty() and game.controller.game.state.to_fen() != expected_fen:
		failures.append("FEN is %s rather than %s" % [game.controller.game.state.to_fen(), expected_fen])
	var presenter = game.get_node_or_null("BoardPresenter")
	if presenter == null:
		failures.append("BoardPresenter is missing")
	else:
		if presenter.actor_count() != expected_actors:
			failures.append("actor count is %d rather than %d" % [presenter.actor_count(), expected_actors])
		if not presenter.matches_state(game.controller.game.state):
			failures.append("actor projection does not match authoritative state")
	var board_camera = game.get_node_or_null("Camera3D")
	if board_camera == null or not board_camera.current or game.get_viewport().get_camera_3d() != board_camera:
		failures.append("board camera is not active")
	var cinematic = game.get_node_or_null("CampaignCinematic")
	if cinematic == null:
		failures.append("CampaignCinematic is missing")
	else:
		if cinematic.is_active():
			failures.append("campaign cinematic is active")
		var overlay := cinematic.get_node_or_null("Overlay") as CanvasItem
		if overlay != null and overlay.visible:
			failures.append("cinematic overlay is visible")
	var arena_intro := game.get_node_or_null("UI/ArenaIntro") as CanvasItem
	if arena_intro != null and arena_intro.visible:
		failures.append("arena intro overlay is visible")
	if require_engine_idle:
		if game.engine_request_pending or game.hint_request_pending or not game._engine_request.is_empty():
			failures.append("a gameplay engine request remains pending")
		if game.engine != null and game.engine.has_pending_request():
			failures.append("Stockfish still has pending protocol work")
	return failures


func assert_gameplay(game, expected_fen: String, expected_history: int, expected_actors: int, require_engine_idle := true) -> Dictionary:
	var failures := gameplay_errors(game, expected_fen, expected_history, expected_actors, require_engine_idle)
	_require(failures.is_empty(), "Invalid gameplay evidence fixture: %s" % "; ".join(failures))
	return {
		"fen": game.controller.game.state.to_fen(),
		"history": game.controller.game.move_history.duplicate(),
		"move_count": game.controller.game.move_history.size(),
		"actor_count": game.get_node("BoardPresenter").actor_count(),
		"screen_phase": "PLAYING",
		"turn_phase": "PLAYER_INPUT",
		"active_camera": str(game.get_viewport().get_camera_3d().get_path()),
		"cinematic_active": false,
		"cinematic_overlay_visible": false,
		"arena_intro_overlay_visible": false,
		"engine_request_pending": false,
	}


func capture(tree: SceneTree, label: String, fixture: Dictionary) -> Dictionary:
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var actual_size := Vector2i(image.get_width(), image.get_height())
	if not _require(actual_size == expected_size, "Capture %s expected %s, received %s." % [label, expected_size, actual_size]):
		return {}
	var filename := "%s.png" % label
	var absolute_path := output_dir.path_join(filename)
	if not _require(image.save_png(absolute_path) == OK, "Could not write %s." % absolute_path):
		return {}
	var record := fixture.duplicate(true)
	record["label"] = label
	record["file"] = filename
	record["width"] = actual_size.x
	record["height"] = actual_size.y
	record["camera"] = _camera_metadata(tree)
	captures.append(record)
	if print_captures:
		print("SCREENSHOT: ", absolute_path)
	return record


func mark_event(kind: String, fixture: String, elapsed_s: float, details: Dictionary = {}) -> void:
	var event := details.duplicate(true)
	event["event"] = kind
	event["fixture"] = fixture
	event["elapsed_s"] = snappedf(elapsed_s, 0.0001)
	events.append(event)


func write_manifest(name := "manifest.json", extra: Dictionary = {}) -> void:
	var manifest := extra.duplicate(true)
	manifest["schema"] = 1
	manifest["revision"] = revision
	manifest["renderer"] = RenderingServer.get_current_rendering_method()
	manifest["display_driver"] = DisplayServer.get_name()
	manifest["gpu_name"] = RenderingServer.get_video_adapter_name()
	manifest["gpu_vendor"] = RenderingServer.get_video_adapter_vendor()
	manifest["requested_size"] = {"width": expected_size.x, "height": expected_size.y}
	manifest["fixed_fps"] = Engine.max_fps
	manifest["captures"] = captures
	manifest["events"] = events
	manifest["valid"] = not failed
	manifest["failures"] = failures
	var path := output_dir.path_join(name)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not _require(file != null, "Could not open %s for writing." % path):
		return
	file.store_string(JSON.stringify(manifest, "\t") + "\n")
	file.close()
	print("MANIFEST: ", path)


func _camera_metadata(tree: SceneTree) -> Dictionary:
	var camera := viewport.get_camera_3d()
	if camera == null:
		return {}
	return {
		"path": str(camera.get_path()),
		"fov": camera.fov,
		"position": [camera.global_position.x, camera.global_position.y, camera.global_position.z],
		"rotation_degrees": [camera.global_rotation_degrees.x, camera.global_rotation_degrees.y, camera.global_rotation_degrees.z],
	}


func exit_code() -> int:
	return 1 if failed else 0


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	failed = true
	failures.append(message)
	push_error(message)
	return false
