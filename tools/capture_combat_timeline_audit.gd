extends SceneTree

## P2 rendered proof for the shared capture timeline. It records the reference
## pawn capture at 0.25x/1x/2x, twenty normal-speed direction/reset cycles, and
## a crowded authoritative board capture through the production presenter.

const Evidence = preload("res://tools/visual_evidence_harness.gd")
const ChessGame = preload("res://scripts/chess/chess_game.gd")
const BattleDirector = preload("res://scripts/presentation/battle_director.gd")
const Resolver = preload("res://scripts/presentation/capture_choreography_resolver.gd")
const Mapper = preload("res://scripts/presentation/board_mapper.gd")
const Types = preload("res://scripts/chess/chess_types.gd")

const SPEEDS := [0.25, 1.0, 2.0]
const TIMEOUT_FRAMES := 3000
const REQUIRED_STAGES: Array[StringName] = [&"anticipation", &"approach", &"plant", &"strike", &"reaction", &"death", &"settlement", &"recovery", &"finished"]

var output_dir := "/tmp/cac-combat-timeline-audit"
var revision := "working-tree"
var expected_size := Vector2i(1280, 720)
var run_mode := "full"
var evidence


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty(): output_dir = args[0]
	if args.size() > 1: revision = args[1]
	if args.size() > 2: expected_size = _parse_size(args[2])
	if args.size() > 3: run_mode = args[3]
	call_deferred("_run")


func _parse_size(value: String) -> Vector2i:
	var fields := value.to_lower().split("x", false)
	assert(fields.size() == 2 and fields[0].is_valid_int() and fields[1].is_valid_int())
	return Vector2i(int(fields[0]), int(fields[1]))


func _run() -> void:
	Engine.max_fps = 60
	evidence = Evidence.new(output_dir, revision, expected_size)
	evidence.print_captures = false
	await evidence.configure_window(self)
	var lab = preload("res://scenes/debug/DebugCombatLab.tscn").instantiate()
	evidence.viewport.add_child(lab)
	await process_frame
	if run_mode != "directions-only":
		for speed in SPEEDS:
			await _record_reference_capture(lab, speed)
	if run_mode == "reference-only":
		evidence.write_manifest("manifest.json", {
			"tool": "capture_combat_timeline_audit.gd",
			"capture_method": "fixed 60 FPS; final unobscured pawn reference at every production timeline stage",
			"mode": "reference-only",
			"playback_speeds": SPEEDS,
			"reference_choreography": "capture.pawn.generic_sword_01",
		})
		quit(evidence.exit_code())
		return
	await _record_direction_cycles(lab)
	if run_mode == "directions-only":
		evidence.write_manifest("manifest.json", {
			"tool": "capture_combat_timeline_audit.gd",
			"capture_method": "fixed 60 FPS; twenty normal-speed resets over eight incoming directions with unobscured equipped-weapon contact",
			"mode": "directions-only",
			"normal_speed_cycles": 20,
			"incoming_directions": 8,
		})
		quit(evidence.exit_code())
		return
	lab.queue_free()
	await process_frame
	await _record_crowded_board_capture()
	evidence.write_manifest("manifest.json", {
		"tool": "capture_combat_timeline_audit.gd",
		"capture_method": "fixed 60 FPS; every production timeline stage and contact frame; twenty normal-speed resets over eight incoming directions; crowded BoardPresenter settlement",
		"playback_speeds": SPEEDS,
		"normal_speed_cycles": 20,
		"incoming_directions": 8,
		"reference_choreography": "capture.pawn.generic_sword_01",
	})
	quit(evidence.exit_code())


