extends SceneTree

const BROWSER_SCENE := preload("res://scenes/debug/DebugAnimationBrowser.tscn")
const Types = preload("res://scripts/chess/chess_types.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var browser = BROWSER_SCENE.instantiate()
	root.add_child(browser)
	await process_frame
	await process_frame
	assert(browser._actor.archetype == Types.PAWN)
	browser._select_archetype(4)
	await process_frame
	await process_frame
	assert(browser._actor.archetype == Types.QUEEN and browser._actor.uses_female_model)
	assert(browser._actor.outfit_id == "female_ranger")
	assert(browser._actor.get_node_or_null("ModelRoot/Armature/Skeleton3D") != null)
	browser._set_playback_speed(0)
	assert(is_equal_approx(browser._actor.animation_speed_multiplier(), 0.25), "Animation Browser must set the selected preview speed.")
	browser._play(&"locomotion.walk.forward", "Walk")
	await process_frame
	browser._toggle_pause()
	assert(browser._actor.is_animation_paused(), "Animation Browser must pause the active clip.")
	browser._toggle_pause()
	assert(not browser._actor.is_animation_paused(), "Animation Browser must resume the active clip.")
	browser._play_primary_attack()
	assert(browser._actor.primary_attack_state() == &"attack.spell.shot_01")
	assert(browser._actor.supports_state(browser._actor.primary_attack_state()))
	browser._play_combat_idle()
	assert(browser._actor.combat_idle_state() == &"combat.idle.spell_01")
	assert(browser._actor.supports_state(browser._actor.combat_idle_state()))
	browser._select_archetype(3)
	await process_frame
	await process_frame
	assert(browser._actor.get_node_or_null("ModelRoot/Armature/Skeleton3D/RookWarHammerAttachment/RookWarHammer") != null, "Rook must carry the imported war hammer without restoring the shield.")
	assert(browser._actor.get_node_or_null("ModelRoot/Armature/Skeleton3D/RookWarHammerAttachment") != null)
	assert(browser._actor.supports_state(browser._actor.combat_idle_state()))
	browser.queue_free()
	print("PASS: animation browser switches and previews full-character archetypes.")
	quit(0)
