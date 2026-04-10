@tool
extends EditorPlugin

var _editor_panel: Control
var _import_plugin: EditorImportPlugin
var _subgraph_import_plugin: EditorImportPlugin
var _registry: NodeRegistry


func _enter_tree() -> void:
	# Boot the GDScript core: create registry and register stdlib
	_registry = NodeRegistry.new()
	StdlibRegistration.register_all(_registry)
	Engine.register_singleton("NodeRegistry", _registry)

	var scene := preload("res://addons/ss_godot_shader_studio/editor/shader_editor_panel.tscn")
	_editor_panel = scene.instantiate() as Control
	get_editor_interface().get_editor_main_screen().add_child(_editor_panel)
	# _ready() has fired on _editor_panel by now, so @onready vars are valid.
	_editor_panel.setup_undo_redo(get_undo_redo())
	_editor_panel.owner = null
	_editor_panel.hide()

	_import_plugin = preload("res://addons/ss_godot_shader_studio/editor/shader_graph_import_plugin.gd").new()
	add_import_plugin(_import_plugin)

	_subgraph_import_plugin = preload("res://addons/ss_godot_shader_studio/editor/subgraph_import_plugin.gd").new()
	add_import_plugin(_subgraph_import_plugin)


func _exit_tree() -> void:
	if is_instance_valid(_editor_panel):
		_editor_panel.queue_free()
		_editor_panel = null
	if _import_plugin != null:
		remove_import_plugin(_import_plugin)
		_import_plugin = null
	if _subgraph_import_plugin != null:
		remove_import_plugin(_subgraph_import_plugin)
		_subgraph_import_plugin = null
	Engine.unregister_singleton("NodeRegistry")
	_registry = null


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if is_instance_valid(_editor_panel):
		_editor_panel.visible = visible


func _get_plugin_name() -> String:
	return "Shader Studio"


func _get_plugin_icon() -> Texture2D:
	return get_editor_interface().get_base_control().get_theme_icon("VisualShader", "EditorIcons")


func _shortcut_input(event: InputEvent) -> void:
	if not is_instance_valid(_editor_panel) or not _editor_panel.visible:
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and key.ctrl_pressed and key.shift_pressed and key.keycode == KEY_Z:
			get_undo_redo() \
					.get_history_undo_redo(EditorUndoRedoManager.GLOBAL_HISTORY) \
					.redo()
			get_viewport().set_input_as_handled()


func _handles(object: Object) -> bool:
	return object is ShaderGraphResource


func _edit(object: Object) -> void:
	if object is ShaderGraphResource:
		_editor_panel.open_file((object as ShaderGraphResource).source_path)
		_make_visible(true)
