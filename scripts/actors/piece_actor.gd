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
const ARROW_SCENE := preload("res://assets/weapons/quaternius/Arrow.fbx")
const BeveledBoxMesh = preload("res://scripts/presentation/beveled_box_mesh.gd")
## Presentation scale only. The actor root stays in board metres so chess
## coordinates, capture destinations, and rebuild checks remain authoritative.
const CHARACTER_PRESENTATION_SCALE := 2.0
## Props live below the doubled imported-character root. Keep them deliberately
## compact so a close board inspection still shows the outfit and face rather
## than a primitive mesh filling the camera.
const WEAPON_DISPLAY_SCALE := 9.0
## Source weapon axes differ substantially. These role-owned grip profiles keep
## the handle in the named palm instead of relying on a shared zero transform.
const WEAPON_GRIPS := {
	Types.PAWN: [
		[&"hand_r", "PawnRightDagger", DAGGER_SCENE, 0.075, Vector3(0.018, -0.015, 0.045), Vector3(82, 8, 92)],
		[&"hand_l", "PawnLeftDagger", DAGGER_2_SCENE, 0.075, Vector3(-0.018, -0.015, 0.045), Vector3(82, -8, -92)],
	],
	Types.KNIGHT: [[&"hand_r", "KnightSpear", SPEAR_SCENE, 0.105, Vector3(0.015, -0.02, 0.06), Vector3(88, 0, 2)]],
	Types.BISHOP: [[&"hand_l", "BishopGoldenBow", BOW_SCENE, 0.088, Vector3(-0.025, 0.005, 0.035), Vector3(88, 0, -88)]],
	Types.ROOK: [[&"hand_r", "RookWarHammer", HAMMER_SCENE, 0.094, Vector3(0.02, -0.03, 0.055), Vector3(88, 4, 92)]],
	Types.QUEEN: [[&"hand_r", "QueenGoldenSword", GOLDEN_SWORD_SCENE, 0.092, Vector3(0.018, -0.02, 0.052), Vector3(88, 0, 92)]],
	Types.KING: [[&"hand_r", "KingClaymore", CLAYMORE_SCENE, 0.098, Vector3(0.022, -0.025, 0.058), Vector3(88, 0, 92)]],
}
const CLIP_MAP := {
	&"idle.neutral": &"Idle",
	# UAL2 supplies the rail and advanced sword clips. Keep UAL1 aliases here
	# only when that player actually owns the imported animation.
	&"idle.talking_01": &"Idle_Talking",
	# Sword_Idle ends in a held pose in the supplied library, so it is not a
	# suitable living board idle. Keep this semantic alias on a looping watch.
	&"combat.idle.spell_01": &"Spell_Simple_Idle",
	&"locomotion.walk.forward": &"Walk",
	# Sprint is the supplied fast forward locomotion clip.  Keep the source name
	# behind a semantic request so presentation callers never depend on UAL.
	&"locomotion.run.forward": &"Sprint",
	# Ceremony-only seating uses UAL1's non-root-motion clips; root placement is
	# still controlled by GrandmasterCeremony like every other actor move.
	&"ceremony.seat.enter": &"Sitting_Enter",
	&"ceremony.seat.idle": &"Sitting_Idle",
	&"ceremony.seat.exit": &"Sitting_Exit",
	&"attack.sword.slash_01": &"Sword_Attack",
	&"attack.punch.jab_01": &"Punch_Jab",
	&"attack.push.guard_01": &"Push",
	&"attack.spell.shot_01": &"Spell_Simple_Shoot",
	# These are project-authored prop timelines layered over compatible body
	# motion. They deliberately remain semantic gameplay requests rather than
	# exposing a source-library filename as a choreography contract.
	&"attack.bow.draw_release_01": &"Spell_Simple_Shoot",
	# Victory reactions must read as acknowledgement from the board camera. Keep
	# combat clips out of this family: attacks belong to the capture itself.
	&"reaction.hit.generic_01": &"Hit_Chest",
	&"reaction.hit.head_01": &"Hit_Head",
	&"death.backward_01": &"Death01",
}
const CLIP_MAP_2 := {
	&"idle.watch_01": &"Idle_Rail",
	&"combat.idle.sword_01": &"Idle_Rail",
	&"stance.fold_arms_01": &"Idle_FoldArms",
	# This pose belongs to UAL2. Resolving it through UAL1 silently leaves the
	# previous clip (notably a king's entrance walk) running after arrival.
	&"stance.challenge_01": &"Idle_Rail_Call",
	&"celebration.call_01": &"Idle_Rail_Call",
	&"celebration.salute_01": &"Yes",
	&"attack.hammer.overhead_01": &"Melee_Hook",
	&"attack.melee.hook_01": &"Melee_Hook",
	&"attack.sword.heavy_combo_01": &"Sword_Heavy_Combo",
	&"attack.sword.dash_01": &"Sword_Dash",
	&"stance.guard_01": &"Sword_Block",
	&"recovery.capture_ready_01": &"Idle_Rail",
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
var _last_played_state: StringName = &"idle.neutral"
var _animation_paused := false
var _animation_speed_multiplier := 1.0
var _locomotion_speed_multiplier := 1.0
var _last_transition_duration_s := 0.0
var _selection_tween: Tween
var _stance_seed := 0
var _stance_loop_state: StringName = &"idle.neutral"
var _stance_gesture_time_s := 0.0
var _ambient_motion_active := false
var _ambient_motion_tween: Tween
var _role_action_tween: Tween
var _recovery_tween: Tween
var _movement_tween: Tween
var _turn_tween: Tween
var _motion_generation := 0
var _moving := false
var _nocked_arrow: Node3D
var uses_female_model := false
var outfit_id := ""
var hair_ids: Array[String] = []
var appearance_seed := 0
var silhouette_profile := ""
var role_accessory_ids: Array[String] = []
var walk_stride_m := 2.2
var last_travel_distance_m := 0.0
var last_travel_duration_s := 0.0
var last_travel_stride_cycles := 0.0


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
	_configure_outfit_parts()
	_apply_team_material_variant(_model_root)
	_create_head()
	_create_hair()
	_create_role_accessories()
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
			silhouette_profile = "low_dual_blade_infantry"
			return MALE_PEASANT_SCENE
		Types.KNIGHT:
			outfit_id = "female_ranger"
			silhouette_profile = "tall_spear_ranger"
			return FEMALE_RANGER_SCENE
		Types.BISHOP:
			outfit_id = "female_peasant"
			silhouette_profile = "long_hair_bow_caster"
			return FEMALE_PEASANT_SCENE
		Types.ROOK:
			outfit_id = "male_ranger"
			silhouette_profile = "broad_hammer_guard"
			return MALE_RANGER_SCENE
		Types.QUEEN:
			outfit_id = "female_ranger"
			silhouette_profile = "golden_blade_commander"
			return FEMALE_RANGER_SCENE
		_:
			outfit_id = "male_ranger"
			silhouette_profile = "royal_claymore_guard"
			return MALE_RANGER_SCENE


func _attach_compatible_animation_player() -> void:
	_animation_player = AnimationPlayer.new()
	_animation_player.name = "AnimationPlayer"
	_model_root.add_child(_animation_player)
	_add_namespaced_library(ANIMATION_LIBRARY_SCENE, &"ual1")
	_add_namespaced_library(ANIMATION_LIBRARY_2_SCENE, &"ual2")
	# The source neutral idle has a visible end-to-start reset. Ping-pong keeps
	# the breathing/weight motion continuous without changing the licensed clip.
	var idle := _animation_player.get_animation(&"ual1/Idle")
	if idle != null:
		idle.loop_mode = Animation.LOOP_PINGPONG


func _add_namespaced_library(source_scene: PackedScene, library_namespace: StringName) -> void:
	var animation_source := source_scene.instantiate()
	var source_player := animation_source.get_node("AnimationPlayer") as AnimationPlayer
	var source_library := source_player.get_animation_library(&"")
	assert(source_library != null, "Imported animation scene must expose its default library.")
	_animation_player.add_animation_library(library_namespace, source_library.duplicate(true) as AnimationLibrary)
	animation_source.free()


func play_clip(clip: StringName) -> void:
	if _animation_player == null:
		return
	var animation_name := clip
	if not _animation_player.has_animation(animation_name):
		animation_name = StringName("ual1/%s" % clip)
	if not _animation_player.has_animation(animation_name):
		animation_name = StringName("ual2/%s" % clip)
	if _animation_player.has_animation(animation_name):
		_animation_player.play(animation_name, _blend_duration(_last_played_state, &""))


func play_state(semantic_id: StringName) -> void:
	_cancel_role_action(semantic_id != &"attack.bow.draw_release_01")
	if semantic_id != &"recovery.capture_ready_01":
		_cancel_recovery()
	_animation_paused = false
	var animation_name := _animation_for_state(semantic_id)
	if _animation_player == null or animation_name.is_empty() or not _animation_player.has_animation(animation_name):
		# A semantic request must never leave a previous locomotion or attack clip
		# driving the model. Fall back to the known neutral state and report that
		# state truthfully to callers.
		semantic_id = &"idle.neutral"
		animation_name = _animation_for_state(semantic_id)
	_last_transition_duration_s = _blend_duration(_last_played_state, semantic_id)
	# Blend time is expressed in wall-clock seconds by AnimationPlayer. Scale it
	# with the active presentation rate so accelerated audits preserve the same
	# normalized transition and cannot sample the preceding pose at contact.
	var playback_blend_s := _last_transition_duration_s / maxf(_animation_speed_multiplier, 0.1)
	_animation_player.play(animation_name, playback_blend_s)
	_apply_animation_speed()
	_last_played_state = semantic_id
	if semantic_id in [&"attack.bow.draw_release_01", &"attack.hammer.overhead_01"]:
		_play_role_authored_action(semantic_id)


func supports_state(semantic_id: StringName) -> bool:
	var animation_name := _animation_for_state(semantic_id)
	return _animation_player != null and not animation_name.is_empty() and _animation_player.has_animation(animation_name)


func _player_for_state(semantic_id: StringName) -> AnimationPlayer:
	return _animation_player


func _clip_for_state(semantic_id: StringName) -> StringName:
	if CLIP_MAP_2.has(semantic_id):
		return CLIP_MAP_2[semantic_id]
	return CLIP_MAP.get(semantic_id, &"")


func _animation_for_state(semantic_id: StringName) -> StringName:
	var clip := _clip_for_state(semantic_id)
	if clip.is_empty():
		return &""
	return StringName("%s/%s" % ["ual2" if CLIP_MAP_2.has(semantic_id) else "ual1", clip])


func _blend_duration(from_state: StringName, to_state: StringName) -> float:
	if _animation_player == null or _animation_player.current_animation.is_empty():
		return 0.0
	if to_state.begins_with("death.") or to_state.begins_with("reaction.hit."):
		return 0.055
	if from_state.begins_with("locomotion.") and to_state.begins_with("attack."):
		return 0.10
	if from_state.begins_with("locomotion.") or to_state.begins_with("locomotion."):
		return 0.14
	return 0.14


func active_animation_name() -> StringName:
	return _animation_player.current_animation if _animation_player != null else &""


func active_source_clip() -> StringName:
	var value := str(active_animation_name())
	return StringName(value.get_file())


func sample_active_animation_at(time_s: float) -> void:
	if _animation_player == null or _animation_player.current_animation.is_empty():
		return
	var animation_name := _animation_player.current_animation
	# End any residual crossfade before evaluating the authored contact frame.
	# This makes the sampled pose independent of render-frame cadence at 0.25x,
	# 1x, or accelerated test playback.
	_animation_player.play(animation_name, 0.0)
	_apply_animation_speed()
	_animation_player.seek(maxf(time_s, 0.0), true)
	var skeleton := get_node_or_null("ModelRoot/Armature/Skeleton3D") as Skeleton3D
	if skeleton != null:
		skeleton.force_update_all_bone_transforms()
		skeleton.force_update_transform()
		for attachment in skeleton.get_children():
			if attachment is Node3D:
				(attachment as Node3D).force_update_transform()


func last_transition_duration() -> float:
	return _last_transition_duration_s


func animation_mixer_count() -> int:
	return 1 if _animation_player != null else 0


func primary_attack_state() -> StringName:
	match archetype:
		Types.KNIGHT:
			return &"attack.punch.jab_01"
		Types.BISHOP:
			return &"attack.bow.draw_release_01"
		Types.QUEEN:
			return &"attack.spell.shot_01"
		Types.ROOK:
			return &"attack.hammer.overhead_01"
		_:
			return &"attack.sword.slash_01"


func capture_attack_state(fallback: StringName) -> StringName:
	# Choreography contact times belong to its authored clip. Only substitute a
	# compatible motion when the actor cannot play that clip.
	if supports_state(fallback):
		return fallback
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


func release_authored_projectile() -> void:
	# The visible nocked arrow belongs to the draw timeline. BattleDirector owns
	# the travelling projectile and removes this preparation prop at the exact
	# release beat, keeping the two representations from overlapping.
	if _nocked_arrow != null and is_instance_valid(_nocked_arrow):
		_nocked_arrow.queue_free()
	_nocked_arrow = null


func recover_after_capture() -> void:
	# Settlement remains on the authoritative board square. This is only a short
	# local exhale/brace after the decisive beat, so it cannot introduce root
	# drift or delay the logical turn handoff.
	_cancel_role_action(true)
	_cancel_recovery()
	play_state(&"recovery.capture_ready_01")
	if _model_root == null:
		return
	var rest_position := _model_root.position
	var rest_rotation := _model_root.rotation
	_recovery_tween = create_tween()
	_recovery_tween.set_speed_scale(_animation_speed_multiplier)
	_recovery_tween.set_parallel(true)
	_recovery_tween.tween_property(_model_root, "position:y", rest_position.y - 0.045, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_recovery_tween.tween_property(_model_root, "rotation:x", rest_rotation.x + 0.055, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_recovery_tween.chain().set_parallel(true)
	_recovery_tween.tween_property(_model_root, "position", rest_position, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_recovery_tween.tween_property(_model_root, "rotation", rest_rotation, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_recovery_tween.tween_callback(_restore_battle_pose)


func _play_role_authored_action(semantic_id: StringName) -> void:
	var weapon := _role_weapon_for_action(semantic_id)
	if weapon == null:
		return
	var rest_position := weapon.position
	var rest_rotation := weapon.rotation
	_role_action_tween = create_tween()
	_role_action_tween.set_speed_scale(_animation_speed_multiplier)
	if semantic_id == &"attack.bow.draw_release_01":
		_create_nocked_arrow(weapon)
		_role_action_tween.set_parallel(true)
		_role_action_tween.tween_property(weapon, "position", rest_position + Vector3(-0.045, 0.025, -0.045), 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_role_action_tween.tween_property(weapon, "rotation", rest_rotation + Vector3(0.12, -0.18, 0.10), 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_role_action_tween.chain().set_parallel(true)
		_role_action_tween.tween_property(weapon, "position", rest_position + Vector3(0.03, -0.02, 0.065), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_role_action_tween.tween_property(weapon, "rotation", rest_rotation + Vector3(-0.08, 0.22, -0.12), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_role_action_tween.chain().set_parallel(true)
		_role_action_tween.tween_property(weapon, "position", rest_position, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_role_action_tween.tween_property(weapon, "rotation", rest_rotation, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		# The loaded hammer's handle is held in the palm; the authored timeline
		# gives it a readable lift, overhead commitment, and recovery at board
		# scale instead of borrowing a push gesture.
		_role_action_tween.set_parallel(true)
		_role_action_tween.tween_property(weapon, "position", rest_position + Vector3(-0.03, 0.12, -0.08), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_role_action_tween.tween_property(weapon, "rotation", rest_rotation + Vector3(-0.95, 0.12, 0.18), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_role_action_tween.chain().set_parallel(true)
		_role_action_tween.tween_property(weapon, "position", rest_position + Vector3(0.08, -0.10, 0.18), 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_role_action_tween.tween_property(weapon, "rotation", rest_rotation + Vector3(0.72, -0.18, -0.22), 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_role_action_tween.chain().set_parallel(true)
		_role_action_tween.tween_property(weapon, "position", rest_position, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_role_action_tween.tween_property(weapon, "rotation", rest_rotation, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _role_weapon_for_action(semantic_id: StringName) -> Node3D:
	var weapon_name := "BishopGoldenBow" if semantic_id == &"attack.bow.draw_release_01" else "RookWarHammer"
	return get_node_or_null("ModelRoot/Armature/Skeleton3D/%sAttachment/%s" % [weapon_name, weapon_name]) as Node3D


func weapon_contact_distance_to(world_point: Vector3) -> float:
	var skeleton := get_node_or_null("ModelRoot/Armature/Skeleton3D")
	if skeleton == null:
		return INF
	var nearest := INF
	for attachment in skeleton.get_children():
		if not str(attachment.name).ends_with("Attachment"):
			continue
		if attachment is MeshInstance3D:
			nearest = minf(nearest, _mesh_distance_to_world_point(attachment as MeshInstance3D, world_point))
		for candidate in attachment.find_children("*", "MeshInstance3D", true, false):
			nearest = minf(nearest, _mesh_distance_to_world_point(candidate as MeshInstance3D, world_point))
	return nearest


func set_equipped_weapons_visible(weapons_visible: bool) -> void:
	for grip in WEAPON_GRIPS.get(archetype, []):
		var weapon := find_child(String(grip[1]), true, false) as Node3D
		if weapon != null:
			weapon.visible = weapons_visible


func equipped_weapons_visible() -> bool:
	for grip in WEAPON_GRIPS.get(archetype, []):
		var weapon := find_child(String(grip[1]), true, false) as Node3D
		if weapon != null and weapon.visible:
			return true
	return false


func _mesh_distance_to_world_point(mesh: MeshInstance3D, world_point: Vector3) -> float:
	if mesh.mesh == null:
		return INF
	var bounds := mesh.get_aabb()
	var local_point := mesh.to_local(world_point)
	var closest := Vector3(
		clampf(local_point.x, bounds.position.x, bounds.end.x),
		clampf(local_point.y, bounds.position.y, bounds.end.y),
		clampf(local_point.z, bounds.position.z, bounds.end.z)
	)
	return mesh.to_global(closest).distance_to(world_point)


func _create_nocked_arrow(bow: Node3D) -> void:
	release_authored_projectile()
	_nocked_arrow = ARROW_SCENE.instantiate() as Node3D
	_nocked_arrow.name = "NockedArrow"
	_nocked_arrow.scale = Vector3.ONE * 0.34
	# This is intentionally a short, visible preparation prop; its world-space
	# successor is spawned by BattleDirector at release.
	_nocked_arrow.position = Vector3(0.0, 0.02, -0.22)
	_nocked_arrow.rotation_degrees = Vector3(0.0, 90.0, 0.0)
	bow.add_child(_nocked_arrow)


func _cancel_role_action(remove_arrow: bool) -> void:
	if _role_action_tween != null and _role_action_tween.is_valid():
		_role_action_tween.kill()
	_role_action_tween = null
	if remove_arrow:
		release_authored_projectile()


func _cancel_recovery() -> void:
	if _recovery_tween != null and _recovery_tween.is_valid():
		_recovery_tween.kill()
	_recovery_tween = null


func combat_idle_state() -> StringName:
	# The UAL1 Rail idle is not available on every imported outfit skeleton.
	# Neutral idle is present for every role and avoids a preview/control state
	# that can silently fail for melee pieces.
	return &"combat.idle.spell_01" if archetype in [Types.BISHOP, Types.QUEEN] else &"idle.neutral"


func start_battle_stance() -> void:
	_cancel_role_action(true)
	_cancel_recovery()
	_stance_seed = abs(int(round(global_position.x * 17.0 + global_position.z * 31.0))) + archetype * 13 + (7 if side < 0 else 0)
	# The duplicated neutral clip uses ping-pong looping, avoiding its source
	# end-to-start reset while preserving deterministic phase staggering.
	_stance_loop_state = &"idle.neutral"
	_restore_battle_pose()
	_stance_gesture_time_s = 0.0


func celebrate_victory(style_index: int) -> void:
	# A teammate acknowledges the capture with a brief, non-combat gesture. The
	# actual attacker remains in its settled battle stance; its attack already
	# supplies the decisive action beat.
	var gestures := _victory_gestures_for_archetype()
	var gesture := gestures[posmod(style_index + _stance_seed, gestures.size())]
	if supports_state(gesture):
		play_state(gesture)
		_stance_gesture_time_s = _victory_duration(gesture)


func _victory_gestures_for_archetype() -> Array[StringName]:
	# UAL's call and affirmative acknowledgement map well to a cheer/raised-hand
	# and nod/thumbs-up style beat. Both are deliberately short and contain no
	# weapon swing, projectile, or lunge.
	return [&"celebration.call_01", &"celebration.salute_01"]


func _victory_duration(gesture: StringName) -> float:
	return minf(maxf(state_duration(gesture), 0.8), 1.35)


func battle_stance_state() -> StringName:
	return _stance_loop_state


func battle_stance_loops() -> bool:
	var animation_name := _animation_for_state(_stance_loop_state)
	var animation := _animation_player.get_animation(animation_name) if _animation_player != null else null
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
	var lean := -0.11 if posmod(_stance_seed + style_index, 2) == 0 else 0.11
	var turn := -0.10 if posmod(_stance_seed + style_index, 3) == 0 else 0.10
	_ambient_motion_tween = create_tween()
	_ambient_motion_tween.set_parallel(true)
	_ambient_motion_tween.tween_property(_model_root, "rotation:z", baseline_rotation.z + lean, 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_ambient_motion_tween.tween_property(_model_root, "rotation:y", baseline_rotation.y + turn, 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_ambient_motion_tween.tween_property(_model_root, "position:y", baseline_position.y + 0.075, 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_ambient_motion_tween.chain().set_parallel(true)
	_ambient_motion_tween.tween_property(_model_root, "rotation", baseline_rotation, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_ambient_motion_tween.tween_property(_model_root, "position", baseline_position, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_ambient_motion_tween.finished.connect(func():
		_ambient_motion_active = false
		_ambient_motion_tween = null
	, CONNECT_ONE_SHOT)
	_ambient_motion_tween.set_speed_scale(_animation_speed_multiplier)


func _process(delta: float) -> void:
	if _stance_gesture_time_s > 0.0:
		_stance_gesture_time_s -= delta
		if _stance_gesture_time_s <= 0.0:
			_restore_battle_pose()


func _seek_stance_offset() -> void:
	var animation_name := _animation_for_state(_stance_loop_state)
	if _animation_player == null:
		return
	var animation := _animation_player.get_animation(animation_name)
	if animation != null and animation.length > 0.05:
		_animation_player.seek(fmod(float(_stance_seed) * 0.173, animation.length), true)


func _restore_battle_pose() -> void:
	if _ambient_motion_tween != null and _ambient_motion_tween.is_valid():
		_ambient_motion_tween.kill()
	_ambient_motion_active = false
	if _model_root != null:
		_model_root.position = Vector3.ZERO
		_model_root.rotation = Vector3.ZERO
	play_state(_stance_loop_state)
	_seek_stance_offset()
	set_animation_paused(false)


func state_duration(semantic_id: StringName) -> float:
	if semantic_id == &"attack.bow.draw_release_01":
		return 0.52
	if semantic_id == &"attack.hammer.overhead_01":
		return 0.60
	if semantic_id == &"recovery.capture_ready_01":
		return 0.36
	var animation_name := _animation_for_state(semantic_id)
	if _animation_player == null or animation_name.is_empty():
		return 0.0
	var animation := _animation_player.get_animation(animation_name)
	return animation.length if animation != null else 0.0


func animation_playback_position() -> float:
	if _animation_player == null:
		return 0.0
	# Non-looping players clear current_animation when they complete. At that
	# point the full known semantic duration is the useful completion position.
	if _animation_player.current_animation.is_empty():
		return state_duration(_last_played_state)
	return _animation_player.current_animation_position


func current_semantic_state() -> StringName:
	return _last_played_state


func set_animation_speed(multiplier: float) -> void:
	_animation_speed_multiplier = maxf(multiplier, 0.1)
	_apply_animation_speed()
	for tween in [_role_action_tween, _recovery_tween, _ambient_motion_tween]:
		if tween != null and tween.is_valid():
			tween.set_speed_scale(_animation_speed_multiplier)


func _apply_animation_speed() -> void:
	if _animation_player != null:
		_animation_player.speed_scale = _animation_speed_multiplier * _locomotion_speed_multiplier


func animation_speed_multiplier() -> float:
	return _animation_speed_multiplier


func set_animation_paused(paused: bool) -> void:
	_animation_paused = paused
	if _animation_player == null:
		return
	if paused:
		_animation_player.pause()
	elif not _animation_player.current_animation.is_empty():
		_animation_player.play()
	for tween in [_movement_tween, _turn_tween, _role_action_tween, _recovery_tween, _ambient_motion_tween]:
		if tween != null and tween.is_valid():
			if paused:
				tween.pause()
			else:
				tween.play()


func is_animation_paused() -> bool:
	return _animation_paused


func move_to_world_position(target: Vector3, duration_s: float) -> Tween:
	_cancel_movement()
	_cancel_ambient_motion()
	_motion_generation += 1
	var generation := _motion_generation
	var start := global_position
	last_travel_distance_m = start.distance_to(target)
	last_travel_duration_s = maxf(duration_s, 0.001)
	last_travel_stride_cycles = last_travel_distance_m / maxf(walk_stride_m, 0.01)
	var walk_duration := maxf(state_duration(&"locomotion.walk.forward"), 0.01)
	# The caller's playback speed may already be represented by the requested
	# root duration. Divide it back out here so stride cadence follows actual
	# distance over actual elapsed time exactly once.
	_locomotion_speed_multiplier = maxf(
		last_travel_stride_cycles * walk_duration / last_travel_duration_s / _animation_speed_multiplier,
		0.1
	)
	play_state(&"locomotion.walk.forward")
	_apply_animation_speed()
	_moving = true
	_movement_tween = create_tween()
	var accel_s := minf(0.16, last_travel_duration_s * 0.22)
	var decel_s := accel_s
	var steady_s := maxf(last_travel_duration_s - accel_s - decel_s, 0.0)
	var denom := maxf(steady_s + accel_s, 0.001)
	var accel_fraction := (0.5 * accel_s) / denom
	var decel_fraction := accel_fraction
	var direction := (target - start)
	_movement_tween.tween_property(self, "global_position", start + direction * accel_fraction, accel_s).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if steady_s > 0.0:
		_movement_tween.tween_property(self, "global_position", start + direction * (1.0 - decel_fraction), steady_s).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	_movement_tween.tween_property(self, "global_position", target, decel_s).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_movement_tween.finished.connect(func():
		if generation != _motion_generation:
			return
		global_position = target
		_moving = false
		_movement_tween = null
		_locomotion_speed_multiplier = 1.0
		_apply_animation_speed()
	, CONNECT_ONE_SHOT)
	if _animation_paused:
		_movement_tween.pause()
	return _movement_tween


func travel_duration_for_distance(distance_m: float, speed_mps := 8.0) -> float:
	return clampf(distance_m / maxf(speed_mps, 0.1) + 0.18, 0.50, 4.0)


func is_presentation_moving() -> bool:
	return _moving


func turn_toward_world_position(target: Vector3, duration_s := -1.0) -> Tween:
	_cancel_turn()
	_cancel_ambient_motion()
	var flat_direction := target - global_position
	flat_direction.y = 0.0
	_turn_tween = create_tween()
	if flat_direction.length_squared() < 0.000001:
		_turn_tween.tween_interval(0.001)
		return _turn_tween
	var desired_yaw := atan2(flat_direction.x, flat_direction.z)
	var shortest_delta := wrapf(desired_yaw - rotation.y, -PI, PI)
	var actual_duration := turn_duration_toward(target) if duration_s < 0.0 else maxf(duration_s, 0.001)
	var generation := _motion_generation
	_turn_tween.tween_property(self, "rotation:y", rotation.y + shortest_delta, actual_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_turn_tween.finished.connect(func():
		if generation == _motion_generation:
			rotation.y = wrapf(rotation.y, -PI, PI)
			_turn_tween = null
	, CONNECT_ONE_SHOT)
	if _animation_paused:
		_turn_tween.pause()
	return _turn_tween


func turn_duration_toward(target: Vector3) -> float:
	var flat_direction := target - global_position
	flat_direction.y = 0.0
	if flat_direction.length_squared() < 0.000001:
		return 0.001
	var desired_yaw := atan2(flat_direction.x, flat_direction.z)
	var shortest_delta := wrapf(desired_yaw - rotation.y, -PI, PI)
	return clampf(absf(shortest_delta) / 7.5, 0.08, 0.32)


func is_presentation_turning() -> bool:
	return _turn_tween != null and _turn_tween.is_valid() and _turn_tween.is_running()


func face_world_position(target: Vector3) -> void:
	_cancel_turn()
	var flat_target := target
	flat_target.y = global_position.y
	if not flat_target.is_equal_approx(global_position):
		look_at(flat_target, Vector3.UP, true)


func restore_board_facing() -> void:
	# Presentation may turn an actor toward a movement target or opponent. Once
	# it settles on its authoritative square, restore the side's board-facing
	# orientation so captures never leave the survivor turned around.
	_cancel_turn()
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
	cancel_presentation_motion()
	global_transform = _home_transform
	visible = true
	if _animation_player != null:
		_animation_player.stop()
	_animation_paused = false
	start_battle_stance()


func cancel_presentation_motion() -> void:
	_motion_generation += 1
	_cancel_movement()
	_cancel_turn()
	_cancel_role_action(true)
	_cancel_recovery()
	_cancel_ambient_motion()
	_locomotion_speed_multiplier = 1.0
	_apply_animation_speed()
	if _model_root != null:
		_model_root.position = Vector3.ZERO
		_model_root.rotation = Vector3.ZERO


func _cancel_movement() -> void:
	if _movement_tween != null and _movement_tween.is_valid():
		_movement_tween.kill()
	_movement_tween = null
	_moving = false
	_locomotion_speed_multiplier = 1.0
	_apply_animation_speed()


func _cancel_turn() -> void:
	if _turn_tween != null and _turn_tween.is_valid():
		_turn_tween.kill()
	_turn_tween = null


func _cancel_ambient_motion() -> void:
	if _ambient_motion_tween != null and _ambient_motion_tween.is_valid():
		_ambient_motion_tween.kill()
	_ambient_motion_tween = null
	_ambient_motion_active = false
	if _model_root != null:
		_model_root.position = Vector3.ZERO
		_model_root.rotation = Vector3.ZERO


func _exit_tree() -> void:
	cancel_presentation_motion()


func _apply_team_material_variant(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh != null:
			for surface in mesh_node.mesh.get_surface_count():
				var source_material := mesh_node.get_active_material(surface) as StandardMaterial3D
				if source_material == null:
					continue
				var team_material := source_material.duplicate() as StandardMaterial3D
				# Keep side color on small garment cues. The ranger belt is a broad
				# torso band, so a strong tint reads as a floating blue/red stripe.
				var detail_name := String(mesh_node.name).to_lower()
				var tint_weight := 0.08
				if "hood" in detail_name or "pauldron" in detail_name:
					tint_weight = 0.28
				elif "belt" in detail_name:
					tint_weight = 0.10
				team_material.albedo_color = source_material.albedo_color.lerp(side_color, tint_weight)
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


func _configure_outfit_parts() -> void:
	# Ranger hoods made knight/queen and rook/king read as duplicate pairs. Keep
	# those heads open; the bishop receives the same-rig hood as its role cue.
	for hood_name in ["Female_Ranger_Head_Hood", "Male_Ranger_Head_Hood"]:
		var hood := _model_root.find_child(hood_name, true, false) as GeometryInstance3D
		if hood != null:
			hood.visible = false


func _create_role_accessories() -> void:
	var skeleton := _model_root.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
	if skeleton == null:
		return
	match archetype:
		Types.KNIGHT:
			var crest := PrismMesh.new()
			crest.size = Vector3(0.055, 0.20, 0.14)
			_add_bone_accessory(skeleton, &"Head", "KnightHelmCrest", crest, Vector3(0.0, 0.14, 0.01), Vector3.ZERO, _team_cloth_material())
		Types.BISHOP:
			_transfer_bishop_hood(skeleton)
			var mantle := TorusMesh.new()
			mantle.inner_radius = 0.105
			mantle.outer_radius = 0.16
			mantle.rings = 8
			mantle.ring_segments = 18
			_add_bone_accessory(skeleton, &"spine_03", "BishopMantleCollar", mantle, Vector3(0.0, 0.02, 0.0), Vector3.ZERO, _team_cloth_material())
		Types.ROOK:
			var shoulders := BeveledBoxMesh.create(Vector3(0.46, 0.075, 0.17), 0.025)
			_add_bone_accessory(skeleton, &"spine_03", "RookShoulderPlate", shoulders, Vector3(0.0, -0.035, 0.0), Vector3.ZERO, _aged_bronze_material())
			for side_x in [-1.0, 1.0]:
				var guard := SphereMesh.new()
				guard.radius = 0.085
				guard.height = 0.105
				_add_bone_accessory(skeleton, &"spine_03", "RookPauldron%s" % ("L" if side_x < 0 else "R"), guard, Vector3(side_x * 0.245, -0.025, 0.0), Vector3.ZERO, _aged_bronze_material())
		Types.QUEEN:
			_add_crown(skeleton, "QueenDiadem", 3, 0.115, 0.21)
		Types.KING:
			_add_crown(skeleton, "KingCrown", 5, 0.13, 0.13)


func _transfer_bishop_hood(target_skeleton: Skeleton3D) -> void:
	var source_root := FEMALE_RANGER_SCENE.instantiate() as Node3D
	var source := source_root.get_node_or_null("Armature/Skeleton3D/Female_Ranger_Head_Hood") as MeshInstance3D
	if source != null:
		var hood := source.duplicate() as MeshInstance3D
		hood.name = "BishopRangerHood"
		hood.skeleton = NodePath("..")
		target_skeleton.add_child(hood)
		_apply_team_material_variant(hood)
		role_accessory_ids.append(hood.name)
	source_root.free()


func _add_crown(skeleton: Skeleton3D, prefix: String, point_count: int, radius: float, height: float) -> void:
	var band := CylinderMesh.new()
	band.top_radius = radius
	band.bottom_radius = radius * 1.05
	band.height = 0.055
	band.radial_segments = 16
	_add_bone_accessory(skeleton, &"Head", "%sBand" % prefix, band, Vector3(0.0, height, 0.0), Vector3.ZERO, _aged_bronze_material())
	for point_index in point_count:
		var angle := TAU * float(point_index) / float(point_count)
		var point := CylinderMesh.new()
		point.top_radius = 0.0
		point.bottom_radius = 0.030 if point_count == 3 else 0.036
		point.height = 0.105 if point_count == 3 else 0.14
		point.radial_segments = 6
		var offset := Vector3(cos(angle) * radius * 0.72, height + (0.075 if point_count == 3 else 0.095), sin(angle) * radius * 0.72)
		_add_bone_accessory(skeleton, &"Head", "%sPoint%02d" % [prefix, point_index], point, offset, Vector3.ZERO, _aged_bronze_material())


func _add_bone_accessory(skeleton: Skeleton3D, bone_name: StringName, accessory_name: String, mesh: Mesh, local_position: Vector3, local_rotation: Vector3, material: StandardMaterial3D) -> void:
	var attachment := BoneAttachment3D.new()
	attachment.name = "%sAttachment" % accessory_name
	attachment.bone_name = bone_name
	skeleton.add_child(attachment)
	var accessory := MeshInstance3D.new()
	accessory.name = accessory_name
	accessory.mesh = mesh
	accessory.position = local_position
	accessory.rotation = local_rotation
	accessory.material_override = material
	attachment.add_child(accessory)
	role_accessory_ids.append(accessory_name)


func _aged_bronze_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("8a6537")
	material.metallic = 0.58
	material.roughness = 0.46
	return material


func _team_cloth_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("4b4a47").lerp(side_color, 0.42)
	material.roughness = 0.88
	return material


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
			# Hair_Long's heavy front lock covers both eyes in several idle and
			# ceremony poses. Buns keeps the face clear beneath the raised diadem.
			return [HAIR_BUNS_SCENE]
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
	for grip: Array in WEAPON_GRIPS.get(archetype, []):
		_add_weapon(skeleton, grip[0], grip[1], grip[2], grip[3], grip[4], grip[5])


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
