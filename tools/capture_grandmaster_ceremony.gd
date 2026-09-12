extends SceneTree

## Rendered Mountain Fortress ceremony inspection. Run with isolated XDG paths
## so it never changes a developer's campaign progress.
var output_dir := "/tmp/cac-grandmaster-ceremony"


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
	var game = preload("res://scenes/app/GameScreen.tscn").instantiate()
	root.add_child(game)
	var director = game.get_node("CampaignCinematic")
	var title: Label = director.get_node("Overlay/SpeechBubble/Content/Title")
	var cues := {"I · THE FIRST GATE": "01-grandmaster-dais", "THE GATEKEEPER": "02-gatekeeper", "THE COMMANDER": "03-commander", "OBJECTIVE": "04-grandmaster-objective"}
	var deadline := Time.get_ticks_msec() + 25000
	while not cues.is_empty() and Time.get_ticks_msec() < deadline:
		await process_frame
		if cues.has(title.text):
			var label: String = cues[title.text]
			cues.erase(title.text)
			await create_timer(0.8).timeout
			await _shot(label)
	assert(cues.is_empty(), "Every dialogue camera must be captured.")
	game.get_node("CampaignCinematic").skip()
	await process_frame
	quit(0)
