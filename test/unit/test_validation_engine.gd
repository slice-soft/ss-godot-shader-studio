## Unit tests for ValidationEngine — all five validation passes.
extends TestCase


var registry: NodeRegistry
var engine: ValidationEngine


func before_all() -> void:
	registry = NodeRegistry.new()
	StdlibRegistration.register_all(registry)


func after_all() -> void:
	registry.free()


func setup() -> void:
	engine = ValidationEngine.new()


# ---- Helper: build a minimal valid spatial document ----

func _make_spatial_doc() -> ShaderGraphDocument:
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("spatial")
	doc.add_node("output/spatial", Vector2.ZERO)
	return doc


# ---- Pass 1: Structural ----

func test_valid_doc_passes_structural() -> void:
	var doc := _make_spatial_doc()
	var result := engine.validate(doc, registry)
	assert_true(result["success"])


func test_unknown_definition_id_is_error() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("spatial")
	doc.add_node("does_not_exist/node", Vector2.ZERO)
	var result := engine.validate(doc, registry)
	assert_false(result["success"])
	assert_true(_has_code(result["issues"], "E003"))


func test_edge_referencing_missing_node_is_error() -> void:
	var doc := _make_spatial_doc()
	var add_id := doc.add_node("math/add", Vector2.ZERO)
	# Manually create a bad edge (references a non-existent from_node).
	var bad_edge := ShaderGraphEdge.new()
	bad_edge.id = "edge_bad"
	bad_edge.from_node_id = "ghost_node"
	bad_edge.from_port_id = "result"
	bad_edge.to_node_id = add_id
	bad_edge.to_port_id = "a"
	doc.get_edges().append(bad_edge)
	var result := engine.validate(doc, registry)
	assert_false(result["success"])
	assert_true(_has_code(result["issues"], "E006"))


# ---- Pass 2: Typing ----

func test_compatible_connection_passes_typing() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("spatial")
	var add_id := doc.add_node("math/add", Vector2.ZERO)
	var out_id := doc.add_node("output/spatial", Vector2.ZERO)
	# FLOAT → FLOAT (roughness port)
	doc.add_edge(add_id, "result", out_id, "roughness")
	var result := engine.validate(doc, registry)
	assert_true(result["success"])


func test_incompatible_connection_is_error() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("spatial")
	var add_id := doc.add_node("math/add", Vector2.ZERO)  # outputs FLOAT
	var out_id := doc.add_node("output/spatial", Vector2.ZERO)
	# FLOAT → VEC3 (albedo port) is a splat (compatible — should pass)
	doc.add_edge(add_id, "result", out_id, "albedo")
	var result := engine.validate(doc, registry)
	assert_true(result["success"])


func test_truncation_produces_warning_not_error() -> void:
	# Connect vertex_color (COLOR/VEC4) → output/spatial albedo (VEC3): IMPLICIT_TRUNCATE
	# This should produce W001 warning but NOT block success.
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("spatial")
	var vc_id  := doc.add_node("input/vertex_color", Vector2.ZERO)  # COLOR = VEC4
	var out_id := doc.add_node("output/spatial", Vector2(200, 0))
	doc.add_edge(vc_id, "color", out_id, "albedo")  # VEC4 → VEC3 truncation
	var result := engine.validate(doc, registry)
	assert_true(result["success"])
	assert_true(_has_code(result["issues"], "W001"))


# ---- Pass 3: Stage ----

func test_wrong_stage_scope_is_error() -> void:
	# Mark an output/spatial node (fragment-only) as vertex — should be an error.
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("spatial")
	var out_id := doc.add_node("output/spatial", Vector2.ZERO)
	var out_node := doc.get_node(out_id)
	out_node.stage_scope = "vertex"  # output/spatial does NOT support vertex
	var result := engine.validate(doc, registry)
	assert_false(result["success"])
	assert_true(_has_code(result["issues"], "E011"))


# ---- Pass 4: Cycle detection ----

func test_cycle_is_error() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("spatial")
	var a := doc.add_node("math/add", Vector2.ZERO)
	var b := doc.add_node("math/multiply", Vector2.ZERO)
	doc.add_node("output/spatial", Vector2.ZERO)
	# Create cycle: a→b, b→a
	doc.add_edge(a, "result", b, "a")
	doc.add_edge(b, "result", a, "b")
	var result := engine.validate(doc, registry)
	assert_false(result["success"])
	assert_true(_has_code(result["issues"], "E020"))


func test_no_cycle_passes() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("spatial")
	var a := doc.add_node("math/add", Vector2.ZERO)
	var b := doc.add_node("math/multiply", Vector2.ZERO)
	var out := doc.add_node("output/spatial", Vector2.ZERO)
	doc.add_edge(a, "result", b, "a")
	doc.add_edge(b, "result", out, "roughness")
	var result := engine.validate(doc, registry)
	assert_true(result["success"])


# ---- Pass 5: Output node presence ----

func test_missing_output_node_is_error() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("spatial")
	doc.add_node("math/add", Vector2.ZERO)
	# No output/spatial node
	var result := engine.validate(doc, registry)
	assert_false(result["success"])
	assert_true(_has_code(result["issues"], "E030"))


func test_canvas_item_requires_canvas_output() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("canvas_item")
	doc.add_node("math/add", Vector2.ZERO)
	# No output/canvas_item — E030
	var result := engine.validate(doc, registry)
	assert_false(result["success"])
	assert_true(_has_code(result["issues"], "E030"))


func test_subgraph_domain_skips_output_check() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("subgraph")
	doc.add_node("math/add", Vector2.ZERO)
	# No output node, but domain=subgraph → should pass (no E030)
	var result := engine.validate(doc, registry)
	assert_true(result["success"])


# ---- Helper ----

func _has_code(issues: Array, code: String) -> bool:
	for issue in issues:
		if issue["code"] == code:
			return true
	return false
