extends SceneTree

const SessionSettings = preload("res://scripts/game/session_settings.gd")


func _init() -> void:
	assert(SessionSettings.save_values(SessionSettings.DEFAULTS) == OK)
	var defaults := SessionSettings.load_values()
	assert(defaults.computer_enabled == true)
	assert(defaults.spectator_enabled == false)
	assert(defaults.beginner_coach_enabled == true)
	assert(defaults.capture_speed_index == 0)
	assert(defaults.campaign_enabled == true)
	assert(defaults.selected_arena_id == "mountain_fortress" and defaults.campaign_snapshot.is_empty(), "A fresh session must start at the first campaign arena.")
	var expected := defaults.duplicate()
	expected.computer_enabled = false
	expected.spectator_enabled = true
	expected.beginner_coach_enabled = false
	expected.difficulty_index = 3
	expected.player_side_index = 1
	expected.capture_speed_index = 1
	expected.camera_shake = false
	expected.master_volume_db = -12.5
	expected.fullscreen = true
	expected.selected_arena_id = "arcane_sky_citadel"
	expected.campaign_enabled = false
	expected.campaign_snapshot = {
		"current_arena_id": "arcane_sky_citadel",
		"unlocked_ids": ["mountain_fortress", "arcane_sky_citadel"],
		"completed_ids": ["mountain_fortress"],
	}
	assert(SessionSettings.save_values(expected) == OK)
	var restored := SessionSettings.load_values()
	for key in expected:
		if key == "computer_enabled":
			assert(restored[key] == true, "Saved local-play preference must be ignored in Stockfish-only V1.")
		else:
			assert(restored[key] == expected[key], "Saved setting %s must round-trip." % key)
	assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(SessionSettings.PATH)) == OK)
	var legacy := ConfigFile.new()
	legacy.set_value(SessionSettings.SECTION, "difficulty_index", 1)
	legacy.set_value(SessionSettings.SECTION, "camera_shake", false)
	assert(legacy.save(SessionSettings.LEGACY_PATHS[0]) == OK)
	var migrated := SessionSettings.load_values()
	assert(migrated.difficulty_index == 1)
	assert(migrated.camera_shake == false)
	assert(SessionSettings.save_values(SessionSettings.DEFAULTS) == OK)
	print("PASS: session settings save, restore, and legacy migration.")
	quit(0)
