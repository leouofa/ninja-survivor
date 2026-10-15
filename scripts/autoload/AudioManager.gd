extends Node

signal music_finished()

var music_player: AudioStreamPlayer
var current_stream: AudioStream = null
var current_duration: float = 180.0

var sfx_pool: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE = 12

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)
	
	# Instantiate SFX pool
	for i in range(SFX_POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_pool.append(p)

func play_track(track_path: String) -> void:
	if ResourceLoader.exists(track_path):
		var stream = load(track_path)
		if stream:
			current_stream = stream
			music_player.stream = stream
			music_player.play()
			current_duration = stream.get_length()
			if current_duration <= 0.0:
				current_duration = 180.0
	else:
		push_error("Track not found: " + track_path)

func stop_music() -> void:
	music_player.stop()

func pause_music() -> void:
	music_player.stream_paused = true

func resume_music() -> void:
	music_player.stream_paused = false

func get_playback_position() -> float:
	if music_player and music_player.playing:
		return music_player.get_playback_position()
	return 0.0

func get_track_duration() -> float:
	return current_duration

func get_progress_ratio() -> float:
	if current_duration > 0.0:
		return clamp(get_playback_position() / current_duration, 0.0, 1.0)
	return 0.0

var _smoothed_amplitude: float = 0.0

func _process(delta: float) -> void:
	if music_player and music_player.playing:
		var bus_idx = AudioServer.get_bus_index("Master")
		var peak_l = AudioServer.get_bus_peak_volume_left_db(bus_idx, 0)
		var peak_r = AudioServer.get_bus_peak_volume_right_db(bus_idx, 0)
		var peak_db = max(peak_l, peak_r)
		var raw_amp = 0.0
		if peak_db > -60.0:
			raw_amp = clamp((peak_db + 45.0) / 45.0, 0.0, 1.0)
		if raw_amp > _smoothed_amplitude:
			_smoothed_amplitude = lerp(_smoothed_amplitude, raw_amp, 25.0 * delta)
		else:
			_smoothed_amplitude = lerp(_smoothed_amplitude, raw_amp, 6.0 * delta)
	else:
		_smoothed_amplitude = lerp(_smoothed_amplitude, 0.0, 10.0 * delta)

func get_live_amplitude() -> float:
	return _smoothed_amplitude

func _on_music_finished() -> void:
	music_finished.emit()

# --- SYNTHESIZED SOUND EFFECTS ---
# Generates custom retro synthwave sound waves programmatically
func play_sfx(sfx_type: String, pitch_scale: float = 1.0) -> void:
	var stream = _get_or_create_sfx_stream(sfx_type)
	if stream:
		for p in sfx_pool:
			if not p.playing:
				p.stream = stream
				p.pitch_scale = pitch_scale * randf_range(0.95, 1.05)
				p.play()
				return
		# If all busy, use first
		sfx_pool[0].stream = stream
		sfx_pool[0].pitch_scale = pitch_scale
		sfx_pool[0].play()

var _cached_sfx: Dictionary = {}

func _get_or_create_sfx_stream(sfx_type: String) -> AudioStreamWAV:
	if _cached_sfx.has(sfx_type):
		return _cached_sfx[sfx_type]
	
	var sample_rate = 22050
	var duration = 0.2
	var samples: PackedByteArray = PackedByteArray()
	
	match sfx_type:
		"shuriken":
			# High pitch swoosh / blade ring
			duration = 0.12
			var num_samples = int(sample_rate * duration)
			samples.resize(num_samples)
			for i in range(num_samples):
				var t = float(i) / sample_rate
				var freq = 1200.0 - (t / duration) * 600.0
				var env = 1.0 - (float(i) / num_samples)
				var val = sin(t * freq * TAU) * env * 0.4
				samples[i] = int(clamp((val + 1.0) * 127.5, 0, 255))
		
		"katana":
			# Heavy metallic cleave
			duration = 0.25
			var num_samples = int(sample_rate * duration)
			samples.resize(num_samples)
			for i in range(num_samples):
				var t = float(i) / sample_rate
				var freq = 450.0 - (t / duration) * 350.0
				var env = 1.0 - (float(i) / num_samples)
				var val = (sin(t * freq * TAU) + (randf() * 0.4 - 0.2)) * env * 0.5
				samples[i] = int(clamp((val + 1.0) * 127.5, 0, 255))
		
		"enemy_hit":
			# Punchy metallic thud
			duration = 0.08
			var num_samples = int(sample_rate * duration)
			samples.resize(num_samples)
			for i in range(num_samples):
				var t = float(i) / sample_rate
				var freq = 300.0 - (t / duration) * 220.0
				var env = pow(1.0 - (float(i) / num_samples), 2)
				var val = sin(t * freq * TAU) * env * 0.5
				samples[i] = int(clamp((val + 1.0) * 127.5, 0, 255))
		
		"enemy_die":
			# Cyber pop / disintegration
			duration = 0.22
			var num_samples = int(sample_rate * duration)
			samples.resize(num_samples)
			for i in range(num_samples):
				var t = float(i) / sample_rate
				var freq = 800.0 - (t / duration) * 650.0
				var env = 1.0 - (float(i) / num_samples)
				var noise = randf() * 0.6 - 0.3
				var val = (sin(t * freq * TAU) * 0.5 + noise) * env * 0.5
				samples[i] = int(clamp((val + 1.0) * 127.5, 0, 255))
				
		"pickup_xp":
			# Bright retro crystal chime
			duration = 0.18
			var num_samples = int(sample_rate * duration)
			samples.resize(num_samples)
			for i in range(num_samples):
				var t = float(i) / sample_rate
				var freq = 900.0 + (t / duration) * 800.0
				var env = 1.0 - (float(i) / num_samples)
				var val = sin(t * freq * TAU) * env * 0.35
				samples[i] = int(clamp((val + 1.0) * 127.5, 0, 255))
		
		"level_up":
			# Fanfare synth arpeggio
			duration = 0.45
			var num_samples = int(sample_rate * duration)
			samples.resize(num_samples)
			for i in range(num_samples):
				var t = float(i) / sample_rate
				var step = int((t / duration) * 4)
				var freqs = [440.0, 554.37, 659.25, 880.0]
				var freq = freqs[min(step, 3)]
				var env = 1.0 - (float(i) / num_samples) * 0.5
				var val = sin(t * freq * TAU) * env * 0.4
				samples[i] = int(clamp((val + 1.0) * 127.5, 0, 255))
		
		"boss_spawn":
			# Deep ominous sub-bass growl
			duration = 0.6
			var num_samples = int(sample_rate * duration)
			samples.resize(num_samples)
			for i in range(num_samples):
				var t = float(i) / sample_rate
				var freq = 90.0 + sin(t * 30.0) * 20.0
				var env = 1.0 - (float(i) / num_samples)
				var val = sin(t * freq * TAU) * env * 0.7
				samples[i] = int(clamp((val + 1.0) * 127.5, 0, 255))
		
		_:
			duration = 0.1
			var num_samples = int(sample_rate * duration)
			samples.resize(num_samples)
			for i in range(num_samples):
				samples[i] = 128

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = samples
	_cached_sfx[sfx_type] = wav
	return wav
