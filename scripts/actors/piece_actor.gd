class_name PieceActor
extends Node3D

const MALE_PEASANT_SCENE := preload("res://assets/characters/quaternius/outfits/Male_Peasant.gltf")
const FEMALE_PEASANT_SCENE := preload("res://assets/characters/quaternius/outfits/Female_Peasant.gltf")
const MALE_RANGER_SCENE := preload("res://assets/characters/quaternius/outfits/Male_Ranger.gltf")
const FEMALE_RANGER_SCENE := preload("res://assets/characters/quaternius/outfits/Female_Ranger.gltf")
const BASE_MALE_SCENE := preload("res://assets/characters/quaternius/Superhero_Male_FullBody.gltf")
const BASE_FEMALE_SCENE := preload("res://assets/characters/quaternius/Superhero_Female_FullBody.gltf")
const HAIR_BEARD_SCENE := preload("res://assets/characters/quaternius/hair/Hair_Beard.gltf")
const HAIR_BUNS_SCENE := preload("res://assets/characters/quaternius/hair/Hair_Buns.gltf")
const HAIR_LONG_SCENE := preload("res://assets/characters/quaternius/hair/Hair_Long.gltf")
const HAIR_SIMPLE_PARTED_SCENE := preload("res://assets/characters/quaternius/hair/Hair_SimpleParted.gltf")
const ANIMATION_LIBRARY_SCENE := preload("res://assets/animations/quaternius/UAL1_Standard.glb")
const ANIMATION_LIBRARY_2_SCENE := preload("res://assets/animations/quaternius/UAL2_Standard.glb")
const Types = preload("res://scripts/chess/chess_types.gd")
## Presentation scale only. The actor root stays in board metres so chess
## coordinates, capture destinations, and rebuild checks remain authoritative.
const CHARACTER_PRESENTATION_SCALE := 2.0
## Props live below the doubled imported-character root. Keep them deliberately
## compact so a close board inspection still shows the outfit and face rather
## than a primitive mesh filling the camera.
const ROLE_PROP_SCALE := 0.62
const CLIP_MAP := {
	&"idle.neutral": &"Idle",
	&"combat.idle.sword_01": &"Sword_Idle",
	&"combat.idle.spell_01": &"Spell_Simple_Idle",
	&"locomotion.walk.forward": &"Walk",
	&"attack.sword.slash_01": &"Sword_Attack",
	&"attack.punch.jab_01": &"Punch_Jab",
	&"attack.push.guard_01": &"Push",
	&"attack.spell.shot_01": &"Spell_Simple_Shoot",
	&"reaction.hit.generic_01": &"Hit_Chest",
	&"reaction.hit.head_01": &"Hit_Head",
	&"death.backward_01": &"Death01",
}
const CLIP_MAP_2 := {
	&"attack.melee.hook_01": &"Melee_Hook",
	&"attack.sword.regular_a_01": &"Sword_Regular_A",
	&"attack.sword.regular_b_01": &"Sword_Regular_B",
	&"reaction.hit.knockback_01": &"Hit_Knockback",
	&"death.knockback_01": &"Hit_Knockback",
}

@export var side_color := Color(0.22, 0.5, 0.95)
@export var archetype := Types.PAWN
@export var side := Types.WHITE

var _home_transform: Transform3D
var _model_root: Node3D
var _visual_accents: Node3D
var _animation_player: AnimationPlayer
var _animation_player_2: AnimationPlayer
var _last_played_state: StringName = &"idle.neutral"
var _animation_paused := false
var _animation_speed_multiplier := 1.0
var uses_female_model := false
var outfit_id := ""
var hair_ids: Array[String] = []


func _ready() -> void:
	rotation.y = PI if side == Types.BLACK else 0.0
	uses_female_model = archetype in [Types.KNIGHT, Types.BISHOP, Types.QUEEN]
	var character_scene := _outfit_scene_for_archetype()
	_model_root = character_scene.instantiate() as Node3D
	_model_root.name = "ModelRoot"
	_model_root.scale = Vector3.ONE * CHARACTER_PRESENTATION_SCALE
	add_child(_model_root)
	_visual_accents = Node3D.new()
	_visual_accents.name = "VisualAccents"
	_visual_accents.scale = Vector3.ONE * CHARACTER_PRESENTATION_SCALE
	add_child(_visual_accents)
	_apply_team_material_variant(_model_root)
	_create_head()
	_create_hair()
	_create_role_prop()
	_attach_compatible_animation_player()
	_create_team_accent()
	_create_piece_glyph()
	_home_transform = global_transform
	play_state(&"idle.neutral")


