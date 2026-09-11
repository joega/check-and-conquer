extends SceneTree

const CAMPAIGN_MAP = preload("res://scenes/app/CampaignMap.tscn")
const SessionSettings = preload("res://scripts/game/session_settings.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	assert(SessionSettings.save_values(SessionSettings.DEFAULTS) == OK, "Campaign-map assertions require a fresh saved route.")
	var map = CAMPAIGN_MAP.instantiate()
	root.add_child(map)
	await process_frame
	assert(map.get_node("MapArt").texture is Texture2D, "The campaign route must be framed by its original illustrated map backdrop.")
	assert(map.get_node("Route").get_child_count() == 5, "The campaign route must expose five arena nodes.")
	assert(map.get_node("Route/MountainFortress").disabled == false, "The first arena must begin available.")
	assert(map.get_node("Route/ArcaneSkyCitadel").disabled, "Future arenas must begin locked.")

	map.set_campaign_snapshot({
		"current_arena_id": "arcane_sky_citadel",
		"unlocked_ids": ["mountain_fortress", "arcane_sky_citadel"],
		"completed_ids": ["mountain_fortress"],
	})
	assert("CONQUERED" in map.get_node("Route/MountainFortress").text, "Completed arenas need a conquered state.")
	assert(not map.get_node("Route/ArcaneSkyCitadel").disabled, "The current unlocked arena must be selectable.")
	assert(map.get_node("Route/FrozenKeep").disabled, "The next future arena must remain locked.")
	map.select_arena("arcane_sky_citadel")
	map.persist_selection()
	assert(map.arena_selected == "arcane_sky_citadel", "The selected arena must survive map state refresh.")
	assert(map._session_values.get("selected_arena_id") == "arcane_sky_citadel", "Entering must stage the selected arena in session settings.")
	assert(map._session_values.get("campaign_snapshot", {}).get("current_arena_id") == "arcane_sky_citadel", "Entering must stage a campaign snapshot.")
	var persisted := SessionSettings.load_values()
	assert(persisted.get("selected_arena_id") == "arcane_sky_citadel", "Selected arena must persist through SessionSettings.")
	assert(persisted.get("campaign_snapshot", {}).get("current_arena_id") == "arcane_sky_citadel", "Campaign snapshot must persist through SessionSettings.")
	assert(map.get_node("PracticeArena") is Button and map.get_node("DebugTools").get_child_count() == 4, "The launch map must expose a practice arena and the current developer-tool group.")
	map.persist_selection(false)
	assert(SessionSettings.load_values().campaign_enabled == false, "Practice matches must not advance the campaign route.")
	map.queue_free()
	await process_frame
	print("PASS: campaign map route states and arena selection persistence.")
	quit()
