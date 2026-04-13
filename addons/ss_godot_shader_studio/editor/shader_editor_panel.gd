@tool
extends Control

const SubgraphContract = preload("res://addons/ss_godot_shader_studio/core/graph/subgraph_contract.gd")
const ShaderGraphPathUtils = preload("res://addons/ss_godot_shader_studio/core/graph/shader_graph_path_utils.gd")

const _PREVIEW_DEBOUNCE_SEC := 0.25
const _SUBGRAPH_WATCH_SEC := 1.0

const _SAVE_REASON_FIRST := "first_save"
const _SAVE_REASON_SAVE := "save"
const _SAVE_REASON_SAVE_AS := "save_as"
const _SAVE_REASON_NORMALIZE := "normalize_path"

var _document: ShaderGraphDocument = null
var _current_path: String = ""
var _undo_redo: EditorUndoRedoManager = null

var _pending_save_path: String = ""
var _pending_save_reason: String = _SAVE_REASON_SAVE
var _pending_generated_shader_code: String = ""
var _watched_subgraph_mtimes: Dictionary = {}

@onready var _graph_canvas = $VBoxContainer/HSplitContainer/GraphCanvas
@onready var _shader_preview = $VBoxContainer/HSplitContainer/RightSplit/ShaderPreview
@onready var _compiler_output = $VBoxContainer/HSplitContainer/RightSplit/CompilerOutput
@onready var _path_hint: Label = $VBoxContainer/PathHint

# Set via setup_side_panels() from plugin.gd after the dock is created.
var _node_inspector = null
var _params_panel = null
@onready var _btn_new: Button = $VBoxContainer/HBoxContainer/New
@onready var _btn_new_subgraph: Button = $VBoxContainer/HBoxContainer/NewSubgraph
@onready var _btn_open: Button = $VBoxContainer/HBoxContainer/Open
@onready var _btn_save: Button = $VBoxContainer/HBoxContainer/Save
@onready var _btn_save_as: Button = $VBoxContainer/HBoxContainer/SaveAs
@onready var _btn_compile: Button = $VBoxContainer/HBoxContainer/Compile
@onready var _domain_option: OptionButton = $VBoxContainer/HBoxContainer/DomainOption

const _DOMAINS := ["spatial", "canvas_item", "fullscreen", "particles", "sky", "fog", "subgraph"]
const _DOMAIN_LABELS := ["Spatial", "Canvas Item", "Fullscreen", "Particles", "Sky", "Fog", "Subgraph"]
const _DOMAIN_OUTPUT := {
	"spatial":     "output/spatial",
	"canvas_item": "output/canvas_item",
	"fullscreen":  "output/fullscreen",
	"particles":   "output/particles",
	"sky":         "output/sky",
	"fog":         "output/fog",
	"subgraph":    "",
}

var _open_dialog: EditorFileDialog
var _save_dialog: EditorFileDialog
var _generated_dir_dialog: EditorFileDialog
var _path_warning_dialog: ConfirmationDialog
var _preview_timer: Timer
var _subgraph_watch_timer: Timer


func setup_undo_redo(ur: EditorUndoRedoManager) -> void:
	_undo_redo = ur
	if is_node_ready():
		_graph_canvas.setup_undo_redo(ur)


func refresh_when_visible() -> void:
	_refresh_document_state(true, true)


func open_file(path: String) -> void:
	var serializer := GraphSerializer.new()
	var doc: ShaderGraphDocument = serializer.load(path)
	if doc == null:
		push_error("ShaderStudio: failed to load '%s'" % path)
		return

	_document = doc
	_current_path = path
	_load_document_into_editor()


func setup_side_panels(node_inspector, params_panel) -> void:
	_node_inspector = node_inspector
	_params_panel = params_panel

	if _node_inspector != null and not _node_inspector.property_edited.is_connected(_on_node_property_edited):
		_node_inspector.property_edited.connect(_on_node_property_edited)
	if _params_panel != null and not _params_panel.parameter_edited.is_connected(_on_parameter_edited):
		_params_panel.parameter_edited.connect(_on_parameter_edited)
	if _document != null:
		_refresh_params()


