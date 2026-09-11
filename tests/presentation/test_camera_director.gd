extends SceneTree

const CameraDirector = preload("res://scripts/presentation/camera_director.gd")
const BoardCamera = preload("res://scripts/presentation/board_camera_controller.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var camera = BoardCamera.new()
	camera.name = "Camera3D"
	camera.position = Vector3(6, 7, 7)
	stage.add_child(camera)
	camera.look_at(Vector3.ZERO)
	var director = CameraDirector.new()
	director.camera_path = NodePath("../Camera3D")
	stage.add_child(director)
	await process_frame
	var board_transform: Transform3D = camera.global_transform
	assert(camera.controls_enabled(), "Capture presentation must leave the player's board controls available.")
	var capture_position: Vector3 = camera.global_position
	director.shake_on_impact()
	await create_timer(0.05).timeout
	assert(not camera.global_position.is_equal_approx(capture_position), "Enabled camera shake must move the capture shot.")
	await create_timer(0.15).timeout
	assert(camera.global_transform.is_equal_approx(board_transform), "Impact polish must return to the exact player-selected board view.")
	stage.queue_free()
	print("PASS: capture polish preserves the player-selected board camera.")
	quit(0)
