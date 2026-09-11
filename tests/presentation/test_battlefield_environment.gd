extends SceneTree

const BattlefieldEnvironment = preload("res://scripts/presentation/battlefield_environment.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var battlefield := BattlefieldEnvironment.new()
	root.add_child(battlefield)
	await process_frame
	assert(battlefield.get_node_or_null("ValleyFloorTerrain") != null, "The presentation setting needs a calm valley floor around the board.")
	assert(battlefield.get_node("ValleyFloorTerrain").mesh is PlaneMesh, "The valley floor must stay flat so no low-poly ridge can cut across the mountain panorama.")
	assert(is_equal_approx((battlefield.get_node("ValleyFloorTerrain") as MeshInstance3D).position.y, -0.32), "The chessboard must occupy the protected flat valley floor.")
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
