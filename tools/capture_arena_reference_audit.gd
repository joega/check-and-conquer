extends SceneTree

const Evidence = preload("res://tools/visual_evidence_harness.gd")
const SessionSettings = preload("res://scripts/game/session_settings.gd")
const ChessGame = preload("res://scripts/chess/chess_game.gd")
const Mapper = preload("res://scripts/presentation/board_mapper.gd")

var output_dir := "/tmp/cac-arena-reference"
var revision := "working-tree"
var expected_size := Vector2i(1280, 720)
var evidence
var game


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty(): output_dir = args[0]
	if args.size() > 1: revision = args[1]
	if args.size() > 2: expected_size = _parse_size(args[2])
	call_deferred("_run")


func _parse_size(value: String) -> Vector2i:
	var fields := value.to_lower().split("x", false)
	assert(fields.size() == 2 and fields[0].is_valid_int() and fields[1].is_valid_int(), "Size must be WIDTHxHEIGHT.")
	return Vector2i(int(fields[0]), int(fields[1]))


func _configure_game(scene) -> void:
	scene.campaign_enabled = false
	scene.arena_id = "mountain_fortress"


func _wait_for_gameplay() -> void:
	await evidence.wait_until(self, func():
		return game.controller != null \
			and game.screen_phase == game.ScreenPhase.PLAYING \
			and game.controller.phase == game.controller.Phase.PLAYER_INPUT \
			and not game.get_node("UI/ArenaIntro").visible \
			and game.engine != null and not game.engine.has_pending_request()
	, "settled Mountain Fortress gameplay", 20000)


func _read_baseline_records() -> Array[Dictionary]:
	var path := "res://artifacts/presentation_overhaul/baseline/visual-%dx%d/manifest.json" % [expected_size.x, expected_size.y]
	var file := FileAccess.open(path, FileAccess.READ)
	assert(file != null, "Missing accepted P0 baseline manifest %s." % path)
	var manifest = JSON.parse_string(file.get_as_text())
	file.close()
	var records: Array[Dictionary] = []
	for capture in manifest.captures:
		if capture.get("fixture") == "arena" and capture.get("arena") == "mountain_fortress":
			records.append(capture)
	assert(records.size() == 2, "Baseline must contain both Mountain player-side views.")
	return records


func _apply_record(record: Dictionary) -> void:
	game.controller.game = ChessGame.new(str(record.fen))
	game.controller.game.move_history = record.history.duplicate()
	game.get_node("BoardPresenter").rebuild_from_state(game.controller.game.state)
	game.get_node("BoardPresenter")._ambient_motion_timer_s = 9999.0
	game.get_node("ChessBoard").set_highlights(-1, [])
	var side := 1 if record.side == "white" else -1
	game.get_node("Camera3D").snap_to_side(side, 0.0)
	await process_frame
	await process_frame


func _board_invariants() -> Dictionary:
	var board = game.get_node("ChessBoard")
	var roundtrips := 0
	var top_height_errors: Array[int] = []
	for square in 64:
		if Mapper.world_to_square(Mapper.square_to_world(square)) == square:
			roundtrips += 1
		var tile := board.tiles[square] as MeshInstance3D
		var world_top := tile.position.y + tile.mesh.get_aabb().end.y
		if not is_zero_approx(world_top):
			top_height_errors.append(square)
	return {
		"tile_count": board.tiles.size(),
		"coordinate_labels": board.coordinate_label_count(),
		"board_extent_m": Mapper.BOARD_SIZE_M,
		"mapping_roundtrips": roundtrips,
		"tile_top_height_errors": top_height_errors,
	}


func _benchmark_aa() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var original_fps := Engine.max_fps
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	for variant in [
		{"name": "disabled", "mode": Viewport.MSAA_DISABLED},
		{"name": "2x", "mode": Viewport.MSAA_2X},
		{"name": "4x", "mode": Viewport.MSAA_4X},
	]:
		evidence.viewport.msaa_3d = variant.mode
		for _warm in 45:
			await RenderingServer.frame_post_draw
		var samples: Array[float] = []
		for _sample in 120:
			var start_us := Time.get_ticks_usec()
			await RenderingServer.frame_post_draw
			samples.append(float(Time.get_ticks_usec() - start_us) / 1000.0)
		samples.sort()
		var median: float = samples[samples.size() / 2]
		var p95: float = samples[int(floor((samples.size() - 1) * 0.95))]
		var record := {"name": variant.name, "mode": int(variant.mode), "frames": samples.size(), "median_ms": snappedf(median, 0.0001), "p95_ms": snappedf(p95, 0.0001)}
		results.append(record)
		await evidence.capture(self, "aa-%s" % variant.name, {"fixture": "aa_comparison", "aa": record})
	evidence.viewport.msaa_3d = Viewport.MSAA_2X
	Engine.max_fps = original_fps
	return results


func _run() -> void:
	evidence = Evidence.new(output_dir, revision, expected_size)
	await evidence.configure_window(self)
	var settings := SessionSettings.DEFAULTS.duplicate(true)
	settings.campaign_enabled = false
	settings.campaign_cinematics_enabled = false
	settings.selected_arena_id = "mountain_fortress"
	settings.spectator_enabled = false
	settings.beginner_coach_enabled = false
	settings.fullscreen = false
	assert(SessionSettings.save_values(settings) == OK, "Could not save isolated audit settings.")
	game = load("res://scenes/app/GameScreen.tscn").instantiate()
	_configure_game(game)
	evidence.viewport.add_child(game)
	await _wait_for_gameplay()
	evidence.viewport.msaa_3d = Viewport.MSAA_2X
	var invariants := _board_invariants()
	assert(invariants.tile_count == 64 and invariants.mapping_roundtrips == 64 and invariants.tile_top_height_errors.is_empty(), "Board geometry changed authoritative mapping or surface height.")
	var baseline_records := _read_baseline_records()
	var comparisons: Array[Dictionary] = []
	for record in baseline_records:
		await _apply_record(record)
		var side_name := str(record.side)
		var fixture: Dictionary = evidence.assert_gameplay(game, str(record.fen), record.history.size(), 32)
		fixture.merge({"fixture": "mountain_reference", "side": side_name, "baseline_file": record.file, "baseline_camera": record.camera, "board_invariants": invariants}, true)
		await evidence.capture(self, "mountain-after-%s" % side_name, fixture)
		comparisons.append({"side": side_name, "baseline_file": record.file, "baseline_fen": record.fen, "baseline_camera": record.camera})
	await _apply_record(baseline_records[0])
	var aa_results := await _benchmark_aa()
	var environment := game.get_node("WorldEnvironment").environment as Environment
	var key := game.get_node("Light") as DirectionalLight3D
	evidence.write_manifest("manifest.json", {
		"tool": "capture_arena_reference_audit.gd",
		"arena": "mountain_fortress",
		"baseline_manifest": "artifacts/presentation_overhaul/baseline/visual-%dx%d/manifest.json" % [expected_size.x, expected_size.y],
		"matched_comparisons": comparisons,
		"board_invariants": invariants,
		"lighting": {"ambient_source": int(environment.ambient_light_source), "ambient_energy": environment.ambient_light_energy, "key_energy": key.light_energy, "shadow_mode": int(key.directional_shadow_mode), "shadow_distance": key.directional_shadow_max_distance},
		"aa_selection": {"name": "2x", "mode": int(Viewport.MSAA_2X), "reason": "Selected after same-scene disabled/2x/4x edge and frame-time comparison."},
		"aa_benchmarks": aa_results,
	})
	quit(evidence.exit_code())