func _ready() -> void:
	for i in _DOMAIN_LABELS.size():
		_domain_option.add_item(_DOMAIN_LABELS[i], i)

	_btn_new.pressed.connect(_on_new)
	_btn_new_subgraph.pressed.connect(_on_new_subgraph)
	_btn_open.pressed.connect(_on_open)
	_btn_save.pressed.connect(_on_save)
	_btn_save_as.pressed.connect(_on_save_as)
	_btn_compile.pressed.connect(_on_compile)
	_domain_option.item_selected.connect(_on_domain_selected)
	_graph_canvas.node_selected_in_canvas.connect(_on_node_selected)
	_graph_canvas.frame_selected_in_canvas.connect(_on_frame_selected)
	_graph_canvas.graph_changed.connect(_on_graph_changed)
	_graph_canvas.parameter_property_edited.connect(_on_parameter_edited)
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
	_save_dialog.title = "Save Shader Graph"
	_save_dialog.add_filter("*.gshadergraph", "Shader Graph")
	_save_dialog.add_filter("*.gssubgraph", "Shader Subgraph")
	_save_dialog.file_selected.connect(_on_save_file_selected)
	add_child(_save_dialog)

	_generated_dir_dialog = EditorFileDialog.new()
	_generated_dir_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	_generated_dir_dialog.title = "Choose Generated Shader Folder"
	_generated_dir_dialog.dir_selected.connect(_on_generated_dir_selected)
	add_child(_generated_dir_dialog)

	_path_warning_dialog = ConfirmationDialog.new()
	_path_warning_dialog.title = "Review Save Location"
	_path_warning_dialog.confirmed.connect(_on_confirm_risky_save)
	add_child(_path_warning_dialog)

	_preview_timer = Timer.new()
	_preview_timer.one_shot = true
	_preview_timer.wait_time = _PREVIEW_DEBOUNCE_SEC
	_preview_timer.timeout.connect(_on_preview_timer_timeout)
	add_child(_preview_timer)

	_subgraph_watch_timer = Timer.new()
	_subgraph_watch_timer.one_shot = false
	_subgraph_watch_timer.wait_time = _SUBGRAPH_WATCH_SEC
	_subgraph_watch_timer.timeout.connect(_on_subgraph_watch_timer_timeout)
	add_child(_subgraph_watch_timer)

	_path_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_refresh_path_hint()

	_on_new()


func _on_new() -> void:
	_document = ShaderGraphDocument.new()
	_document.set_name("Untitled")
	_current_path = ""
	_add_default_output_node()
	_load_document_into_editor()


func _on_new_subgraph() -> void:
	_document = ShaderGraphDocument.new()
	_document.set_name("Untitled Subgraph")
	_document.set_shader_domain("subgraph")
	_current_path = ""
	_load_document_into_editor()


func _load_document_into_editor() -> void:
	_pending_generated_shader_code = ""
	_graph_canvas.load_document(_document)
	_compiler_output.clear_output()
	_shader_preview.apply_shader("")
	_sync_domain_dropdown()
	_refresh_document_state(true, true)


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


func _refresh_document_state(refresh_dynamic_ports: bool, schedule_preview: bool) -> void:
	if _document == null:
		_refresh_path_hint()
		return

	if refresh_dynamic_ports:
		_graph_canvas.refresh_dynamic_ports()

	_revalidate_document()
	_refresh_params()
	_refresh_path_hint()
	_refresh_subgraph_watchers()

	if schedule_preview:
		_schedule_preview_refresh()


func _revalidate_document() -> void:
	var registry := Engine.get_singleton("NodeRegistry") as NodeRegistry
	if registry == null or _document == null:
		return
	var validator := ValidationEngine.new()
	var result: Dictionary = validator.validate(_document, registry)
	_graph_canvas.apply_validation_result(result.get("issues", []))


func _refresh_params() -> void:
	if _params_panel != null:
		_params_panel.refresh(_document)


func _refresh_path_hint() -> void:
	var domain := _document.get_shader_domain() if _document != null else "spatial"
	_path_hint.text = ShaderGraphPathUtils.guidance_for_path(_current_path, domain, _get_generated_shader_path())


func _get_generated_shader_dir() -> String:
	if _document == null:
		return ""
	return _document.get_generated_shader_dir().strip_edges()


func _set_generated_shader_dir(dir_path: String) -> void:
	if _document == null:
		return
	_document.set_generated_shader_dir(dir_path.strip_edges())


