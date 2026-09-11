extends SceneTree

const COMBAT_LAB_SCENE := preload("res://scenes/debug/DebugCombatLab.tscn")
const CYCLE_COUNT := 20
const EPSILON := 0.001


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lab := COMBAT_LAB_SCENE.instantiate()
	root.add_child(lab)
	await process_frame
	await process_frame
	var attacker = lab.get_node("Attacker")
	var victim = lab.get_node("Victim")
	var battle_director = lab.get_node("BattleDirector")
	var lab_audio = lab.get_node("ArenaAudioDirector")
	lab._set_playback_speed(1)
	assert(is_equal_approx(battle_director.playback_speed, 0.5), "Combat Lab must expose replay speed controls.")
	lab._set_playback_speed(2)
	lab._select_attacker(4)
	lab._select_victim(1)
	await process_frame
	attacker = lab.get_node("Attacker")
	victim = lab.get_node("Victim")
	assert(attacker.archetype == 5 and attacker.uses_female_model)
	assert(victim.archetype == 2 and victim.uses_female_model)
	lab._select_attacker(0)
	lab._select_victim(0)
	await process_frame
	attacker = lab.get_node("Attacker")
	victim = lab.get_node("Victim")
	var attacker_home: Transform3D = attacker.global_transform
	var victim_home: Transform3D = victim.global_transform
	lab._preview_recovery()
	assert(attacker.current_semantic_state() == &"recovery.capture_ready_01" and attacker.global_transform.is_equal_approx(attacker_home), "Combat Lab recovery preview must preserve the authoritative actor transform.")
	lab._preview_victory()
	assert(attacker.current_semantic_state().begins_with("celebration.") and victim.current_semantic_state().begins_with("celebration."), "Combat Lab must expose acknowledgement previews for pose timing inspection.")
	lab._reset_lab()
	Engine.time_scale = 32.0
	for cycle in CYCLE_COUNT:
		lab._play_capture()
		await battle_director.presentation_finished
		assert(lab_audio.played_sfx_kinds.has(&"dual_sword_impact"), "Combat Lab must route the same weapon event through ArenaAudioDirector as gameplay.")
		assert(not victim.visible, "Victim remained visible after cycle %d." % (cycle + 1))
		assert(attacker.global_position.distance_to(victim_home.origin) < EPSILON, "Attacker missed destination on cycle %d." % (cycle + 1))
		assert(is_zero_approx(attacker.rotation.y), "White attacker must restore board-facing orientation on cycle %d." % (cycle + 1))
		lab._reset_lab()
		await process_frame
		assert(attacker.global_transform.is_equal_approx(attacker_home), "Attacker drifted on cycle %d." % (cycle + 1))
		assert(victim.global_transform.is_equal_approx(victim_home), "Victim drifted on cycle %d." % (cycle + 1))
	lab._play_capture()
	battle_director.request_skip()
	await battle_director.presentation_finished
	assert(not victim.visible, "Skip must still resolve the victim.")
	assert(attacker.global_position.distance_to(victim_home.origin) < EPSILON, "Skip must settle the attacker on the destination.")
	Engine.time_scale = 1.0
	lab._reset_lab()
	await process_frame
	lab.queue_free()
	print("PASS: Combat Lab completed %d play/reset cycles without transform drift." % CYCLE_COUNT)
	quit(0)
