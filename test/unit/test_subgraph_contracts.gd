extends TestCase

const SubgraphContract = preload("res://addons/ss_godot_shader_studio/core/graph/subgraph_contract.gd")


const _TMP_DIR := "res://test/.tmp_subgraph_contracts"

var compiler: ShaderGraphCompiler
var registry: NodeRegistry
var validator: ValidationEngine
var _owns_registry := false


func before_all() -> void:
	if Engine.get_singleton("NodeRegistry") != null:
		registry = Engine.get_singleton("NodeRegistry") as NodeRegistry
	else:
		registry = NodeRegistry.new()
		StdlibRegistration.register_all(registry)
		Engine.register_singleton("NodeRegistry", registry)
		_owns_registry = true


func after_all() -> void:
	if _owns_registry:
		Engine.unregister_singleton("NodeRegistry")
		registry.free()


func setup() -> void:
	compiler = ShaderGraphCompiler.new()
	validator = ValidationEngine.new()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_TMP_DIR))


func teardown() -> void:
	_remove_tmp_file(_TMP_DIR.path_join("texture_passthrough.gssubgraph"))
	_remove_tmp_file(_TMP_DIR.path_join("legacy_passthrough.gshadergraph"))


func test_subgraph_validation_requires_path() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("canvas_item")
	doc.add_node("utility/subgraph", Vector2.ZERO)
	doc.add_node("output/canvas_item", Vector2(320, 0))

	var result := validator.validate(doc, registry)
	assert_false(result["success"])
	assert_true(_has_code(result["issues"], "E040"))


func test_dynamic_subgraph_contract_supports_sampler2d_passthrough() -> void:
	var subgraph_path := _TMP_DIR.path_join("texture_passthrough.gssubgraph")
	var subgraph_doc := _make_texture_passthrough_subgraph()
	_save_doc(subgraph_doc, subgraph_path)

	var contract := SubgraphContract.build_contract_from_document(subgraph_doc)
	var parent := _make_texture_passthrough_parent(subgraph_path, contract)
	var result := compiler.compile_gd(parent, "res://shader_assets/graphs/live_canvas.gshadergraph")

	assert_true(result["success"])
	assert_contains(result["shader_code"], "texture(")
	assert_contains(result["shader_code"], "shader_type canvas_item;")
	assert_contains(result["shader_code"], "Source: res://shader_assets/graphs/live_canvas.gshadergraph")


func test_legacy_subgraph_extension_is_still_resolved() -> void:
	var legacy_path := _TMP_DIR.path_join("legacy_passthrough.gshadergraph")
	var subgraph_doc := _make_texture_passthrough_subgraph()
	_save_doc(subgraph_doc, legacy_path)

	var contract := SubgraphContract.build_contract_from_document(subgraph_doc)
	var requested_path := _TMP_DIR.path_join("legacy_passthrough.gssubgraph")
	var parent := _make_texture_passthrough_parent(requested_path, contract)
	var result := compiler.compile_gd(parent)

	assert_true(result["success"])
	assert_contains(result["shader_code"], "texture(")


func _make_texture_passthrough_subgraph() -> ShaderGraphDocument:
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("subgraph")
	doc.set_name("Texture Passthrough")

	var input_id := doc.add_node("subgraph/input", Vector2(40, 120))
	var output_id := doc.add_node("subgraph/output", Vector2(320, 120))

	var input_node := doc.get_node(input_id)
	input_node.set_property("input_name", "source_tex")
	input_node.set_property("input_type", "sampler2D")

	var output_node := doc.get_node(output_id)
	output_node.set_property("output_name", "passthrough_tex")
	output_node.set_property("output_type", "sampler2D")

	doc.add_edge(input_id, "value", output_id, "value")
	return doc


func _make_texture_passthrough_parent(path: String, contract: Dictionary) -> ShaderGraphDocument:
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("canvas_item")
	doc.set_name("TextureParent")

	var parameter_id := doc.add_node("parameter/texture2d", Vector2(20, 40))
	var subgraph_id := doc.add_node("utility/subgraph", Vector2(220, 40))
	var uv_id := doc.add_node("input/uv", Vector2(20, 180))
	var sample_id := doc.add_node("texture/sample_2d", Vector2(420, 100))
	var output_id := doc.add_node("output/canvas_item", Vector2(680, 100))

	doc.get_node(subgraph_id).set_property("subgraph_path", path)
	doc.get_node(parameter_id).set_property("param_name", "source_tex")

	var input_port_id: String = contract["inputs"][0]["id"]
	var output_port_id: String = contract["outputs"][0]["id"]

	doc.add_edge(parameter_id, "value", subgraph_id, input_port_id)
	doc.add_edge(subgraph_id, output_port_id, sample_id, "tex")
	doc.add_edge(uv_id, "uv", sample_id, "uv")
	doc.add_edge(sample_id, "rgba", output_id, "color")

	return doc


func _save_doc(doc: ShaderGraphDocument, path: String) -> void:
	var serializer := GraphSerializer.new()
	serializer.save(doc, path)


func _remove_tmp_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _has_code(issues: Array, code: String) -> bool:
	for issue in issues:
		if issue["code"] == code:
			return true
	return false
