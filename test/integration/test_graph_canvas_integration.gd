extends TestCase

const CANVAS_SCENE = preload("res://addons/ss_godot_shader_studio/editor/graph_canvas.tscn")
const SubgraphContract = preload("res://addons/ss_godot_shader_studio/core/graph/subgraph_contract.gd")

const _TMP_DIR := "res://test/.tmp_graph_canvas"

var _tree: SceneTree
var _canvas: GraphEdit


func before_all() -> void:
	_tree = Engine.get_main_loop() as SceneTree
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_TMP_DIR))


func setup() -> void:
	_canvas = CANVAS_SCENE.instantiate()
	_tree.root.add_child(_canvas)
	SubgraphContract._cache.clear()
	await _tree.process_frame


func teardown() -> void:
	_free_node(_canvas)
	_canvas = null
	SubgraphContract._cache.clear()
	for path in [
		_TMP_DIR.path_join("wrapper_ports.gssubgraph"),
		_TMP_DIR.path_join("contract_refresh.gssubgraph"),
	]:
		_remove_file_if_exists(path)


func test_load_document_builds_dynamic_ports_from_subgraph_contract() -> void:
	var subgraph_path := _TMP_DIR.path_join("wrapper_ports.gssubgraph")
	var subgraph_doc := _make_subgraph(
		[
			{"name": "base", "type": "color"},
			{"name": "tint", "type": "color"},
		],
		[
			{"name": "result", "type": "color"},
		])
	_save_doc(subgraph_doc, subgraph_path)

	var parent := ShaderGraphDocument.new()
	parent.set_shader_domain("canvas_item")
	var wrapper_id := parent.add_node("utility/subgraph", Vector2.ZERO)
	parent.add_node("output/canvas_item", Vector2(360, 0))
	parent.get_node(wrapper_id).set_property("subgraph_path", subgraph_path)

	_canvas.load_document(parent)

	var wrapper_node := parent.get_node(wrapper_id)
	var inputs: Array = _canvas._effective_input_ports(wrapper_node)
	var outputs: Array = _canvas._effective_output_ports(wrapper_node)
	var widget := _canvas.get_node(NodePath(wrapper_id)) as GraphNode
	var first_row := widget.get_child(0) as HBoxContainer
	var second_row := widget.get_child(1) as HBoxContainer

	assert_eq(inputs.size(), 2)
	assert_eq(outputs.size(), 1)
	assert_eq(inputs[0]["name"], "base")
	assert_eq(inputs[1]["name"], "tint")
	assert_eq(outputs[0]["name"], "result")
	assert_eq((first_row.get_child(0) as Label).text, "base")
	assert_eq((first_row.get_child(1) as Label).text, "result")
	assert_eq((second_row.get_child(0) as Label).text, "tint")


func test_refresh_dynamic_ports_removes_edges_when_contract_shrinks() -> void:
	var subgraph_path := _TMP_DIR.path_join("contract_refresh.gssubgraph")
	var initial_doc := _make_subgraph(
		[{"name": "color_in", "type": "color"}],
		[{"name": "color_out", "type": "color"}])
	_save_doc(initial_doc, subgraph_path)

	var contract := SubgraphContract.build_contract_from_document(initial_doc)
	var parent := ShaderGraphDocument.new()
	parent.set_shader_domain("canvas_item")
	var param_id := parent.add_node("parameter/color", Vector2.ZERO)
	var wrapper_id := parent.add_node("utility/subgraph", Vector2(220, 0))
	var output_id := parent.add_node("output/canvas_item", Vector2(460, 0))
	parent.get_node(param_id).set_property("param_name", "tint")
	parent.get_node(wrapper_id).set_property("subgraph_path", subgraph_path)
	parent.add_edge(param_id, "value", wrapper_id, contract["inputs"][0]["id"])
	parent.add_edge(wrapper_id, contract["outputs"][0]["id"], output_id, "color")

	_canvas.load_document(parent)
	assert_eq(parent.get_all_edges().size(), 2)

	var shrunk_doc := _make_subgraph([], [])
	_save_doc(shrunk_doc, subgraph_path)
	SubgraphContract._cache.clear()

	var result: Dictionary = _canvas.refresh_dynamic_ports()

	assert_eq(result["removed_edges"], 2)
	assert_eq(parent.get_all_edges().size(), 0)


func test_apply_validation_result_and_clear_validation_toggle_titlebar_override() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("spatial")
	var add_id := doc.add_node("math/add", Vector2.ZERO)

	_canvas.load_document(doc)

	var widget := _canvas.get_node(NodePath(add_id)) as GraphNode
	assert_false(widget.has_theme_stylebox_override("titlebar"))

	_canvas.apply_validation_result([
		{"node_id": add_id, "severity": 2, "message": "Broken"},
	])
	assert_true(widget.has_theme_stylebox_override("titlebar"))

	_canvas.clear_validation()
	assert_false(widget.has_theme_stylebox_override("titlebar"))


func _make_subgraph(inputs: Array, outputs: Array) -> ShaderGraphDocument:
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("subgraph")
	doc.set_name("Contract")

	for i in inputs.size():
		var input_id := doc.add_node("subgraph/input", Vector2(40, 80 + i * 80))
		var input_node := doc.get_node(input_id)
		input_node.set_property("input_name", inputs[i].get("name", "input_%d" % i))
		input_node.set_property("input_type", inputs[i].get("type", "float"))

	for i in outputs.size():
		var output_id := doc.add_node("subgraph/output", Vector2(320, 80 + i * 80))
		var output_node := doc.get_node(output_id)
		output_node.set_property("output_name", outputs[i].get("name", "output_%d" % i))
		output_node.set_property("output_type", outputs[i].get("type", "float"))

	return doc


func _save_doc(doc: ShaderGraphDocument, path: String) -> void:
	var serializer := GraphSerializer.new()
	serializer.save(doc, path)


func _remove_file_if_exists(path: String) -> void:
	if path.is_empty() or not FileAccess.file_exists(path):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _free_node(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	node.free()
