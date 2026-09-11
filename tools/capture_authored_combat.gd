extends SceneTree

## Focused visual proof for the two project-authored role action timelines.
## Run under isolated XDG directories so the active campaign save is untouched.
var output_dir := "/tmp/cac-authored-combat"


func _init() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		output_dir = OS.get_cmdline_user_args()[0]
	call_deferred("_run")


func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output_dir.path_join(label + ".png")) == OK)
	print("SCREENSHOT: ", label)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	var lab = preload("res://scenes/debug/DebugCombatLab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	# These controls intentionally bypass a match so their end poses can be
	# inspected without capture timing or destination movement in the way.
	lab._preview_recovery()
	await create_timer(0.16).timeout
	await _shot("capture-recovery")
	lab._preview_victory()
	await create_timer(0.16).timeout
	await _shot("victory-acknowledgement")
	lab._reset_lab()
	await process_frame
	# The bow shot is captured during its nocked-arrow preparation, then again
	# at contact. The precise release hand-off remains owned by BattleDirector.
	lab._select_attacker(2)
	lab._select_victim(0)
	await process_frame
	lab._play_capture()
	await create_timer(0.22).timeout
	await _shot("bishop-draw")
	await lab.get_node("BattleDirector").impact_landed
	await _shot("bishop-contact")
	await lab.get_node("BattleDirector").presentation_finished
	lab._reset_lab()
	await process_frame
	# The hammer contact arrives on the authored overhead descent rather than a
	# thrown-wall substitute.
	lab._select_attacker(3)
	lab._select_victim(0)
	await process_frame
	lab._play_capture()
	await lab.get_node("BattleDirector").impact_landed
	await _shot("rook-hammer-contact")
	await lab.get_node("BattleDirector").presentation_finished
	lab._reset_lab()
	await process_frame
	quit(0)
