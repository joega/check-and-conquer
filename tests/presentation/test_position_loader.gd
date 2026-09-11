extends SceneTree

const LOADER_SCENE = preload("res://scenes/debug/DebugPositionLoader.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var loader = LOADER_SCENE.instantiate()
	root.add_child(loader)
	await process_frame
	assert(loader.get_node("BoardPresenter").actor_count() == 32, "Loader must project its initial FEN into the visible presenter.")
	assert(loader.load_fen("7k/8/8/3pP3/8/8/8/K7 w - d6 0 1"))
	await process_frame
	assert(loader.get_node("BoardPresenter").actor_count() == 4, "Preset-style FEN must rebuild the visible actor projection.")
	assert(not loader.load_fen("not a fen"), "Invalid input must be rejected without asserting.")
	assert(loader.get_node("BoardPresenter").actor_count() == 4, "Invalid FEN must not replace the last valid projection.")
	assert("expected six" in loader.get_node("UI/Status").text)
	loader.queue_free()
	print("PASS: position loader validates FEN and rebuilds its visible projection.")
	quit()