func _record_reference_capture(lab, speed: float) -> void:
	lab._select_attacker(0)
	lab._select_victim(0)
	await process_frame
	lab._reset_lab()
	var director = lab.get_node("BattleDirector")
	director.playback_speed = speed
	var attacker = lab._attacker
	var victim = lab._victim
	var attacker_home: Transform3D = attacker.global_transform
	var victim_home: Transform3D = victim.global_transform
	var destination: Vector3 = victim.global_position
	var fixture := "pawn-reference-%s" % _speed_label(speed)
	var frame_clock := [0]
	var pending: Array[String] = []
	var finished := [false]
	var impacts := [0]
	var audio_cues: Array[StringName] = []
	var stage_callback = func(stage: StringName):
		evidence.mark_event("stage", fixture, float(frame_clock[0]) / 60.0, {"stage": str(stage), "speed": speed})
		pending.append("stage-%s" % stage)
	var impact_callback = func():
		impacts[0] += 1
		pending.append("actual-contact")
		evidence.mark_event("impact_landed", fixture, float(frame_clock[0]) / 60.0, {
			"weapon_contact_distance_m": director.last_weapon_contact_distance_m,
			"contact_radius_m": director.choreography.contact_radius_m,
		})
	var audio_callback = func(kind: StringName):
		audio_cues.append(kind)
		evidence.mark_event("audio_cue", fixture, float(frame_clock[0]) / 60.0, {"kind": str(kind)})
	director.presentation_stage.connect(stage_callback)
	director.impact_landed.connect(impact_callback)
	director.weapon_impact.connect(audio_callback)
	director.presentation_finished.connect(func(): finished[0] = true, CONNECT_ONE_SHOT)
	director.choreography = Resolver.resolve(Types.PAWN)
	director.play_capture(attacker, victim, destination)
	while not finished[0] and frame_clock[0] < TIMEOUT_FRAMES:
		await process_frame
		frame_clock[0] += 1
		while not pending.is_empty():
			var event_label: String = pending.pop_front()
			await evidence.capture(self, "%s-%04d-%s" % [fixture, frame_clock[0], event_label], {
				"fixture": fixture,
				"event": event_label,
				"frame": frame_clock[0],
				"speed": speed,
				"attacker_position": _vector(attacker.global_position),
				"victim_position": _vector(victim.global_position),
				"attacker_state": str(attacker.current_semantic_state()),
				"victim_state": str(victim.current_semantic_state()),
			})
	evidence._require(finished[0], "%s timed out." % fixture)
	evidence._require(_has_stage_subsequence(director.stage_history, REQUIRED_STAGES), "%s missed required stage order: %s" % [fixture, director.stage_history])
	evidence._require(impacts[0] == 1, "%s must emit exactly one contact." % fixture)
	evidence._require(audio_cues.count(&"approach_step") == 1 and audio_cues.count(&"dual_sword_impact") == 1, "%s emitted incorrect audio cues: %s" % [fixture, audio_cues])
	evidence._require(director.last_weapon_contact_distance_m <= director.choreography.contact_radius_m, "%s dagger missed contact zone: %.3f m." % [fixture, director.last_weapon_contact_distance_m])
	evidence._require(attacker.global_position.is_equal_approx(destination) and not victim.visible, "%s did not settle exactly." % fixture)
	lab._reset_lab()
	await process_frame
	evidence._require(attacker.global_transform.is_equal_approx(attacker_home) and victim.global_transform.is_equal_approx(victim_home) and victim.visible, "%s reset drifted." % fixture)
	director.presentation_stage.disconnect(stage_callback)
	director.impact_landed.disconnect(impact_callback)
	director.weapon_impact.disconnect(audio_callback)


