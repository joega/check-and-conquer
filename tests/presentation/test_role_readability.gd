extends SceneTree

const ACTOR_SCENE = preload("res://scenes/actors/PieceActor.tscn")
const PieceActor = preload("res://scripts/actors/piece_actor.gd")
const Types = preload("res://scripts/chess/chess_types.gd")

const EXPECTED_ACCESSORIES := {
	Types.PAWN: 0,
	Types.KNIGHT: 1,
	Types.BISHOP: 2,
	Types.ROOK: 3,
	Types.QUEEN: 4,
	Types.KING: 6,
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var signatures: Dictionary = {}
	for side in [Types.WHITE, Types.BLACK]:
		for archetype in [Types.PAWN, Types.KNIGHT, Types.BISHOP, Types.ROOK, Types.QUEEN, Types.KING]:
			var actor = ACTOR_SCENE.instantiate()
			actor.side = side
			actor.side_color = Color(0.20, 0.48, 0.95) if side == Types.WHITE else Color(0.83, 0.24, 0.22)
			actor.archetype = archetype
			actor.appearance_seed = archetype + (20 if side == Types.BLACK else 0)
			actor.position = Vector3(3.0, 0.0, -2.0)
			root.add_child(actor)
			await process_frame
			assert(actor.scale.is_equal_approx(Vector3.ONE), "Role accessories must not change authoritative actor scale.")
			assert((actor.get_node("ModelRoot") as Node3D).scale.is_equal_approx(Vector3.ONE * PieceActor.CHARACTER_PRESENTATION_SCALE), "All roles must preserve canonical presentation scale.")
			assert(actor.role_accessory_ids.size() == EXPECTED_ACCESSORIES[archetype], "Role %d has an unexpected silhouette accessory set." % archetype)
			var signature := "%s|%s|%s" % [actor.outfit_id, actor.silhouette_profile, ",".join(actor.role_accessory_ids)]
			if side == Types.WHITE:
				assert(not signatures.has(signature), "Label-hidden visual signatures must be unique across the six roles.")
				signatures[signature] = archetype
			var skeleton := actor.get_node("ModelRoot/Armature/Skeleton3D") as Skeleton3D
			for accessory_id in actor.role_accessory_ids:
				if accessory_id == "BishopRangerHood":
					var hood := skeleton.get_node(accessory_id) as MeshInstance3D
					assert(hood.skin != null and hood.skeleton == NodePath(".."), "The bishop hood must remain bound to the compatible outfit skeleton.")
					continue
				var attachment := skeleton.get_node("%sAttachment" % accessory_id) as BoneAttachment3D
				assert(attachment != null and skeleton.find_bone(attachment.bone_name) >= 0, "%s must follow a valid role bone." % accessory_id)
				var accessory := attachment.get_node(accessory_id) as MeshInstance3D
				assert(accessory.mesh != null and accessory.global_transform.is_finite(), "%s must remain finite and visible." % accessory_id)
			var native_female_hood := actor.get_node_or_null("ModelRoot/Armature/Skeleton3D/Female_Ranger_Head_Hood") as GeometryInstance3D
			var native_male_hood := actor.get_node_or_null("ModelRoot/Armature/Skeleton3D/Male_Ranger_Head_Hood") as GeometryInstance3D
			assert(native_female_hood == null or not native_female_hood.visible, "Knight and queen must not retain the shared ranger hood.")
			assert(native_male_hood == null or not native_male_hood.visible, "Rook and king must not retain the shared ranger hood.")
			if archetype == Types.QUEEN:
				assert(actor.hair_ids.has("Hair_Buns") and not actor.hair_ids.has("Hair_Long"), "Queen hair must leave the eyes clear beneath the diadem.")
				var diadem_band := actor.find_child("QueenDiademBand", true, false) as MeshInstance3D
				assert(diadem_band != null and diadem_band.position.y >= 0.19, "The queen diadem band must sit above the brow instead of crossing the eyes.")
			var belt := actor.find_child("*Belt*", true, false) as MeshInstance3D
			if belt != null:
				var belt_material := belt.get_surface_override_material(0) as StandardMaterial3D
				if belt_material != null:
					var belt_rgb := Vector3(belt_material.albedo_color.r, belt_material.albedo_color.g, belt_material.albedo_color.b)
					var side_rgb := Vector3(actor.side_color.r, actor.side_color.g, actor.side_color.b)
					assert(belt_rgb.distance_to(side_rgb) > 0.20, "A broad torso belt must not become a saturated team-color chest band.")
			var home: Transform3D = actor.global_transform
			for state in [&"idle.neutral", &"locomotion.walk.forward", actor.primary_attack_state(), &"recovery.capture_ready_01", &"death.backward_01"]:
				actor.reset_actor()
				actor.play_state(state)
				await create_timer(0.03).timeout
				assert(actor.global_transform.is_equal_approx(home), "Skeletal pose %s must not move role %d off its authoritative root." % [state, archetype])
				for accessory_id in actor.role_accessory_ids:
					var accessory_node := actor.find_child(accessory_id, true, false) as Node3D
					assert(accessory_node == null or accessory_node.global_transform.is_finite(), "Accessory %s must remain finite through %s." % [accessory_id, state])
			actor.queue_free()
			await process_frame
	assert(signatures.size() == 6, "The six roles must keep six unique label-hidden profiles.")
	print("PASS: six role silhouettes stay bone-bound, team-readable, and root-stable through required poses.")
	quit(0)
