extends SceneTree

const SessionSettings = preload("res://scripts/game/session_settings.gd")


func _init() -> void:
	assert(SessionSettings.save_values(SessionSettings.DEFAULTS) == OK)
	var defaults := SessionSettings.load_values()
	assert(defaults.computer_enabled == true)
	assert(defaults.spectator_enabled == false)
	assert(defaults.capture_speed_index == 0)
	var expected := defaults.duplicate()
	expected.computer_enabled = false
	expected.spectator_enabled = true
	expected.difficulty_index = 1
	expected.player_side_index = 1
	expected.capture_speed_index = 1
	expected.camera_shake = false
	expected.master_volume_db = -12.5
	expected.fullscreen = true
	assert(SessionSettings.save_values(expected) == OK)
	var restored := SessionSettings.load_values()
	for key in expected:
		assert(restored[key] == expected[key], "Saved setting %s must round-trip." % key)
	assert(SessionSettings.save_values(SessionSettings.DEFAULTS) == OK)
	print("PASS: session settings save and restore.")
	quit(0)