func _get_generated_shader_path() -> String:
	if _document == null or _document.get_shader_domain() == "subgraph" or _current_path.is_empty():
		return ""
	var output_dir := _get_generated_shader_dir()
	if output_dir.is_empty():
		return ""
	return ShaderGraphPathUtils.generated_shader_path_for_dir(_current_path, output_dir)


func _refresh_subgraph_watchers() -> void:
	_watched_subgraph_mtimes.clear()

	if _document == null or _document.get_shader_domain() == "subgraph":
		_subgraph_watch_timer.stop()
		return

	for entry in _document.get_all_nodes():
		var node := entry as ShaderGraphNodeInstance
		if node == null or node.get_definition_id() != "utility/subgraph":
			continue
		var raw_path := str(node.get_property("subgraph_path")) if node.get_property("subgraph_path") != null else ""
		var resolved_path := SubgraphContract.resolve_subgraph_path(raw_path)
		if resolved_path.is_empty():
			continue
		_watched_subgraph_mtimes[resolved_path] = FileAccess.get_modified_time(resolved_path)

	if _watched_subgraph_mtimes.is_empty():
		_subgraph_watch_timer.stop()
	else:
		_subgraph_watch_timer.start()


func _schedule_preview_refresh() -> void:
	if _document == null:
		_preview_timer.stop()
		return

	if _document.get_shader_domain() == "subgraph":
		_preview_timer.stop()
		_shader_preview.apply_shader("")
		return

	if not visible:
		_preview_timer.stop()
		return

	_preview_timer.start(_PREVIEW_DEBOUNCE_SEC)


func _on_preview_timer_timeout() -> void:
	if _document == null or _document.get_shader_domain() == "subgraph":
		return
	_compile_document(false, false)


func _on_subgraph_watch_timer_timeout() -> void:
	if _document == null or _watched_subgraph_mtimes.is_empty():
		return

	var changed := false
	for path in _watched_subgraph_mtimes:
		var exists := FileAccess.file_exists(path)
		var modified_time := FileAccess.get_modified_time(path) if exists else -1
		if modified_time != _watched_subgraph_mtimes[path]:
			changed = true
			break

	if changed:
		_refresh_document_state(true, true)


func _on_open() -> void:
	_open_dialog.popup_centered_ratio(0.7)


func _on_open_file_selected(path: String) -> void:
	open_file(path)


func _on_save() -> void:
	if _document == null:
		return

	if _current_path.is_empty():
		_show_save_dialog(_SAVE_REASON_FIRST)
		return

	var normalized_current := ShaderGraphPathUtils.normalize_source_path(
		_current_path,
		_document.get_shader_domain())
	if normalized_current != _current_path:
		_show_save_dialog(_SAVE_REASON_NORMALIZE)
		return

	_perform_save(_current_path, _SAVE_REASON_SAVE)


func _on_save_as() -> void:
	if _document == null:
		return
	_show_save_dialog(_SAVE_REASON_SAVE_AS)


func _show_save_dialog(reason: String) -> void:
	if _document == null:
		return

	_pending_save_reason = reason
	ShaderGraphPathUtils.ensure_source_dir_exists(_document.get_shader_domain(), _current_path)

	var suggested_path := _suggested_save_path(reason)
	_save_dialog.title = "Save Subgraph" if _document.get_shader_domain() == "subgraph" else "Save Shader Graph"
	_save_dialog.current_dir = suggested_path.get_base_dir()
	_save_dialog.current_file = suggested_path.get_file()
	_save_dialog.popup_centered_ratio(0.7)


func _suggested_save_path(reason: String) -> String:
	if not _current_path.is_empty() and reason != _SAVE_REASON_FIRST:
		return ShaderGraphPathUtils.normalize_source_path(_current_path, _document.get_shader_domain())
	return ShaderGraphPathUtils.default_source_path(
		_document.get_shader_domain(),
		_document.get_name(),
		_current_path)


func _on_save_file_selected(path: String) -> void:
	if _document == null:
		return

	_pending_save_path = ShaderGraphPathUtils.normalize_source_path(path, _document.get_shader_domain())
	var warning := ShaderGraphPathUtils.risky_save_reason(_pending_save_path)
	if not warning.is_empty():
		_path_warning_dialog.dialog_text = "%s\n\nUbicacion recomendada: %s" % [
			warning,
			ShaderGraphPathUtils.default_source_dir(_document.get_shader_domain(), _current_path),
		]
		_path_warning_dialog.popup_centered()
		return

	_confirm_pending_save()


