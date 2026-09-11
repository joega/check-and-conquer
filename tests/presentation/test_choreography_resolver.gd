extends SceneTree

const Types = preload("res://scripts/chess/chess_types.gd")
const Resolver = preload("res://scripts/presentation/capture_choreography_resolver.gd")
const PIECE_ACTOR_SCENE = preload("res://scenes/actors/PieceActor.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ids: Array[StringName] = []
	for archetype in [Types.PAWN, Types.KNIGHT, Types.BISHOP, Types.ROOK, Types.QUEEN, Types.KING]:
		var choreography = Resolver.resolve(archetype)
		assert(choreography != null and not choreography.id.is_empty())
		assert(choreography.approach_duration_s > 0.0 and choreography.cleanup_time_s >= choreography.impact_time_s)
		assert(choreography.victim_hit_variants.size() >= 2, "Generic choreography must provide a deterministic choice of victim reactions.")
		assert(choreography.victim_death_variants.size() >= 2, "Generic choreography must provide a deterministic choice of victim deaths.")
		var actor = PIECE_ACTOR_SCENE.instantiate()
		actor.archetype = archetype
		root.add_child(actor)
		await process_frame
		assert(actor.supports_state(choreography.attacker_clip), "Archetype %d lacks normalized clip %s." % [archetype, choreography.attacker_clip])
		for reaction in choreography.victim_hit_variants:
			assert(actor.supports_state(reaction), "Archetype %d lacks normalized reaction %s." % [archetype, reaction])
		for death in choreography.victim_death_variants:
			assert(actor.supports_state(death), "Archetype %d lacks normalized death %s." % [archetype, death])
		actor.queue_free()
		ids.append(choreography.id)
		for victim_type in [Types.PAWN, Types.KNIGHT, Types.BISHOP, Types.ROOK, Types.QUEEN, Types.KING]:
			assert(Resolver.resolve_matchup(archetype, victim_type) != null)
	var signature = Resolver.resolve_matchup(Types.KNIGHT, Types.PAWN)
	assert(signature.id == &"capture.knight_vs_pawn.lunge_01")
	assert(signature.attacker_followup_clip == &"attack.push.guard_01" and signature.followup_time_s > 0.0)
	var knight = PIECE_ACTOR_SCENE.instantiate()
	knight.archetype = Types.KNIGHT
	root.add_child(knight)
	await process_frame
	assert(knight.supports_state(signature.attacker_clip) and knight.supports_state(signature.attacker_followup_clip))
	knight.queue_free()
	var queen_signature = Resolver.resolve_matchup(Types.QUEEN, Types.ROOK)
	assert(queen_signature.id == &"capture.queen_vs_rook.command_01")
	assert(queen_signature.attacker_followup_clip == &"attack.push.guard_01" and queen_signature.followup_time_s > 0.0)
	var queen = PIECE_ACTOR_SCENE.instantiate()
	queen.archetype = Types.QUEEN
	root.add_child(queen)
	await process_frame
	assert(queen.supports_state(queen_signature.attacker_clip) and queen.supports_state(queen_signature.attacker_followup_clip))
	queen.queue_free()
	var rook_signature = Resolver.resolve_matchup(Types.ROOK, Types.KNIGHT)
	assert(rook_signature.id == &"capture.rook_vs_knight.breaker_01")
	var rook = PIECE_ACTOR_SCENE.instantiate()
	rook.archetype = Types.ROOK
	root.add_child(rook)
	await process_frame
	assert(rook.supports_state(rook_signature.attacker_clip) and rook.supports_state(rook_signature.attacker_followup_clip))
	rook.queue_free()
	var king_signature = Resolver.resolve_matchup(Types.KING, Types.BISHOP)
	assert(king_signature.id == &"capture.king_vs_bishop.strike_01")
	var king = PIECE_ACTOR_SCENE.instantiate()
	king.archetype = Types.KING
	root.add_child(king)
	await process_frame
	assert(king.supports_state(king_signature.attacker_clip))
	king.queue_free()
	var pawn_signature = Resolver.resolve_matchup(Types.PAWN, Types.QUEEN)
	assert(pawn_signature.id == &"capture.pawn_vs_queen.riposte_01")
	var pawn = PIECE_ACTOR_SCENE.instantiate()
	pawn.archetype = Types.PAWN
	root.add_child(pawn)
	await process_frame
	assert(pawn.supports_state(pawn_signature.attacker_clip))
	pawn.queue_free()
	var bishop_signature = Resolver.resolve_matchup(Types.BISHOP, Types.KING)
	assert(bishop_signature.id == &"capture.bishop_vs_king.judgment_01")
	var bishop = PIECE_ACTOR_SCENE.instantiate()
	bishop.archetype = Types.BISHOP
	root.add_child(bishop)
	await process_frame
	assert(bishop.supports_state(bishop_signature.attacker_clip) and bishop.supports_state(bishop_signature.attacker_followup_clip))
	bishop.queue_free()
	assert(Resolver.resolve_matchup(Types.KNIGHT, Types.BISHOP).id == Resolver.resolve(Types.KNIGHT).id, "Unmapped matchups must retain their generic fallback.")
	assert(ids.size() == 6 and not ids.has(&""))
	print("PASS: all 36 archetype matchups resolve with a tested signature override and generic fallbacks.")
	quit(0)
