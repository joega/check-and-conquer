class_name ArenaAudioDirector
extends Node

## Original procedural score plus CC0-recorded combat effects. Audio intent
## stays separate from chess rules and combat choreography.

const SAMPLE_RATE := 22050
const MUSIC_DURATION_S := 12.0
const SFX_STREAMS := {
	&"piece_land": [preload("res://assets/audio/cc0_fantasy/wood-twigs-break-01.ogg")],
	&"approach_step": [preload("res://assets/audio/cc0_fantasy/wood-twigs-break-01.ogg")],
	&"sword_impact": [preload("res://assets/audio/cc0_fantasy/sword-clash-01.ogg"), preload("res://assets/audio/cc0_fantasy/sword-clash-03.ogg")],
	&"dual_sword_impact": [preload("res://assets/audio/cc0_fantasy/sword-clash-03.ogg"), preload("res://assets/audio/cc0_fantasy/sword-clash-01.ogg")],
	&"royal_blade_impact": [preload("res://assets/audio/cc0_fantasy/sword-clash-01.ogg")],
	&"spear_impact": [preload("res://assets/audio/cc0_fantasy/metal-hammer-hit-01.ogg")],
	&"arrow_release": [preload("res://assets/audio/cc0_fantasy/arrow-feathers-01.ogg"), preload("res://assets/audio/cc0_fantasy/arrow-grab-from-quiver-01.ogg")],
	&"arrow_impact": [preload("res://assets/audio/cc0_fantasy/metal-hammer-hit-01.ogg")],
	&"arcane_cast": [preload("res://assets/audio/cc0_fantasy/fireball-01.ogg")],
	&"arcane_impact": [preload("res://assets/audio/cc0_fantasy/fireball-01.ogg")],
	&"wall_slam": [preload("res://assets/audio/cc0_fantasy/metal-hammer-hit-01.ogg")],
	&"hammer_impact": [preload("res://assets/audio/cc0_fantasy/metal-hammer-hit-01.ogg")],
}

var active_arena_id := "mountain_fortress"
var last_sfx_kind: StringName = &""
var played_sfx_kinds: Array[StringName] = []
var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_cycles: Dictionary = {}


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "ArenaMusic"
	_music_player.volume_db = -18.0
	add_child(_music_player)
	for index in 3:
		var player := AudioStreamPlayer.new()
		player.name = "ArenaSFX%02d" % index
		player.volume_db = -8.0
		add_child(player)
		_sfx_players.append(player)


func set_arena(arena_id: String) -> void:
	active_arena_id = arena_id
	if _music_player == null:
		return
	_music_player.stop()
	_music_player.stream = _build_music_stream(arena_id)
	_music_player.play()


func play_piece_land() -> void:
	_play_sfx(&"piece_land")


func play_weapon_impact(kind: StringName) -> void:
	_play_sfx(kind)


func stop_all() -> void:
	if _music_player != null:
		_music_player.stop()
	stop_combat_sfx()


func stop_combat_sfx() -> void:
	for player in _sfx_players:
		player.stop()
		player.stream = null


func _exit_tree() -> void:
	stop_all()
	if _music_player != null:
		_music_player.stream = null


func _play_sfx(kind: StringName) -> void:
	last_sfx_kind = kind
	played_sfx_kinds.append(kind)
	if _sfx_players.is_empty():
		return
	var player := _sfx_players[0]
	for candidate in _sfx_players:
		if not candidate.playing:
			player = candidate
			break
	# Footfalls should support the walk, never dominate it. Combat impact cues
	# retain their punch while a square landing is deliberately subdued.
	player.volume_db = -18.0 if kind in [&"piece_land", &"approach_step"] else -8.0
	player.stream = _sfx_stream_for(kind)
	player.play()


func _sfx_stream_for(kind: StringName) -> AudioStream:
	var streams: Array = SFX_STREAMS.get(kind, [])
	if not streams.is_empty():
		var index: int = int(_sfx_cycles.get(kind, 0)) % streams.size()
		_sfx_cycles[kind] = index + 1
		return streams[index]
	# The fallback protects debug callers that introduce a new cue before a
	# recorded asset is assigned; normal gameplay uses the CC0 samples above.
	return _build_sfx_stream(kind)


func _build_music_stream(arena_id: String) -> AudioStreamWAV:
	var profile := _music_profile(arena_id)
	var frame_count := int(SAMPLE_RATE * MUSIC_DURATION_S)
	var data := PackedByteArray()
	data.resize(frame_count * 4)
	var chord_notes: Array = profile.chords
	for frame in frame_count:
		var time := float(frame) / float(SAMPLE_RATE)
		var chord_index := int(time / 2.0) % chord_notes.size()
		var chord: Array = chord_notes[chord_index]
		var left := _music_sample(time, chord, profile, -0.16)
		var right := _music_sample(time, chord, profile, 0.16)
		_write_stereo_frame(data, frame, left, right)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = true
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frame_count
	stream.data = data
	return stream


