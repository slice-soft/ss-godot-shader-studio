extends TestCase


var compiler: ShaderGraphCompiler


func before_all() -> void:
	if Engine.get_singleton("NodeRegistry") == null:
		var reg := NodeRegistry.new()
		StdlibRegistration.register_all(reg)
		Engine.register_singleton("NodeRegistry", reg)


func setup() -> void:
	compiler = ShaderGraphCompiler.new()


func test_spatial_example_graph_compiles() -> void:
	var serializer := GraphSerializer.new()
	var doc := serializer.load("res://shaders/examples/spatial_triplanar_rim.gshadergraph")
	assert_not_null(doc)
	var result := compiler.compile_gd(doc, "res://shaders/examples/spatial_triplanar_rim.gshadergraph")
	assert_true(result["success"])
	assert_contains(result["shader_code"], "varying vec3 _v0;")
	assert_contains(result["shader_code"], "_sgs_triplanar")
	assert_contains(result["shader_code"], "EMISSION =")


func test_fullscreen_example_graph_compiles() -> void:
	var serializer := GraphSerializer.new()
	var doc := serializer.load("res://shaders/examples/fullscreen_posterized_glitch.gshadergraph")
	assert_not_null(doc)
	var result := compiler.compile_gd(doc, "res://shaders/examples/fullscreen_posterized_glitch.gshadergraph")
	assert_true(result["success"])
	assert_contains(result["shader_code"], "shader_type canvas_item;")
	assert_contains(result["shader_code"], "_sgs_screen_tex")
	assert_contains(result["shader_code"], "_sgs_dither")


func test_particles_example_graph_compiles() -> void:
	var serializer := GraphSerializer.new()
	var doc := serializer.load("res://shaders/examples/particles_orbit_burst.gshadergraph")
	assert_not_null(doc)
	var result := compiler.compile_gd(doc, "res://shaders/examples/particles_orbit_burst.gshadergraph")
	assert_true(result["success"])
	assert_contains(result["shader_code"], "shader_type particles;")
	assert_contains(result["shader_code"], "VELOCITY =")
	assert_contains(result["shader_code"], "node_20_sg__")
