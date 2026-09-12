extends SceneTree

const ACTOR = preload("res://scenes/actors/PieceActor.tscn")
const CEREMONY = preload("res://scripts/presentation/grandmaster_ceremony.gd")
const Types = preload("res://scripts/chess/chess_types.gd")

class BoardProjection:
	var actors: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var board := BoardProjection.new()
	for side in [Types.WHITE, Types.BLACK]:
		var actor = ACTOR.instantiate()
		actor.archetype = Types.KING
		actor.side = side
		stage.add_child(actor)
		actor.position = Vector3(side * 12.0, 0.0, side * 14.0)
		board.actors[side] = actor
	var ceremony = CEREMONY.new()
	stage.add_child(ceremony)
	await process_frame
	for human_side in [Types.WHITE, Types.BLACK]:
		var speakers: Dictionary = ceremony.prepare(board, human_side)
		ceremony.bring_kings_to_parley()
		await create_timer(0.35).timeout
		for actor in board.actors.values():
			assert(actor._animation_player.current_animation == &"Walk", "Both kings must actually walk during travel.")
		# An early speech cue cannot stop either actor before arrival.
		ceremony.set_dialogue_speaker(speakers.gatekeeper)
		for actor in board.actors.values():
			assert(actor._animation_player.current_animation == &"Walk", "Dialogue cannot stop an approaching king.")
		var pending: Array = board.actors.values()
		var deadline := Time.get_ticks_msec() + 2500
		while not pending.is_empty() and Time.get_ticks_msec() < deadline:
			await process_frame
			for actor in pending.duplicate():
				# Sine easing can be approximately at the marker one frame before
				# travel ends. Check the exact tween destination for arrival.
				if actor.position == Vector3(-3.2, 0.0, -6.5) or actor.position == Vector3(3.2, 0.0, -6.5):
					_assert_stopped(actor)
					assert(actor._animation_player.current_animation == &"Idle", "Arrival must play the actual neutral standing idle.")
					pending.erase(actor)
		assert(pending.is_empty(), "Both kings must reach their own parley markers.")
		# Check the listener through the first speaker's line, then swap roles.
		for speaker in [speakers.gatekeeper, speakers.commander]:
			ceremony.set_dialogue_speaker(speaker)
			await create_timer(0.2).timeout
			for actor in board.actors.values():
				_assert_stopped(actor)
				if actor == speaker:
					assert(actor._animation_player.current_animation == &"Idle_Talking")
				else:
					assert(actor._animation_player.current_animation == &"Idle", "The listening king must stand neutrally without a rail-leaning gesture.")
		ceremony.cleanup()
	stage.queue_free()
	print("PASS: Both king colors stop actual walk playback on arrival, before dialogue, for either commander side.")
	quit(0)


func _assert_stopped(actor) -> void:
	assert(actor._animation_player.current_animation != &"Walk", "A king at its final parley marker must not keep walking in place.")
	assert(not (actor._animation_player.is_playing() and actor._animation_player_2.is_playing()), "Only one library may animate a king at a time.")
