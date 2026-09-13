extends SceneTree

## Fixed-frame locomotion evidence for P0/P1. Run with --fixed-fps 60. Each
## fixture uses a legal domain move, records root position every frame, and
## saves evenly spaced images through the same BoardPresenter used by gameplay.

const Evidence = preload("res://tools/visual_evidence_harness.gd")
const ChessGame = preload("res://scripts/chess/chess_game.gd")
const Mapper = preload("res://scripts/presentation/board_mapper.gd")

const FIXTURES := [
	{"id": "pawn-short", "fen": "4k3/8/8/8/8/8/4P3/4K3 w - - 0 1", "uci": "e2e3"},
	{"id": "pawn-two-square", "fen": "4k3/8/8/8/8/8/4P3/4K3 w - - 0 1", "uci": "e2e4"},
	{"id": "knight", "fen": "4k3/8/8/8/8/8/8/1N2K3 w - - 0 1", "uci": "b1c3"},
	{"id": "rook-long", "fen": "4k3/8/8/8/8/8/8/R3K3 w - - 0 1", "uci": "a1a7"},
	{"id": "bishop-long", "fen": "4k3/8/8/8/8/8/8/2B1K3 w - - 0 1", "uci": "c1h6"},
]
const SPEEDS := [1.0, 0.25]
const SAMPLE_EVERY_FRAMES := 15
const CAPTURE_SAMPLE_EVERY_FRAMES := 30
const TIMEOUT_FRAMES := 2400

var output_dir := "/tmp/cac-movement-audit"
var revision := "working-tree"
var expected_size := Vector2i(1280, 720)
var idle_only := false
var evidence


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		output_dir = args[0]
	if args.size() > 1:
		revision = args[1]
	if args.size() > 2:
		expected_size = _parse_size(args[2])
	if args.size() > 3:
		idle_only = args[3] == "idle-only"
	call_deferred("_run")


func _parse_size(value: String) -> Vector2i:
	var fields := value.to_lower().split("x", false)
	assert(fields.size() == 2 and fields[0].is_valid_int() and fields[1].is_valid_int(), "Size must be WIDTHxHEIGHT.")
	return Vector2i(int(fields[0]), int(fields[1]))


func _run() -> void:
	Engine.max_fps = 60
	evidence = Evidence.new(output_dir, revision, expected_size)
	evidence.print_captures = false
	await evidence.configure_window(self)
	var loader = preload("res://scenes/debug/DebugPositionLoader.tscn").instantiate()
	evidence.viewport.add_child(loader)
	await process_frame
	loader.get_node("BoardPresenter")._ambient_motion_timer_s = 9999.0
	loader.get_node("Camera3D").current = true
	await _record_idle_loops(loader)
	if idle_only:
		evidence.write_manifest("manifest.json", {
			"tool": "capture_movement_audit.gd",
			"capture_method": "fixed 60 FPS simulation; close camera samples both sides of every seam across three complete ping-pong idle cycles",
			"mode": "idle-only",
		})
		quit(evidence.exit_code())
		return
	for speed in SPEEDS:
		Engine.time_scale = speed
		for fixture in FIXTURES:
			await _record_move(loader, fixture, speed)
	Engine.time_scale = 1.0
	loader.queue_free()
	await process_frame
	var lab = preload("res://scenes/debug/DebugCombatLab.tscn").instantiate()
	evidence.viewport.add_child(lab)
	await process_frame
	for speed in SPEEDS:
		await _record_capture(lab, speed)
	evidence.write_manifest("manifest.json", {
		"tool": "capture_movement_audit.gd",
		"capture_method": "fixed 60 FPS simulation; three ping-pong idle cycles sampled around every seam; movement PNG every 15 frames, capture PNG every 30 frames; root transforms recorded every frame",
		"baseline_manifest": "artifacts/presentation_overhaul/baseline/motion-%dx%d/manifest.json" % [expected_size.x, expected_size.y],
		"p1_reference_manifest": "artifacts/presentation_overhaul/p1/final-motion-%dx%d/manifest.json" % [expected_size.x, expected_size.y],
		"sample_every_frames": SAMPLE_EVERY_FRAMES,
		"capture_sample_every_frames": CAPTURE_SAMPLE_EVERY_FRAMES,
		"playback_speeds": SPEEDS,
		"fixtures": FIXTURES,
	})
	quit(evidence.exit_code())


