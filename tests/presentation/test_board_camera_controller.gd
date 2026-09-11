extends SceneTree

const BoardCamera = preload("res://scripts/presentation/board_camera_controller.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var camera = BoardCamera.new()
	camera.position = Vector3(24, 28, 28)
	root.add_child(camera)
	await process_frame
	var initial_position: Vector3 = camera.global_position
	camera.zoom_by(-2.0)
	assert(camera.global_position.distance_to(Vector3.ZERO) < initial_position.distance_to(Vector3.ZERO))
	camera.orbit_by(0.8, -0.1)
	assert(not camera.global_position.is_equal_approx(initial_position))
	assert(camera.global_transform.basis.z.dot((camera.global_position - camera.current_focus_target()).normalized()) > 0.99, "Orbit camera must keep looking at its active board or character focus target.")
	camera.zoom_by(-100.0)
	assert(camera.current_focus_target().y > 2.9, "Close zoom must lift its target to the enlarged character face level.")
	assert(camera.global_position.y > camera.current_focus_target().y, "Close zoom must keep the viewing camera above the face target.")
	camera.reset_view()
	assert(camera.focused_side() == 1 and camera.global_position.distance_to(Vector3.ZERO) > 40.0, "Reset view must restore the default player-side board framing after close inspection.")
	camera.snap_to_side(-1, 0.0)
	assert(camera.focused_side() == -1 and camera.global_position.z > 0.0, "Black's default view must mirror White's from the opposing board end.")
	camera.queue_free()
	print("PASS: board camera zoom and orbit controls preserve board focus.")
	quit(0)