func _outfit_scene_for_archetype() -> PackedScene:
	match archetype:
		Types.PAWN:
			outfit_id = "male_peasant"
			return MALE_PEASANT_SCENE
		Types.KNIGHT:
			outfit_id = "female_ranger"
			return FEMALE_RANGER_SCENE
		Types.BISHOP:
			outfit_id = "female_peasant"
			return FEMALE_PEASANT_SCENE
		Types.ROOK:
			outfit_id = "male_ranger"
			return MALE_RANGER_SCENE
		Types.QUEEN:
			outfit_id = "female_ranger"
			return FEMALE_RANGER_SCENE
		_:
			outfit_id = "male_ranger"
			return MALE_RANGER_SCENE


func _attach_compatible_animation_player() -> void:
	_animation_player = _attach_animation_player(ANIMATION_LIBRARY_SCENE, "AnimationPlayer")
	_animation_player_2 = _attach_animation_player(ANIMATION_LIBRARY_2_SCENE, "CombatAnimationPlayer")


func _attach_animation_player(source_scene: PackedScene, player_name: String) -> AnimationPlayer:
	var animation_source := source_scene.instantiate()
	var player := animation_source.get_node("AnimationPlayer") as AnimationPlayer
	animation_source.remove_child(player)
	player.name = player_name
	player.owner = null
	_model_root.add_child(player)
	animation_source.free()
	return player


func play_clip(clip: StringName) -> void:
	if _animation_player != null and _animation_player.has_animation(clip):
		if _animation_player_2 != null:
			_animation_player_2.stop()
		_animation_player.play(clip)


func play_state(semantic_id: StringName) -> void:
	_animation_paused = false
	_last_played_state = semantic_id
	if CLIP_MAP_2.has(semantic_id):
		var clip_2: StringName = CLIP_MAP_2[semantic_id]
		if _animation_player_2 != null and _animation_player_2.has_animation(clip_2):
			if _animation_player != null:
				_animation_player.stop()
			_animation_player_2.play(clip_2)
			return
	play_clip(CLIP_MAP.get(semantic_id, &"Idle"))


func supports_state(semantic_id: StringName) -> bool:
	if CLIP_MAP_2.has(semantic_id):
		return _animation_player_2 != null and _animation_player_2.has_animation(CLIP_MAP_2[semantic_id])
	return CLIP_MAP.has(semantic_id) and _animation_player != null and _animation_player.has_animation(CLIP_MAP[semantic_id])


func primary_attack_state() -> StringName:
	match archetype:
		Types.KNIGHT:
			return &"attack.punch.jab_01"
		Types.BISHOP, Types.QUEEN:
			return &"attack.spell.shot_01"
		Types.ROOK:
			return &"attack.push.guard_01"
		_:
			return &"attack.sword.slash_01"


func combat_idle_state() -> StringName:
	return &"combat.idle.spell_01" if archetype in [Types.BISHOP, Types.QUEEN] else &"combat.idle.sword_01"


func state_duration(semantic_id: StringName) -> float:
	var player := _animation_player
	var clip: StringName = CLIP_MAP.get(semantic_id, &"Idle")
	if CLIP_MAP_2.has(semantic_id):
		player = _animation_player_2
		clip = CLIP_MAP_2[semantic_id]
	if player == null:
		return 0.0
	var animation := player.get_animation(clip)
	return animation.length if animation != null else 0.0


func animation_playback_position() -> float:
	var player := _animation_player_2 if CLIP_MAP_2.has(_last_played_state) else _animation_player
	if player == null:
		return 0.0
	# Non-looping players clear current_animation when they complete. At that
	# point the full known semantic duration is the useful completion position.
	if player.current_animation.is_empty():
		return state_duration(_last_played_state)
	return player.current_animation_position


func current_semantic_state() -> StringName:
	return _last_played_state


func set_animation_speed(multiplier: float) -> void:
	_animation_speed_multiplier = maxf(multiplier, 0.1)
	if _animation_player != null:
		_animation_player.speed_scale = _animation_speed_multiplier
	if _animation_player_2 != null:
		_animation_player_2.speed_scale = _animation_speed_multiplier


func animation_speed_multiplier() -> float:
	return _animation_speed_multiplier


func set_animation_paused(paused: bool) -> void:
	_animation_paused = paused
	var active_player := _animation_player_2 if CLIP_MAP_2.has(_last_played_state) else _animation_player
	if active_player == null:
		return
	if paused:
		active_player.pause()
	elif not active_player.current_animation.is_empty():
		active_player.play()


