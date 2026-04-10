@tool
extends EditorPlugin

var _editor_panel: Control
var _side_dock: Control
var _import_plugin: EditorImportPlugin
var _subgraph_import_plugin: EditorImportPlugin
var _registry: NodeRegistry
var _owns_registry := false


func _enter_tree() -> void:
	# Boot the GDScript core: create registry and register stdlib
	if Engine.has_singleton("NodeRegistry"):
		_registry = Engine.get_singleton("NodeRegistry") as NodeRegistry
	else:
		_registry = NodeRegistry.new()
		StdlibRegistration.register_all(_registry)
		Engine.register_singleton("NodeRegistry", _registry)
		_owns_registry = true

	var scene := preload("res://addons/ss_godot_shader_studio/editor/shader_editor_panel.tscn")
	_editor_panel = scene.instantiate() as Control
	get_editor_interface().get_editor_main_screen().add_child(_editor_panel)
	# _ready() has fired on _editor_panel by now, so @onready vars are valid.
	_editor_panel.setup_undo_redo(get_undo_redo())
	_editor_panel.owner = null
	_editor_panel.hide()

	# Build the side dock (Properties + Parameters) and add it to the Inspector dock area.
	var ni_scene := preload("res://addons/ss_godot_shader_studio/editor/node_inspector.tscn")
	var pp_scene := preload("res://addons/ss_godot_shader_studio/editor/parameters_panel.tscn")
	var ni := ni_scene.instantiate()
	ni.name = "Properties"
	var pp := pp_scene.instantiate()
	pp.name = "Parameters"
	_side_dock = TabContainer.new()
	_side_dock.name = "Shader Studio"
	_side_dock.add_child(ni)
	_side_dock.add_child(pp)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _side_dock)
	_editor_panel.setup_side_panels(ni, pp)

	_import_plugin = preload("res://addons/ss_godot_shader_studio/editor/shader_graph_import_plugin.gd").new()
	add_import_plugin(_import_plugin)

	_subgraph_import_plugin = preload("res://addons/ss_godot_shader_studio/editor/subgraph_import_plugin.gd").new()
	add_import_plugin(_subgraph_import_plugin)


func _exit_tree() -> void:
	if is_instance_valid(_side_dock):
		remove_control_from_docks(_side_dock)
		_side_dock.queue_free()
		_side_dock = null
	if is_instance_valid(_editor_panel):
		_editor_panel.queue_free()
		_editor_panel = null
	if _import_plugin != null:
		remove_import_plugin(_import_plugin)
		_import_plugin = null
	if _subgraph_import_plugin != null:
		remove_import_plugin(_subgraph_import_plugin)
		_subgraph_import_plugin = null
	if _owns_registry and Engine.has_singleton("NodeRegistry"):
		Engine.unregister_singleton("NodeRegistry")
	_registry = null
	_owns_registry = false


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if is_instance_valid(_editor_panel):
		_editor_panel.visible = visible
		if visible:
			_editor_panel.call_deferred("refresh_when_visible")
	# Auto-focus the Shader Studio dock tab when entering this screen.
	if visible and is_instance_valid(_side_dock):
		var tab_container := _side_dock.get_parent() as TabContainer
		if tab_container != null:
			tab_container.current_tab = _side_dock.get_index()


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
