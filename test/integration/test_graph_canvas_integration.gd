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


func test_refresh_node_widget_preserves_visual_position() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("canvas_item")
	var param_id := doc.add_node("parameter/float", Vector2(32, 48))
	doc.add_node("output/canvas_item", Vector2(320, 0))

	_canvas.load_document(doc)

	var widget := _canvas.get_node(NodePath(param_id)) as GraphNode
	widget.position_offset = Vector2(420, 180)
	_canvas.refresh_node_widget(doc.get_node(param_id))

	assert_eq(doc.get_node(param_id).get_position(), Vector2(420, 180))
	assert_eq(widget.position_offset, Vector2(420, 180))


func test_parameter_widget_edit_bubbles_up_to_canvas_signal() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("canvas_item")
	var param_id := doc.add_node("parameter/float", Vector2.ZERO)
	doc.add_node("output/canvas_item", Vector2(260, 0))

	_canvas.load_document(doc)

	var seen := {
		"node": null,
		"key": "",
		"value": null,
	}
	_canvas.parameter_property_edited.connect(func(node_instance: ShaderGraphNodeInstance, key: String, value: Variant) -> void:
		seen["node"] = node_instance
		seen["key"] = key
		seen["value"] = value
	)

	var widget := _canvas.get_node(NodePath(param_id)) as GraphNode
	widget._emit_property("param_name", "tint_amount")

	assert_eq(seen["node"], doc.get_node(param_id))
	assert_eq(seen["key"], "param_name")
	assert_eq(seen["value"], "tint_amount")
	assert_eq(doc.get_node(param_id).get_property("param_name"), "tint_amount")


func test_search_popup_filters_domain_stage_and_enter_activates_result() -> void:
	var doc := ShaderGraphDocument.new()
	doc.set_shader_domain("canvas_item")
	doc.set_stage_config({
		"has_vertex": false,
		"has_fragment": true,
		"has_light": false,
	})
	doc.add_node("output/canvas_item", Vector2.ZERO)

	_canvas.load_document(doc)

	var popup = _canvas.get_node("NodeSearchPopup")
	var chosen := {
		"id": "",
		"pos": Vector2.ZERO,
	}
	popup.node_chosen.connect(func(def_id: String, graph_pos: Vector2) -> void:
		chosen["id"] = def_id
		chosen["pos"] = graph_pos
	)

	popup.open_at(Vector2i.ZERO, Vector2(12, 34), _canvas._get_domain_flag(), _canvas._get_stage_flag())

	assert_true(_tree_contains_text(popup._tree, "Canvas Texture"))
	assert_false(_tree_contains_text(popup._tree, "Fresnel"))
	assert_false(_tree_contains_text(popup._tree, "Canvas Vertex"))

	popup._refresh_tree("canvas texture")
	var enter := InputEventKey.new()
	enter.pressed = true
	enter.keycode = KEY_ENTER
	popup._on_search_key(enter)

	assert_eq(chosen["id"], "input/canvas_texture")
	assert_eq(chosen["pos"], Vector2(12, 34))


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


func _tree_contains_text(tree: Tree, label: String) -> bool:
	var root := tree.get_root()
	if root == null:
		return false

	var stack: Array[TreeItem] = [root]
	while not stack.is_empty():
		var item: TreeItem = stack.pop_back()
		if item.get_text(0).strip_edges() == label:
			return true
		var child: TreeItem = item.get_first_child()
		while child != null:
			stack.append(child)
			child = child.get_next()
	return false
