class_name SynthwaveBackground
extends ColorRect

## Controller script for the procedurally generated Synthwave Outrun background.
## Feeds real-time audio amplitude from AudioManager into the shader material.

const SHADER_RES = preload("res://shaders/synthwave_background.gdshader")

@export var audio_reactive: bool = true
@export var grid_speed: float = 0.85:
	set(value):
		grid_speed = value
		if _shader_mat:
			_shader_mat.set_shader_parameter("grid_speed", grid_speed)

var _shader_mat: ShaderMaterial

func _ready() -> void:
	if material is ShaderMaterial:
		_shader_mat = material as ShaderMaterial
	else:
		_shader_mat = ShaderMaterial.new()
		_shader_mat.shader = SHADER_RES
		material = _shader_mat

	_shader_mat.set_shader_parameter("grid_speed", grid_speed)

func _process(_delta: float) -> void:
	if not _shader_mat:
		return

	if audio_reactive:
		var audio_mgr = get_node_or_null("/root/AudioManager")
		if audio_mgr and audio_mgr.has_method("get_live_amplitude"):
			var amp: float = audio_mgr.get_live_amplitude()
			_shader_mat.set_shader_parameter("live_amplitude", amp)
			return

	_shader_mat.set_shader_parameter("live_amplitude", 0.0)
