extends SceneTree

const MAIN_SCENE = preload("res://scenes/app/Main.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	assert(not main.get_node("LoadingOverlay").visible, "The menu must begin interactive.")
	main._begin_loading("res://scenes/app/Main.tscn")
	assert(main.get_node("LoadingOverlay").visible, "A menu choice must immediately acknowledge scene preparation.")
	assert(main.get_node("LoadingOverlay/Panel/Progress").value > 0.0, "The loading overlay must show a non-empty progress indicator.")
	assert(main.get_node("Margin/Content/PlayLocal").disabled, "Menu actions must lock while a scene is loading.")
	assert(not main._loading_scene_path.is_empty(), "The selected destination must remain tracked until the threaded load completes.")
	var progress := []
	var status := ResourceLoader.load_threaded_get_status(main._loading_scene_path, progress)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await process_frame
		status = ResourceLoader.load_threaded_get_status(main._loading_scene_path, progress)
	assert(status == ResourceLoader.THREAD_LOAD_LOADED, "The requested menu scene must complete threaded preparation.")
	assert(ResourceLoader.load_threaded_get(main._loading_scene_path) is PackedScene, "Threaded scene preparation must return a playable scene.")
	main._loading_scene_path = ""
	main.queue_free()
	await process_frame
	print("PASS: main menu acknowledges asynchronous scene loading.")
	quit()
