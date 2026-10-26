extends RefCounted
const MIX_RATE := 22050


static func pop_sound() -> AudioStreamWAV:
	var duration := 0.12
	var samples := int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in samples:
		var t := float(i) / float(samples)
		var envelope := (1.0 - t) * (1.0 - t) * 0.7
		var noise := rng.randf_range(-1.0, 1.0)
		_write_sample(data, i, noise * envelope)
	return _make_stream(data)


static func correct_chime() -> AudioStreamWAV:
	var duration := 0.4
	var samples := int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / float(samples)
		var envelope := (1.0 - t * t) * 0.5
		var freq := 523.0 if t < 0.45 else 659.0
		_write_sample(data, i, sin(TAU * freq * t) * envelope)
	return _make_stream(data)


static func wrong_buzz() -> AudioStreamWAV:
	var duration := 0.22
	var samples := int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / float(samples)
		var envelope := (1.0 - t) * 0.3
		var sample := (sin(TAU * 200.0 * t) + sin(TAU * 237.0 * t)) * 0.5 * envelope
		_write_sample(data, i, sample)
	return _make_stream(data)


static func click_sound() -> AudioStreamWAV:
	var duration := 0.06
	var samples := int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / float(samples)
		_write_sample(data, i, sin(TAU * 800.0 * t) * (1.0 - t) * 0.45)
	return _make_stream(data)


static func countdown_tick() -> AudioStreamWAV:
	var duration := 0.07
	var samples := int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / float(samples)
		_write_sample(data, i, sin(TAU * 1000.0 * t) * (1.0 - t) * 0.28)
	return _make_stream(data)


# Helpers 

static func _write_sample(data: PackedByteArray, index: int, value: float) -> void:
	var clamped := clampf(value, -1.0, 1.0)
	var int_val := int(clamped * 32767.0)
	var u := int_val & 0xFFFF
	data[index * 2] = u & 0xFF
	data[index * 2 + 1] = (u >> 8) & 0xFF


static func _make_stream(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream

