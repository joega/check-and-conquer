extends SceneTree


func _init() -> void:
	assert(ProjectSettings.get_setting("application/config/name") == "Warchessed")
	call_deferred("_run")


func _run() -> void:
	var debug_scenes := [
		"res://scenes/app/Main.tscn",
		"res://scenes/app/CampaignMap.tscn",
		"res://scenes/debug/DebugCombatLab.tscn",
		"res://scenes/debug/DebugAnimationBrowser.tscn",
		"res://scenes/debug/DebugPositionLoader.tscn",
	]
	assert(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/app/CampaignMap.tscn", "The Warpath map must be the launch screen.")
	for scene_path: String in debug_scenes:
		assert(ResourceLoader.exists(scene_path), "Missing required debug scene: %s" % scene_path)
		var packed_scene := load(scene_path) as PackedScene
		assert(packed_scene != null, "Could not load scene: %s" % scene_path)
		var scene_instance := packed_scene.instantiate()
		assert(scene_instance != null, "Could not instantiate scene: %s" % scene_path)
		scene_instance.free()
	print("PASS: bootstrap project configuration and required debug-scene paths are present.")
	quit(0)
