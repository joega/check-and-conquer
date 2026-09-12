extends SceneTree

## Deterministic visual audit for semantic animation routing. This uses the
## actual Animation Browser scene so UAL1/UAL2 ownership changes can be checked
## without manually changing a player's campaign state.
var output_dir := "/tmp/cac-animation-browser"


func _init() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		output_dir = OS.get_cmdline_user_args()[0]
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	var browser = preload("res://scenes/debug/DebugAnimationBrowser.tscn").instantiate()
	root.add_child(browser)
	await process_frame
	await process_frame
	var captures := {
		"ual1-neutral": &"idle.neutral",
		"ual2-watch": &"idle.watch_01",
		"ual2-guard": &"stance.guard_01",
		"ual2-heavy-combo": &"attack.sword.heavy_combo_01",
	}
	for label: String in captures:
		browser._play(captures[label], label)
		await create_timer(0.25).timeout
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(output_dir.path_join(label + ".png")) == OK)
		print("SCREENSHOT: ", output_dir.path_join(label + ".png"))
	browser.queue_free()
	await process_frame
	quit(0)