func _record_idle_loops(loader) -> void:
	const IDLE_FEN := "4k3/8/8/8/8/8/4P3/4K3 w - - 0 1"
	assert(loader.load_fen(IDLE_FEN), "Idle fixture FEN must load.")
	await process_frame
	var presenter = loader.get_node("BoardPresenter")
	var actor = presenter.actors.get(12)
	assert(actor != null and actor.battle_stance_loops(), "Idle fixture requires the repaired continuous battle stance.")
	var camera := loader.get_node("Camera3D") as Camera3D
	camera.fov = 42.0
	_track_actor(camera, actor)
	var source_duration_s: float = actor.state_duration(&"idle.neutral")
	var half_cycle_frames := maxi(int(round(source_duration_s * 60.0)), 1)
	var total_frames := half_cycle_frames * 6
	var capture_frames := {}
	for boundary in range(7):
		var seam_frame := boundary * half_cycle_frames
		for offset in [-1, 0, 1]:
			capture_frames[maxi(seam_frame + offset, 1)] = true
	var home_position: Vector3 = actor.global_position
	evidence.mark_event("idle_inspection_started", "idle-three-loops", 0.0, {
		"source_duration_s": source_duration_s,
		"ping_pong_cycle_duration_s": source_duration_s * 2.0,
		"cycles": 3,
	})
	for frame in range(1, total_frames + 2):
		await process_frame
		_track_actor(camera, actor)
		var elapsed_s := float(frame) / 60.0
		evidence.mark_event("idle_sample", "idle-three-loops", elapsed_s, {
			"frame": frame,
			"playback_position": actor.animation_playback_position(),
			"root_position": _vector3_array(actor.global_position),
			"yaw": actor.rotation.y,
			"semantic_state": str(actor.current_semantic_state()),
		})
		if capture_frames.has(frame):
			await evidence.capture(self, "idle-three-loops-%04d" % frame, {
				"fixture": "idle-three-loops",
				"event": "idle_seam_sample",
				"frame": frame,
				"elapsed_s": elapsed_s,
				"playback_position": actor.animation_playback_position(),
				"yaw": actor.rotation.y,
			})
	assert(actor.global_position.is_equal_approx(home_position), "Idle loop must never move the authoritative actor root.")
	assert(actor.current_semantic_state() == &"idle.neutral" and not actor.is_animation_paused(), "Idle must remain continuously active through three cycles.")
	evidence.mark_event("idle_inspection_finished", "idle-three-loops", float(total_frames) / 60.0, {
		"cycles": 3,
		"exact_root": true,
	})


func _record_move(loader, fixture: Dictionary, speed: float) -> void:
	var game = ChessGame.new(fixture.fen)
	assert(loader.load_fen(fixture.fen), "Movement fixture FEN must load: %s" % fixture.id)
	await process_frame
	var result = game.try_uci(fixture.uci)
	assert(result != null and not result.is_capture, "Movement fixture must submit a legal quiet move: %s" % fixture.id)
	var presenter = loader.get_node("BoardPresenter")
	var actor = presenter.actors.get(result.from_square)
	assert(actor != null, "Movement fixture actor is missing: %s" % fixture.id)
	var camera := loader.get_node("Camera3D") as Camera3D
	camera.fov = 42.0
	_track_actor(camera, actor)
	var start: Vector3 = actor.global_position
	var target: Vector3 = Mapper.square_to_world(result.to_square)
	var fixture_id := "%s-%s" % [fixture.id, "025x" if is_equal_approx(speed, 0.25) else "1x"]
	evidence.mark_event("move_requested", fixture_id, 0.0, {
		"uci": fixture.uci,
		"before_fen": result.before_fen,
		"after_fen": result.after_fen,
		"distance_m": start.distance_to(target),
		"speed": speed,
	})
	var landed := [false]
	var landed_callable := func(): landed[0] = true
	presenter.piece_landed.connect(landed_callable, CONNECT_ONE_SHOT)
	presenter.present_quiet_move(result)
	var frame := 0
	while not landed[0] and frame < TIMEOUT_FRAMES:
		await process_frame
		frame += 1
		_track_actor(camera, actor)
		var elapsed_s := float(frame) / 60.0
		evidence.mark_event("root_sample", fixture_id, elapsed_s, {
			"frame": frame,
			"position": [actor.global_position.x, actor.global_position.y, actor.global_position.z],
			"yaw": actor.rotation.y,
			"semantic_state": str(actor.current_semantic_state()),
			"active_animation": str(actor.active_animation_name()),
		})
		if frame == 1 or frame % SAMPLE_EVERY_FRAMES == 0:
			await evidence.capture(self, "%s-%03d" % [fixture_id, frame], {
				"fixture": fixture_id,
				"event": "motion_sample",
				"frame": frame,
				"elapsed_s": elapsed_s,
				"speed": speed,
				"uci": fixture.uci,
				"root_position": [actor.global_position.x, actor.global_position.y, actor.global_position.z],
				"yaw": actor.rotation.y,
				"semantic_state": str(actor.current_semantic_state()),
				"active_animation": str(actor.active_animation_name()),
			})
	assert(landed[0], "Movement fixture timed out: %s" % fixture_id)
	assert(actor.global_position.is_equal_approx(target), "Movement fixture did not settle exactly: %s" % fixture_id)
	assert(presenter.matches_state(game.state), "Movement fixture projection does not match domain state: %s" % fixture_id)
	evidence.mark_event("piece_landed", fixture_id, float(frame) / 60.0, {
		"frame": frame,
		"position": [actor.global_position.x, actor.global_position.y, actor.global_position.z],
		"exact_settlement": true,
	})
	await evidence.capture(self, "%s-settled" % fixture_id, {
		"fixture": fixture_id,
		"event": "piece_landed",
		"frame": frame,
		"speed": speed,
		"uci": fixture.uci,
		"fen": game.state.to_fen(),
		"exact_settlement": true,
	})


