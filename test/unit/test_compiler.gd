## Integration tests for ShaderGraphCompiler — end-to-end GLSL generation.
## Each test verifies structural and semantic properties of the emitted shader.
extends TestCase


var compiler: ShaderGraphCompiler


func before_all() -> void:
	# NodeRegistry must be registered as an Engine singleton for compile_gd().
	if Engine.get_singleton("NodeRegistry") == null:
		var reg := NodeRegistry.new()
		StdlibRegistration.register_all(reg)
		Engine.register_singleton("NodeRegistry", reg)


func setup() -> void:
	compiler = ShaderGraphCompiler.new()


# ---- Helper ----

func _strip_banner(code: String) -> String:
	# Remove the generated file header (lines starting with "// ===..." block).
	var lines := code.split("\n")
	var start := 0
	for i in lines.size():
		if lines[i].begins_with("shader_type"):
			start = i
			break
	return "\n".join(lines.slice(start))


# ---- Spatial domain ----

func test_spatial_basic_succeeds() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_name("Test")
	doc.set_shader_domain("spatial")
	var add_id := doc.add_node("math/add", Vector2.ZERO)
	var mul_id := doc.add_node("math/multiply", Vector2(200, 0))
	var out_id := doc.add_node("output/spatial", Vector2(400, 0))
	doc.add_edge(add_id, "result", mul_id, "a")
	doc.add_edge(mul_id, "result", out_id, "roughness")
	var result := compiler.compile_gd(doc)
	assert_true(result["success"])


func test_spatial_shader_type_line() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_name("Test")
	doc.set_shader_domain("spatial")
	doc.add_node("output/spatial", Vector2.ZERO)
	var result := compiler.compile_gd(doc)
	assert_contains(result["shader_code"], "shader_type spatial;")


func test_spatial_has_fragment_function() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_name("Test")
	doc.set_shader_domain("spatial")
	doc.add_node("output/spatial", Vector2.ZERO)
	var result := compiler.compile_gd(doc)
	assert_contains(result["shader_code"], "void fragment()")


func test_spatial_no_vertex_when_no_vertex_nodes() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_name("Test")
	doc.set_shader_domain("spatial")
	doc.add_node("output/spatial", Vector2.ZERO)
	var result := compiler.compile_gd(doc)
	assert_not_contains(result["shader_code"], "void vertex()")


func test_spatial_has_vertex_function_when_vertex_offset_present() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_name("Test")
	doc.set_shader_domain("spatial")
	doc.add_node("output/spatial", Vector2.ZERO)
	doc.add_node("output/vertex_offset", Vector2(200, 0))
	var result := compiler.compile_gd(doc)
	assert_contains(result["shader_code"], "void vertex()")


func test_spatial_vertex_to_fragment_connection_emits_varying() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_name("Varying")
	doc.set_shader_domain("spatial")
	var world_pos_id := doc.add_node("input/world_position", Vector2.ZERO)
	var out_id := doc.add_node("output/spatial", Vector2(220, 0))
	doc.add_edge(world_pos_id, "pos", out_id, "albedo")
	var result := compiler.compile_gd(doc)

	assert_true(result["success"])
	assert_contains(result["shader_code"], "varying vec3 _v0;")
	assert_contains(result["shader_code"], "_v0 = _t0;")
	assert_contains(result["shader_code"], "ALBEDO = _v0;")


func test_spatial_add_multiply_contains_operations() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_name("Test")
	doc.set_shader_domain("spatial")
	var add_id := doc.add_node("math/add", Vector2.ZERO)
	var mul_id := doc.add_node("math/multiply", Vector2(200, 0))
	var out_id := doc.add_node("output/spatial", Vector2(400, 0))
	doc.add_edge(add_id, "result", mul_id, "a")
	doc.add_edge(mul_id, "result", out_id, "roughness")
	var result := compiler.compile_gd(doc)
	var code: String = _strip_banner(result["shader_code"])
	assert_contains(code, " + ")
	assert_contains(code, " * ")
	assert_contains(code, "ROUGHNESS =")


func test_spatial_output_assigns_pbr_builtins() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_name("Test")
	doc.set_shader_domain("spatial")
	doc.add_node("output/spatial", Vector2.ZERO)
	var result := compiler.compile_gd(doc)
	var code: String = result["shader_code"]
	assert_contains(code, "ALBEDO =")
	assert_contains(code, "ROUGHNESS =")
	assert_contains(code, "METALLIC =")
	assert_contains(code, "ALPHA =")


# ---- Canvas Item domain ----

func test_canvas_item_shader_type() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_name("Test")
	doc.set_shader_domain("canvas_item")
	doc.add_node("output/canvas_item", Vector2.ZERO)
	var result := compiler.compile_gd(doc)
	assert_true(result["success"])
	assert_contains(result["shader_code"], "shader_type canvas_item;")


func test_canvas_item_has_fragment() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_name("Test")
	doc.set_shader_domain("canvas_item")
	doc.add_node("output/canvas_item", Vector2.ZERO)
	var result := compiler.compile_gd(doc)
	assert_contains(result["shader_code"], "void fragment()")


func test_canvas_item_assigns_color() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_name("Test")
	doc.set_shader_domain("canvas_item")
	doc.add_node("output/canvas_item", Vector2.ZERO)
	var result := compiler.compile_gd(doc)
	assert_contains(result["shader_code"], "COLOR =")


# ---- Particles domain ----

func test_particles_has_process_function() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_name("Test")
	doc.set_shader_domain("particles")
	doc.add_node("output/particles", Vector2.ZERO)
	var result := compiler.compile_gd(doc)
	assert_true(result["success"])
	assert_contains(result["shader_code"], "void process()")
	assert_contains(result["shader_code"], "shader_type particles;")


