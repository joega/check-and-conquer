extends SceneTree

const ImpactAudio = preload("res://scripts/presentation/procedural_impact_audio.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var impact_audio = ImpactAudio.new()
	root.add_child(impact_audio)
	await process_frame
	impact_audio.play_impact()
	assert(impact_audio.last_frame_count == int(22050.0 * impact_audio.duration_s), "Impact audio must synthesize its complete fixed duration.")
	assert(impact_audio.last_frame_count > 0)
	await create_timer(impact_audio.duration_s + 0.05).timeout
	impact_audio.free()
	print("PASS: procedural capture impact audio synthesizes a bounded clip.")
	quit(0)
