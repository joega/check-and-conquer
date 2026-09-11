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
	var attacker := Node3D.new()
	attacker.position = Vector3(-1, 0, 0)
	stage.add_child(attacker)
	var victim := Node3D.new()
	victim.position = Vector3(1, 0, 0)
	stage.add_child(victim)
	await process_frame
	var board_transform: Transform3D = camera.global_transform
	director.begin_capture(attacker, victim)
	assert(not camera.controls_enabled(), "Board orbit must be suspended during a capture shot.")
	await create_timer(0.25).timeout
	assert(not camera.global_transform.is_equal_approx(board_transform), "Capture camera must leave the board shot.")
	var action_target := victim.global_position + Vector3.UP * 0.95
	assert(camera.global_transform.basis.z.dot((camera.global_position - action_target).normalized()) > 0.97, "Capture shot must face its staged impact target.")
	assert(camera.global_position.y - action_target.y >= director.capture_height_m - 0.1, "Capture shot must be high enough to keep other pieces out of the action view.")
	assert(Vector2(camera.global_position.x - action_target.x, camera.global_position.z - action_target.z).length() < 0.5, "Capture shot must remain nearly top-down over the impact target.")
	var capture_position: Vector3 = camera.global_position
	director.shake_on_impact()
	await create_timer(0.05).timeout
	assert(not camera.global_position.is_equal_approx(capture_position), "Enabled camera shake must move the capture shot.")
	await director.return_to_board().finished
	assert(camera.global_transform.is_equal_approx(board_transform), "Camera must restore the exact board transform.")
	assert(camera.controls_enabled(), "Board orbit must return after the capture shot.")
	stage.queue_free()
	print("PASS: capture camera stages and restores the board shot.")
	quit(0)
