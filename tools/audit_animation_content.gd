extends SceneTree

const ACTOR_SCENE = preload("res://scenes/actors/PieceActor.tscn")
const Types = preload("res://scripts/chess/chess_types.gd")

var output_path := "artifacts/presentation_overhaul/p5/content-audit.json"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty(): output_path = args[0]
	call_deferred("_run")


func _metric_for(player: AnimationPlayer, skeleton: Skeleton3D, animation_name: StringName) -> Dictionary:
	if not player.has_animation(animation_name):
		return {"animation": str(animation_name), "available": false}
	var animation := player.get_animation(animation_name)
	var hand_l := skeleton.find_bone("hand_l")
	var hand_r := skeleton.find_bone("hand_r")
	var foot_l := skeleton.find_bone("foot_l")
	var foot_r := skeleton.find_bone("foot_r")
	var separations: Array[float] = []
	var left_positions: Array[Vector3] = []
	var right_positions: Array[Vector3] = []
	var left_feet: Array[float] = []
	var right_feet: Array[float] = []
	player.play(animation_name)
	for frame in range(0, maxi(1, ceili(animation.length * 30.0)) + 1):
		var time_s := minf(animation.length, float(frame) / 30.0)
		player.seek(time_s, true)
		var left := skeleton.get_bone_global_pose(hand_l).origin
		var right := skeleton.get_bone_global_pose(hand_r).origin
		left_positions.append(left)
		right_positions.append(right)
		separations.append(left.distance_to(right))
		left_feet.append(skeleton.get_bone_global_pose(foot_l).origin.y)
		right_feet.append(skeleton.get_bone_global_pose(foot_r).origin.y)
	player.stop()
	return {
		"animation": str(animation_name),
		"available": true,
		"length_s": animation.length,
		"track_count": animation.get_track_count(),
		"loop_mode": int(animation.loop_mode),
		"sample_rate_hz": 30,
		"hand_separation_m": {"min": separations.min(), "max": separations.max(), "range": separations.max() - separations.min()},
		"left_hand_span_m": _max_span(left_positions),
		"right_hand_span_m": _max_span(right_positions),
		"left_foot_vertical_span_m": left_feet.max() - left_feet.min(),
		"right_foot_vertical_span_m": right_feet.max() - right_feet.min(),
	}


func _max_span(points: Array[Vector3]) -> float:
	var span := 0.0
	for point in points:
		span = maxf(span, point.distance_to(points[0]))
	return span


func _run() -> void:
	var actor = ACTOR_SCENE.instantiate()
	actor.archetype = Types.BISHOP
	root.add_child(actor)
	await process_frame
	var player := actor.get_node("ModelRoot/AnimationPlayer") as AnimationPlayer
	var skeleton := actor.get_node("ModelRoot/Armature/Skeleton3D") as Skeleton3D
	var candidates: Array[Dictionary] = []
	for source_name in [
		&"ual1/Spell_Simple_Shoot", &"ual1/Pistol_Shoot",
		&"ual2/Melee_Hook", &"ual2/TreeChopping", &"ual2/Farm_Harvest", &"ual2/OverhandThrow",
	]:
		candidates.append(_metric_for(player, skeleton, source_name))
	var report := {
		"schema": 1,
		"godot_version": Engine.get_version_info().string,
		"rig": {"path": "Armature/Skeleton3D", "bone_count": skeleton.get_bone_count(), "root_motion_policy": "in-place; actor root controlled by code"},
		"semantic_fallbacks": {"attack.bow.draw_release_01": "ual1/Spell_Simple_Shoot + prop timeline", "attack.hammer.overhead_01": "ual2/Melee_Hook + prop timeline"},
		"candidates": candidates,
		"result": "blocked_on_content",
		"reason": "No installed clip supplies a bow draw/string release or a two-handed hammer grip with planted whole-body mechanics.",
	}
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	assert(file != null, "Could not write %s." % output_path)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	print("ANIMATION_CONTENT_AUDIT: ", output_path)
	actor.queue_free()
	await process_frame
	quit(0)
