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
	var target_before_pan: Vector3 = camera.target
	camera.pan_by(Vector2(90.0, -45.0))
	assert(not camera.target.is_equal_approx(target_before_pan), "Middle-drag panning must move the close-focus target across the board.")
	camera.zoom_by(-100.0)
	assert(camera.current_focus_target().y > 2.9, "Close zoom must lift its target to the enlarged character face level.")
	assert(camera.global_position.y > camera.current_focus_target().y, "Close zoom must keep the viewing camera above the face target.")
	assert(camera.global_position.y - camera.current_focus_target().y < 1.2, "Close zoom must ease into an eye-level pitch instead of retaining the high board-view angle.")
	camera.reset_view()
	assert(camera.focused_side() == 1 and camera.target.is_equal_approx(Vector3.ZERO) and camera.global_position.distance_to(Vector3.ZERO) > 25.0, "Reset view must restore the closer centered player-side framing after close inspection.")
	assert(camera.global_position.z < 0.0 and absf(camera.global_position.x) < 0.1, "White's turn framing must sit directly behind White's rank-one team.")
	for corner in [Vector3(-16, 0, -16), Vector3(-16, 0, 16), Vector3(16, 0, -16), Vector3(16, 0, 16)]:
		assert(camera.is_position_in_frustum(corner), "Default player-side framing must keep every board corner visible.")
	var default_left := camera.unproject_position(Vector3(-16, 0, -16)).x
	var default_right := camera.unproject_position(Vector3(16, 0, -16)).x
	assert(default_left > get_root().get_visible_rect().size.x * 0.10 and default_right < get_root().get_visible_rect().size.x * 0.90, "Default framing must reserve only a narrow background margin around the board.")
	var default_top := INF
	var default_bottom := -INF
	for corner in [Vector3(-16, 0, -16), Vector3(-16, 0, 16), Vector3(16, 0, -16), Vector3(16, 0, 16)]:
		var screen_corner := camera.unproject_position(corner)
		default_top = minf(default_top, screen_corner.y)
		default_bottom = maxf(default_bottom, screen_corner.y)
	assert(default_top > get_root().get_visible_rect().size.y * 0.05 and default_bottom < get_root().get_visible_rect().size.y * 0.95, "Default framing must leave visible sky and valley padding above and below the board.")
	camera.snap_to_side(-1, 0.0)
	assert(camera.focused_side() == -1 and camera.global_position.z > 0.0, "Black's default view must mirror White's from the opposing board end.")
	assert(absf(camera.global_position.x) < 0.1, "Black's turn framing must sit directly behind Black's rank-eight team.")
	for corner in [Vector3(-16, 0, -16), Vector3(-16, 0, 16), Vector3(16, 0, -16), Vector3(16, 0, 16)]:
		assert(camera.is_position_in_frustum(corner), "Mirrored player-side framing must keep every board corner visible.")
	var walker := Node3D.new()
	root.add_child(walker)
	walker.global_position = Vector3.ZERO
	camera.begin_move_follow(walker, Vector3(0.0, 0.0, -4.0))
	walker.global_position = Vector3(0.0, 0.0, -2.0)
	await process_frame
	assert(not camera.controls_enabled(), "Move follow must lock manual orbit while the actor is walking.")
	assert(camera.global_position.z > walker.global_position.z, "Move follow must stay behind the actor relative to its destination.")
	assert(absf(camera.global_position.x - walker.global_position.x) > 0.5, "Move follow must use a shoulder offset so adjacent pieces do not hide the walker.")
	assert(camera.global_position.y > walker.global_position.y + 3.0, "Move follow must frame the actor from above the board surface.")
	var walker_screen_position := camera.unproject_position(walker.global_position + Vector3.UP * 1.55)
	var viewport_center := get_root().get_visible_rect().get_center()
	assert(walker_screen_position.distance_to(viewport_center) < get_root().get_visible_rect().size.x * 0.18, "Move follow must hold the walking character near screen center.")
	camera.end_move_follow()
	assert(camera.controls_enabled(), "Move follow must restore manual inspection after the walk.")
	walker.queue_free()
	camera.snap_to_side(1, 0.5)
	await process_frame
	var interrupted_transform: Transform3D = camera.global_transform
	camera.set_controls_enabled(false)
	await create_timer(0.6).timeout
	assert(camera.global_transform.is_equal_approx(interrupted_transform), "Disabling board controls must cancel a pending board snap so a capture shot owns the camera.")
	camera.queue_free()
	print("PASS: board camera zoom and orbit controls preserve board focus.")
	quit(0)
