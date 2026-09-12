extends SceneTree

const GAME_SCREEN = preload("res://scenes/app/GameScreen.tscn")
const SessionSettings = preload("res://scripts/game/session_settings.gd")
const Types = preload("res://scripts/chess/chess_types.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var settings := SessionSettings.DEFAULTS.duplicate()
	settings.campaign_cinematics_enabled = false
	assert(SessionSettings.save_values(settings) == OK)
	var screen = GAME_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var board = screen.get_node("BoardPresenter")
	var ceremony = screen.get_node("GrandmasterCeremony")
	assert(ceremony.has_node("GrandmasterDais/TemporaryThroneChair") and ceremony.has_node("Grandmaster"), "The ceremony must use the supplied chair on a separate raised dais with its own Grandmaster actor.")
	assert(ceremony.get_node("Grandmaster/VisualAccents").visible == false, "The Grandmaster must not carry a chess ring or glyph.")
	var chair := ceremony.get_node("GrandmasterDais/TemporaryThroneChair") as Node3D
	var grandmaster := ceremony.get_node("Grandmaster") as Node3D
	assert(is_equal_approx(chair.rotation.y, PI), "The temporary throne chair must receive its own 180-degree board-facing correction.")
	assert(is_equal_approx(chair.scale.x, 2.75), "The human-scale chair must match the Grandmaster rather than swallowing the seated pose.")
	assert(grandmaster.current_semantic_state() == &"stance.fold_arms_01", "The Grandmaster must retain the distinct overseer pose while facing the board.")
	assert(grandmaster._animation_player_2.current_animation == &"Idle_FoldArms", "The standing pose must actually play from its supplying library.")
	assert(grandmaster.global_position.distance_to(chair.global_position) > 2.2, "The Grandmaster must stand clear of the chair rather than clipping through its seat.")
	assert(is_equal_approx(grandmaster.scale.x, 1.48), "The Grandmaster must be scaled to read credibly beside the oversized throne prop.")
	ceremony.begin_grandmaster_seating()
	await create_timer(1.35).timeout
	assert(grandmaster.current_semantic_state() == &"ceremony.seat.idle", "The Grandmaster must settle into UAL1's seated idle after entering the chair.")
	# Inspect the actual skeletal pose relative to the source chair mesh. A root
	# equality test passed while the knees/shins were inside the seat.
	var skeleton: Skeleton3D = grandmaster.find_children("*", "Skeleton3D", true, false)[0]
	for sample in range(20):
		var pelvis := _bone_in_chair(skeleton, chair, "pelvis")
		var knee := _bone_in_chair(skeleton, chair, "calf_l")
		var toe := _bone_in_chair(skeleton, chair, "ball_l")
		assert(pelvis.y > 0.50 and pelvis.y < 0.63, "Hips must rest immediately above the 0.50 m seat top.")
		assert(pelvis.z > -0.22 and pelvis.z < -0.05, "Hips must sit inside the seat, ahead of its backrest.")
		assert(knee.z > 0.26, "Knees must clear the chair's front edge; shins cannot pass through the seat.")
		assert(absf(toe.y) < 0.03, "Feet must rest on the same floor as the chair legs.")
		await create_timer(0.1).timeout
	var speakers: Dictionary = ceremony.prepare(board, Types.WHITE)
	assert(speakers.has("grandmaster") and speakers.has("commander") and speakers.has("gatekeeper"), "The Grandmaster and both real kings must supply the dialogue bindings.")
	var visible_board_actors := 0
	for actor in board.actors.values():
		if actor.visible:
			visible_board_actors += 1
	assert(visible_board_actors == 2, "Only the two real kings may be visible during the parley; the army must not masquerade as chess state.")
	ceremony.bring_kings_to_parley()
	await create_timer(0.35).timeout
	ceremony.set_dialogue_speaker(speakers["gatekeeper"])
	for actor in board.actors.values():
		if actor.archetype == Types.KING:
			assert(actor.current_semantic_state() == &"locomotion.walk.forward", "A dialogue cue must not decide when either king stops walking.")
	await create_timer(0.95).timeout
	for actor in board.actors.values():
		if actor.archetype == Types.KING:
			assert(actor.current_semantic_state() == &"idle.neutral", "A king must stop and stand neutrally instead of walking in place.")
			assert(is_equal_approx(actor.global_position.z, -6.5) and is_equal_approx(absf(actor.global_position.x), 3.2), "Each king must stop at its exact center parley marker.")
	ceremony.return_kings_to_board()
	await create_timer(0.9).timeout
	assert(board.matches_state(screen.controller.game.state), "Kings must walk back to their exact board squares before the army materializes.")
	for actor in board.actors.values():
		if actor.archetype == Types.KING:
			assert(actor.current_semantic_state() != &"locomotion.run.forward", "A king must leave the run clip once it reaches its exact home square.")
	ceremony.settle_board_formation()
	await create_timer(1.1).timeout
	assert(board.actor_count() == 32 and board.matches_state(screen.controller.game.state), "Ceremony cleanup must restore the exact authoritative projection.")
	for actor in board.actors.values():
		assert(actor.visible, "Every board actor must materialize before input becomes available.")
	screen.queue_free()
	await process_frame
	print("PASS: Grandmaster dais ceremony hides, parley-stages, and restores the authoritative formation.")
	quit(0)


func _bone_in_chair(skeleton: Skeleton3D, chair: Node3D, bone: String) -> Vector3:
	return chair.to_local(skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone(bone)).origin))
