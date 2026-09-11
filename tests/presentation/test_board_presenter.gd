extends SceneTree
const BoardState = preload("res://scripts/chess/board_state.gd")
const Presenter = preload("res://scripts/presentation/board_presenter.gd")
const Types = preload("res://scripts/chess/chess_types.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var presenter = Presenter.new()
	root.add_child(presenter)
	presenter.rebuild_from_state(BoardState.starting_position())
	await process_frame
	assert(presenter.actor_count() == 32)
	var black_king = presenter.actors[60]
	var white_pawn = presenter.actors[8]
	assert(white_pawn.global_transform.basis.z.dot((black_king.global_position - white_pawn.global_position).normalized()) > 0.99, "White pieces must face the opposing king rather than hold a fixed board direction.")
	var battle_stances := {}
	for actor in presenter.actors.values():
		assert(not actor.battle_stance_state().is_empty(), "Every actor must choose a readable battle stance.")
		assert(actor.is_animation_paused(), "Board pieces must hold a clean neutral pose instead of visibly snapping through a loop seam.")
		battle_stances[actor.battle_stance_state()] = true
	assert(battle_stances.size() == 1, "The opening formation must share a clean neutral rest pose before isolated ambient movement begins.")
	presenter._play_next_ambient_motion()
	var moving_count := 0
	for actor in presenter.actors.values():
		if actor.is_available_for_ambient_motion() == false and actor.current_semantic_state() == actor.battle_stance_state():
			moving_count += 1
	assert(moving_count == 1, "The ambient scheduler must animate only one available board piece at a time.")
	var celebration_states := {}
	for index in [8, 1, 2, 0, 3, 4]:
		var celebrant = presenter.actors[index]
		celebrant.celebrate_victory(index)
		assert(celebrant.current_semantic_state() in [&"celebration.call_01", &"celebration.salute_01"], "Victory gestures must remain non-combat acknowledgement poses.")
		celebration_states[celebrant.current_semantic_state()] = true
	assert(celebration_states.size() <= 2, "Victory gestures must use the restrained acknowledgement set.")
	for actor in presenter.actors.values():
		actor.start_battle_stance()
	var capture_winner = presenter.actors[8]
	presenter._celebrate_capture(capture_winner)
	assert(capture_winner.current_semantic_state() == capture_winner.battle_stance_state(), "The capturing actor must remain focused after settling on its destination square.")
	var teammate_celebrants := 0
	for actor in presenter.actors.values():
		if actor != capture_winner and actor.side == capture_winner.side and actor.current_semantic_state().begins_with("celebration."):
			teammate_celebrants += 1
	assert(teammate_celebrants >= 1 and teammate_celebrants <= 2, "Only one or two teammates may acknowledge a capture.")
	assert(presenter.actors[0].archetype == 4 and presenter.actors[1].archetype == 2)
	assert(not presenter.actors[8].uses_female_model and not presenter.actors[0].uses_female_model and presenter.actors[1].uses_female_model)
	var expected_outfits := {
		8: "male_peasant", 1: "female_ranger", 2: "female_peasant",
		0: "male_ranger", 3: "female_ranger", 4: "male_ranger",
	}
	for square in expected_outfits:
		var actor = presenter.actors[square]
		assert(actor.outfit_id == expected_outfits[square], "Archetype at %s must use its assigned full outfit." % square)
		assert(actor.get_node("ModelRoot").scale.is_equal_approx(Vector3(2, 2, 2)), "The complete imported character must use the two-times presentation scale.")
		assert(actor.get_node("VisualAccents").scale.is_equal_approx(Vector3(2, 2, 2)), "Role and team accents must scale with the character.")
		assert(actor.get_node_or_null("ModelRoot/Armature/Skeleton3D") != null, "Imported outfit must retain the animated humanoid skeleton.")
		var detailed_head := actor.get_node_or_null("ModelRoot/Armature/Skeleton3D/HeadMesh") as MeshInstance3D
		assert(detailed_head != null and detailed_head.mesh is ArrayMesh and detailed_head.mesh.get_surface_count() == 1, "Full outfits must restore the textured, skinned base-character head mesh.")
		assert(actor.get_node_or_null("ModelRoot/Armature/Skeleton3D/Eyes") != null and actor.get_node_or_null("ModelRoot/Armature/Skeleton3D/Eyebrows") != null, "Detailed base-character facial meshes must remain present over the outfit.")
		var outfit_mesh := actor.get_node_or_null("ModelRoot/Armature/Skeleton3D") as Skeleton3D
		assert(not actor.hair_ids.is_empty(), "Every archetype must attach a compatible hairstyle or beard to complete its silhouette.")
		for hair_id in actor.hair_ids:
			var hair := actor.get_node_or_null("ModelRoot/Armature/Skeleton3D/%s" % hair_id) as MeshInstance3D
			assert(hair != null, "Configured hair must be attached to the animated outfit skeleton.")
			assert(hair.skeleton == NodePath("..") and hair.skin != null and hair.skin.get_bind_count() == outfit_mesh.get_bone_count(), "Hair must remain fully skinned to the compatible outfit skeleton.")
		assert(outfit_mesh.get_child(0) != null, "Outfit skeleton must retain its textured mesh children.")
	var skeleton_path := "ModelRoot/Armature/Skeleton3D/"
	assert(presenter.actors[0].get_node_or_null(skeleton_path + "RookWarHammerAttachment/RookWarHammer") != null, "Rook must carry an imported war-hammer mesh.")
	assert(presenter.actors[8].get_node_or_null(skeleton_path + "PawnRightDaggerAttachment/PawnRightDagger") != null, "Pawn must carry an imported right-hand dagger.")
	assert(presenter.actors[8].get_node_or_null(skeleton_path + "PawnLeftDaggerAttachment/PawnLeftDagger") != null, "Pawn must dual-wield imported daggers.")
	assert(presenter.actors[1].get_node_or_null(skeleton_path + "KnightSpearAttachment/KnightSpear") != null, "Knight must carry an imported spear mesh.")
	assert(presenter.actors[2].get_node_or_null(skeleton_path + "BishopGoldenBowAttachment/BishopGoldenBow") != null, "Bishop must carry an imported bow mesh.")
	assert(presenter.actors[3].get_node_or_null(skeleton_path + "QueenGoldenSwordAttachment/QueenGoldenSword") != null, "Queen must carry an imported golden sword mesh.")
	assert(presenter.actors[4].get_node_or_null(skeleton_path + "KingClaymoreAttachment/KingClaymore") != null, "King must carry an imported claymore mesh.")
	for path in [skeleton_path + "PawnRightDaggerAttachment/PawnRightDagger", skeleton_path + "KnightSpearAttachment/KnightSpear", skeleton_path + "BishopGoldenBowAttachment/BishopGoldenBow", skeleton_path + "RookWarHammerAttachment/RookWarHammer", skeleton_path + "QueenGoldenSwordAttachment/QueenGoldenSword", skeleton_path + "KingClaymoreAttachment/KingClaymore"]:
		var weapon := presenter.actors[8 if "Pawn" in path else 1 if "Knight" in path else 2 if "Bishop" in path else 0 if "Rook" in path else 3 if "Queen" in path else 4].get_node(path) as Node3D
		assert(weapon.scale.length() < 0.22, "Weapon roots must normalize imported FBX scale instead of enlarging the board.")
		assert(_largest_weapon_mesh_extent(weapon) < 2.5, "Imported weapon geometry must remain character-scale instead of filling the board.")
	for square in [8, 1, 2, 3, 4, 0]:
		assert(presenter.actors[square].get_node_or_null("VisualAccents/RookBattlement") == null, "Large overhead primitive type markers must not obstruct character or capture views.")
	assert(presenter.actors[4].get_node_or_null("VisualAccents/PieceGlyph") != null, "Each character must retain a compact class glyph on its base.")
	assert((presenter.actors[0].get_node("VisualAccents/PieceGlyph") as Label3D).text == "♜", "Base glyphs must use recognizable chess crests instead of single-letter abbreviations.")
	assert(presenter.actors[4].get_node_or_null("VisualAccents/TeamRing") != null and presenter.actors[4].get_node_or_null("VisualAccents/TeamBase") == null, "Side identity must use a compact ring rather than a full colored disk.")
	assert(presenter.actors[4].hair_ids.size() == 2, "The king must retain both a hairstyle and beard for a distinct full-character silhouette.")
	assert(not is_equal_approx(presenter.actors[8].rotation.y, presenter.actors[48].rotation.y), "Opposing armies must orient toward their respective opposing kings.")
	var white_material := (presenter.actors[8].get_node("ModelRoot/Armature/Skeleton3D").get_child(0) as MeshInstance3D).get_surface_override_material(0) as StandardMaterial3D
	var black_material := (presenter.actors[48].get_node("ModelRoot/Armature/Skeleton3D").get_child(0) as MeshInstance3D).get_surface_override_material(0) as StandardMaterial3D
	assert(white_material != null and black_material != null and not white_material.albedo_color.is_equal_approx(black_material.albedo_color), "Sides must receive distinct textured material tints.")
	var first_pawn_hair := presenter.actors[8].get_node("ModelRoot/Armature/Skeleton3D/%s" % presenter.actors[8].hair_ids[0]) as MeshInstance3D
	var second_pawn_hair := presenter.actors[9].get_node("ModelRoot/Armature/Skeleton3D/%s" % presenter.actors[9].hair_ids[0]) as MeshInstance3D
	var first_hair_material := first_pawn_hair.get_surface_override_material(0) as StandardMaterial3D
	var second_hair_material := second_pawn_hair.get_surface_override_material(0) as StandardMaterial3D
	assert(first_hair_material != null and second_hair_material != null and not first_hair_material.albedo_color.is_equal_approx(second_hair_material.albedo_color), "Square-stable appearance seeds must vary hair and brow colors across otherwise matching pieces.")
	assert(presenter.matches_state(BoardState.starting_position()))
	presenter.set_selected_square(8)
	var selected_ring := presenter.actors[8].get_node("VisualAccents/TeamRing") as MeshInstance3D
	var unselected_ring := presenter.actors[9].get_node("VisualAccents/TeamRing") as MeshInstance3D
	assert((selected_ring.material_override as StandardMaterial3D).emission_enabled and not (unselected_ring.material_override as StandardMaterial3D).emission_enabled, "Selecting a square must emphasize only that actor's compact base ring.")
	presenter.set_selected_square(-1)
	assert(not (selected_ring.material_override as StandardMaterial3D).emission_enabled, "Clearing selection must return the actor base ring to its non-emissive board state.")
	presenter.show_check_on_side(Types.BLACK)
	assert(presenter.actors[60].get_node_or_null("VisualAccents/CheckHalo") != null, "A checking move must mark the threatened king with a compact base halo.")
	presenter.clear_check_indicator()
	assert(presenter.actors[60].get_node_or_null("VisualAccents/CheckHalo") == null, "The check indicator must clear on the next non-checking move.")
	presenter.actors[0].global_position.x += 0.1
	assert(not presenter.matches_state(BoardState.starting_position()))
	presenter.rebuild_from_state(BoardState.starting_position())
	await process_frame
	assert(presenter.matches_state(BoardState.starting_position()))
	presenter.rebuild_from_state(BoardState.from_fen("8/8/8/8/8/8/8/K6k w - - 0 1"))
	await process_frame
	assert(presenter.actor_count() == 2)
	presenter.rebuild_from_state(BoardState.from_fen("3k4/8/8/8/8/8/4P3/4K3 w - - 0 1"))
	await process_frame
	var moved_king_pawn = presenter.actors[12]
	var moved_black_king = presenter.actors[59]
	assert(moved_king_pawn.global_transform.basis.z.dot((moved_black_king.global_position - moved_king_pawn.global_position).normalized()) > 0.99, "Rebuilding after a king move must reorient the army toward the king's new square.")
	presenter.queue_free()
	print("PASS: board presenter rebuilds from FEN state.")
	quit()


func _largest_weapon_mesh_extent(node: Node) -> float:
	var largest := 0.0
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		largest = mesh_instance.get_aabb().size.length() * mesh_instance.global_transform.basis.get_scale().length() / sqrt(3.0)
	for child in node.get_children():
		largest = maxf(largest, _largest_weapon_mesh_extent(child))
	return largest
