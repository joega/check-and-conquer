extends SceneTree

const Evidence = preload("res://tools/visual_evidence_harness.gd")
const SessionSettings = preload("res://scripts/game/session_settings.gd")

var output_dir := "artifacts/presentation_overhaul/p6/performance-1920x1080"
var revision := "working-tree"
var expected_size := Vector2i(1920, 1080)
var evidence


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty(): output_dir = args[0]
	if args.size() > 1: revision = args[1]
	if args.size() > 2:
		var fields := args[2].to_lower().split("x", false)
		expected_size = Vector2i(int(fields[0]), int(fields[1]))
	call_deferred("_run")


func _sample_frames(count: int) -> Array[float]:
	var samples: Array[float] = []
	for _frame in count:
		var start_us := Time.get_ticks_usec()
		await RenderingServer.frame_post_draw
		samples.append(float(Time.get_ticks_usec() - start_us) / 1000.0)
	return samples


func _statistics(samples: Array[float], label: String) -> Dictionary:
	var ordered := samples.duplicate()
	ordered.sort()
	var median: float = ordered[ordered.size() / 2]
	var p95: float = ordered[int(floor((ordered.size() - 1) * 0.95))]
	return {
		"fixture": label,
		"frames": ordered.size(),
		"median_ms": snappedf(median, 0.0001),
		"p95_ms": snappedf(p95, 0.0001),
		"over_16_67_ms": ordered.filter(func(value): return value > 16.67).size(),
	}


func _p3_reference_p95() -> float:
	var file := FileAccess.open("res://artifacts/presentation_overhaul/p3/mountain-1920x1080/manifest.json", FileAccess.READ)
	if file == null: return -1.0
	var manifest = JSON.parse_string(file.get_as_text())
	file.close()
	for record in manifest.aa_benchmarks:
		if record.name == "2x": return float(record.p95_ms)
	return -1.0


func _run() -> void:
	assert(expected_size == Vector2i(1920, 1080), "Performance acceptance must run at 1080p.")
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	evidence = Evidence.new(output_dir, revision, expected_size)
	await evidence.configure_window(self)
	evidence.viewport.msaa_3d = Viewport.MSAA_2X
	var settings := SessionSettings.DEFAULTS.duplicate(true)
	settings.campaign_enabled = false
	settings.campaign_cinematics_enabled = false
	settings.selected_arena_id = "mountain_fortress"
	settings.spectator_enabled = false
	settings.beginner_coach_enabled = false
	settings.fullscreen = false
	assert(SessionSettings.save_values(settings) == OK)
	var game = load("res://scenes/app/GameScreen.tscn").instantiate()
	game.campaign_enabled = false
	game.arena_id = "mountain_fortress"
	evidence.viewport.add_child(game)
	await evidence.wait_until(self, func(): return game.controller != null and game.screen_phase == game.ScreenPhase.PLAYING and game.controller.phase == game.controller.Phase.PLAYER_INPUT and not game.get_node("UI/ArenaIntro").visible, "full starting board", 20000)
	game.get_node("BoardPresenter")._ambient_motion_timer_s = 9999.0
	for _warm in 120: await RenderingServer.frame_post_draw
	var board_stats := _statistics(await _sample_frames(360), "full_starting_board")
	await evidence.capture(self, "full-starting-board", {"fixture": "full_starting_board", "actor_count": game.get_node("BoardPresenter").actor_count(), "samples": board_stats})
	game.queue_free()
	await process_frame
	var lab = load("res://scenes/debug/DebugCombatLab.tscn").instantiate()
	evidence.viewport.add_child(lab)
	await process_frame
	lab.get_node("BattleDirector").playback_speed = 1.0
	for _warm in 120: await RenderingServer.frame_post_draw
	var capture_samples: Array[float] = []
	var completed := 0
	for cycle in 5:
		lab._reset_lab()
		await process_frame
		var finished := [false]
		lab.get_node("BattleDirector").presentation_finished.connect(func(): finished[0] = true, CONNECT_ONE_SHOT)
		lab._play_capture()
		while not finished[0]:
			var frame_samples := await _sample_frames(1)
			capture_samples.append(frame_samples[0])
		completed += 1
	var capture_stats := _statistics(capture_samples, "five_normal_speed_captures")
	await evidence.capture(self, "captures-complete", {"fixture": "five_normal_speed_captures", "cycles": completed, "samples": capture_stats, "effects_remaining": lab.get_node("BattleDirector").active_temporary_effect_count()})
	var reference_p95 := _p3_reference_p95()
	var regression_percent := ((float(board_stats.p95_ms) / reference_p95) - 1.0) * 100.0 if reference_p95 > 0.0 else 0.0
	evidence.write_manifest("manifest.json", {
		"tool": "benchmark_presentation.gd",
		"sampling": "2x MSAA, vsync/max-fps disabled, 120 rendered warm-up frames; 360 full-board samples and every rendered frame across five normal-speed Combat Lab captures",
		"board": board_stats,
		"captures": capture_stats,
		"renderer_target_ms": 16.67,
		"p3_reference_p95_ms": reference_p95,
		"board_p95_regression_percent": snappedf(regression_percent, 0.01),
		"investigation_required": regression_percent > 10.0,
	})
	quit(evidence.exit_code())
