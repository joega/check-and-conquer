class_name BoardPresenter
extends Node3D

const Types = preload("res://scripts/chess/chess_types.gd")
const Mapper = preload("res://scripts/presentation/board_mapper.gd")
const ACTOR_SCENE = preload("res://scenes/actors/PieceActor.tscn")

signal piece_landed

var actors: Dictionary = {}
const WALK_SPEED_MPS := 9.0
var _ambient_rng := RandomNumberGenerator.new()
var _ambient_motion_timer_s := 0.9
var _ambient_motion_index := 0
var _last_ambient_actor: Node
var _presentation_generation := 0


func _ready() -> void:
	_ambient_rng.seed = 88421


func _process(delta: float) -> void:
	_ambient_motion_timer_s -= delta
	if _ambient_motion_timer_s > 0.0:
		return
	_play_next_ambient_motion()
	# One isolated movement every few seconds makes the formation feel alert
	# without ever resembling a synchronized animation loop.
	_ambient_motion_timer_s = _ambient_rng.randf_range(2.2, 4.4)


func _play_next_ambient_motion() -> void:
	var candidates: Array = []
	for actor in actors.values():
		if actor != null and is_instance_valid(actor) and actor.is_available_for_ambient_motion() and actor != _last_ambient_actor:
			candidates.append(actor)
	if candidates.is_empty() and _last_ambient_actor != null and is_instance_valid(_last_ambient_actor) and _last_ambient_actor.is_available_for_ambient_motion():
		candidates.append(_last_ambient_actor)
	if candidates.is_empty():
		return
	var actor = candidates[_ambient_rng.randi_range(0, candidates.size() - 1)]
	actor.play_ambient_motion(_ambient_motion_index)
	_ambient_motion_index += 1
	_last_ambient_actor = actor

func rebuild_from_state(state) -> void:
	_presentation_generation += 1
	for actor in actors.values():
		actor.cancel_presentation_motion()
		actor.queue_free()
	actors.clear()
	for square in Types.BOARD_SIZE:
		if state.get_piece(square) == Types.EMPTY: continue
		var actor = ACTOR_SCENE.instantiate()
		actor.position = Mapper.square_to_world(square) + Vector3(0, 0, 0)
		actor.side_color = Color(0.2, 0.48, 0.95) if state.get_piece(square) > 0 else Color(0.83, 0.24, 0.22)
		actor.side = Types.piece_side(state.get_piece(square))
		actor.archetype = Types.piece_type(state.get_piece(square))
		actor.appearance_seed = square
		add_child(actor)
		actors[square] = actor
	_face_actors_toward_opposing_kings()

func present_quiet_move(result) -> void:
	var generation := _presentation_generation
	if result.is_capture:
		var victim_square: int = result.en_passant_capture_square if result.is_en_passant else result.to_square
		var victim = actors.get(victim_square)
		if victim != null:
			victim.queue_free()
			actors.erase(victim_square)
	var actor = actors.get(result.from_square)
	if actor == null: return
	actors.erase(result.from_square)
	actors[result.to_square] = actor
	await _walk_actor_to(actor, Mapper.square_to_world(result.to_square), generation)
	if generation != _presentation_generation or not is_instance_valid(actor):
		return
	if result.is_castle:
		var rook_from: int = result.rook_from
		var rook_to: int = result.rook_to
		var rook = actors.get(rook_from)
		if rook != null:
			actors.erase(rook_from)
			actors[rook_to] = rook
			await _walk_actor_to(rook, Mapper.square_to_world(rook_to), generation)
			if generation != _presentation_generation or not is_instance_valid(rook):
				return
	_apply_promotion(result)
	actor.start_battle_stance()
	_face_actors_toward_opposing_kings()

func actor_count() -> int:
	return actors.size()


func set_selected_square(square: int) -> void:
	for actor_square in actors:
		var actor = actors[actor_square]
		if actor != null and is_instance_valid(actor):
			actor.set_selected(actor_square == square)


