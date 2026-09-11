extends SceneTree

const BattlefieldEnvironment = preload("res://scripts/presentation/battlefield_environment.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var battlefield := BattlefieldEnvironment.new()
	root.add_child(battlefield)
	await process_frame
	assert(battlefield.get_node_or_null("SummitTerrain") != null, "The presentation setting needs a rocky summit around the board.")
	assert(battlefield.get_node("SummitTerrain").mesh is ArrayMesh, "The mountain top must use a generated terrain mesh rather than a blank plane.")
	assert(is_equal_approx(battlefield._summit_vertex(0.0, 0.0).y, -0.32), "The chessboard must occupy the protected flat summit.")
	assert(battlefield._summit_vertex(42.0, 42.0).y < -8.0, "Terrain outside the altar must descend down the mountain rather than creating a horizon ridge.")
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
	print("PASS: battlefield environment builds a descending summit and deterministic weather.")
	quit()
