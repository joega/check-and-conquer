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
	assert(map.get_node("OpeningHorn") is AudioStreamPlayer and map.get_node("OpeningHorn").stream is AudioStreamMP3, "The opening campaign map must carry the imported war-horn cue.")
	assert(map.get_node("Route").get_child_count() == 5, "The campaign route must expose five arena nodes.")
	assert(map.get_node("Route") is HBoxContainer, "Arena cards must use one responsive row rather than manually staggered coordinates.")
	var first_card := map.get_node("Route/MountainFortress") as Control
	for arena_node in map.get_node("Route").get_children():
		var card := arena_node as Control
		assert(card.size_flags_horizontal == Control.SIZE_EXPAND_FILL and is_equal_approx(card.global_position.y, first_card.global_position.y), "Every campaign arena card must share one aligned responsive row.")
	assert(map.get_node("Route/MountainFortress").disabled == false, "The first arena must begin available.")
	assert(map.get_node("Route/ArcaneSkyCitadel").disabled, "Future arenas must begin locked.")
	var locked_arena := map.get_node("Route/ArcaneSkyCitadel") as Button
	assert(locked_arena.modulate.r > 0.8 and locked_arena.modulate.g > 0.6 and locked_arena.get_theme_color("font_disabled_color").g > 0.6, "Locked arena names must retain the readable campaign-gold treatment alongside their lock indicator.")
	assert(map.get_node("PracticeArenaPicker").item_count == 5, "Practice must offer every arena without campaign-unlock requirements.")

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
	map._select_practice_arena(3)
	map.persist_selection(false, map.practice_arena_id)
	assert(SessionSettings.load_values().campaign_enabled == false and SessionSettings.load_values().selected_arena_id == "lava_forge", "Practice must persist a freely selected arena while disabling campaign progression.")
	map.queue_free()
	await process_frame
	print("PASS: campaign map route states and arena selection persistence.")
	quit()
