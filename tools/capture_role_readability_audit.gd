extends SceneTree

const Evidence = preload("res://tools/visual_evidence_harness.gd")
const SessionSettings = preload("res://scripts/game/session_settings.gd")
const ACTOR_SCENE = preload("res://scenes/actors/PieceActor.tscn")
const Types = preload("res://scripts/chess/chess_types.gd")
const BeveledBoxMesh = preload("res://scripts/presentation/beveled_box_mesh.gd")

const ROLE_NAMES := ["pawn", "knight", "bishop", "rook", "queen", "king"]
const ROLE_ORDER := [Types.PAWN, Types.KNIGHT, Types.BISHOP, Types.ROOK, Types.QUEEN, Types.KING]

var output_dir := "/tmp/cac-role-readability"
var revision := "working-tree"
var expected_size := Vector2i(1280, 720)
var evidence
var audit_scene: Node
var lineup_actors: Array[Node] = []
var lineup_camera: Camera3D


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


func _clear_scene() -> void:
	if audit_scene != null:
		audit_scene.queue_free()
		await process_frame
	lineup_actors.clear()
	lineup_camera = null


func _make_lineup(side: int) -> void:
	await _clear_scene()
	var stage := Node3D.new()
	stage.name = "RoleReadabilityStage"
	evidence.viewport.add_child(stage)
	audit_scene = stage
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("25292d")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.82, 0.82, 0.82)
	environment.ambient_light_energy = 0.42
	world.environment = environment
	stage.add_child(world)
	var floor := MeshInstance3D.new()
	floor.name = "LineupFloor"
	floor.mesh = BeveledBoxMesh.create(Vector3(17.0, 0.24, 5.0), 0.10)
	floor.position.y = -0.12
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("6f6556")
	floor_material.roughness = 0.88
	floor.material_override = floor_material
	stage.add_child(floor)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-52, -32, 0)
	key.light_energy = 0.95
	key.shadow_enabled = true
	key.shadow_opacity = 0.62
	stage.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-45, 145, 0)
	fill.light_energy = 0.28
	fill.shadow_enabled = false
	stage.add_child(fill)
	lineup_camera = Camera3D.new()
	lineup_camera.name = "Camera3D"
	lineup_camera.fov = 43.0
	stage.add_child(lineup_camera)
	lineup_camera.current = true
	lineup_camera.position = Vector3(0.0, 4.0, 14.5 if side == Types.WHITE else -14.5)
	lineup_camera.look_at(Vector3(0.0, 1.8, 0.0), Vector3.UP)
	for index in ROLE_ORDER.size():
		var actor = ACTOR_SCENE.instantiate()
		actor.name = "Role_%s" % ROLE_NAMES[index]
		actor.archetype = ROLE_ORDER[index]
		actor.side = side
		actor.side_color = Color(0.20, 0.48, 0.95) if side == Types.WHITE else Color(0.83, 0.24, 0.22)
		actor.appearance_seed = 300 + index + (20 if side == Types.BLACK else 0)
		actor.position = Vector3((float(index) - 2.5) * 2.55, 0.0, 0.0)
		stage.add_child(actor)
		lineup_actors.append(actor)
	await process_frame
	for actor in lineup_actors:
		var glyph := actor.get_node_or_null("VisualAccents/PieceGlyph") as CanvasItem
		if glyph != null: glyph.visible = false


func _lineup_metadata(side: int, state_name: StringName) -> Dictionary:
	var records: Array[Dictionary] = []
	var indices := range(lineup_actors.size())
	if side == Types.BLACK:
		indices.reverse()
	for index in indices:
		var actor = lineup_actors[index]
		records.append({
			"role": ROLE_NAMES[index],
			"archetype": actor.archetype,
			"outfit": actor.outfit_id,
			"silhouette": actor.silhouette_profile,
			"accessories": actor.role_accessory_ids.duplicate(),
			"root": [actor.global_position.x, actor.global_position.y, actor.global_position.z],
		})
	var screen_order := ROLE_NAMES.duplicate()
	if side == Types.BLACK:
		screen_order.reverse()
	return {"fixture": "label_hidden_role_lineup", "side": "white" if side == Types.WHITE else "black", "state": str(state_name), "role_order_left_to_right": screen_order, "roles": records, "piece_glyphs_visible": false}


