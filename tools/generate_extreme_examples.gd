extends SceneTree

const GRAPH_DIR := "res://shaders/examples"
const GENERATED_DIR := "res://assets/shaders/examples"
const SUBGRAPH_DIR := "res://shader_assets/subgraphs"

const PALETTE_SUBGRAPH_PATH := "res://shader_assets/subgraphs/extreme_palette.gssubgraph"
const SPATIAL_GRAPH_PATH := "res://shaders/examples/spatial_triplanar_rim.gshadergraph"
const FULLSCREEN_GRAPH_PATH := "res://shaders/examples/fullscreen_posterized_glitch.gshadergraph"
const PARTICLES_GRAPH_PATH := "res://shaders/examples/particles_orbit_burst.gshadergraph"

var _registry: NodeRegistry = null
var _owns_registry := false
var _serializer := GraphSerializer.new()


func _initialize() -> void:
	_prepare_registry()
	_ensure_dir(GRAPH_DIR)
	_ensure_dir(GENERATED_DIR)
	_ensure_dir(SUBGRAPH_DIR)

	var docs := [
		{
			"path": PALETTE_SUBGRAPH_PATH,
			"doc": _make_palette_subgraph(),
			"compile": false,
		},
		{
			"path": SPATIAL_GRAPH_PATH,
			"doc": _make_spatial_triplanar_rim(),
			"compile": true,
		},
		{
			"path": FULLSCREEN_GRAPH_PATH,
			"doc": _make_fullscreen_posterized_glitch(),
			"compile": true,
		},
		{
			"path": PARTICLES_GRAPH_PATH,
			"doc": _make_particles_orbit_burst(),
			"compile": true,
		},
	]

	for entry in docs:
		var path: String = entry["path"]
		var doc: ShaderGraphDocument = entry["doc"]
		var compile_output: bool = entry["compile"]
		var save_err := _serializer.save(doc, path)
		if save_err != OK:
			push_error("Could not save example: %s" % path)
			_shutdown(1)
			return
		print("[saved] %s" % path)

		if not compile_output:
			continue

		var compiler := ShaderGraphCompiler.new()
		var result: Dictionary = compiler.compile_gd(doc, path)
		if not result.get("success", false):
			push_error("Compile failed for %s" % path)
			for issue in result.get("issues", []):
				print("  - %s: %s" % [issue.get("code", "?"), issue.get("message", "")])
			_shutdown(1)
			return

		var shader_path := GENERATED_DIR.path_join("%s.generated.gdshader" % path.get_file().get_basename())
		_write_text(shader_path, result.get("shader_code", ""))
		print("[compiled] %s" % shader_path)

	_shutdown(0)


func _prepare_registry() -> void:
	if Engine.has_singleton("NodeRegistry"):
		_registry = Engine.get_singleton("NodeRegistry") as NodeRegistry
		return

	_registry = NodeRegistry.new()
	StdlibRegistration.register_all(_registry)
	Engine.register_singleton("NodeRegistry", _registry)
	_owns_registry = true


func _shutdown(code: int) -> void:
	if _owns_registry and _registry != null:
		Engine.unregister_singleton("NodeRegistry")
		_registry.free()
	quit(code)


