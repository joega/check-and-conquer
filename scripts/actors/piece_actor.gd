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
const DAGGER_SCENE := preload("res://assets/weapons/quaternius/Dagger.fbx")
const DAGGER_2_SCENE := preload("res://assets/weapons/quaternius/Dagger_2.fbx")
const SPEAR_SCENE := preload("res://assets/weapons/quaternius/Spear.fbx")
const BOW_SCENE := preload("res://assets/weapons/quaternius/Bow_Golden.fbx")
const HAMMER_SCENE := preload("res://assets/weapons/quaternius/Hammer_Double.fbx")
const GOLDEN_SWORD_SCENE := preload("res://assets/weapons/quaternius/Sword_Golden.fbx")
const CLAYMORE_SCENE := preload("res://assets/weapons/quaternius/Claymore.fbx")
## Presentation scale only. The actor root stays in board metres so chess
## coordinates, capture destinations, and rebuild checks remain authoritative.
const CHARACTER_PRESENTATION_SCALE := 2.0
## Props live below the doubled imported-character root. Keep them deliberately
## compact so a close board inspection still shows the outfit and face rather
## than a primitive mesh filling the camera.
const WEAPON_DISPLAY_SCALE := 9.0
const CLIP_MAP := {
	&"idle.neutral": &"Idle",
	&"idle.watch_01": &"Idle_Rail",
	&"idle.talking_01": &"Idle_Talking",
	# Sword_Idle ends in a held pose in the supplied library, so it is not a
	# suitable living board idle. Keep this semantic alias on a looping watch.
	&"combat.idle.sword_01": &"Idle_Rail",
	&"combat.idle.spell_01": &"Spell_Simple_Idle",
	&"locomotion.walk.forward": &"Walk",
	&"attack.sword.slash_01": &"Sword_Attack",
	&"attack.sword.heavy_combo_01": &"Sword_Heavy_Combo",
	&"attack.sword.dash_01": &"Sword_Dash",
	&"stance.guard_01": &"Sword_Block",
	&"stance.challenge_01": &"Idle_Rail_Call",
	&"stance.fold_arms_01": &"Idle_FoldArms",
	&"attack.punch.jab_01": &"Punch_Jab",
	&"attack.push.guard_01": &"Push",
	&"attack.spell.shot_01": &"Spell_Simple_Shoot",
	&"celebration.dance_01": &"Dance",
	&"celebration.punch_cross_01": &"Punch_Cross",
	&"celebration.spell_cast_01": &"Spell_Simple_Shoot",
	&"celebration.push_01": &"Push",
	&"reaction.hit.generic_01": &"Hit_Chest",
	&"reaction.hit.head_01": &"Hit_Head",
	&"death.backward_01": &"Death01",
}
const CLIP_MAP_2 := {
	&"celebration.sword_combo_01": &"Sword_Regular_Combo",
	&"celebration.sword_heavy_01": &"Sword_Heavy_Combo",
	&"celebration.call_01": &"Idle_Rail_Call",
	&"celebration.salute_01": &"Yes",
	&"attack.melee.hook_01": &"Melee_Hook",
	&"attack.sword.regular_a_01": &"Sword_Regular_A",
	&"attack.sword.regular_b_01": &"Sword_Regular_B",
	&"attack.sword.regular_c_01": &"Sword_Regular_C",
	&"attack.sword.combo_01": &"Sword_Regular_Combo",
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
var _selection_tween: Tween
var _stance_seed := 0
var _stance_loop_state: StringName = &"idle.neutral"
var _stance_gesture_time_s := 0.0
var _ambient_motion_active := false
var _ambient_motion_tween: Tween
var uses_female_model := false
var outfit_id := ""
var hair_ids: Array[String] = []
var appearance_seed := 0


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
	start_battle_stance()


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


func capture_attack_state(fallback: StringName) -> StringName:
	# Each role prefers a fitting weapon motion while respecting any explicit
	# signature choreography. Similar units rotate through compatible clips so
	# their combat beats do not all read as one repeated gesture.
	var candidates: Array[StringName] = [fallback]
	match archetype:
		Types.PAWN:
			candidates = [&"attack.sword.regular_a_01", &"attack.sword.regular_b_01", &"attack.sword.regular_c_01", fallback]
		Types.KNIGHT:
			candidates = [&"attack.sword.dash_01", &"attack.punch.jab_01", fallback]
		Types.ROOK:
			candidates = [&"attack.sword.heavy_combo_01", &"attack.melee.hook_01", fallback]
		Types.KING:
			candidates = [&"attack.sword.combo_01", &"attack.sword.heavy_combo_01", fallback]
	for offset in candidates.size():
		var candidate := candidates[(_stance_seed + offset) % candidates.size()]
		if supports_state(candidate):
			return candidate
	return fallback


func combat_idle_state() -> StringName:
	return &"combat.idle.spell_01" if archetype in [Types.BISHOP, Types.QUEEN] else &"combat.idle.sword_01"


func start_battle_stance() -> void:
	_stance_seed = abs(int(round(global_position.x * 17.0 + global_position.z * 31.0))) + archetype * 13 + (7 if side < 0 else 0)
	# The supplied looping clips visibly snap at their seams. Hold each actor in
	# a clean neutral pose, then let BoardPresenter occasionally select one actor
	# for a small, isolated ambient movement.
	_stance_loop_state = &"idle.neutral"
	_restore_battle_pose()
	_stance_gesture_time_s = 0.0


func celebrate_victory(style_index: int) -> void:
	# Full-body, role-aware victory beats. Source clips are deliberately varied
	# so a nearby squad reads as a small battle party rather than synchronized
	# bouncing pieces. This is presentation-only and restores the regular stance.
	var gestures := _victory_gestures_for_archetype()
	var gesture := gestures[posmod(style_index + _stance_seed, gestures.size())]
	if supports_state(gesture):
		play_state(gesture)
		_stance_gesture_time_s = _victory_duration(gesture)


func _victory_gestures_for_archetype() -> Array[StringName]:
	match archetype:
		Types.PAWN:
			return [&"celebration.sword_combo_01", &"celebration.punch_cross_01", &"celebration.dance_01"]
		Types.KNIGHT:
			return [&"celebration.sword_heavy_01", &"celebration.dance_01", &"celebration.call_01"]
		Types.BISHOP:
			return [&"celebration.spell_cast_01", &"celebration.call_01", &"celebration.salute_01"]
		Types.ROOK:
			return [&"celebration.push_01", &"celebration.sword_heavy_01", &"celebration.call_01"]
		Types.QUEEN:
			return [&"celebration.spell_cast_01", &"celebration.sword_combo_01", &"celebration.dance_01"]
		_:
			return [&"celebration.sword_heavy_01", &"celebration.salute_01", &"celebration.call_01"]


func _victory_duration(gesture: StringName) -> float:
	# Dance is a looping source clip; let it play multiple beats before returning
	# to the regular stance. The rest are complete authored actions.
	if gesture == &"celebration.dance_01":
		return 2.4
	return maxf(state_duration(gesture), 1.0)


func battle_stance_state() -> StringName:
	return _stance_loop_state


func battle_stance_loops() -> bool:
	var player := _animation_player_2 if CLIP_MAP_2.has(_stance_loop_state) else _animation_player
	var clip: StringName = CLIP_MAP_2.get(_stance_loop_state, CLIP_MAP.get(_stance_loop_state, &"Idle"))
	var animation := player.get_animation(clip) if player != null else null
	return animation != null and animation.loop_mode != Animation.LOOP_NONE


func is_available_for_ambient_motion() -> bool:
	return visible and not _ambient_motion_active and _stance_gesture_time_s <= 0.0 and _last_played_state == _stance_loop_state


func play_ambient_motion(style_index: int) -> void:
	if not is_available_for_ambient_motion() or _model_root == null:
		return
	_ambient_motion_active = true
	var baseline_position := _model_root.position
	var baseline_rotation := _model_root.rotation
	# This needs to read from the normal board camera, not only in a close-up.
	# It is still a weight shift rather than a jump or a repeated exercise loop.
	var lean := -0.085 if posmod(_stance_seed + style_index, 2) == 0 else 0.085
	var turn := -0.075 if posmod(_stance_seed + style_index, 3) == 0 else 0.075
	_ambient_motion_tween = create_tween()
	_ambient_motion_tween.set_parallel(true)
	_ambient_motion_tween.tween_property(_model_root, "rotation:z", baseline_rotation.z + lean, 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_ambient_motion_tween.tween_property(_model_root, "rotation:y", baseline_rotation.y + turn, 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_ambient_motion_tween.tween_property(_model_root, "position:y", baseline_position.y + 0.045, 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_ambient_motion_tween.chain().set_parallel(true)
	_ambient_motion_tween.tween_property(_model_root, "rotation", baseline_rotation, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_ambient_motion_tween.tween_property(_model_root, "position", baseline_position, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_ambient_motion_tween.finished.connect(func(): _ambient_motion_active = false)


func _process(delta: float) -> void:
	if _stance_gesture_time_s > 0.0:
		_stance_gesture_time_s -= delta
		if _stance_gesture_time_s <= 0.0:
			_restore_battle_pose()


func _seek_stance_offset() -> void:
	var player := _animation_player_2 if CLIP_MAP_2.has(_stance_loop_state) else _animation_player
	var clip: StringName = CLIP_MAP_2.get(_stance_loop_state, CLIP_MAP.get(_stance_loop_state, &"Idle"))
	if player == null:
		return
	var animation := player.get_animation(clip)
	if animation != null and animation.length > 0.05:
		player.seek(fmod(float(_stance_seed) * 0.173, animation.length), true)


func _restore_battle_pose() -> void:
	if _ambient_motion_tween != null and _ambient_motion_tween.is_valid():
		_ambient_motion_tween.kill()
	_ambient_motion_active = false
	if _model_root != null:
		_model_root.position = Vector3.ZERO
		_model_root.rotation = Vector3.ZERO
	play_state(_stance_loop_state)
	_seek_stance_offset()
	# Pausing a clean sampled frame avoids the visible seam in the third-party
	# idle loop. Brief ambient movements supply life without a constant reset.
	set_animation_paused(true)


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


func set_selected(selected: bool) -> void:
	# Selection lives on the existing compact base ring, never above a character's
	# head. It stays readable at board scale without spoiling close inspections or
	# capture shots.
	var ring := _visual_accents.get_node_or_null("TeamRing") as MeshInstance3D
	if ring == null:
		return
	if _selection_tween != null and _selection_tween.is_valid():
		_selection_tween.kill()
	var material := ring.material_override as StandardMaterial3D
	if material != null:
		material.emission_enabled = selected
		material.emission = side_color.lerp(Color.WHITE, 0.32)
		material.emission_energy_multiplier = 1.8 if selected else 0.0
	if not selected:
		ring.scale = Vector3.ONE
		return
	ring.scale = Vector3.ONE
	_selection_tween = create_tween().set_loops()
	_selection_tween.tween_property(ring, "scale", Vector3.ONE * 1.45, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_selection_tween.tween_property(ring, "scale", Vector3.ONE * 1.08, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


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
	start_battle_stance()


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
	# A thin ring preserves side recognition while leaving the square and the
	# character's silhouette visible at the board camera distance.
	_add_marker("TeamRing", _team_ring(), Vector3(0, 0.018, 0), side_color)


func _create_piece_glyph() -> void:
	# A compact glyph on the base replaces the large floating primitive markers.
	# It is readable from the board, never obstructs a face, and stays below the
	# overhead capture camera's action framing.
	var glyph := Label3D.new()
	glyph.name = "PieceGlyph"
	glyph.text = _piece_glyph_text()
	glyph.position = Vector3(0, 0.041, 0)
	glyph.rotation_degrees = Vector3(-90, 0, 0)
	glyph.font_size = 58
	glyph.pixel_size = 0.0042
	glyph.outline_size = 5
	glyph.modulate = Color(1.0, 0.84, 0.4)
	_visual_accents.add_child(glyph)


func _piece_glyph_text() -> String:
	match archetype:
		Types.KNIGHT:
			return "♞"
		Types.BISHOP:
			return "♝"
		Types.ROOK:
			return "♜"
		Types.QUEEN:
			return "♛"
		Types.KING:
			return "♚"
	return "♟"


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
		if feature_name == &"Eyebrows":
			_tint_mesh(feature, _hair_color())
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
			_tint_mesh(hair, _hair_color())
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


func _hair_color() -> Color:
	# Square-derived identity keeps a character's look stable across any rebuild
	# while breaking up the old uniform white hair and brow appearance.
	var palette := [
		Color(0.09, 0.055, 0.035), Color(0.20, 0.10, 0.045),
		Color(0.38, 0.16, 0.055), Color(0.60, 0.35, 0.11),
		Color(0.72, 0.64, 0.42), Color(0.38, 0.40, 0.45),
	]
	return palette[posmod(appearance_seed + archetype * 3 + (2 if side < 0 else 0), palette.size())]


func _tint_mesh(mesh_node: MeshInstance3D, color: Color) -> void:
	if mesh_node.mesh == null:
		return
	for surface in mesh_node.mesh.get_surface_count():
		var source := mesh_node.get_active_material(surface) as StandardMaterial3D
		if source == null:
			continue
		var material := source.duplicate() as StandardMaterial3D
		material.albedo_color = color
		mesh_node.set_surface_override_material(surface, material)


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
	var skeleton := _model_root.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
	if skeleton == null:
		return
	match archetype:
		Types.PAWN:
			_add_weapon(skeleton, &"hand_r", "PawnRightDagger", DAGGER_SCENE, 0.08, Vector3(0, 0, 0.01), Vector3.ZERO)
			_add_weapon(skeleton, &"hand_l", "PawnLeftDagger", DAGGER_2_SCENE, 0.08, Vector3(0, 0, 0.01), Vector3.ZERO)
		Types.KNIGHT:
			_add_weapon(skeleton, &"hand_r", "KnightSpear", SPEAR_SCENE, 0.12, Vector3(0, 0, 0.015), Vector3.ZERO)
		Types.BISHOP:
			_add_weapon(skeleton, &"hand_l", "BishopGoldenBow", BOW_SCENE, 0.10, Vector3(0, 0, 0.015), Vector3.ZERO)
		Types.ROOK:
			_add_weapon(skeleton, &"hand_r", "RookWarHammer", HAMMER_SCENE, 0.10, Vector3(0, 0, 0.01), Vector3.ZERO)
		Types.QUEEN:
			_add_weapon(skeleton, &"hand_r", "QueenGoldenSword", GOLDEN_SWORD_SCENE, 0.10, Vector3(0, 0, 0.01), Vector3.ZERO)
		Types.KING:
			_add_weapon(skeleton, &"hand_r", "KingClaymore", CLAYMORE_SCENE, 0.11, Vector3(0, 0, 0.01), Vector3.ZERO)


func _add_weapon(skeleton: Skeleton3D, bone_name: StringName, weapon_name: String, weapon_scene: PackedScene, display_scale: float, grip_offset: Vector3, rotation_degrees_value: Vector3) -> void:
	var attachment := BoneAttachment3D.new()
	attachment.name = "%sAttachment" % weapon_name
	attachment.bone_name = bone_name
	skeleton.add_child(attachment)
	var weapon := weapon_scene.instantiate() as Node3D
	weapon.name = weapon_name
	weapon.position = grip_offset
	weapon.rotation_degrees = rotation_degrees_value
	weapon.scale = Vector3.ONE * display_scale
	attachment.add_child(weapon)


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


func _team_ring() -> TorusMesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.24
	mesh.outer_radius = 0.32
	mesh.rings = 6
	mesh.ring_segments = 20
	return mesh


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
