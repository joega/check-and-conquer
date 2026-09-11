## Small, UI-independent persistence layer for player-facing session options.
## Values are intentionally primitive so a corrupt or old config can safely fall
## back to the defaults without affecting chess or presentation state.
extends RefCounted

const PATH := "user://warchessed_settings.cfg"
const LEGACY_PATH := "user://warboard_settings.cfg"
const SECTION := "session"

const DEFAULTS := {
	"computer_enabled": true,
	"spectator_enabled": false,
	"difficulty_index": 0,
	"player_side_index": 0,
	"capture_speed_index": 0,
	"camera_shake": true,
	"master_volume_db": 0.0,
	"fullscreen": false,
}


static func load_values() -> Dictionary:
	var values := DEFAULTS.duplicate()
	var config := ConfigFile.new()
	if config.load(PATH) != OK and config.load(LEGACY_PATH) != OK:
		return values
	for key in DEFAULTS:
		if config.has_section_key(SECTION, key):
			values[key] = config.get_value(SECTION, key, DEFAULTS[key])
	# V1 is exclusively player-versus-Stockfish. Ignore any older saved local
	# play toggle so opening the game never hands both sides to one player.
	values.computer_enabled = true
	return values


static func save_values(values: Dictionary) -> Error:
	var config := ConfigFile.new()
	for key in DEFAULTS:
		config.set_value(SECTION, key, values.get(key, DEFAULTS[key]))
	return config.save(PATH)
