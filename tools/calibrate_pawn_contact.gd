extends SceneTree

## Deterministic P2 calibration sweep for the equipped pawn daggers. This uses
## the production BattleDirector and semantic attack, then reports the measured
## mesh-to-victim contact distance at each authored impact candidate.

const ActorScene = preload("res://scenes/actors/PieceActor.tscn")
const BattleDirector = preload("res://scripts/presentation/battle_director.gd")
const Resolver = preload("res://scripts/presentation/capture_choreography_resolver.gd")
const Types = preload("res://scripts/chess/chess_types.gd")

const ANCHORS := [0.4, 0.7, 1.0, 1.3, 1.6]
const CONTACT_TIMES := [0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var battle := BattleDirector.new()
	battle.playback_speed = 4.0
	root.add_child(battle)
	var attacker = ActorScene.instantiate()
	var victim = ActorScene.instantiate()
	root.add_child(attacker)
	root.add_child(victim)
	await process_frame
	print("anchor_m\tcontact_time_s\tbest_height_m\tdagger_distance_m")
	for anchor in ANCHORS:
		for contact_time in CONTACT_TIMES:
			_reset_pair(attacker, victim)
			var choreography = Resolver.resolve(Types.PAWN).duplicate(true)
			choreography.anchor_separation_m = anchor
			choreography.impact_time_s = contact_time
			battle.choreography = choreography
			var measurement := [INF, 0.0]
			var stop_at_contact = func():
				for height_index in range(5, 26):
					var height := float(height_index) / 10.0
					var distance: float = attacker.weapon_contact_distance_to(victim.global_position + Vector3.UP * height)
					if distance < measurement[0]:
						measurement[0] = distance
						measurement[1] = height
				battle.request_skip()
			battle.impact_landed.connect(stop_at_contact, CONNECT_ONE_SHOT)
			await battle.play_capture(attacker, victim, victim.global_position)
			print("%.2f\t%.2f\t%.2f\t%.4f" % [anchor, contact_time, measurement[1], measurement[0]])
	battle.queue_free()
	attacker.queue_free()
	victim.queue_free()
	await process_frame
	quit(0)


func _reset_pair(attacker, victim) -> void:
	attacker.reset_actor()
	victim.reset_actor()
	attacker.global_position = Vector3(0.0, 0.0, 3.0)
	victim.global_position = Vector3(0.0, 0.0, -3.0)
	attacker.visible = true
	victim.visible = true