func _ensure_dir(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open generated shader for writing: %s" % path)
		return
	file.store_string(text)
	file.close()


func _add_node(
		doc: ShaderGraphDocument,
		def_id: String,
		pos: Vector2,
		props: Dictionary = {},
		title_override: String = "",
		stage_scope: String = "any") -> String:
	var node_id := doc.add_node(def_id, pos)
	var node := doc.get_node(node_id)
	if node == null:
		return ""

	node.stage_scope = stage_scope
	for key in props:
		node.set_property(key, props[key])

	var def := _registry.get_definition(def_id) if _registry != null else null
	if title_override.is_empty():
		node.title = def.get_display_name() if def != null else def_id
	else:
		node.title = title_override
	return node_id


func _configure_graph(doc: ShaderGraphDocument, name: String, domain: String) -> void:
	doc.set_name(name)
	doc.set_shader_domain(domain)
	doc.set_generated_shader_dir(GENERATED_DIR)


func _add_palette_subgraph_node(doc: ShaderGraphDocument, pos: Vector2) -> String:
	return _add_node(doc, "utility/subgraph", pos, {
		"subgraph_path": PALETTE_SUBGRAPH_PATH,
	}, "Extreme Palette")


func _make_palette_subgraph() -> ShaderGraphDocument:
	var doc := ShaderGraphDocument.new()
	doc.set_name("Extreme Palette")
	doc.set_shader_domain("subgraph")

	var hue_id := _add_node(doc, "subgraph/input", Vector2(40, 40), {
		"input_name": "Hue",
		"input_type": "float",
		"port_id": "hue_in",
	}, "Hue")
	var sat_id := _add_node(doc, "subgraph/input", Vector2(40, 150), {
		"input_name": "Saturation",
		"input_type": "float",
		"port_id": "sat_in",
	}, "Saturation")
	var val_id := _add_node(doc, "subgraph/input", Vector2(40, 260), {
		"input_name": "Value",
		"input_type": "float",
		"port_id": "val_in",
	}, "Value")
	var append_id := _add_node(doc, "swizzle/append_vec3", Vector2(320, 150))
	var hsv_id := _add_node(doc, "color/hsv_to_rgb", Vector2(600, 150))
	var out_id := _add_node(doc, "subgraph/output", Vector2(880, 170), {
		"output_name": "RGB",
		"output_type": "vec3",
		"port_id": "rgb_out",
	}, "RGB")

	doc.add_edge(hue_id, "value", append_id, "x")
	doc.add_edge(sat_id, "value", append_id, "y")
	doc.add_edge(val_id, "value", append_id, "z")
	doc.add_edge(append_id, "result", hsv_id, "hsv")
	doc.add_edge(hsv_id, "rgb", out_id, "value")
	return doc


func _make_spatial_triplanar_rim() -> ShaderGraphDocument:
	var doc := ShaderGraphDocument.new()
	_configure_graph(doc, "Spatial Triplanar Rim", "spatial")

	var tex_id := _add_node(doc, "parameter/texture2d", Vector2(60, 80), {
		"param_name": "albedo_tex",
	}, "Albedo Texture")
	var blend_id := _add_node(doc, "parameter/float", Vector2(60, 190), {
		"param_name": "blend_sharpness",
		"default_value": "6.0",
	}, "Blend Sharpness")
	var roughness_id := _add_node(doc, "parameter/float", Vector2(60, 300), {
		"param_name": "roughness_amount",
		"default_value": "0.35",
	}, "Roughness")
	var rim_color_id := _add_node(doc, "parameter/color", Vector2(60, 420), {
		"param_name": "rim_color",
		"default_value": "vec4(0.1, 0.7, 1.0, 1.0)",
	}, "Rim Color")
	var rim_power_id := _add_node(doc, "parameter/float", Vector2(60, 530), {
		"param_name": "rim_power",
		"default_value": "4.5",
	}, "Rim Power")
	var wave_speed_id := _add_node(doc, "parameter/float", Vector2(60, 760), {
		"param_name": "wave_speed",
		"default_value": "1.5",
	}, "Wave Speed", "vertex")
	var wave_amp_id := _add_node(doc, "parameter/float", Vector2(60, 870), {
		"param_name": "wave_amplitude",
		"default_value": "0.15",
	}, "Wave Amplitude", "vertex")

	var world_pos_id := _add_node(doc, "input/world_position", Vector2(320, 80))
	var world_normal_id := _add_node(doc, "surface/world_normal", Vector2(320, 220))
	var triplanar_id := _add_node(doc, "effects/triplanar", Vector2(640, 130))
	var view_dir_id := _add_node(doc, "input/view_direction", Vector2(320, 420))
	var fresnel_id := _add_node(doc, "effects/fresnel", Vector2(640, 410))
	var rim_rgb_id := _add_node(doc, "color/color_to_vec3", Vector2(330, 560))
	var emission_id := _add_node(doc, "vector/lerp", Vector2(940, 470))
	var spatial_out_id := _add_node(doc, "output/spatial", Vector2(1280, 250))

	var local_pos_id := _add_node(doc, "surface/vertex_position_local", Vector2(320, 760), {}, "", "vertex")
	var add_xz_id := _add_node(doc, "math/add", Vector2(560, 760), {}, "", "vertex")
	var time_scaled_id := _add_node(doc, "input/time_scaled", Vector2(320, 900), {}, "", "vertex")
	var phase_id := _add_node(doc, "math/add", Vector2(790, 820), {}, "", "vertex")
	var sin_id := _add_node(doc, "trig/sin", Vector2(1020, 820), {}, "", "vertex")
	var amp_id := _add_node(doc, "math/multiply", Vector2(1220, 820), {}, "", "vertex")
	var offset_id := _add_node(doc, "swizzle/append_vec3", Vector2(1460, 820), {}, "", "vertex")
	var vertex_out_id := _add_node(doc, "output/vertex_offset", Vector2(1700, 820))

	doc.add_edge(tex_id, "value", triplanar_id, "tex")
	doc.add_edge(blend_id, "value", triplanar_id, "blend")
	doc.add_edge(world_pos_id, "pos", triplanar_id, "world_pos")
	doc.add_edge(world_normal_id, "normal", triplanar_id, "normal")
	doc.add_edge(triplanar_id, "rgb", spatial_out_id, "albedo")
	doc.add_edge(roughness_id, "value", spatial_out_id, "roughness")

	doc.add_edge(view_dir_id, "dir", fresnel_id, "view")
	doc.add_edge(world_normal_id, "normal", fresnel_id, "normal")
	doc.add_edge(rim_power_id, "value", fresnel_id, "power")
	doc.add_edge(rim_color_id, "value", rim_rgb_id, "color")
	doc.add_edge(rim_rgb_id, "rgb", emission_id, "b")
	doc.add_edge(fresnel_id, "result", emission_id, "t")
	doc.add_edge(emission_id, "result", spatial_out_id, "emission")

	doc.add_edge(local_pos_id, "x", add_xz_id, "a")
	doc.add_edge(local_pos_id, "z", add_xz_id, "b")
	doc.add_edge(wave_speed_id, "value", time_scaled_id, "speed")
	doc.add_edge(add_xz_id, "result", phase_id, "a")
	doc.add_edge(time_scaled_id, "result", phase_id, "b")
	doc.add_edge(phase_id, "result", sin_id, "x")
	doc.add_edge(sin_id, "result", amp_id, "a")
	doc.add_edge(wave_amp_id, "value", amp_id, "b")
	doc.add_edge(amp_id, "result", offset_id, "y")
	doc.add_edge(offset_id, "result", vertex_out_id, "offset")

	return doc


func _make_fullscreen_posterized_glitch() -> ShaderGraphDocument:
	var doc := ShaderGraphDocument.new()
	_configure_graph(doc, "Fullscreen Posterized Glitch", "fullscreen")

	var hue_id := _add_node(doc, "parameter/float", Vector2(60, 70), {
		"param_name": "hue_amount",
		"default_value": "0.08",
	}, "Hue Shift")
	var contrast_id := _add_node(doc, "parameter/float", Vector2(60, 180), {
		"param_name": "contrast_amount",
		"default_value": "1.4",
	}, "Contrast")
	var steps_id := _add_node(doc, "parameter/float", Vector2(60, 290), {
		"param_name": "posterize_steps",
		"default_value": "5.0",
	}, "Posterize Steps")
	var palette_hue_id := _add_node(doc, "parameter/float", Vector2(60, 540), {
		"param_name": "palette_hue",
		"default_value": "0.92",
	}, "Palette Hue")
	var palette_sat_id := _add_node(doc, "parameter/float", Vector2(60, 650), {
		"param_name": "palette_saturation",
		"default_value": "0.95",
	}, "Palette Saturation")
	var palette_val_id := _add_node(doc, "parameter/float", Vector2(60, 760), {
		"param_name": "palette_value",
		"default_value": "0.85",
	}, "Palette Value")

	var screen_id := _add_node(doc, "input/screen_texture", Vector2(320, 70))
	var hue_shift_id := _add_node(doc, "image/hue_shift", Vector2(600, 70))
	var contrast_fx_id := _add_node(doc, "image/simple_contrast", Vector2(860, 70))
	var posterize_id := _add_node(doc, "image/posterize", Vector2(1130, 70))
	var grayscale_id := _add_node(doc, "image/grayscale", Vector2(610, 300))
	var frag_coord_id := _add_node(doc, "input/frag_coord", Vector2(330, 420))
	var dither_id := _add_node(doc, "effects/dither", Vector2(900, 350))
	var palette_id := _add_palette_subgraph_node(doc, Vector2(620, 620))
	var lerp_id := _add_node(doc, "vector/lerp", Vector2(1180, 280))
	var out_id := _add_node(doc, "output/fullscreen", Vector2(1450, 260))

	doc.add_edge(screen_id, "rgb", hue_shift_id, "color")
	doc.add_edge(hue_id, "value", hue_shift_id, "shift")
	doc.add_edge(hue_shift_id, "result", contrast_fx_id, "color")
	doc.add_edge(contrast_id, "value", contrast_fx_id, "contrast")
	doc.add_edge(contrast_fx_id, "result", posterize_id, "color")
	doc.add_edge(steps_id, "value", posterize_id, "steps")

	doc.add_edge(screen_id, "rgb", grayscale_id, "color")
	doc.add_edge(frag_coord_id, "pos", dither_id, "screen_pos")
	doc.add_edge(grayscale_id, "result", dither_id, "value")

	doc.add_edge(palette_hue_id, "value", palette_id, "hue_in")
	doc.add_edge(palette_sat_id, "value", palette_id, "sat_in")
	doc.add_edge(palette_val_id, "value", palette_id, "val_in")

	doc.add_edge(posterize_id, "result", lerp_id, "a")
	doc.add_edge(palette_id, "rgb_out", lerp_id, "b")
	doc.add_edge(dither_id, "result", lerp_id, "t")
	doc.add_edge(lerp_id, "result", out_id, "color")

	return doc


func _make_particles_orbit_burst() -> ShaderGraphDocument:
	var doc := ShaderGraphDocument.new()
	_configure_graph(doc, "Particles Orbit Burst", "particles")

	var orbit_speed_id := _add_node(doc, "parameter/float", Vector2(60, 70), {
		"param_name": "orbit_speed",
		"default_value": "2.0",
	}, "Orbit Speed")
	var orbit_strength_id := _add_node(doc, "parameter/float", Vector2(60, 180), {
		"param_name": "orbit_strength",
		"default_value": "2.5",
	}, "Orbit Strength")
	var upward_id := _add_node(doc, "parameter/float", Vector2(60, 290), {
		"param_name": "upward_speed",
		"default_value": "1.25",
	}, "Upward Speed")
	var hue_bias_id := _add_node(doc, "parameter/float", Vector2(60, 540), {
		"param_name": "hue_bias",
		"default_value": "0.15",
	}, "Hue Bias")
	var sat_id := _add_node(doc, "parameter/float", Vector2(60, 650), {
		"param_name": "particle_saturation",
		"default_value": "0.95",
	}, "Particle Saturation")
	var val_id := _add_node(doc, "parameter/float", Vector2(60, 760), {
		"param_name": "particle_value",
		"default_value": "1.0",
	}, "Particle Value")

	var rand_id := _add_node(doc, "input/particles_random", Vector2(330, 60))
	var index_id := _add_node(doc, "input/particles_index", Vector2(330, 180))
	var time_scaled_id := _add_node(doc, "input/time_scaled", Vector2(330, 300))
	var phase_x_id := _add_node(doc, "math/add", Vector2(580, 90))
	var sin_id := _add_node(doc, "trig/sin", Vector2(820, 90))
	var vel_x_id := _add_node(doc, "math/multiply", Vector2(1040, 90))
	var phase_z_id := _add_node(doc, "math/add", Vector2(580, 220))
	var cos_id := _add_node(doc, "trig/cos", Vector2(820, 220))
	var vel_z_id := _add_node(doc, "math/multiply", Vector2(1040, 220))
	var velocity_id := _add_node(doc, "swizzle/append_vec3", Vector2(1290, 170))

	var hue_base_id := _add_node(doc, "math/add", Vector2(590, 560))
	var hue_anim_id := _add_node(doc, "math/add", Vector2(840, 560))
	var hue_wrap_id := _add_node(doc, "math/fract", Vector2(1070, 560))
	var palette_id := _add_palette_subgraph_node(doc, Vector2(1330, 620))
	var color_id := _add_node(doc, "color/vec3_to_color", Vector2(1600, 640))
	var out_id := _add_node(doc, "output/particles", Vector2(1870, 370))

	doc.add_edge(orbit_speed_id, "value", time_scaled_id, "speed")
	doc.add_edge(rand_id, "rand", phase_x_id, "a")
	doc.add_edge(time_scaled_id, "result", phase_x_id, "b")
	doc.add_edge(phase_x_id, "result", sin_id, "x")
	doc.add_edge(sin_id, "result", vel_x_id, "a")
	doc.add_edge(orbit_strength_id, "value", vel_x_id, "b")

	doc.add_edge(index_id, "index", phase_z_id, "a")
	doc.add_edge(time_scaled_id, "result", phase_z_id, "b")
	doc.add_edge(phase_z_id, "result", cos_id, "x")
	doc.add_edge(cos_id, "result", vel_z_id, "a")
	doc.add_edge(orbit_strength_id, "value", vel_z_id, "b")

	doc.add_edge(vel_x_id, "result", velocity_id, "x")
	doc.add_edge(upward_id, "value", velocity_id, "y")
	doc.add_edge(vel_z_id, "result", velocity_id, "z")
	doc.add_edge(velocity_id, "result", out_id, "velocity")

	doc.add_edge(rand_id, "rand", hue_base_id, "a")
	doc.add_edge(hue_bias_id, "value", hue_base_id, "b")
	doc.add_edge(hue_base_id, "result", hue_anim_id, "a")
	doc.add_edge(time_scaled_id, "result", hue_anim_id, "b")
	doc.add_edge(hue_anim_id, "result", hue_wrap_id, "x")

	doc.add_edge(hue_wrap_id, "result", palette_id, "hue_in")
	doc.add_edge(sat_id, "value", palette_id, "sat_in")
	doc.add_edge(val_id, "value", palette_id, "val_in")
	doc.add_edge(palette_id, "rgb_out", color_id, "rgb")
	doc.add_edge(color_id, "color", out_id, "color")

	return doc