func _record_capture(lab, speed: float) -> void:
	lab._reset_lab()
	await process_frame
	var fixture_id := "pawn-capture-%s" % ("025x" if is_equal_approx(speed, 0.25) else "1x")
	var director = lab.get_node("BattleDirector")
	director.playback_speed = speed
	var attacker = lab._attacker
	var victim = lab._victim
	var attacker_home: Transform3D = attacker.global_transform
	var victim_home: Transform3D = victim.global_transform
	var destination: Vector3 = victim.global_position
	var frame_clock := [0]
	var finished := [false]
	director.impact_landed.connect(func():
		evidence.mark_event("impact_landed", fixture_id, float(frame_clock[0]) / 60.0, {
			"attacker_position": [attacker.global_position.x, attacker.global_position.y, attacker.global_position.z],
			"victim_position": [victim.global_position.x, victim.global_position.y, victim.global_position.z],
		})
	, CONNECT_ONE_SHOT)
	director.victim_death_finished.connect(func():
		evidence.mark_event("victim_death_finished", fixture_id, float(frame_clock[0]) / 60.0)
	, CONNECT_ONE_SHOT)
	director.presentation_finished.connect(func():
		finished[0] = true
		evidence.mark_event("presentation_finished", fixture_id, float(frame_clock[0]) / 60.0)
	, CONNECT_ONE_SHOT)
	evidence.mark_event("capture_requested", fixture_id, 0.0, {
		"attacker": "pawn",
		"victim": "pawn",
		"speed": speed,
		"attacker_home": _vector3_array(attacker_home.origin),
		"victim_home": _vector3_array(victim_home.origin),
	})
	lab._play_capture()
	while not finished[0] and frame_clock[0] < TIMEOUT_FRAMES:
		await process_frame
		frame_clock[0] += 1
		var elapsed_s := float(frame_clock[0]) / 60.0
		evidence.mark_event("capture_root_sample", fixture_id, elapsed_s, {
			"frame": frame_clock[0],
			"attacker_position": _vector3_array(attacker.global_position),
			"victim_position": _vector3_array(victim.global_position),
			"attacker_yaw": attacker.rotation.y,
			"victim_yaw": victim.rotation.y,
			"attacker_state": str(attacker.current_semantic_state()),
			"victim_state": str(victim.current_semantic_state()),
		})
		if frame_clock[0] == 1 or frame_clock[0] % CAPTURE_SAMPLE_EVERY_FRAMES == 0:
			await evidence.capture(self, "%s-%04d" % [fixture_id, frame_clock[0]], {
				"fixture": fixture_id,
				"event": "capture_motion_sample",
				"frame": frame_clock[0],
				"elapsed_s": elapsed_s,
				"speed": speed,
				"attacker_position": _vector3_array(attacker.global_position),
				"victim_position": _vector3_array(victim.global_position),
				"attacker_yaw": attacker.rotation.y,
				"victim_yaw": victim.rotation.y,
				"attacker_state": str(attacker.current_semantic_state()),
				"victim_state": str(victim.current_semantic_state()),
			})
	assert(finished[0], "Capture fixture timed out: %s" % fixture_id)
	assert(attacker.global_position.is_equal_approx(destination), "Capture attacker did not settle exactly: %s" % fixture_id)
	assert(not victim.visible, "Capture victim must remain removed after death: %s" % fixture_id)
	await evidence.capture(self, "%s-settled" % fixture_id, {
		"fixture": fixture_id,
		"event": "presentation_finished",
		"frame": frame_clock[0],
		"speed": speed,
		"exact_settlement": true,
	})
	lab._reset_lab()
	await process_frame
	assert(attacker.global_transform.is_equal_approx(attacker_home), "Capture reset drifted attacker: %s" % fixture_id)
	assert(victim.global_transform.is_equal_approx(victim_home) and victim.visible, "Capture reset drifted victim: %s" % fixture_id)
	evidence.mark_event("reset_complete", fixture_id, float(frame_clock[0] + 1) / 60.0, {"exact_home_transforms": true})


func _vector3_array(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _track_actor(camera: Camera3D, actor: Node3D) -> void:
	camera.global_position = actor.global_position + Vector3(7.0, 5.0, 8.0)
	camera.look_at(actor.global_position + Vector3.UP * 1.35, Vector3.UP)
