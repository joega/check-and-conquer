extends SceneTree

const ArenaAudioDirector = preload("res://scripts/presentation/arena_audio_director.gd")
const ArenaCatalog = preload("res://scripts/presentation/arena_catalog.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var audio := ArenaAudioDirector.new()
	root.add_child(audio)
	await process_frame
	for arena_id in ArenaCatalog.ids():
		audio.set_arena(arena_id)
		var music := audio.get_node("ArenaMusic") as AudioStreamPlayer
		assert(audio.active_arena_id == arena_id)
		assert(music.stream is AudioStreamWAV and (music.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD, "Every arena needs a looping original music bed.")
	audio.play_piece_land()
	assert((audio.get_node("ArenaSFX00").stream as AudioStreamWAV).resource_path.begins_with("res://assets/audio/cc0_fantasy/"), "Movement must use a recorded CC0 cue instead of a synthesized beep.")
	for kind in [&"dual_sword_impact", &"spear_impact", &"arrow_release", &"arrow_impact", &"arcane_cast", &"arcane_impact", &"wall_slam", &"hammer_impact"]:
		audio.play_weapon_impact(kind)
	assert(audio.played_sfx_kinds.has(&"piece_land") and audio.played_sfx_kinds.has(&"arcane_impact"), "Board movement and each weapon family must have independently triggered sounds.")
	audio.stop_all()
	audio.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("PASS: arena music and weapon-specific recorded combat audio are available.")
	quit(0)