func _music_profile(arena_id: String) -> Dictionary:
	match arena_id:
		"arcane_sky_citadel":
			return {"chords": [[220.0, 261.63, 329.63], [196.0, 246.94, 293.66], [174.61, 220.0, 261.63]], "pulse": 0.64, "air": 0.42, "bell": 1.0}
		"frozen_keep":
			return {"chords": [[146.83, 174.61, 220.0], [130.81, 164.81, 196.0], [123.47, 146.83, 185.0]], "pulse": 0.36, "air": 0.62, "bell": 0.72}
		"lava_forge":
			return {"chords": [[110.0, 130.81, 164.81], [98.0, 123.47, 146.83], [92.5, 110.0, 138.59]], "pulse": 1.15, "air": 0.20, "bell": 0.34}
		"forest_ruins":
			return {"chords": [[196.0, 246.94, 293.66], [174.61, 220.0, 261.63], [164.81, 207.65, 246.94]], "pulse": 0.52, "air": 0.55, "bell": 0.86}
		_:
			return {"chords": [[146.83, 185.0, 220.0], [164.81, 196.0, 246.94], [130.81, 164.81, 196.0]], "pulse": 0.78, "air": 0.35, "bell": 0.58}


func _music_sample(time: float, chord: Array, profile: Dictionary, pan: float) -> float:
	var pad := 0.0
	for index in chord.size():
		var frequency := float(chord[index]) * (1.0 + pan * (0.012 + index * 0.004))
		pad += sin(TAU * frequency * time + index * 0.62) * (0.11 - index * 0.014)
		pad += sin(TAU * frequency * 0.5 * time + index) * 0.026
	var step_phase := fmod(time * (1.0 + float(profile.pulse) * 0.35), 0.5)
	var pulse_envelope := exp(-step_phase * (9.0 - float(profile.pulse) * 2.4))
	var bass := sin(TAU * float(chord[0]) * 0.5 * time) * 0.13 * pulse_envelope
	var bell_step := fmod(time + 0.08, 1.0)
	var bell_envelope := exp(-bell_step * 5.8) * float(profile.bell)
	var bell := sin(TAU * float(chord[2]) * 2.0 * time) * 0.045 * bell_envelope
	var air := sin(TAU * (0.11 + pan * 0.008) * time) * 0.018 * float(profile.air)
	var fade := minf(minf(time / 0.35, (MUSIC_DURATION_S - time) / 0.35), 1.0)
	return clampf((pad + bass + bell + air) * maxf(fade, 0.0), -0.88, 0.88)


func _build_sfx_stream(kind: StringName) -> AudioStreamWAV:
	var duration := 0.22
	if kind in [&"wall_slam", &"hammer_impact"]:
		duration = 0.42
	elif kind in [&"arcane_cast", &"arrow_release"]:
		duration = 0.16
	var frame_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(frame_count * 4)
	for frame in frame_count:
		var time := float(frame) / float(SAMPLE_RATE)
		var sample := _sfx_sample(kind, time)
		_write_stereo_frame(data, frame, sample * 0.96, sample * 0.82)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = true
	stream.data = data
	return stream


func _sfx_sample(kind: StringName, time: float) -> float:
	var noise := sin(TAU * 731.0 * time) * sin(TAU * 1217.0 * time)
	match kind:
		&"piece_land":
			return sin(TAU * 118.0 * time) * exp(-23.0 * time) * 0.62 + sin(TAU * 620.0 * time) * exp(-68.0 * time) * 0.16
		&"sword_impact", &"dual_sword_impact", &"royal_blade_impact":
			var metal := sin(TAU * 980.0 * time) + sin(TAU * 1470.0 * time) * 0.46
			return (metal * 0.24 + noise * 0.18) * exp(-18.0 * time) + sin(TAU * 95.0 * time) * exp(-24.0 * time) * 0.3
		&"spear_impact":
			return (sin(TAU * 310.0 * time) * 0.4 + noise * 0.22) * exp(-20.0 * time)
		&"arrow_release":
			return (sin(TAU * (340.0 + time * 2400.0) * time) * 0.23 + noise * 0.08) * exp(-34.0 * time)
		&"arrow_impact":
			return (sin(TAU * 520.0 * time) * 0.25 + noise * 0.32) * exp(-26.0 * time)
		&"arcane_cast":
			return sin(TAU * (190.0 + time * 1380.0) * time) * exp(-11.0 * time) * 0.32
		&"arcane_impact":
			return (sin(TAU * 168.0 * time) * 0.42 + sin(TAU * 890.0 * time) * 0.14 + noise * 0.14) * exp(-12.0 * time)
		&"wall_slam", &"hammer_impact":
			return (sin(TAU * 58.0 * time) * 0.75 + noise * 0.2) * exp(-12.0 * time)
		_:
			return (sin(TAU * 180.0 * time) * 0.42 + noise * 0.15) * exp(-19.0 * time)


func _write_stereo_frame(data: PackedByteArray, frame: int, left: float, right: float) -> void:
	var left_pcm := int(round(clampf(left, -1.0, 1.0) * 32767.0)) & 0xffff
	var right_pcm := int(round(clampf(right, -1.0, 1.0) * 32767.0)) & 0xffff
	var offset := frame * 4
	data[offset] = left_pcm & 0xff
	data[offset + 1] = (left_pcm >> 8) & 0xff
	data[offset + 2] = right_pcm & 0xff
	data[offset + 3] = (right_pcm >> 8) & 0xff
