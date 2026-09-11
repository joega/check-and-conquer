class_name BoardPresenter
extends Node3D

const Types = preload("res://scripts/chess/chess_types.gd")
const Mapper = preload("res://scripts/presentation/board_mapper.gd")
const ACTOR_SCENE = preload("res://scenes/actors/PieceActor.tscn")

var actors: Dictionary = {}
const WALK_SPEED_MPS := 7.0

signal quiet_move_started(actor: Node3D, destination: Vector3, duration_s: float)

func rebuild_from_state(state) -> void:
	for actor in actors.values(): actor.queue_free()
	actors.clear()
	for square in Types.BOARD_SIZE:
		if state.get_piece(square) == Types.EMPTY: continue
		var actor = ACTOR_SCENE.instantiate()
		actor.position = Mapper.square_to_world(square) + Vector3(0, 0, 0)
		actor.side_color = Color(0.2, 0.48, 0.95) if state.get_piece(square) > 0 else Color(0.83, 0.24, 0.22)
		actor.side = Types.piece_side(state.get_piece(square))
		actor.archetype = Types.piece_type(state.get_piece(square))
		add_child(actor)
		actors[square] = actor

func present_quiet_move(result) -> void:
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
	await _walk_actor_to(actor, Mapper.square_to_world(result.to_square))
	if result.is_castle:
		var rook_from: int = result.rook_from
		var rook_to: int = result.rook_to
		var rook = actors.get(rook_from)
		if rook != null:
			actors.erase(rook_from)
			actors[rook_to] = rook
			await _walk_actor_to(rook, Mapper.square_to_world(rook_to))
	_apply_promotion(result)
	actor.play_state(&"idle.neutral")

func actor_count() -> int:
	return actors.size()


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
	attacker.play_state(&"idle.neutral")


func _walk_actor_to(actor, target: Vector3) -> void:
	actor.face_world_position(target)
	var distance: float = actor.global_position.distance_to(target)
	var duration: float = clampf(distance / WALK_SPEED_MPS, 0.32, 1.25)
	# Root movement stays authoritative and code-controlled, while the imported
	# in-place gait is retimed to complete one visible stride over the same
	# interval. Without this, a four-metre pawn step ends halfway through a slow
	# source clip and reads as a slide.
	var walk_duration := maxf(actor.state_duration(&"locomotion.walk.forward"), 0.01)
	actor.set_animation_speed(walk_duration / duration)
	actor.play_state(&"locomotion.walk.forward")
	quiet_move_started.emit(actor, target, duration)
	await actor.move_to_world_position(target, duration).finished
	actor.set_animation_speed(1.0)
	actor.restore_board_facing()
	actor.play_state(&"idle.neutral")


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
	add_child(replacement)
	actors[result.to_square] = replacement
	old_actor.queue_free()
