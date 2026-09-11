extends SceneTree

const BattleDirector = preload("res://scripts/presentation/battle_director.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var director := BattleDirector.new()
	root.add_child(director)
	# Distance sampling has a hard per-projectile ceiling even if a renderer
	# happens to present many frames during a very slow capture.
	var state := {"last_position": Vector3.ZERO, "emitted": 0}
	director._emit_projectile_trail(state, Vector3(100.0, 0.0, 0.0), Color.CYAN)
	assert(int(state.emitted) == director.TRAIL_MAX_PER_PROJECTILE, "Trail emission must be bounded by distance, not rendered frames.")
	assert(director.active_temporary_effect_count() == director.TRAIL_MAX_PER_PROJECTILE)
	director._spawn_elemental_impact(Vector3.ZERO, Color.RED, Color.YELLOW)
	var burst = director.get_node("ElementalImpact")
	var core = burst.get_child(0) as MeshInstance3D
	assert(core.name.is_empty() or core.mesh is SphereMesh, "Spell contact must use a bounded core mesh rather than a full-screen overlay.")
	assert((core.material_override as StandardMaterial3D).transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "Spell core must fade rather than form an opaque sphere.")
	director._clear_temporary_effects()
	await process_frame
	assert(director.active_temporary_effect_count() == 0, "Skip/reset cleanup must remove all temporary spell effects.")
	director.queue_free()
	print("PASS: spell trails are distance-bounded and temporary effects clean up deterministically.")
	quit(0)
