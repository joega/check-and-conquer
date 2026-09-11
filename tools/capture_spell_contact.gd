extends SceneTree

## Focused renderer evidence for ranged contact readability. This avoids a
## player save and is intentionally separate from the broad visual audit.
var output_dir := "/tmp/cac-spell-contact"


func _init() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		output_dir = OS.get_cmdline_user_args()[0]
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for role in [2, 4]:
		var lab = preload("res://scenes/debug/DebugCombatLab.tscn").instantiate()
		root.add_child(lab)
		await process_frame
		lab._select_attacker(role)
		lab._select_victim(0)
		await process_frame
		lab._play_capture()
		await lab.get_node("BattleDirector").impact_landed
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(output_dir.path_join("spell-%d-contact.png" % role)) == OK)
		await lab.get_node("BattleDirector").presentation_finished
		lab.queue_free()
		await process_frame
	quit(0)
