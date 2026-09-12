extends SceneTree

## Isolated, deterministic front/side views of the actual ceremony assets.
## godot --path . --script tools/capture_seating_fit.gd -- /tmp/cac-seat-fit
func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var output := "/tmp/cac-seat-fit"
	if not OS.get_cmdline_user_args().is_empty():
		output = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	var stage = preload("res://scripts/presentation/grandmaster_ceremony.gd").new()
	root.add_child(stage)
	await process_frame
	stage.begin_grandmaster_seating()
	await create_timer(1.4).timeout
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.current = true
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 6.5
	var light := DirectionalLight3D.new()
	stage.add_child(light)
	light.rotation_degrees = Vector3(-45, -30, 0)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.25, 0.25, 0.25)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.6
	stage.add_child(environment)
	var positions := {"front": Vector3(9, 4, 0), "side": Vector3(20, 4, 10), "three-quarter": Vector3(10, 5, 9)}
	for view in positions:
		camera.position = positions[view]
		camera.look_at(Vector3(20, 2.8, 0))
		await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(output.path_join(view + ".png")) == OK)
		print("SCREENSHOT: ", output.path_join(view + ".png"))
	quit(0)
