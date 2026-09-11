extends SceneTree

const BattlefieldEnvironment = preload("res://scripts/presentation/battlefield_environment.gd")
const ArenaCatalog = preload("res://scripts/presentation/arena_catalog.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var battlefield := BattlefieldEnvironment.new()
	root.add_child(battlefield)
	await process_frame
	assert(ArenaCatalog.ids().size() == 5, "The campaign must expose five arena definitions.")
	assert(battlefield.get_node_or_null("SummitTerrain") == null, "No generated terrain mesh may cut across the panoramic mountain environment.")
	assert(battlefield.get_node_or_null("ArenaAtmosphereLight") is OmniLight3D, "The setting must include the deterministic atmosphere light.")
	assert(battlefield.get_node_or_null("ArenaArchitecture") != null, "Each arena needs its own local grand-terrace architecture.")
	assert(battlefield.get_node("ArenaArchitecture").get_child_count() >= 40, "The mountain terrace must include a full slab ring and four arena markers.")
	assert(battlefield.get_node_or_null("StormRain") == null, "No weather mesh may cross the board sightline.")
	battlefield._process(2.0)
	assert((battlefield.get_node("ArenaAtmosphereLight") as OmniLight3D).light_energy > 1.6, "The atmosphere light must visibly pulse at the deterministic arena beat.")
	for arena_id in ArenaCatalog.ids():
		var definition := ArenaCatalog.definition(arena_id)
		assert(ResourceLoader.exists(definition.backdrop_path) and load(definition.backdrop_path) is Texture2D, "Every arena must have an imported panoramic backdrop.")
		battlefield.apply_arena(arena_id)
		assert(battlefield.arena_id == arena_id, "Arena application must select %s." % arena_id)
		assert(battlefield.get_node("ArenaArchitecture").get_child_count() >= 40, "Every arena must rebuild a complete local terrace frame.")
	battlefield.queue_free()
	print("PASS: battlefield environment switches five grand arenas with a clear panorama sightline.")
	quit()
