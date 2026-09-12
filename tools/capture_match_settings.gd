extends SceneTree

## Deterministic Match Settings layout evidence at the supported desktop sizes.
## Cinematics are disabled only for this capture so the menu can be opened
## without modifying a player's saved configuration.
const GAME_SCREEN = preload("res://scenes/app/GameScreen.tscn")
const SessionSettings = preload("res://scripts/game/session_settings.gd")

var output_dir := "/tmp/cac-match-settings"


func _init() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		output_dir = OS.get_cmdline_user_args()[0]
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	var settings := SessionSettings.DEFAULTS.duplicate()
	settings.campaign_cinematics_enabled = false
	assert(SessionSettings.save_values(settings) == OK)
	for size in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = size
		var screen = GAME_SCREEN.instantiate()
		root.add_child(screen)
		await process_frame
		await process_frame
		screen._toggle_settings_menu()
		await process_frame
		await RenderingServer.frame_post_draw
		var label := "%dx%d" % [size.x, size.y]
		assert(root.get_texture().get_image().save_png(output_dir.path_join(label + ".png")) == OK)
		print("SCREENSHOT: ", output_dir.path_join(label + ".png"))
		screen.queue_free()
		await process_frame
	quit(0)
