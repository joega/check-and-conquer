extends SceneTree

const COMBAT_LAB_SCENE := preload("res://scenes/debug/DebugCombatLab.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lab = COMBAT_LAB_SCENE.instantiate()
	root.add_child(lab)
	await process_frame
	var battle = lab.get_node("BattleDirector")
	var victim = lab.get_node("Victim")
	var destination: Vector3 = victim.global_position
	lab._play_capture()
	await battle.victim_death_finished
	assert(victim.animation_playback_position() >= victim.state_duration(battle.last_victim_death_clip) - 0.05, "Victim must finish the full death animation before cleanup.")
	assert(lab.get_node("Attacker").global_position.distance_to(destination) > 0.1, "The winner must still be approaching the claimed square after the death beat.")
	await battle.presentation_finished
	assert(not victim.visible)
	assert(lab.get_node("Attacker").global_position.is_equal_approx(destination), "Capture completion must settle at the destination after its winner walk.")
	lab._reset_lab()
	battle.playback_speed = 2.0
	lab._play_capture()
	await battle.victim_death_finished
	assert(victim.animation_playback_position() >= victim.state_duration(battle.last_victim_death_clip) - 0.05, "Quick capture must still play the whole death clip.")
	await battle.presentation_finished
	assert(is_equal_approx(battle.playback_speed, 2.0) and not victim.visible)
	lab._reset_lab()
	battle.playback_speed = 1.0
	lab._select_attacker(1)
	lab._select_victim(0)
	await process_frame
	await process_frame
	victim = lab.get_node("Victim")
	var impact_events: Array[int] = []
	battle.impact_landed.connect(func(): impact_events.append(1))
	lab._play_capture()
	assert(battle.choreography.id == &"capture.knight_vs_pawn.lunge_01")
	await battle.victim_death_finished
	assert(impact_events.size() == 2, "Knight-versus-pawn signature must land both beats.")
	assert(battle.last_victim_death_clip == &"death.knockback_01", "Knight-versus-pawn must exercise the UAL2 knockback death variant.")
	assert(victim.animation_playback_position() >= victim.state_duration(battle.last_victim_death_clip) - 0.05, "Signature capture must retain the complete victim death clip.")
	await battle.presentation_finished
	assert(not victim.visible)
	lab._reset_lab()
	lab._select_attacker(4)
	lab._select_victim(3)
	await process_frame
	await process_frame
	victim = lab.get_node("Victim")
	lab._play_capture()
	assert(battle.choreography.id == &"capture.queen_vs_rook.command_01")
	await battle.victim_death_finished
	assert(impact_events.size() == 4, "Queen-versus-rook signature must land both beats.")
	assert(victim.animation_playback_position() >= victim.state_duration(battle.last_victim_death_clip) - 0.05, "Second signature capture must retain the complete victim death clip.")
	await battle.presentation_finished
	assert(not victim.visible)
	lab._reset_lab()
	lab._select_attacker(3)
	lab._select_victim(1)
	await process_frame
	await process_frame
	victim = lab.get_node("Victim")
	lab._play_capture()
	assert(battle.choreography.id == &"capture.rook_vs_knight.breaker_01")
	await battle.victim_death_finished
	assert(impact_events.size() == 6, "Rook-versus-knight signature must land both beats.")
	assert(victim.animation_playback_position() >= victim.state_duration(battle.last_victim_death_clip) - 0.05, "Resolved signature death must finish before cleanup.")
	await battle.presentation_finished
	assert(not victim.visible)
	lab.queue_free()
	print("PASS: capture waits for the complete victim death animation.")
	quit(0)
