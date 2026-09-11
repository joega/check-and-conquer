extends SceneTree

const BattlefieldEnvironment = preload("res://scripts/presentation/battlefield_environment.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var battlefield := BattlefieldEnvironment.new()
	root.add_child(battlefield)
	await process_frame
	assert(battlefield.get_node_or_null("MountainValleyTerrain") != null, "The presentation setting needs a mountain valley terrain base around the board.")
	assert(battlefield.get_node("MountainValleyTerrain").mesh is ArrayMesh, "The valley must be a generated height-field terrain rather than primitive mountain props.")
	assert(is_equal_approx(battlefield._valley_vertex(0.0, 0.0).y, -0.32), "The chessboard must occupy the protected flat valley floor.")
	assert(is_equal_approx(battlefield._valley_vertex(24.0, -24.0).y, -0.32), "The player camera must remain inside the unobstructed valley floor.")
	assert(battlefield._valley_vertex(48.0, 48.0).y > 5.0, "Terrain outside the board valley must rise into surrounding mountains.")
	assert(battlefield.get_node_or_null("StormFlash") is OmniLight3D, "The setting must include the deterministic lightning light.")
	var beacon_count := 0
	for child in battlefield.get_children():
		if child.name.begins_with("StormBeacon"):
			beacon_count += 1
	assert(beacon_count == 4, "The board setting must frame the arena with four storm beacons.")
	assert(battlefield.get_node_or_null("StormRain") == null, "No weather mesh may cross the board sightline.")
	battlefield._process(2.0)
	assert((battlefield.get_node("StormFlash") as OmniLight3D).light_energy > 3.9, "Lightning must visibly pulse at the deterministic storm beat.")
	battlefield.queue_free()
	print("PASS: battlefield environment builds deterministic mountains and weather.")
	quit()
