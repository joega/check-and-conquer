extends SceneTree

const ACTOR_SCENE = preload("res://scenes/actors/PieceActor.tscn")
const Types = preload("res://scripts/chess/chess_types.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var bishop = ACTOR_SCENE.instantiate()
	bishop.archetype = Types.BISHOP
	root.add_child(bishop)
	var rook = ACTOR_SCENE.instantiate()
	rook.archetype = Types.ROOK
	rook.position.x = 3.0
	root.add_child(rook)
	await process_frame
	assert(bishop.supports_state(&"attack.bow.draw_release_01"))
	assert(rook.supports_state(&"attack.hammer.overhead_01"))
	bishop.play_state(&"attack.bow.draw_release_01")
	assert(bishop.current_semantic_state() == &"attack.bow.draw_release_01")
	assert(bishop.get_node_or_null("ModelRoot/Armature/Skeleton3D/BishopGoldenBowAttachment/BishopGoldenBow/NockedArrow") != null, "The authored bow action must visibly prepare a nocked arrow before release.")
	assert(is_equal_approx(bishop.state_duration(&"attack.bow.draw_release_01"), 0.52))
	bishop.release_authored_projectile()
	await process_frame
	assert(bishop.get_node_or_null("ModelRoot/Armature/Skeleton3D/BishopGoldenBowAttachment/BishopGoldenBow/NockedArrow") == null, "The local nocked arrow must hand off cleanly to the director-owned projectile.")
	rook.play_state(&"attack.hammer.overhead_01")
	assert(rook.current_semantic_state() == &"attack.hammer.overhead_01" and is_equal_approx(rook.state_duration(&"attack.hammer.overhead_01"), 0.60))
	var rook_square: Vector3 = rook.global_position
	rook.recover_after_capture()
	assert(rook.current_semantic_state() == &"recovery.capture_ready_01")
	await create_timer(0.5).timeout
	assert(rook.global_position.is_equal_approx(rook_square), "Post-capture recovery must not move the authoritative actor root.")
	bishop.queue_free()
	rook.queue_free()
	await process_frame
	print("PASS: authored bow/hammer action timelines hand off cleanly and recovery preserves board settlement.")
	quit()
