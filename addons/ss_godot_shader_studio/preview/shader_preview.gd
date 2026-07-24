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
var _bg_rect: TextureRect               = null  # 3D scene texture so hint_screen_texture has content
var _color_rect: ColorRect              = null

# Channel / UV visualization modes for the 3D preview
enum PreviewMode { FULL, CHANNEL_R, CHANNEL_G, CHANNEL_B, ALPHA, UV }
var _mode: PreviewMode = PreviewMode.FULL

# Cached shader code for mode switching
var _last_shader_code: String = ""

# Orbit camera state
var _dragging: bool        = false
var _last_mouse: Vector2   = Vector2.ZERO
var _orbit_az: float       = 0.0
var _orbit_el: float       = deg_to_rad(15.0)
var _orbit_dist: float     = 2.5
const _ORBIT_SPEED: float  = 0.007
const _ZOOM_SPEED: float   = 0.25
const _MIN_DIST: float     = 0.4
const _MAX_DIST: float     = 8.0

# Preview mesh type
enum PreviewMeshType { CAPSULE, SPHERE, BOX, PLANE, TORUS, CYLINDER }
var _mesh_type: PreviewMeshType = PreviewMeshType.CAPSULE

# Toolbar buttons
var _toolbar: HBoxContainer = null


func _ready() -> void:
	stretch = true
	_light.position = Vector3(1.0, 2.0, 1.0)
	_light.look_at(Vector3.ZERO, Vector3.UP)
	_light.light_energy = 1.2
	_update_camera()

	# Build 2D preview using a SubViewportContainer (Control → has .visible)
	_container_2d = SubViewportContainer.new()
	_container_2d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_container_2d.stretch = true
	_container_2d.visible = false
	_container_2d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container_2d)

	_viewport_2d = SubViewport.new()
	_viewport_2d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport_2d.transparent_bg = true
	_container_2d.add_child(_viewport_2d)

	# Background TextureRect showing the 3D scene so hint_screen_texture samples the capsule.
	_bg_rect = TextureRect.new()
	_bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_viewport_2d.add_child(_bg_rect)

	_color_rect = ColorRect.new()
	_color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_viewport_2d.add_child(_color_rect)

	_build_toolbar()


func _build_toolbar() -> void:
	_toolbar = HBoxContainer.new()
	_toolbar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_toolbar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toolbar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_toolbar)

	var dropdown := OptionButton.new()
	dropdown.custom_minimum_size = Vector2(120, 32)
	dropdown.add_theme_font_size_override("font_size", 14)
	var meshes := ["Capsule", "Sphere", "Box", "Plane", "Torus", "Cylinder"]
	for label in meshes:
		dropdown.add_item(label)
	dropdown.selected = 0
	dropdown.item_selected.connect(func(idx: int) -> void: set_preview_mesh_type(idx as PreviewMeshType))
	_toolbar.add_child(dropdown)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_dragging = event.pressed
				_last_mouse = event.position
				accept_event()
			MOUSE_BUTTON_WHEEL_UP:
				_orbit_dist = clamp(_orbit_dist - _ZOOM_SPEED, _MIN_DIST, _MAX_DIST)
				_update_camera()
				accept_event()
			MOUSE_BUTTON_WHEEL_DOWN:
				_orbit_dist = clamp(_orbit_dist + _ZOOM_SPEED, _MIN_DIST, _MAX_DIST)
				_update_camera()
				accept_event()
	elif event is InputEventMouseMotion and _dragging:
		var delta: Vector2 = event.position - _last_mouse
		_last_mouse = event.position
		_orbit_az  -= delta.x * _ORBIT_SPEED
		_orbit_el  += delta.y * _ORBIT_SPEED
		_orbit_el   = clamp(_orbit_el, deg_to_rad(-89.0), deg_to_rad(89.0))
		_update_camera()
		accept_event()


func _update_camera() -> void:
	var x := _orbit_dist * cos(_orbit_el) * sin(_orbit_az)
	var y := _orbit_dist * sin(_orbit_el)
	var z := _orbit_dist * cos(_orbit_el) * cos(_orbit_az)
	_camera.position = Vector3(x, y, z)
	_camera.look_at(Vector3.ZERO, Vector3.UP)


func set_preview_mesh_type(type: PreviewMeshType) -> void:
	_mesh_type = type
	match type:
		PreviewMeshType.CAPSULE:  _mesh.mesh = CapsuleMesh.new()
		PreviewMeshType.SPHERE:   _mesh.mesh = SphereMesh.new()
		PreviewMeshType.BOX:      _mesh.mesh = BoxMesh.new()
		PreviewMeshType.PLANE:    _mesh.mesh = PlaneMesh.new()
		PreviewMeshType.TORUS:    _mesh.mesh = TorusMesh.new()
		PreviewMeshType.CYLINDER: _mesh.mesh = CylinderMesh.new()


func apply_shader(shader_code: String) -> void:
	_last_shader_code = shader_code
	_apply_with_mode(shader_code, _mode)


func apply_texture_uniforms(textures: Dictionary) -> void:
	var mat := _mesh.material_override
	if mat == null or not mat is ShaderMaterial:
		return
	for param_name in textures:
		var path := str(textures[param_name])
		if path.is_empty():
			continue
		var tex = load(path)
		if tex is Texture2D:
			(mat as ShaderMaterial).set_shader_parameter(param_name, tex)


func set_preview_mode(mode: PreviewMode) -> void:
	_mode = mode
	if not _last_shader_code.is_empty():
		_apply_with_mode(_last_shader_code, _mode)


func _apply_with_mode(shader_code: String, mode: PreviewMode) -> void:
	if shader_code.is_empty():
		_mesh.material_override = null
		if _color_rect:
			_color_rect.material = null
		_node3d.visible = true
		_container_2d.visible = false
		return

	var is_2d := (shader_code.contains("shader_type canvas_item")
			or shader_code.contains("shader_type particles"))
	var is_unsupported := (shader_code.contains("shader_type sky")
			or shader_code.contains("shader_type fog"))

	if is_unsupported:
		# Sky and fog require a full scene setup — skip preview silently.
		_node3d.visible = false
		_container_2d.visible = false
		return

	if is_2d:
		# Keep 3D scene rendering — its texture becomes the background for hint_screen_texture.
		_node3d.visible = true
		_container_2d.visible = true
		_bg_rect.texture = ($SubViewport as SubViewport).get_texture()
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