func _record_direction_cycles(lab) -> void:
	var director = lab.get_node("BattleDirector")
	director.playback_speed = 1.0
	director.choreography = Resolver.resolve(Types.PAWN)
	var attacker = lab._attacker
	var victim = lab._victim
	for cycle in 20:
		var fixture := "direction-cycle-%02d" % (cycle + 1)
		var angle := TAU * float(cycle % 8) / 8.0
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var victim_home := Transform3D(Basis.IDENTITY, Vector3.ZERO)
		var attacker_home := Transform3D(Basis.IDENTITY, direction * 6.0)
		attacker.cancel_presentation_motion()
		victim.cancel_presentation_motion()
		attacker.global_transform = attacker_home
		victim.global_transform = victim_home
		attacker.visible = true
		victim.visible = true
		attacker.start_battle_stance()
		victim.start_battle_stance()
		var impacts := [0]
		var finished := [false]
		var capture_contact := [cycle < 8]
		var impact_callback = func():
			impacts[0] += 1
			if capture_contact[0]: capture_contact[0] = true
		director.impact_landed.connect(impact_callback)
		director.presentation_finished.connect(func(): finished[0] = true, CONNECT_ONE_SHOT)
		director.play_capture(attacker, victim, victim_home.origin)
		var frame := 0
		while not finished[0] and frame < TIMEOUT_FRAMES:
			await process_frame
			frame += 1
			if capture_contact[0] and impacts[0] == 1:
				capture_contact[0] = false
				await evidence.capture(self, "%s-contact" % fixture, {
					"fixture": fixture,
					"event": "actual-contact",
					"incoming_direction": _vector(direction),
					"weapon_contact_distance_m": director.last_weapon_contact_distance_m,
				})
		director.impact_landed.disconnect(impact_callback)
		evidence._require(finished[0] and impacts[0] == 1, "%s failed or duplicated contact." % fixture)
		evidence._require(attacker.global_position.is_equal_approx(victim_home.origin) and not victim.visible, "%s failed settlement." % fixture)
		evidence._require(director.last_weapon_contact_distance_m <= director.choreography.contact_radius_m, "%s dagger missed by %.3f m." % [fixture, director.last_weapon_contact_distance_m])
		attacker.cancel_presentation_motion()
		victim.cancel_presentation_motion()
		attacker.global_transform = attacker_home
		victim.global_transform = victim_home
		victim.visible = true
		evidence._require(attacker.global_transform.is_equal_approx(attacker_home) and victim.global_transform.is_equal_approx(victim_home), "%s reset drifted." % fixture)
		evidence._require(director.active_temporary_effect_count() == 0, "%s left temporary effects." % fixture)
		evidence.mark_event("normal_speed_reset", fixture, float(frame) / 60.0, {
			"cycle": cycle + 1,
			"direction_index": cycle % 8,
			"contact_count": impacts[0],
			"exact_reset": true,
		})


func _record_crowded_board_capture() -> void:
	var loader = preload("res://scenes/debug/DebugPositionLoader.tscn").instantiate()
	evidence.viewport.add_child(loader)
	await process_frame
	loader.get_node("BoardPresenter")._ambient_motion_timer_s = 9999.0
	var game = ChessGame.new()
	assert(game.try_uci("e2e4") != null and game.try_uci("d7d5") != null)
	var before_fen: String = game.state.to_fen()
	var result = game.try_uci("e4d5")
	assert(result != null and result.is_capture)
	assert(loader.load_fen(before_fen))
	await process_frame
	var presenter = loader.get_node("BoardPresenter")
	var attacker = presenter.actors[result.from_square]
	var victim = presenter.actors[result.to_square]
	var director := BattleDirector.new()
	loader.add_child(director)
	director.choreography = Resolver.resolve(Types.PAWN)
	director.playback_speed = 1.0
	var camera := loader.get_node("Camera3D") as Camera3D
	var camera_transform := camera.global_transform
	var contact := [false]
	var finished := [false]
	director.impact_landed.connect(func(): contact[0] = true, CONNECT_ONE_SHOT)
	director.presentation_finished.connect(func(): finished[0] = true, CONNECT_ONE_SHOT)
	director.play_capture(attacker, victim, Mapper.square_to_world(result.to_square))
	var frame := 0
	var contact_captured := false
	while not finished[0] and frame < TIMEOUT_FRAMES:
		await process_frame
		frame += 1
		if contact[0] and not contact_captured:
			contact_captured = true
			await evidence.capture(self, "crowded-board-contact", {
				"fixture": "crowded-board",
				"event": "actual-contact",
				"before_fen": before_fen,
				"after_fen": result.after_fen,
				"actor_count": presenter.actor_count(),
			})
	presenter.settle_capture(result)
	await process_frame
	evidence._require(finished[0] and contact_captured, "Crowded-board capture did not finish through contact.")
	evidence._require(presenter.matches_state(game.state), "Crowded-board projection did not match authoritative result.")
	evidence._require(camera.global_transform.is_equal_approx(camera_transform) and camera.current, "Crowded-board capture changed the board camera.")
	await evidence.capture(self, "crowded-board-settled", {
		"fixture": "crowded-board",
		"event": "settled",
		"fen": game.state.to_fen(),
		"actor_count": presenter.actor_count(),
		"camera_stable": true,
	})
	director.queue_free()
	loader.queue_free()
	await process_frame


func _has_stage_subsequence(actual: Array[StringName], expected: Array[StringName]) -> bool:
	var next := 0
	for stage in actual:
		if next < expected.size() and stage == expected[next]: next += 1
	return next == expected.size()


func _speed_label(speed: float) -> String:
	return "025x" if is_equal_approx(speed, 0.25) else "2x" if is_equal_approx(speed, 2.0) else "1x"


func _vector(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]
