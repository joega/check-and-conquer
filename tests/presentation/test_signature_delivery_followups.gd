extends SceneTree

const Types = preload("res://scripts/chess/chess_types.gd")
const Resolver = preload("res://scripts/presentation/capture_choreography_resolver.gd")
const BattleDirector = preload("res://scripts/presentation/battle_director.gd")
const PIECE_ACTOR_SCENE = preload("res://scenes/actors/PieceActor.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for matchup in [[Types.BISHOP, Types.KING], [Types.ROOK, Types.KNIGHT], [Types.QUEEN, Types.ROOK]]:
		var director := BattleDirector.new()
		director.playback_speed = 12.0
		root.add_child(director)
		var attacker = PIECE_ACTOR_SCENE.instantiate()
		attacker.archetype = matchup[0]
		attacker.position = Vector3(-2.0, 0.0, 0.0)
		root.add_child(attacker)
		var victim = PIECE_ACTOR_SCENE.instantiate()
		victim.archetype = matchup[1]
		victim.position = Vector3(2.0, 0.0, 0.0)
		root.add_child(victim)
		await process_frame
		var impacts := [0]
		director.impact_landed.connect(func(): impacts[0] += 1)
		director.choreography = Resolver.resolve_matchup(matchup[0], matchup[1])
		await director.play_capture(attacker, victim, victim.global_position)
		var expected_impacts := 1 if director.choreography.delivery == "hammer_smash" else 2
		assert(impacts[0] >= expected_impacts, "%s must play its authored delivery%s before settlement." % [director.choreography.id, "" if expected_impacts == 1 else " and follow-up impact"])
		assert(not victim.visible and attacker.global_position.is_equal_approx(Vector3(2.0, 0.0, 0.0)), "%s must still settle deterministically after its signature follow-up." % director.choreography.id)
		director.queue_free()
		attacker.queue_free()
		victim.queue_free()
		await process_frame
	print("PASS: delivery-based signature captures play their authored delivery and declared follow-up beats before settlement.")
	quit(0)