func _capture_pose_set(side: int) -> void:
	await _make_lineup(side)
	var poses := [
		{"name": "idle", "wait": 0.20},
		{"name": "walk", "wait": 0.25},
		{"name": "attack", "wait": 0.28},
		{"name": "recovery", "wait": 0.16},
		{"name": "death", "wait": 0.72},
	]
	var homes: Array[Transform3D] = []
	for actor in lineup_actors: homes.append(actor.global_transform)
	for pose in poses:
		for actor in lineup_actors:
			actor.reset_actor()
			match pose.name:
				"idle": actor.play_state(&"idle.neutral")
				"walk": actor.play_state(&"locomotion.walk.forward")
				"attack": actor.play_state(actor.primary_attack_state())
				"recovery": actor.recover_after_capture()
				"death": actor.play_state(&"death.backward_01")
		await create_timer(pose.wait).timeout
		var max_root_drift := 0.0
		for index in lineup_actors.size():
			max_root_drift = maxf(max_root_drift, lineup_actors[index].global_position.distance_to(homes[index].origin))
		var metadata := _lineup_metadata(side, StringName(pose.name))
		metadata["sample_time_s"] = pose.wait
		metadata["max_root_drift_m"] = max_root_drift
		await evidence.capture(self, "lineup-%s-%s" % [metadata.side, pose.name], metadata)


func _configure_game(scene) -> void:
	scene.campaign_enabled = false
	scene.arena_id = "mountain_fortress"


func _capture_starting_ranks() -> void:
	await _clear_scene()
	var settings := SessionSettings.DEFAULTS.duplicate(true)
	settings.campaign_enabled = false
	settings.campaign_cinematics_enabled = false
	settings.selected_arena_id = "mountain_fortress"
	settings.spectator_enabled = false
	settings.beginner_coach_enabled = false
	settings.fullscreen = false
	assert(SessionSettings.save_values(settings) == OK)
	var game = load("res://scenes/app/GameScreen.tscn").instantiate()
	_configure_game(game)
	evidence.viewport.add_child(game)
	audit_scene = game
	await evidence.wait_until(self, func(): return game.controller != null and game.screen_phase == game.ScreenPhase.PLAYING and game.controller.phase == game.controller.Phase.PLAYER_INPUT and not game.get_node("UI/ArenaIntro").visible, "settled role-rank fixture", 20000)
	game.get_node("BoardPresenter")._ambient_motion_timer_s = 9999.0
	for actor in game.get_node("BoardPresenter").actors.values():
		var glyph := actor.get_node_or_null("VisualAccents/PieceGlyph") as CanvasItem
		if glyph != null: glyph.visible = false
	for side in [Types.WHITE, Types.BLACK]:
		game.get_node("Camera3D").snap_to_side(side, 0.0)
		await process_frame
		var fixture: Dictionary = evidence.assert_gameplay(game, Types.STARTING_FEN, 0, 32)
		fixture.merge({"fixture": "label_hidden_starting_ranks", "side": "white" if side == Types.WHITE else "black", "piece_glyphs_visible": false}, true)
		await evidence.capture(self, "starting-ranks-%s" % fixture.side, fixture)


func _capture_queen_face() -> void:
	await _make_lineup(Types.WHITE)
	var queen = lineup_actors[4]
	queen.play_state(&"idle.neutral")
	await create_timer(0.20).timeout
	lineup_camera.position = queen.global_position + Vector3(0.0, 2.25, 4.2)
	lineup_camera.look_at(queen.global_position + Vector3.UP * 1.65, Vector3.UP)
	await process_frame
	await evidence.capture(self, "queen-face-clear", {
		"fixture": "queen_face_clearance",
		"hair": queen.hair_ids.duplicate(),
		"accessories": queen.role_accessory_ids.duplicate(),
		"state": "idle.neutral",
		"review": "Both eyes unobstructed; diadem band above brow; no saturated torso band.",
	})


func _run() -> void:
	evidence = Evidence.new(output_dir, revision, expected_size)
	await evidence.configure_window(self)
	evidence.viewport.msaa_3d = Viewport.MSAA_2X
	await _capture_pose_set(Types.WHITE)
	await _capture_pose_set(Types.BLACK)
	await _capture_queen_face()
	await _capture_starting_ranks()
	evidence.write_manifest("manifest.json", {
		"tool": "capture_role_readability_audit.gd",
		"role_order": ROLE_NAMES,
		"review_method": "Labels and base glyphs hidden; identify from outfit, headwear, accessories, body shape, and weapon at gameplay scale.",
		"pre_change_ambiguities": ["pawn/bishop", "knight/queen", "rook/king"],
		"implementor_review": {
			"identified_left_to_right_white": ROLE_NAMES,
			"identified_left_to_right_black": ["king", "queen", "rook", "bishop", "knight", "pawn"],
			"confidence": {"pawn": "high", "knight": "medium", "bishop": "high", "rook": "high", "queen": "medium", "king": "high"},
			"remaining_ambiguity": "Knight and queen are the closest pair at the farthest starting rank when their hand weapons overlap another actor; crest versus diadem remains visible.",
		},
	})
	quit(evidence.exit_code())
