@tool
extends Control

var _document: ShaderGraphDocument = null
var _current_path: String = ""
var _undo_redo: EditorUndoRedoManager = null

@onready var _graph_canvas = $VBoxContainer/HSplitContainer/GraphCanvas
@onready var _node_inspector = $VBoxContainer/HSplitContainer/VSplitContainer/RightTabs/NodeInspector
@onready var _params_panel = $VBoxContainer/HSplitContainer/VSplitContainer/RightTabs/ParametersPanel
@onready var _shader_preview = $VBoxContainer/HSplitContainer/VSplitContainer/VSplitContainer2/ShaderPreview
@onready var _compiler_output = $VBoxContainer/HSplitContainer/VSplitContainer/VSplitContainer2/CompilerOutput
@onready var _btn_new: Button = $VBoxContainer/HBoxContainer/New
@onready var _btn_new_subgraph: Button = $VBoxContainer/HBoxContainer/NewSubgraph
@onready var _btn_open: Button = $VBoxContainer/HBoxContainer/Open
@onready var _btn_save: Button = $VBoxContainer/HBoxContainer/Save
@onready var _btn_compile: Button = $VBoxContainer/HBoxContainer/Compile

var _open_dialog: EditorFileDialog
var _save_dialog: EditorFileDialog


func setup_undo_redo(ur: EditorUndoRedoManager) -> void:
	_undo_redo = ur
	if is_node_ready():
		_graph_canvas.setup_undo_redo(ur)


func open_file(path: String) -> void:
	var serializer := GraphSerializer.new()
	var doc: ShaderGraphDocument = serializer.load(path)
	if doc == null:
		push_error("ShaderStudio: failed to load '%s'" % path)
		return
	_document = doc
	_current_path = path
	_graph_canvas.load_document(_document)
	_compiler_output.clear_output()
	_shader_preview.apply_shader("")
	_on_graph_changed()
	_params_panel.refresh(_document)


func _ready() -> void:
	var right_tabs := $VBoxContainer/HSplitContainer/VSplitContainer/RightTabs as TabContainer
	right_tabs.set_tab_title(0, "Properties")
	right_tabs.set_tab_title(1, "Parameters")

	_btn_new.pressed.connect(_on_new)
	_btn_new_subgraph.pressed.connect(_on_new_subgraph)
	_btn_open.pressed.connect(_on_open)
	_btn_save.pressed.connect(_on_save)
	_btn_compile.pressed.connect(_on_compile)
	_graph_canvas.node_selected_in_canvas.connect(_on_node_selected)
	_graph_canvas.frame_selected_in_canvas.connect(_on_frame_selected)
	_graph_canvas.graph_changed.connect(_on_graph_changed)
	if _undo_redo != null:
		_graph_canvas.setup_undo_redo(_undo_redo)

	_open_dialog = EditorFileDialog.new()
	_open_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_open_dialog.title = "Open Shader Graph / Subgraph"
	_open_dialog.add_filter("*.gshadergraph", "Shader Graph")
	_open_dialog.add_filter("*.gssubgraph", "Shader Subgraph")
	_open_dialog.file_selected.connect(_on_open_file_selected)
	add_child(_open_dialog)

	_save_dialog = EditorFileDialog.new()
	_save_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	_save_dialog.title = "Save"
	_save_dialog.add_filter("*.gshadergraph", "Shader Graph")
	_save_dialog.add_filter("*.gssubgraph", "Shader Subgraph")
	_save_dialog.file_selected.connect(_on_save_file_selected)
	add_child(_save_dialog)

	_on_new()


func _on_new() -> void:
	_document = ShaderGraphDocument.new()
	_document.set_name("Untitled")
	_current_path = ""
	_add_default_output_node()
	_graph_canvas.load_document(_document)
	_compiler_output.clear_output()
	_shader_preview.apply_shader("")
	_on_graph_changed()
	_params_panel.refresh(_document)


func _on_new_subgraph() -> void:
	_document = ShaderGraphDocument.new()
	_document.set_name("Untitled Subgraph")
	_document.set_shader_domain("subgraph")
	_current_path = ""
	_graph_canvas.load_document(_document)
	_compiler_output.clear_output()
	_shader_preview.apply_shader("")
	_on_graph_changed()
	_params_panel.refresh(_document)


func _add_default_output_node() -> void:
	var node_id := _document.add_node("output/spatial", Vector2(400, 200))
	var node_inst: ShaderGraphNodeInstance = _document.get_node(node_id)
	if node_inst == null:
		return
	var registry = Engine.get_singleton("NodeRegistry")
	if registry != null:
		var def = registry.get_definition("output/spatial")
		if def != null:
			node_inst.set_title(def.get_display_name())


func _on_open() -> void:
	_open_dialog.popup_centered_ratio(0.7)


func _on_open_file_selected(path: String) -> void:
	open_file(path)


func _on_save() -> void:
	if _document == null:
		return
	if _current_path.is_empty():
		_save_dialog.popup_centered_ratio(0.7)
	else:
		_do_save(_current_path)


func _on_save_file_selected(path: String) -> void:
	_current_path = path
	_do_save(path)


func _do_save(path: String) -> void:
	_graph_canvas.sync_positions_to_document()
	var serializer := GraphSerializer.new()
	var err: int = serializer.save(_document, path)
	if err != OK:
		push_error("ShaderStudio: failed to save to '%s' (err %d)" % [path, err])
		return
	# Subgraph files don't compile as standalone shaders.
	if _document.get_shader_domain() == "subgraph":
		_compiler_output.clear_output()
		return
	# Regenerate .generated.gdshader on every save.
	var result: Dictionary = _run_compile_internal()
	_compiler_output.show_result(result)
	if result.get("success", false):
		_shader_preview.apply_shader(result.get("shader_code", ""))
		_write_generated_shader(path, result.get("shader_code", ""))


func _on_compile() -> void:
	if _document == null:
		return
	if _document.get_shader_domain() == "subgraph":
		_compiler_output.clear_output()
		return
	_compiler_output.show_compiling()
	await get_tree().process_frame
	var result: Dictionary = _run_compile_internal()
	_compiler_output.show_result(result)
	if result.get("success", false):
		_shader_preview.apply_shader(result.get("shader_code", ""))
		if not _current_path.is_empty():
			_write_generated_shader(_current_path, result.get("shader_code", ""))


func _run_compile_internal() -> Dictionary:
	_graph_canvas.sync_positions_to_document()
	var compiler := ShaderGraphCompiler.new()
	return compiler.compile_gd(_document)


func _write_generated_shader(graph_path: String, code: String) -> void:
	var shader_path := graph_path.get_basename() + ".generated.gdshader"
	var file := FileAccess.open(shader_path, FileAccess.WRITE)
	if file:
		file.store_string(code)
		file.close()


## Runs a lightweight validation pass after every graph change and
## updates the visual overlay on each node widget.
func _on_graph_changed() -> void:
	if _document == null:
		return
	var registry := Engine.get_singleton("NodeRegistry") as NodeRegistry
	if registry == null:
		return
	var validator := ValidationEngine.new()
	var result: Dictionary = validator.validate(_document, registry)
	_graph_canvas.apply_validation_result(result.get("issues", []))
	_params_panel.refresh(_document)


func _on_node_selected(node_instance: ShaderGraphNodeInstance) -> void:
	_node_inspector.inspect(node_instance)


func _on_frame_selected(frame_data: Dictionary, frame_widget: GraphFrame) -> void:
	_node_inspector.inspect_frame(frame_data, frame_widget)