func _on_confirm_risky_save() -> void:
	_confirm_pending_save()


func _confirm_pending_save() -> void:
	if _pending_save_path.is_empty():
		return
	_perform_save(_pending_save_path, _pending_save_reason)
	_pending_save_path = ""


func _perform_save(path: String, reason: String) -> void:
	if _document == null:
		return

	_graph_canvas.sync_positions_to_document()
	ShaderGraphPathUtils.ensure_source_dir_exists(_document.get_shader_domain(), path)

	var previous_path := _current_path
	var normalized_path := ShaderGraphPathUtils.normalize_source_path(path, _document.get_shader_domain())
	_maybe_sync_document_name(normalized_path, previous_path)

	var serializer := GraphSerializer.new()
	var err: int = serializer.save(_document, normalized_path)
	if err != OK:
		push_error("ShaderStudio: failed to save to '%s' (err %d)" % [normalized_path, err])
		return

	_current_path = normalized_path
	_refresh_path_hint()
	_refresh_subgraph_watchers()

	if reason == _SAVE_REASON_NORMALIZE and not previous_path.is_empty() and previous_path != normalized_path:
		_cleanup_old_source_artifacts(previous_path)

	if _document.get_shader_domain() == "subgraph":
		_compiler_output.clear_output()
		_shader_preview.apply_shader("")
		return

	_compile_document(true, true)


func _maybe_sync_document_name(path: String, previous_path: String) -> void:
	if _document == null or path.is_empty():
		return

	var current_name := _document.get_name().strip_edges()
	var previous_base := previous_path.get_file().get_basename() if not previous_path.is_empty() else ""
	if current_name.is_empty() \
			or current_name.begins_with("Untitled") \
			or (not previous_base.is_empty() and current_name == previous_base):
		_document.set_name(path.get_file().get_basename())


func _cleanup_old_source_artifacts(old_path: String) -> void:
	_remove_file_if_exists(old_path)
	_remove_file_if_exists(ShaderGraphPathUtils.import_metadata_path(old_path))
	_remove_file_if_exists(ShaderGraphPathUtils.generated_shader_path(old_path))
	_remove_file_if_exists(ShaderGraphPathUtils.generated_uid_path(old_path))
	if not _get_generated_shader_dir().is_empty():
		_remove_file_if_exists(ShaderGraphPathUtils.generated_shader_path_for_dir(old_path, _get_generated_shader_dir()))
		_remove_file_if_exists(ShaderGraphPathUtils.generated_uid_path_for_dir(old_path, _get_generated_shader_dir()))


func _remove_file_if_exists(path: String) -> void:
	if path.is_empty() or not FileAccess.file_exists(path):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _on_compile() -> void:
	if _document == null:
		return
	if _document.get_shader_domain() == "subgraph":
		_compiler_output.clear_output()
		_shader_preview.apply_shader("")
		return

	_compiler_output.show_compiling()
	await get_tree().process_frame
	_compile_document(true, not _current_path.is_empty())


func _compile_document(show_output: bool, write_generated: bool) -> Dictionary:
	if _document == null:
		return {"success": false, "shader_code": "", "issues": []}

	var result: Dictionary = _run_compile_internal()
	if show_output:
		_compiler_output.show_result(result)

	if result.get("success", false):
		var shader_code := result.get("shader_code", "")
		_shader_preview.apply_shader(shader_code)
		if write_generated and not _current_path.is_empty():
			_write_generated_shader_or_prompt(_current_path, shader_code)
	else:
		_shader_preview.apply_shader("")

	return result


func _run_compile_internal() -> Dictionary:
	_graph_canvas.sync_positions_to_document()
	var compiler := ShaderGraphCompiler.new()
	return compiler.compile_gd(_document, _current_path)


func _write_generated_shader_or_prompt(graph_path: String, code: String) -> void:
	if _document == null or graph_path.is_empty():
		return

	if _get_generated_shader_dir().is_empty():
		_pending_generated_shader_code = code
		_show_generated_dir_dialog()
		return

	_write_generated_shader(graph_path, code)


