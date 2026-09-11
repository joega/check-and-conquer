extends SceneTree
const BoardState = preload("res://scripts/chess/board_state.gd")
const Presenter = preload("res://scripts/presentation/board_presenter.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var presenter = Presenter.new()
	root.add_child(presenter)
	presenter.rebuild_from_state(BoardState.starting_position())
	await process_frame
	assert(presenter.actor_count() == 32)
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
	assert(presenter.actors[0].get_node_or_null("ModelRoot/Armature/Skeleton3D/RightHandProp/RookShield") == null, "Rook shield must not obstruct the full outfit silhouette.")
	assert(presenter.actors[0].get_node_or_null("VisualAccents/RookBattlement") == null, "Large overhead primitive type markers must not obstruct character or capture views.")
	assert(presenter.actors[4].get_node_or_null("VisualAccents/PieceGlyph") != null, "Each character must retain a compact class glyph on its base.")
	assert(presenter.actors[4].hair_ids.size() == 2, "The king must retain both a hairstyle and beard for a distinct full-character silhouette.")
	assert(presenter.actors[0].get_node_or_null("ModelRoot/Armature/Skeleton3D/RightHandProp/RookMaceHead") != null, "Rook must retain a non-obstructive hand prop.")
	assert(presenter.actors[8].get_node_or_null("ModelRoot/Armature/Skeleton3D/RightHandProp/PawnSwordBlade") != null, "Pawn must carry a distinct sword assembly rather than a team-colored primitive.")
	assert(presenter.actors[1].get_node_or_null("ModelRoot/Armature/Skeleton3D/RightHandProp/KnightLanceTip") != null, "Knight must carry a distinct lance assembly.")
	assert(presenter.actors[2].get_node_or_null("ModelRoot/Armature/Skeleton3D/RightHandProp/BishopFocusOrb") != null, "Bishop must carry a distinct staff and focus assembly.")
	assert(presenter.actors[3].get_node_or_null("ModelRoot/Armature/Skeleton3D/RightHandProp/QueenCrownOrb") != null, "Queen must carry a distinct sceptre assembly.")
	assert(presenter.actors[4].get_node_or_null("ModelRoot/Armature/Skeleton3D/RightHandProp/KingBlade") != null, "King must carry a distinct royal blade assembly.")
	for square in [8, 1, 2, 3, 4, 0]:
		assert(presenter.actors[square].get_node_or_null("ModelRoot/Armature/Skeleton3D/RightHandProp") != null, "Role props must remain attached to animated hands.")
	assert(is_zero_approx(presenter.actors[8].rotation.y), "White actors must use the board-forward orientation.")
	assert(is_equal_approx(abs(presenter.actors[48].rotation.y), PI), "Black actors must face the opposite board direction.")
	var white_material := (presenter.actors[8].get_node("ModelRoot/Armature/Skeleton3D").get_child(0) as MeshInstance3D).get_surface_override_material(0) as StandardMaterial3D
	var black_material := (presenter.actors[48].get_node("ModelRoot/Armature/Skeleton3D").get_child(0) as MeshInstance3D).get_surface_override_material(0) as StandardMaterial3D
	assert(white_material != null and black_material != null and not white_material.albedo_color.is_equal_approx(black_material.albedo_color), "Sides must receive distinct textured material tints.")
	assert(presenter.matches_state(BoardState.starting_position()))
	presenter.actors[0].global_position.x += 0.1
	assert(not presenter.matches_state(BoardState.starting_position()))
	presenter.rebuild_from_state(BoardState.starting_position())
	await process_frame
	assert(presenter.matches_state(BoardState.starting_position()))
	presenter.rebuild_from_state(BoardState.from_fen("8/8/8/8/8/8/8/K6k w - - 0 1"))
	await process_frame
	assert(presenter.actor_count() == 2)
	presenter.queue_free()
	print("PASS: board presenter rebuilds from FEN state.")
	quit()
