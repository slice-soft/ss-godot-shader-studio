@tool
extends SubViewportContainer

@onready var _node3d: Node3D               = $SubViewport/Node3D
@onready var _mesh: MeshInstance3D         = $SubViewport/Node3D/MeshInstance3D
@onready var _camera: Camera3D             = $SubViewport/Node3D/Camera3D
@onready var _light: DirectionalLight3D    = $SubViewport/Node3D/DirectionalLight3D

# 2D preview — created dynamically so the scene file stays unchanged.
# We use a SubViewportContainer (Control) so .visible works correctly.
var _container_2d: SubViewportContainer = null
var _viewport_2d: SubViewport           = null
var _color_rect: ColorRect              = null

# Channel / UV visualization modes for the 3D preview
enum PreviewMode { FULL, CHANNEL_R, CHANNEL_G, CHANNEL_B, ALPHA, UV }
var _mode: PreviewMode = PreviewMode.FULL

# Cached shader code for mode switching
var _last_shader_code: String = ""


func _ready() -> void:
	stretch = true
	_camera.position = Vector3(0.0, 0.0, 2.5)
	_camera.look_at(Vector3.ZERO, Vector3.UP)
	_light.position = Vector3(1.0, 2.0, 1.0)
	_light.look_at(Vector3.ZERO, Vector3.UP)
	_light.light_energy = 1.2

	# Build 2D preview using a SubViewportContainer (Control → has .visible)
	_container_2d = SubViewportContainer.new()
	_container_2d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_container_2d.stretch = true
	_container_2d.visible = false
	add_child(_container_2d)

	_viewport_2d = SubViewport.new()
	_viewport_2d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport_2d.transparent_bg = true
	_container_2d.add_child(_viewport_2d)

	_color_rect = ColorRect.new()
	_color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_viewport_2d.add_child(_color_rect)


func apply_shader(shader_code: String) -> void:
	_last_shader_code = shader_code
	_apply_with_mode(shader_code, _mode)


func set_preview_mode(mode: PreviewMode) -> void:
	_mode = mode
	if not _last_shader_code.is_empty():
		_apply_with_mode(_last_shader_code, _mode)


func _apply_with_mode(shader_code: String, mode: PreviewMode) -> void:
	if shader_code.is_empty():
		_mesh.material_override = null
		if _color_rect:
			_color_rect.material = null
		return

	var is_2d := (shader_code.contains("shader_type canvas_item")
			or shader_code.contains("shader_type particles"))

	if is_2d:
		# Hide 3D content (Node3D.visible is valid), show 2D container
		_node3d.visible = false
		_container_2d.visible = true
		var shader := Shader.new()
		shader.code = shader_code
		var mat := ShaderMaterial.new()
		mat.shader = shader
		_color_rect.material = mat
	else:
		_node3d.visible = true
		_container_2d.visible = false
		var display_code := _wrap_with_mode(shader_code, mode)
		var shader := Shader.new()
		shader.code = display_code
		var mat := ShaderMaterial.new()
		mat.shader = shader
		_mesh.material_override = mat


## Wraps the compiled shader with a visualization overlay for channel/UV debug.
func _wrap_with_mode(code: String, mode: PreviewMode) -> String:
	match mode:
		PreviewMode.CHANNEL_R: return _channel_overlay(code, "r")
		PreviewMode.CHANNEL_G: return _channel_overlay(code, "g")
		PreviewMode.CHANNEL_B: return _channel_overlay(code, "b")
		PreviewMode.ALPHA:     return _channel_overlay(code, "a")
		PreviewMode.UV:        return _uv_overlay()
		_:                     return code


func _channel_overlay(original_code: String, channel: String) -> String:
	# Appends a greyscale remap of the chosen ALBEDO channel before the
	# closing brace of fragment() — works for spatial shaders only.
	if not original_code.contains("void fragment()"):
		return original_code
	var close := original_code.rfind("}")
	if close < 0:
		return original_code
	var injection := "\n\t// channel viz: %s\n\tALBEDO = vec3(ALBEDO.%s);" % [channel, channel]
	return original_code.substr(0, close) + injection + "\n" + original_code.substr(close)


func _uv_overlay() -> String:
	return (
		"// UV debug overlay\n"
		+ "shader_type spatial;\n"
		+ "void fragment() {\n"
		+ "\tALBEDO = vec3(UV, 0.0);\n"
		+ "\tROUGHNESS = 1.0;\n"
		+ "\tMETALLIC = 0.0;\n"
		+ "}\n"
	)