func _show_generated_dir_dialog() -> void:
	if _document == null or _current_path.is_empty():
		return

	var suggested_dir := ShaderGraphPathUtils.default_generated_shader_dir(_get_generated_shader_dir())
	_generated_dir_dialog.title = "Choose Folder For %s" % ShaderGraphPathUtils.generated_shader_filename(_current_path)
	ShaderGraphPathUtils.ensure_generated_dir_exists(suggested_dir)
	_generated_dir_dialog.current_dir = suggested_dir
	_generated_dir_dialog.popup_centered_ratio(0.7)


func _on_generated_dir_selected(dir_path: String) -> void:
	if _document == null:
		return

	var normalized_dir := dir_path.strip_edges()
	if normalized_dir.is_empty():
		return

	_set_generated_shader_dir(normalized_dir)
	ShaderGraphPathUtils.ensure_generated_dir_exists(_get_generated_shader_dir())
	_persist_document_metadata()
	_refresh_path_hint()

	if not _pending_generated_shader_code.is_empty() and not _current_path.is_empty():
		_write_generated_shader(_current_path, _pending_generated_shader_code)
		_pending_generated_shader_code = ""


func _persist_document_metadata() -> void:
	if _document == null or _current_path.is_empty():
		return

	var serializer := GraphSerializer.new()
	var err := serializer.save(_document, _current_path)
	if err != OK:
		push_warning("ShaderStudio: failed to persist editor metadata for '%s'" % _current_path)


func _write_generated_shader(graph_path: String, code: String) -> void:
	var shader_path := _get_generated_shader_path()
	if shader_path.is_empty():
		push_warning("ShaderStudio: generated shader output folder not configured for '%s'" % graph_path)
		return

	ShaderGraphPathUtils.ensure_generated_dir_exists(shader_path.get_base_dir())
	var file := FileAccess.open(shader_path, FileAccess.WRITE)
	if file:
		file.store_string(code)
		file.close()
	else:
		push_error("ShaderStudio: failed to write generated shader '%s'" % shader_path)


func _on_graph_changed() -> void:
	_refresh_document_state(true, true)


func _on_node_property_edited(node_instance: ShaderGraphNodeInstance, key: String, _value: Variant) -> void:
	if _document == null:
		return

	if key == "subgraph_path":
		var resolved := SubgraphContract.resolve_subgraph_path(
			str(node_instance.get_property("subgraph_path")) if node_instance.get_property("subgraph_path") != null else "")
		if not resolved.is_empty():
			node_instance.set_property("subgraph_path", resolved)

	_refresh_document_state(true, true)


func _on_parameter_edited(_node_instance: ShaderGraphNodeInstance, _key: String, _value: Variant) -> void:
	_refresh_document_state(false, true)


func _on_node_selected(node_instance: ShaderGraphNodeInstance) -> void:
	if _node_inspector != null:
		_node_inspector.inspect(node_instance)


func _on_frame_selected(frame_data: Dictionary, frame_widget: GraphFrame) -> void:
	if _node_inspector != null:
		_node_inspector.inspect_frame(frame_data, frame_widget)


func _sync_domain_dropdown() -> void:
	if _document == null:
		return
	var domain := _document.get_shader_domain()
	var idx := _DOMAINS.find(domain)
	if idx >= 0:
		_domain_option.selected = idx


func _on_domain_selected(index: int) -> void:
	if _document == null:
		return

	var new_domain: String = _DOMAINS[index]
	if new_domain == _document.get_shader_domain():
		return

	_document.set_shader_domain(new_domain)
	_swap_output_node(new_domain)
	_graph_canvas.load_document(_document)
	_compiler_output.clear_output()
	_shader_preview.apply_shader("")
	_refresh_document_state(true, true)


func _swap_output_node(domain: String) -> void:
	# Remove existing output node (any definition_id starting with "output/")
	var old_pos := Vector2(400, 200)
	for node in _document.get_all_nodes():
		var inst := node as ShaderGraphNodeInstance
		if inst.definition_id.begins_with("output/"):
			old_pos = inst.position
			_document.remove_node(inst.id)
			break

	# Add new output node for the domain (subgraph has none)
	var output_def: String = _DOMAIN_OUTPUT.get(domain, "")
	if output_def.is_empty():
		return
	var registry = Engine.get_singleton("NodeRegistry")
	if registry == null:
		return
	var def = registry.get_definition(output_def)
	if def == null:
		return
	var node_id := _document.add_node(output_def, old_pos)
	var node_inst: ShaderGraphNodeInstance = _document.get_node(node_id)
	if node_inst != null:
		node_inst.set_title(def.get_display_name())
