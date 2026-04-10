## Unit tests for IRBuilder — topological sort, variable assignment, stage routing.
extends TestCase


var registry: NodeRegistry


func before_all() -> void:
	registry = NodeRegistry.new()
	StdlibRegistration.register_all(registry)


# ---- Helper: minimal spatial graph ----

func _make_spatial_graph() -> ShaderGraphDocument:
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("spatial")
	var add_id := doc.add_node("math/add", Vector2.ZERO)
	var mul_id := doc.add_node("math/multiply", Vector2(200, 0))
	var out_id := doc.add_node("output/spatial", Vector2(400, 0))
	doc.add_edge(add_id, "result", mul_id, "a")
	doc.add_edge(mul_id, "result", out_id, "roughness")
	return doc


# ---- IR structure ----

func test_ir_has_required_keys() -> void:
	var doc := _make_spatial_graph()
	var ir := IRBuilder.build(doc, registry)
	assert_true(ir.has("shader_domain"))
	assert_true(ir.has("uniforms"))
	assert_true(ir.has("varyings"))
	assert_true(ir.has("helper_functions"))
	assert_true(ir.has("vertex_nodes"))
	assert_true(ir.has("fragment_nodes"))


func test_shader_domain_preserved() -> void:
	var doc := _make_spatial_graph()
	var ir := IRBuilder.build(doc, registry)
	assert_eq(ir["shader_domain"], "spatial")


# ---- Fragment vs vertex routing ----

func test_spatial_output_goes_to_fragment() -> void:
	var doc := _make_spatial_graph()
	var ir := IRBuilder.build(doc, registry)
	# All nodes in this graph are fragment-stage
	assert_eq(ir["vertex_nodes"].size(), 0)
	assert_eq(ir["fragment_nodes"].size(), 3)  # add, multiply, output


func test_vertex_offset_goes_to_vertex_stage() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("spatial")
	doc.add_node("output/spatial", Vector2.ZERO)
	var vert_id := doc.add_node("output/vertex_offset", Vector2(200, 0))
	# output/vertex_offset has STAGE_VERTEX — should land in vertex_nodes
	var ir := IRBuilder.build(doc, registry)
	assert_eq(ir["vertex_nodes"].size(), 1)
	assert_eq((ir["vertex_nodes"][0] as Dictionary)["definition_id"], "output/vertex_offset")


# ---- Variable naming ----

func test_output_vars_assigned_to_fragment_nodes() -> void:
	var doc := _make_spatial_graph()
	var ir := IRBuilder.build(doc, registry)
	var fnodes: Array = ir["fragment_nodes"]
	# First two nodes (add, multiply) should have output vars
	var add_node: Dictionary = fnodes[0]
	var mul_node: Dictionary = fnodes[1]
	assert_false(add_node["output_vars"].is_empty())
	assert_false(mul_node["output_vars"].is_empty())


func test_connected_input_resolved_to_upstream_var() -> void:
	var doc := _make_spatial_graph()
	var ir := IRBuilder.build(doc, registry)
	var fnodes: Array = ir["fragment_nodes"]
	# multiply.a should receive the var_name of add.result
	var add_node: Dictionary  = fnodes[0]
	var mul_node: Dictionary  = fnodes[1]
	var add_result_var: String = (add_node["output_vars"]["result"] as Dictionary)["var_name"]
	var mul_a_var: String      = (mul_node["resolved_inputs"]["a"] as Dictionary)["var_name"]
	assert_eq(mul_a_var, add_result_var)


func test_unconnected_input_uses_default() -> void:
	var doc := _make_spatial_graph()
	var ir := IRBuilder.build(doc, registry)
	var fnodes: Array = ir["fragment_nodes"]
	# add.a and add.b are not connected — should fall back to default "0.0"
	var add_node: Dictionary = fnodes[0]
	var a_var: String = (add_node["resolved_inputs"]["a"] as Dictionary)["var_name"]
	var b_var: String = (add_node["resolved_inputs"]["b"] as Dictionary)["var_name"]
	assert_eq(a_var, "0.0")
	assert_eq(b_var, "0.0")


# ---- Topological order ----

func test_topo_order_respected() -> void:
	# In the Add→Multiply→Output chain, add must appear before multiply.
	var doc := _make_spatial_graph()
	var ir := IRBuilder.build(doc, registry)
	var fnodes: Array = ir["fragment_nodes"]
	var def_ids := fnodes.map(func(n): return n["definition_id"])
	assert_true(def_ids.find("math/add") < def_ids.find("math/multiply"))
	assert_true(def_ids.find("math/multiply") < def_ids.find("output/spatial"))


# ---- Parameter nodes (uniforms) ----

func test_parameter_node_adds_uniform() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("spatial")
	var param_id := doc.add_node("parameter/float", Vector2.ZERO)
	var param_node := doc.get_node(param_id)
	param_node.set_property("param_name", "my_roughness")
	doc.add_node("output/spatial", Vector2.ZERO)
	var ir := IRBuilder.build(doc, registry)
	assert_eq(ir["uniforms"].size(), 1)
	assert_eq((ir["uniforms"][0] as Dictionary)["name"], "my_roughness")


func test_duplicate_parameter_name_only_one_uniform() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("spatial")
	for _i in 3:
		var pid := doc.add_node("parameter/float", Vector2.ZERO)
		doc.get_node(pid).set_property("param_name", "shared_param")
	doc.add_node("output/spatial", Vector2.ZERO)
	var ir := IRBuilder.build(doc, registry)
	assert_eq(ir["uniforms"].size(), 1)


# ---- Type casts in IR ----

func test_float_to_vec3_generates_splat_in_var_name() -> void:
	# Connect math/add (FLOAT output) to output/spatial albedo (VEC3 input).
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("spatial")
	var add_id := doc.add_node("math/add", Vector2.ZERO)
	var out_id := doc.add_node("output/spatial", Vector2(200, 0))
	doc.add_edge(add_id, "result", out_id, "albedo")  # FLOAT → VEC3 (splat)
	var ir := IRBuilder.build(doc, registry)
	var out_node: Dictionary = ir["fragment_nodes"].back()
	var albedo_var: String = (out_node["resolved_inputs"]["albedo"] as Dictionary)["var_name"]
	# Should be wrapped: "vec3(_t0)"
	assert_contains(albedo_var, "vec3(")


func test_vec4_to_vec3_generates_swizzle() -> void:
	# input/vertex_color outputs COLOR (VEC4 base) → output/spatial albedo (VEC3) → truncate .xyz
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("spatial")
	var vc_id  := doc.add_node("input/vertex_color", Vector2.ZERO)  # COLOR/VEC4 output
	var out_id := doc.add_node("output/spatial", Vector2(200, 0))
	doc.add_edge(vc_id, "color", out_id, "albedo")  # VEC4 → VEC3 (truncate .xyz)
	var ir := IRBuilder.build(doc, registry)
	var out_node: Dictionary = ir["fragment_nodes"].back()
	var albedo_var: String = (out_node["resolved_inputs"]["albedo"] as Dictionary)["var_name"]
	assert_contains(albedo_var, ".xyz")
