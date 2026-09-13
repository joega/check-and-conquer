extends SceneTree

const BattlefieldEnvironment = preload("res://scripts/presentation/battlefield_environment.gd")
const ArenaCatalog = preload("res://scripts/presentation/arena_catalog.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lighting_host := Node3D.new()
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	world_environment.environment = Environment.new()
	lighting_host.add_child(world_environment)
	var key_light := DirectionalLight3D.new()
	key_light.name = "Light"
	lighting_host.add_child(key_light)
	var fill_light := DirectionalLight3D.new()
	fill_light.name = "FillLight"
	lighting_host.add_child(fill_light)
	var lit_battlefield := BattlefieldEnvironment.new()
	lighting_host.add_child(lit_battlefield)
	root.add_child(lighting_host)
	await process_frame

	var battlefield := BattlefieldEnvironment.new()
	root.add_child(battlefield)
	await process_frame
	assert(ArenaCatalog.ids().size() == 5, "The campaign must expose five arena definitions.")
	assert(battlefield.get_node_or_null("SummitTerrain") == null, "No generated terrain mesh may cut across the panoramic mountain environment.")
	assert(battlefield.get_node_or_null("ArenaAtmosphereLight") is OmniLight3D, "The setting must include the deterministic atmosphere light.")
	assert(battlefield.get_node_or_null("ArenaArchitecture") != null, "Each arena needs its own local grand-terrace architecture.")
	assert(battlefield.get_node("ArenaArchitecture").get_child_count() >= 40, "The mountain terrace must include a full slab ring and four arena markers.")
	assert(battlefield.get_node_or_null("StormRain") == null, "No weather mesh may cross the board sightline.")
	battlefield._storm_time = 0.0
	battlefield._process(2.0)
	assert((battlefield.get_node("ArenaAtmosphereLight") as OmniLight3D).light_energy > 1.0, "The restrained atmosphere light must visibly pulse at the deterministic arena beat.")
	for arena_id in ArenaCatalog.ids():
		var definition := ArenaCatalog.definition(arena_id)
		assert(ResourceLoader.exists(definition.backdrop_path) and load(definition.backdrop_path) is Texture2D, "Every arena must have an imported panoramic backdrop.")
		battlefield.apply_arena(arena_id)
		assert(battlefield.arena_id == arena_id, "Arena application must select %s." % arena_id)
		assert(battlefield.get_node("ArenaArchitecture").get_child_count() >= 40, "Every arena must rebuild a complete local terrace frame.")
		var dressing := battlefield.get_node("ArenaArchitecture/ArenaSetDressing") as Node3D
		var expected_landmarks := 2 if arena_id == "mountain_fortress" else 3
		assert(dressing != null and dressing.get_child_count() >= expected_landmarks, "%s needs %d distinct landmarks; found %d." % [arena_id, expected_landmarks, dressing.get_child_count() if dressing != null else -1])
		lit_battlefield.apply_arena(arena_id)
		assert(world_environment.environment.ambient_light_color == BattlefieldEnvironment.BOARD_AMBIENT_COLOR, "Arena lighting must keep board ambient color neutral in %s." % arena_id)
		assert(world_environment.environment.ambient_light_source == Environment.AMBIENT_SOURCE_COLOR, "Panorama light must not tint the playable board in %s." % arena_id)
		assert(is_equal_approx(world_environment.environment.ambient_light_energy, BattlefieldEnvironment.BOARD_AMBIENT_ENERGY), "Arena lighting must preserve bright neutral ambient energy in %s." % arena_id)
		assert(key_light.light_color == BattlefieldEnvironment.BOARD_KEY_COLOR and is_equal_approx(key_light.light_energy, BattlefieldEnvironment.BOARD_KEY_ENERGY), "Arena key light must stay neutral in %s." % arena_id)
		assert(fill_light.light_color == BattlefieldEnvironment.BOARD_FILL_COLOR and is_equal_approx(fill_light.light_energy, BattlefieldEnvironment.BOARD_FILL_ENERGY), "Arena fill light must stay neutral in %s." % arena_id)
		if arena_id == "mountain_fortress":
			assert(dressing.get_node_or_null("FortressBannerStandard00") != null and dressing.get_node_or_null("FortressBannerStandard01") != null, "Mountain foreground needs two coherent banner standards.")
			for marker_index in 4:
				assert(battlefield.get_node_or_null("ArenaArchitecture/ArenaMarker%02d/FortressTorch" % marker_index) != null, "Mountain corner marker %d must use the owned torch prop." % marker_index)
			assert(battlefield.find_children("FortressWatchtower*", "MeshInstance3D", true, false).is_empty(), "Primitive foreground watchtowers must be removed.")
			assert(key_light.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS and is_equal_approx(key_light.directional_shadow_max_distance, 52.0), "Mountain reference shadow settings must model feet across the terrace.")
		else:
			for marker_index in 4:
				var marker := battlefield.get_node("ArenaArchitecture/ArenaMarker%02d" % marker_index)
				assert((marker.get_child(0) as MeshInstance3D).mesh is ArrayMesh, "%s markers must inherit the beveled reference plinth." % arena_id)
				var accent := marker.get_node("ArenaAccent") as MeshInstance3D
				assert((accent.material_override as StandardMaterial3D).emission_energy_multiplier <= 0.82, "%s marker emission must remain restrained." % arena_id)
		if arena_id == "lava_forge":
			assert(dressing.get_node_or_null("ForgeTorch00") != null and dressing.get_node_or_null("ForgeTorch02") != null, "Lava Forge must use the owned torch props on authored plinths.")
		if arena_id == "forest_ruins":
			assert((dressing.get_node("GroveArchPillar00_-1") as MeshInstance3D).mesh is ArrayMesh, "Forest arches must inherit authored edge treatment.")
	battlefield.queue_free()
	lighting_host.queue_free()
	print("PASS: battlefield environment switches five grand arenas with a clear panorama sightline.")
	quit()
