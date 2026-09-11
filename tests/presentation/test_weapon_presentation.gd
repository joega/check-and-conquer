extends SceneTree

const ACTOR_SCENE = preload("res://scenes/actors/PieceActor.tscn")
const BattleDirector = preload("res://scripts/presentation/battle_director.gd")
const Types = preload("res://scripts/chess/chess_types.gd")


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
	pawn.archetype = Types.KNIGHT
	assert(battle._melee_sound_for(pawn) == &"spear_impact")
	pawn.archetype = Types.ROOK
	assert(battle._melee_sound_for(pawn) == &"hammer_impact")
	battle.queue_free()
	pawn.queue_free()
	await process_frame
	print("PASS: weapon motion variants, afterimages, and family sounds are role-specific.")
	quit(0)
