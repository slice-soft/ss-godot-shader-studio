extends TestCase

const PANEL_SCENE = preload("res://addons/ss_godot_shader_studio/editor/shader_editor_panel.tscn")
const ShaderGraphPathUtils = preload("res://addons/ss_godot_shader_studio/core/graph/shader_graph_path_utils.gd")

const _TMP_ROOT := "res://test/.tmp_editor_panel"
const _GRAPH_DIR := "res://test/.tmp_editor_panel/graphs"
const _GENERATED_DIR := "res://test/.tmp_editor_panel/generated"

var _tree: SceneTree
var _panel: Control


func before_all() -> void:
	_tree = Engine.get_main_loop() as SceneTree
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_GRAPH_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_GENERATED_DIR))


func setup() -> void:
	_panel = PANEL_SCENE.instantiate()
	_tree.root.add_child(_panel)
	await _tree.process_frame


func teardown() -> void:
	_free_node(_panel)
	_panel = null
	for path in [
		_GRAPH_DIR.path_join("screen_green_final.gshadergraph"),
		_GRAPH_DIR.path_join("live_output.gshadergraph"),
		_GRAPH_DIR.path_join("fancy_subgraph.gssubgraph"),
		_GENERATED_DIR.path_join("screen_green_final.generated.gdshader"),
		_GENERATED_DIR.path_join("screen_green_final.generated.gdshader.uid"),
		_GENERATED_DIR.path_join("live_output.generated.gdshader"),
		_GENERATED_DIR.path_join("live_output.generated.gdshader.uid"),
	]:
		_remove_file_if_exists(path)


func test_new_graph_hint_mentions_recommended_source_and_generated_output() -> void:
	var hint := _panel.get_node("VBoxContainer/PathHint") as Label
	assert_contains(hint.text, "res://shader_assets/graphs")
	assert_contains(hint.text, "Shader generado: se pedira carpeta de salida")


func test_save_writes_normalized_graph_and_generated_shader_to_selected_folder() -> void:
	_panel._set_generated_shader_dir(_GENERATED_DIR)
	_panel._perform_save(_GRAPH_DIR.path_join("Screen Green Final.gshadergraph"), "save_as")

	var saved_path := _GRAPH_DIR.path_join("screen_green_final.gshadergraph")
	var generated_path := ShaderGraphPathUtils.generated_shader_path_for_dir(saved_path, _GENERATED_DIR)
	var serializer := GraphSerializer.new()
	var loaded := serializer.load(saved_path)
	var shader_text := _read_text(generated_path)
	var hint := _panel.get_node("VBoxContainer/PathHint") as Label

	assert_true(FileAccess.file_exists(saved_path))
	assert_true(FileAccess.file_exists(generated_path))
	assert_not_null(loaded)
	assert_eq(loaded.get_generated_shader_dir(), _GENERATED_DIR)
	assert_contains(shader_text, "shader_type spatial;")
	assert_contains(hint.text, generated_path)


func test_save_without_output_folder_defers_generated_shader_until_selected() -> void:
	_panel._perform_save(_GRAPH_DIR.path_join("Live Output.gshadergraph"), "save_as")

	var saved_path := _GRAPH_DIR.path_join("live_output.gshadergraph")
	var generated_path := ShaderGraphPathUtils.generated_shader_path_for_dir(saved_path, _GENERATED_DIR)

	assert_true(FileAccess.file_exists(saved_path))
	assert_eq(_panel._get_generated_shader_dir(), "")
	assert_false(_panel._pending_generated_shader_code.is_empty())
	assert_false(FileAccess.file_exists(generated_path))

	_panel._on_generated_dir_selected(_GENERATED_DIR)
	var serializer := GraphSerializer.new()
	var loaded := serializer.load(saved_path)

	assert_true(FileAccess.file_exists(generated_path))
	assert_true(_panel._pending_generated_shader_code.is_empty())
	assert_not_null(loaded)
	assert_eq(loaded.get_generated_shader_dir(), _GENERATED_DIR)


func test_save_subgraph_forces_extension_and_skips_generated_shader() -> void:
	_panel._on_new_subgraph()
	_panel._perform_save(_GRAPH_DIR.path_join("Fancy Subgraph.gshadergraph"), "save_as")

	var saved_path := _GRAPH_DIR.path_join("fancy_subgraph.gssubgraph")
	var generated_path := ShaderGraphPathUtils.generated_shader_path_for_dir(saved_path, _GENERATED_DIR)
	var serializer := GraphSerializer.new()
	var loaded := serializer.load(saved_path)

	assert_true(FileAccess.file_exists(saved_path))
	assert_false(FileAccess.file_exists(generated_path))
	assert_true(_panel._pending_generated_shader_code.is_empty())
	assert_not_null(loaded)
	assert_eq(loaded.get_shader_domain(), "subgraph")


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


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
