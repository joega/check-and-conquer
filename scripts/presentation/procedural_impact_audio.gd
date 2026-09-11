class_name ProceduralImpactAudio
extends AudioStreamPlayer

## A small original synthesized impact. It keeps V1 captures readable before
## licensed authored SFX are selected, without adding an external audio asset.

@export var duration_s := 0.16
@export var low_frequency_hz := 92.0
@export var click_frequency_hz := 740.0
@export var sound_enabled := true

var last_frame_count := 0


func _ready() -> void:
	stream = _build_impact_stream()


func play_impact() -> void:
	if not sound_enabled:
		return
	if stream == null:
		stream = _build_impact_stream()
	play()


func _build_impact_stream() -> AudioStreamWAV:
	var sample_rate := 22050.0
	var data := PackedByteArray()
	last_frame_count = int(sample_rate * duration_s)
	data.resize(last_frame_count * 4) # Stereo signed 16-bit PCM.
	for frame in last_frame_count:
		var time := float(frame) / sample_rate
		var envelope := exp(-24.0 * time)
		var low := sin(TAU * low_frequency_hz * time) * 0.42
		var click := sin(TAU * click_frequency_hz * time) * exp(-90.0 * time) * 0.12
		var pcm := int(round(clampf((low + click) * envelope, -1.0, 1.0) * 32767.0)) & 0xffff
		var offset := frame * 4
		data[offset] = pcm & 0xff
		data[offset + 1] = (pcm >> 8) & 0xff
		data[offset + 2] = pcm & 0xff
		data[offset + 3] = (pcm >> 8) & 0xff
	var impact_stream := AudioStreamWAV.new()
	impact_stream.format = AudioStreamWAV.FORMAT_16_BITS
	impact_stream.mix_rate = int(sample_rate)
	impact_stream.stereo = true
	impact_stream.data = data
	return impact_stream
