extends SceneTree

const BattlefieldEnvironment = preload("res://scripts/presentation/battlefield_environment.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var battlefield := BattlefieldEnvironment.new()
	root.add_child(battlefield)
	await process_frame
	assert(battlefield.get_node_or_null("MountainPlateau") != null, "The presentation setting needs a terrain base around the board.")
	assert(battlefield.get_node_or_null("StormFlash") is OmniLight3D, "The setting must include the deterministic lightning light.")
	assert(battlefield.get_node_or_null("StormRain") is GPUParticles3D, "The setting must include a bounded rain layer.")
	var mountain_count := 0
	var beacon_count := 0
	for child in battlefield.get_children():
		if child.name.begins_with("Mountain") and child.name != "MountainPlateau":
			mountain_count += 1
		if child.name.begins_with("StormBeacon"):
			beacon_count += 1
	assert(mountain_count == 10, "The board setting must surround play with a complete mountain ring.")
	assert(beacon_count == 4, "The board setting must frame the arena with four storm beacons.")
	battlefield._process(2.0)
	assert((battlefield.get_node("StormFlash") as OmniLight3D).light_energy > 3.9, "Lightning must visibly pulse at the deterministic storm beat.")
	battlefield.queue_free()
	print("PASS: battlefield environment builds deterministic mountains and weather.")
	quit()
