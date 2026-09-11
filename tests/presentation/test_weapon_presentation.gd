extends SceneTree

const ACTOR_SCENE = preload("res://scenes/actors/PieceActor.tscn")
const BattleDirector = preload("res://scripts/presentation/battle_director.gd")
const Types = preload("res://scripts/chess/chess_types.gd")
const PieceActor = preload("res://scripts/actors/piece_actor.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle := BattleDirector.new()
	root.add_child(battle)
	var pawn = ACTOR_SCENE.instantiate()
	pawn.archetype = Types.PAWN
	pawn.position = Vector3(2.0, 0.0, -2.0)
	root.add_child(pawn)
	await process_frame
	assert(pawn.supports_state(pawn.capture_attack_state(&"attack.sword.slash_01")), "Pawn captures must select a compatible enhanced sword motion.")
	battle._spawn_weapon_swing(pawn)
	assert(battle.get_node_or_null("WeaponSwingArc00") != null and battle.get_node_or_null("WeaponSwingArc01") != null, "Dual-wielding pawns must create two readable weapon afterimages.")
	assert(battle._melee_sound_for(pawn) == &"dual_sword_impact")
	for archetype in [Types.PAWN, Types.KNIGHT, Types.BISHOP, Types.ROOK, Types.QUEEN, Types.KING]:
		pawn.archetype = archetype
		assert(not PieceActor.WEAPON_GRIPS.get(archetype, []).is_empty(), "Every role needs explicit role-owned weapon grip data.")
	pawn.archetype = Types.PAWN
	battle._spawn_role_impact(pawn, Vector3(0.0, 1.0, -2.0))
	assert(battle.get_node_or_null("RoleImpact_Pawn") != null and battle.get_node("RoleImpact_Pawn").get_child_count() >= 8, "Pawn strikes must produce a distinct dual-blade impact stamp with visible shards.")
	pawn.archetype = Types.KNIGHT
	battle._spawn_role_impact(pawn, Vector3(0.0, 1.0, -2.0))
	assert(battle.get_node_or_null("RoleImpact_Knight") != null, "Every archetype must emit an identifiable role-colored impact stamp.")
	assert(battle._melee_sound_for(pawn) == &"spear_impact")
	pawn.archetype = Types.ROOK
	assert(battle._melee_sound_for(pawn) == &"hammer_impact")
	var brick_volley := battle._spawn_rook_brick_volley(Vector3.ZERO, Vector3(0.0, 0.0, -5.0))
	assert(brick_volley.get_child_count() == 8 and brick_volley.get_node_or_null("ThrownBrick_00") != null, "Rook attacks must hurl an obvious pile of individual bricks rather than form an unclear gray object.")
	brick_volley.queue_free()
	battle.queue_free()
	pawn.queue_free()
	await process_frame
	print("PASS: weapon motion variants, afterimages, and family sounds are role-specific.")
	quit(0)