# ---- Sky domain ----

func test_sky_has_sky_function() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_name("Test")
	doc.set_shader_domain("sky")
	doc.add_node("output/sky", Vector2.ZERO)
	var result := compiler.compile_gd(doc)
	assert_true(result["success"])
	assert_contains(result["shader_code"], "void sky()")
	assert_contains(result["shader_code"], "shader_type sky;")


# ---- Fog domain ----

func test_fog_has_fog_function() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_name("Test")
	doc.set_shader_domain("fog")
	doc.add_node("output/fog", Vector2.ZERO)
	var result := compiler.compile_gd(doc)
	assert_true(result["success"])
	assert_contains(result["shader_code"], "void fog()")
	assert_contains(result["shader_code"], "shader_type fog;")


# ---- Fullscreen domain ----

func test_fullscreen_compiles_as_canvas_item() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_name("Test")
	doc.set_shader_domain("fullscreen")
	doc.add_node("output/fullscreen", Vector2.ZERO)
	var result := compiler.compile_gd(doc)
	assert_true(result["success"])
	assert_contains(result["shader_code"], "shader_type canvas_item;")


# ---- Error cases ----

func test_compile_fails_without_registry() -> void:
	# Temporarily unregister to test the null-registry guard.
	var reg = Engine.get_singleton("NodeRegistry")
	Engine.unregister_singleton("NodeRegistry")
	var doc := ShaderGraphDocument.new()
	doc.set_name("Test")
	doc.set_shader_domain("spatial")
	doc.add_node("output/spatial", Vector2.ZERO)
	var result := compiler.compile_gd(doc)
	assert_false(result["success"])
	# Restore
	Engine.register_singleton("NodeRegistry", reg)


func test_subgraph_domain_cannot_be_compiled_directly() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_name("Test")
	doc.set_shader_domain("subgraph")
	var result := compiler.compile_gd(doc)
	assert_false(result["success"])
	assert_true(_has_code(result["issues"], "E101"))


func test_unsupported_domain_returns_error() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_name("Test")
	doc.set_shader_domain("fantasy_domain")
	var result := compiler.compile_gd(doc)
	assert_false(result["success"])
	assert_true(_has_code(result["issues"], "E100"))


func test_missing_output_node_fails() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_name("Test")
	doc.set_shader_domain("spatial")
	# No output node → validation should fail
	var result := compiler.compile_gd(doc)
	assert_false(result["success"])


func test_fragment_to_vertex_connection_fails_validation() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_name("BadStages")
	doc.set_shader_domain("spatial")
	var view_id := doc.add_node("input/view_direction", Vector2.ZERO)
	var vert_id := doc.add_node("output/vertex_offset", Vector2(220, 0))
	doc.add_node("output/spatial", Vector2(440, 0))
	doc.add_edge(view_id, "dir", vert_id, "offset")
	var result := compiler.compile_gd(doc)
	assert_false(result["success"])
	assert_true(_has_code(result["issues"], "E014"))


# ---- Uniforms ----

func test_parameter_float_emits_uniform() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_name("Test")
	doc.set_shader_domain("spatial")
	var pid := doc.add_node("parameter/float", Vector2.ZERO)
	doc.get_node(pid).set_property("param_name", "roughness_val")
	var out_id := doc.add_node("output/spatial", Vector2(200, 0))
	doc.add_edge(pid, "value", out_id, "roughness")
	var result := compiler.compile_gd(doc)
	assert_true(result["success"])
	assert_contains(result["shader_code"], "uniform float roughness_val")


func test_parameter_vec4_emits_vec4_uniform() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_name("Test")
	doc.set_shader_domain("spatial")
	var pid := doc.add_node("parameter/vec4", Vector2.ZERO)
	doc.get_node(pid).set_property("param_name", "tint_color")
	doc.add_node("output/spatial", Vector2(200, 0))
	var result := compiler.compile_gd(doc)
	assert_true(result["success"])
	assert_contains(result["shader_code"], "uniform vec4 tint_color")


func test_uniforms_emitted_in_sorted_order() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_name("Test")
	doc.set_shader_domain("spatial")
	var p1 := doc.add_node("parameter/float", Vector2.ZERO)
	var p2 := doc.add_node("parameter/float", Vector2(100, 0))
	doc.get_node(p1).set_property("param_name", "z_param")
	doc.get_node(p2).set_property("param_name", "a_param")
	doc.add_node("output/spatial", Vector2(300, 0))
	var result := compiler.compile_gd(doc)
	var code: String = result["shader_code"]
	var z_pos: int = code.find("z_param")
	var a_pos: int = code.find("a_param")
	assert_gt(z_pos, a_pos, "uniforms should be sorted: a_param before z_param")


# ---- Output determinism ----

func test_compile_is_deterministic() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_name("Det")
	doc.set_shader_domain("spatial")
	var a := doc.add_node("math/add", Vector2.ZERO)
	var b := doc.add_node("math/multiply", Vector2(200, 0))
	var o := doc.add_node("output/spatial", Vector2(400, 0))
	doc.add_edge(a, "result", b, "a")
	doc.add_edge(b, "result", o, "roughness")
	var r1 := compiler.compile_gd(doc)
	var r2 := compiler.compile_gd(doc)
	assert_eq(r1["shader_code"], r2["shader_code"])


# ---- Helper ----

func _has_code(issues: Array, code: String) -> bool:
	for issue in issues:
		if (issue as Dictionary)["code"] == code:
			return true
	return false