func show_check_on_side(side: int) -> void:
	clear_check_indicator()
	for actor in actors.values():
		if actor == null or not is_instance_valid(actor) or actor.side != side or actor.archetype != Types.KING:
			continue
		var accents := actor.get_node_or_null("VisualAccents") as Node3D
		if accents == null:
			return
		var halo := MeshInstance3D.new()
		halo.name = "CheckHalo"
		var mesh := TorusMesh.new()
		mesh.inner_radius = 0.48
		mesh.outer_radius = 0.58
		mesh.rings = 8
		mesh.ring_segments = 28
		halo.mesh = mesh
		halo.position.y = 0.035
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.20, 0.05)
		material.emission_enabled = true
		material.emission = Color(1.0, 0.06, 0.01)
		material.emission_energy_multiplier = 2.8
		halo.material_override = material
		accents.add_child(halo)
		var pulse := halo.create_tween().set_loops()
		pulse.tween_property(halo, "scale", Vector3.ONE * 1.30, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		pulse.tween_property(halo, "scale", Vector3.ONE, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		return


func clear_check_indicator() -> void:
	for actor in actors.values():
		if actor == null or not is_instance_valid(actor):
			continue
		var halo: Node = actor.get_node_or_null("VisualAccents/CheckHalo")
		if halo != null:
			halo.free()


func matches_state(state) -> bool:
	var expected_count := 0
	for square in Types.BOARD_SIZE:
		var piece: int = state.get_piece(square)
		if piece == Types.EMPTY:
			continue
		expected_count += 1
		var actor = actors.get(square)
		if actor == null or not is_instance_valid(actor):
			return false
		if actor.archetype != Types.piece_type(piece):
			return false
		if not actor.global_position.is_equal_approx(Mapper.square_to_world(square)):
			return false
	return actors.size() == expected_count

func settle_capture(result) -> void:
	var victim_square: int = result.en_passant_capture_square if result.is_en_passant else result.to_square
	var victim = actors.get(victim_square)
	if victim != null:
		victim.queue_free()
		actors.erase(victim_square)
	var attacker = actors.get(result.from_square)
	actors.erase(result.from_square)
	actors[result.to_square] = attacker
	attacker.global_position = Mapper.square_to_world(result.to_square)
	_apply_promotion(result)
	_celebrate_capture(attacker)
	_face_actors_toward_opposing_kings()
	piece_landed.emit()


func _celebrate_capture(winner) -> void:
	var allies: Array = []
	for candidate in actors.values():
		if candidate != null and is_instance_valid(candidate) and candidate != winner and candidate.side == winner.side:
			allies.append(candidate)
	allies.sort_custom(func(a, b): return a.global_position.distance_squared_to(winner.global_position) < b.global_position.distance_squared_to(winner.global_position))
	# The winner has just completed the attack and occupies the destination; do
	# not make it immediately perform another flourish. A capture earns a small,
	# varied acknowledgement from one or two nearby teammates at most.
	var celebration_count := 1 + posmod(int(round(winner.global_position.x + winner.global_position.z)), 2)
	for index in mini(allies.size(), celebration_count):
		allies[index].celebrate_victory(index)


func celebrate_victory_for_side(winning_side: int) -> void:
	# Checkmate has already been decided by the domain. This is a bounded visual
	# acknowledgement for the full winning formation, distinct from the smaller
	# nearby reaction after an ordinary capture.
	var winners: Array = []
	for actor in actors.values():
		if actor != null and is_instance_valid(actor) and actor.side == winning_side:
			winners.append(actor)
	winners.sort_custom(func(a, b): return a.global_position.z < b.global_position.z)
	for index in winners.size():
		winners[index].celebrate_victory(index)


func _face_actors_toward_opposing_kings() -> void:
	# The opposing king is each army's visual command target. Resolving it from
	# the current projection keeps every unit locked on after a king move, while
	# chess authority remains entirely in the domain state.
	var king_positions := {}
	for actor in actors.values():
		if actor != null and is_instance_valid(actor) and actor.archetype == Types.KING:
			king_positions[actor.side] = actor.global_position
	for actor in actors.values():
		if actor == null or not is_instance_valid(actor):
			continue
		var opposing_king_position: Variant = king_positions.get(-actor.side)
		if opposing_king_position is Vector3:
			actor.face_world_position(opposing_king_position)


func _walk_actor_to(actor, target: Vector3, generation := -1) -> void:
	var active_generation := _presentation_generation if generation < 0 else generation
	actor.turn_toward_world_position(target)
	while is_instance_valid(actor) and actor.is_presentation_turning() and active_generation == _presentation_generation:
		await get_tree().process_frame
	if not is_instance_valid(actor) or active_generation != _presentation_generation:
		return
	var distance: float = actor.global_position.distance_to(target)
	var duration: float = actor.travel_duration_for_distance(distance, WALK_SPEED_MPS)
	actor.move_to_world_position(target, duration)
	while is_instance_valid(actor) and actor.is_presentation_moving() and active_generation == _presentation_generation:
		await get_tree().process_frame
	if not is_instance_valid(actor) or active_generation != _presentation_generation:
		return
	var opposing_king_position: Variant = _opposing_king_position(actor.side)
	if opposing_king_position is Vector3:
		actor.turn_toward_world_position(opposing_king_position)
		while is_instance_valid(actor) and actor.is_presentation_turning() and active_generation == _presentation_generation:
			await get_tree().process_frame
	else:
		actor.restore_board_facing()
	if not is_instance_valid(actor) or active_generation != _presentation_generation:
		return
	actor.start_battle_stance()
	piece_landed.emit()


func _opposing_king_position(side: int) -> Variant:
	for candidate in actors.values():
		if candidate != null and is_instance_valid(candidate) and candidate.side == -side and candidate.archetype == Types.KING:
			return candidate.global_position
	return null


func _apply_promotion(result) -> void:
	if not result.is_promotion:
		return
	var old_actor = actors.get(result.to_square)
	if old_actor == null:
		return
	var replacement = ACTOR_SCENE.instantiate()
	replacement.position = Mapper.square_to_world(result.to_square)
	replacement.side_color = Color(0.2, 0.48, 0.95) if result.moving_piece > 0 else Color(0.83, 0.24, 0.22)
	replacement.side = Types.piece_side(result.moving_piece)
	replacement.archetype = result.promotion_piece_type
	replacement.appearance_seed = result.to_square
	add_child(replacement)
	actors[result.to_square] = replacement
	old_actor.queue_free()