func is_animation_paused() -> bool:
	return _animation_paused


func move_to_world_position(target: Vector3, duration_s: float) -> Tween:
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, duration_s).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	return tween


func face_world_position(target: Vector3) -> void:
	var flat_target := target
	flat_target.y = global_position.y
	if not flat_target.is_equal_approx(global_position):
		look_at(flat_target, Vector3.UP, true)


func restore_board_facing() -> void:
	# Presentation may turn an actor toward a movement target or opponent. Once
	# it settles on its authoritative square, restore the side's board-facing
	# orientation so captures never leave the survivor turned around.
	rotation = Vector3.ZERO
	rotation.y = PI if side == Types.BLACK else 0.0


func set_home_transform(value: Transform3D) -> void:
	_home_transform = value


func reset_actor() -> void:
	global_transform = _home_transform
	visible = true
	if _animation_player != null:
		_animation_player.stop()
	if _animation_player_2 != null:
		_animation_player_2.stop()
	_animation_paused = false
	play_state(&"idle.neutral")


func _apply_team_material_variant(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh != null:
			for surface in mesh_node.mesh.get_surface_count():
				var source_material := mesh_node.get_active_material(surface) as StandardMaterial3D
				if source_material == null:
					continue
				var team_material := source_material.duplicate() as StandardMaterial3D
				# Preserve the imported texture and add a restrained team tint, rather
				# than replacing detailed outfit materials with a flat color.
				team_material.albedo_color = source_material.albedo_color.lerp(side_color, 0.16)
				mesh_node.set_surface_override_material(surface, team_material)
	for child in node.get_children():
		_apply_team_material_variant(child)


func _create_team_accent() -> void:
	# Keep team identity visible without covering the imported outfit detail.
	_add_marker("TeamBase", _cylinder(0.44, 0.44, 0.035), Vector3(0, 0.018, 0), side_color)


func _create_piece_glyph() -> void:
	# A compact glyph on the base replaces the large floating primitive markers.
	# It is readable from the board, never obstructs a face, and stays below the
	# overhead capture camera's action framing.
	var glyph := Label3D.new()
	glyph.name = "PieceGlyph"
	glyph.text = _piece_glyph_text()
	glyph.position = Vector3(0, 0.041, 0)
	glyph.rotation_degrees = Vector3(-90, 0, 0)
	glyph.font_size = 38
	glyph.pixel_size = 0.0035
	glyph.outline_size = 5
	glyph.modulate = Color(1.0, 0.84, 0.4)
	_visual_accents.add_child(glyph)


func _piece_glyph_text() -> String:
	match archetype:
		Types.KNIGHT:
			return "N"
		Types.BISHOP:
			return "B"
		Types.ROOK:
			return "R"
		Types.QUEEN:
			return "Q"
		Types.KING:
			return "K"
	return "P"


func _create_head() -> void:
	# Fantasy's full outfits replace the body but omit the base-character face.
	# Preserve the outfit meshes, then transfer only the detailed head, eyes, and
	# brows from the matching base character onto the shared skeleton. This avoids
	# a second torso beneath the clothes and keeps the original facial detail.
	var target_skeleton := _model_root.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
	if target_skeleton == null:
		return
	var base_root := (BASE_FEMALE_SCENE if uses_female_model else BASE_MALE_SCENE).instantiate() as Node3D
	var source_skeleton := base_root.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
	var body_name := "Superhero_Female" if uses_female_model else "SuperHero_Male"
	var source_body := base_root.get_node_or_null("Armature/Skeleton3D/%s" % body_name) as MeshInstance3D
	if source_skeleton == null or source_body == null or source_body.mesh == null:
		base_root.free()
		return
	var head := MeshInstance3D.new()
	head.name = "HeadMesh"
	head.mesh = _extract_head_mesh(source_body.mesh, source_skeleton)
	head.skin = source_body.skin
	head.skeleton = NodePath("..")
	target_skeleton.add_child(head)
	for feature_name in [&"Eyes", &"Eyebrows"]:
		var source_feature := source_skeleton.get_node_or_null(NodePath(feature_name)) as MeshInstance3D
		if source_feature == null:
			continue
		var feature := source_feature.duplicate() as MeshInstance3D
		feature.name = feature_name
		feature.skeleton = NodePath("..")
		target_skeleton.add_child(feature)
	base_root.free()


func _create_hair() -> void:
	# Hair is authored for the same 65-joint rig as the outfits. Transfer its
	# skinned mesh onto the outfit skeleton just like the detailed base face,
	# preserving a complete character without layering a second body underneath.
	var target_skeleton := _model_root.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
	if target_skeleton == null:
		return
	for hair_scene in _hair_scenes_for_archetype():
		var hair_root := hair_scene.instantiate() as Node3D
		var source_skeleton := hair_root.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
		var source_hair := source_skeleton.get_child(0) as MeshInstance3D if source_skeleton != null and source_skeleton.get_child_count() > 0 else null
		if source_hair != null:
			var hair := source_hair.duplicate() as MeshInstance3D
			hair.skeleton = NodePath("..")
			target_skeleton.add_child(hair)
			hair_ids.append(hair.name)
		hair_root.free()


func _hair_scenes_for_archetype() -> Array[PackedScene]:
	match archetype:
		Types.PAWN:
			return [HAIR_SIMPLE_PARTED_SCENE]
		Types.KNIGHT:
			return [HAIR_BUNS_SCENE]
		Types.BISHOP:
			return [HAIR_LONG_SCENE]
		Types.ROOK:
			return [HAIR_BEARD_SCENE]
		Types.QUEEN:
			return [HAIR_LONG_SCENE]
		Types.KING:
			return [HAIR_SIMPLE_PARTED_SCENE, HAIR_BEARD_SCENE]
	return []


func _extract_head_mesh(source_mesh: Mesh, source_skeleton: Skeleton3D) -> ArrayMesh:
	var source_arrays := source_mesh.surface_get_arrays(0)
	var indices: PackedInt32Array = source_arrays[Mesh.ARRAY_INDEX]
	var joints: PackedInt32Array = source_arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = source_arrays[Mesh.ARRAY_WEIGHTS]
	var head_bone := source_skeleton.find_bone("Head")
	var neck_bone := source_skeleton.find_bone("neck_01")
	var head_indices := PackedInt32Array()
	for triangle_start in range(0, indices.size(), 3):
		var a: int = indices[triangle_start]
		var b: int = indices[triangle_start + 1]
		var c: int = indices[triangle_start + 2]
		if _is_head_vertex(a, joints, weights, head_bone, neck_bone) and _is_head_vertex(b, joints, weights, head_bone, neck_bone) and _is_head_vertex(c, joints, weights, head_bone, neck_bone):
			head_indices.append(a)
			head_indices.append(b)
			head_indices.append(c)
	# Rebuild only the attributes required by this skinned, textured face. The
	# import's compressed auxiliary channels cannot be passed back to ArrayMesh.
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = source_arrays[Mesh.ARRAY_VERTEX]
	arrays[Mesh.ARRAY_NORMAL] = source_arrays[Mesh.ARRAY_NORMAL]
	arrays[Mesh.ARRAY_TEX_UV] = source_arrays[Mesh.ARRAY_TEX_UV]
	arrays[Mesh.ARRAY_COLOR] = source_arrays[Mesh.ARRAY_COLOR]
	arrays[Mesh.ARRAY_BONES] = joints
	arrays[Mesh.ARRAY_WEIGHTS] = weights
	arrays[Mesh.ARRAY_INDEX] = head_indices
	var head_mesh := ArrayMesh.new()
	head_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	head_mesh.surface_set_material(0, source_mesh.surface_get_material(0))
	return head_mesh


func _is_head_vertex(vertex_index: int, joints: PackedInt32Array, weights: PackedFloat32Array, head_bone: int, neck_bone: int) -> bool:
	var strongest_weight := -1.0
	var strongest_bone := -1
	for influence in 4:
		var weight: float = weights[vertex_index * 4 + influence]
		if weight > strongest_weight:
			strongest_weight = weight
			strongest_bone = joints[vertex_index * 4 + influence]
	return strongest_bone == head_bone or strongest_bone == neck_bone


func _create_role_prop() -> void:
	var skeleton = _model_root.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
	if skeleton == null:
		return
	var hand_attachment := BoneAttachment3D.new()
	hand_attachment.name = "RightHandProp"
	hand_attachment.bone_name = &"hand_r"
	skeleton.add_child(hand_attachment)
	# Keep blades and mace heads neutral. The board fill light is intentionally
	# cool for character readability; blue-tinted metal under that light looked
	# like a team-coloured placeholder weapon at close range.
	var steel := Color(0.67, 0.68, 0.72)
	var gold := Color(0.82, 0.62, 0.2)
	var wood := Color(0.28, 0.14, 0.055)
	var gem := side_color.lightened(0.22)
	match archetype:
		Types.PAWN:
			_add_hand_prop(hand_attachment, "PawnSwordGrip", _cylinder(0.055, 0.055, 0.18), Vector3(0, -0.18, 0), wood, 0.0)
			_add_hand_prop(hand_attachment, "PawnSwordGuard", _box(Vector3(0.34, 0.05, 0.08)), Vector3(0, -0.29, 0), gold, 0.7)
			_add_hand_prop(hand_attachment, "PawnSwordBlade", _cone(0.12, 0.018, 0.72), Vector3(0, -0.67, 0), steel, 0.86)
		Types.KNIGHT:
			_add_hand_prop(hand_attachment, "KnightLanceShaft", _cylinder(0.045, 0.045, 1.15), Vector3(0, -0.58, 0), wood, 0.0)
			_add_hand_prop(hand_attachment, "KnightLanceTip", _cone(0.12, 0.0, 0.3), Vector3(0, -1.3, 0), steel, 0.86)
			_add_hand_prop(hand_attachment, "KnightPennant", _box(Vector3(0.32, 0.2, 0.025)), Vector3(0.14, -0.82, 0.035), gem, 0.2)
		Types.BISHOP:
			_add_hand_prop(hand_attachment, "BishopStaff", _cylinder(0.06, 0.06, 0.96), Vector3(0, -0.45, 0), wood, 0.0)
			_add_hand_prop(hand_attachment, "BishopFocusOrb", _sphere(0.16, 0.3), Vector3(0, -0.98, 0), gem, 0.35)
			_add_hand_prop(hand_attachment, "BishopFocusCollar", _cylinder(0.12, 0.12, 0.07), Vector3(0, -0.82, 0), gold, 0.7)
		Types.ROOK:
			_add_hand_prop(hand_attachment, "RookMaceHandle", _cylinder(0.07, 0.07, 0.68), Vector3(0, -0.32, 0), wood, 0.0)
			_add_hand_prop(hand_attachment, "RookMaceHead", _sphere(0.22, 0.42), Vector3(0, -0.82, 0), steel, 0.82)
			_add_hand_prop(hand_attachment, "RookMaceSpike", _cone(0.08, 0.0, 0.18), Vector3(0, -1.1, 0), gold, 0.7)
		Types.QUEEN:
			_add_hand_prop(hand_attachment, "QueenSceptre", _cylinder(0.045, 0.055, 0.82), Vector3(0, -0.38, 0), gold, 0.72)
			_add_hand_prop(hand_attachment, "QueenCrownOrb", _sphere(0.16, 0.32), Vector3(0, -0.9, 0), gem, 0.35)
		Types.KING:
			_add_hand_prop(hand_attachment, "KingSwordGrip", _cylinder(0.06, 0.06, 0.2), Vector3(0, -0.16, 0), wood, 0.0)
			_add_hand_prop(hand_attachment, "KingSwordGuard", _box(Vector3(0.42, 0.06, 0.09)), Vector3(0, -0.29, 0), gold, 0.75)
			_add_hand_prop(hand_attachment, "KingBlade", _cone(0.14, 0.018, 0.9), Vector3(0, -0.76, 0), steel, 0.9)
			_add_hand_prop(hand_attachment, "KingPommel", _sphere(0.08, 0.16), Vector3(0, -0.04, 0), gem, 0.35)


func _add_hand_prop(parent: Node3D, prop_name: String, mesh: Mesh, prop_position: Vector3, color: Color, metallic := 0.45) -> void:
	var prop := MeshInstance3D.new()
	prop.name = prop_name
	prop.mesh = mesh
	prop.position = prop_position * ROLE_PROP_SCALE
	prop.scale = Vector3.ONE * ROLE_PROP_SCALE
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = 0.52 if metallic > 0.5 else 0.62
	prop.material_override = material
	parent.add_child(prop)


func _add_marker(marker_name: String, mesh: Mesh, marker_position: Vector3, color: Color, rotation := Vector3.ZERO) -> void:
	var marker := MeshInstance3D.new()
	marker.name = marker_name
	marker.mesh = mesh
	marker.position = marker_position
	marker.rotation = rotation
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.28
	material.roughness = 0.42
	marker.material_override = material
	_visual_accents.add_child(marker)


func _sphere(radius: float, height: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	return mesh


func _cone(bottom_radius: float, top_radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom_radius
	mesh.top_radius = top_radius
	mesh.height = height
	return mesh


func _box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


func _cylinder(top_radius: float, bottom_radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	return mesh
