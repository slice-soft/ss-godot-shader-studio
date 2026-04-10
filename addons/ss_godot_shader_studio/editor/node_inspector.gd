@tool
extends PanelContainer

const SubgraphContract = preload("res://addons/ss_godot_shader_studio/core/graph/subgraph_contract.gd")

signal property_edited(node_instance: ShaderGraphNodeInstance, key: String, value: Variant)

var _current_node: ShaderGraphNodeInstance = null

@onready var _title_label: Label         = $VBoxContainer/NodeTitle
@onready var _props_container: VBoxContainer = $VBoxContainer/ScrollContainer/PropertiesContainer

var _subgraph_dialog: EditorFileDialog = null


func inspect(node_instance: ShaderGraphNodeInstance) -> void:
	_current_node = node_instance
	_title_label.text = node_instance.get_title()
	_clear_properties()

	var props: Dictionary = node_instance.get_properties()
	for key in props:
		_add_property_row(node_instance, key, props[key])


func inspect_frame(frame_data: Dictionary, frame_widget: GraphFrame) -> void:
	_current_node = null
	_title_label.text = "Frame"
	_clear_properties()

	var row := HBoxContainer.new()

	var label := Label.new()
	label.text = "title:"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	row.add_child(label)

	var edit := LineEdit.new()
	edit.text = frame_data.get("title", "")
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.placeholder_text = "Comment"
	edit.text_submitted.connect(func(text: String) -> void:
		frame_data["title"] = text
		frame_widget.title = text
	)
	edit.focus_exited.connect(func() -> void:
		frame_data["title"] = edit.text
		frame_widget.title = edit.text
	)
	row.add_child(edit)
	_props_container.add_child(row)


func _clear_properties() -> void:
	for child in _props_container.get_children():
		_props_container.remove_child(child)
		child.free()


func _add_property_row(node_inst: ShaderGraphNodeInstance, key: String, value: Variant) -> void:
	# Custom GLSL body editor (utility/custom_function)
	if key == "body":
		_add_body_editor(node_inst, key, str(value) if value != null else "")
		return

	# Subgraph path picker (utility/subgraph)
	if key == "subgraph_path":
		_add_subgraph_path_row(node_inst, key, str(value) if value != null else "")
		return

	if key == "input_type" or key == "output_type":
		_add_type_picker_row(node_inst, key, str(value) if value != null else "")
		return

	# Default: single-line LineEdit
	var row := HBoxContainer.new()

	var label := Label.new()
	label.text = key + ":"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	row.add_child(label)

	var edit := LineEdit.new()
	edit.text = str(value)
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.text_submitted.connect(func(text: String) -> void:
		_update_node_property(node_inst, key, text)
	)
	edit.focus_exited.connect(func() -> void:
		_update_node_property(node_inst, key, edit.text)
	)
	row.add_child(edit)

	_props_container.add_child(row)


## Multi-line GLSL expression editor for utility/custom_function nodes.
func _add_body_editor(node_inst: ShaderGraphNodeInstance, key: String, value: String) -> void:
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label := Label.new()
	label.text = "GLSL expression:"
	vbox.add_child(label)

	var hint := Label.new()
	hint.text = "inputs: {a}  {b}  {c}  {d}"
	hint.add_theme_font_size_override("font_size", 10)
	hint.modulate = Color(0.65, 0.65, 0.65)
	vbox.add_child(hint)

	var edit := TextEdit.new()
	edit.text = value
	edit.custom_minimum_size = Vector2(0, 72)
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	edit.text_changed.connect(func() -> void:
		_update_node_property(node_inst, key, edit.text)
	)
	vbox.add_child(edit)

	_props_container.add_child(vbox)


## File-picker row for the subgraph_path property of utility/subgraph nodes.
func _add_subgraph_path_row(node_inst: ShaderGraphNodeInstance, key: String, value: String) -> void:
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label := Label.new()
	label.text = "Subgraph file:"
	vbox.add_child(label)

	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var path_edit := LineEdit.new()
	path_edit.text = value
	path_edit.placeholder_text = "res://...gssubgraph"
	path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	path_edit.text_submitted.connect(func(text: String) -> void:
		_update_node_property(node_inst, key, text)
	)
	path_edit.focus_exited.connect(func() -> void:
		_update_node_property(node_inst, key, path_edit.text)
	)
	hbox.add_child(path_edit)

	var browse_btn := Button.new()
	browse_btn.text = "..."
	browse_btn.tooltip_text = "Browse for a .gssubgraph file"
	browse_btn.pressed.connect(func() -> void:
		_open_subgraph_dialog(node_inst, key, path_edit)
	)
	hbox.add_child(browse_btn)

	vbox.add_child(hbox)
	_props_container.add_child(vbox)


func _add_type_picker_row(node_inst: ShaderGraphNodeInstance, key: String, value: String) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label := Label.new()
	label.text = key + ":"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	row.add_child(label)

	var picker := OptionButton.new()
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var types := ["float", "vec2", "vec3", "vec4", "color", "sampler2D"]
	var normalized := SubgraphContract.normalize_type_name(value)
	for i in types.size():
		picker.add_item(types[i], i)
		if types[i] == normalized:
			picker.selected = i
	picker.item_selected.connect(func(index: int) -> void:
		_update_node_property(node_inst, key, types[index])
	)
	row.add_child(picker)

	_props_container.add_child(row)


func _open_subgraph_dialog(node_inst: ShaderGraphNodeInstance,
		key: String, path_edit: LineEdit) -> void:
	if _subgraph_dialog == null:
		_subgraph_dialog = EditorFileDialog.new()
		_subgraph_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
		_subgraph_dialog.title = "Open Subgraph"
		_subgraph_dialog.add_filter("*.gssubgraph", "Shader Subgraph")
		add_child(_subgraph_dialog)
	# Disconnect previous signals before reconnecting.
	if _subgraph_dialog.file_selected.is_connected(_on_subgraph_file_selected.bind(node_inst, key, path_edit)):
		_subgraph_dialog.file_selected.disconnect(_on_subgraph_file_selected.bind(node_inst, key, path_edit))
	_subgraph_dialog.file_selected.connect(_on_subgraph_file_selected.bind(node_inst, key, path_edit), CONNECT_ONE_SHOT)
	_subgraph_dialog.popup_centered_ratio(0.7)


func _on_subgraph_file_selected(path: String, node_inst: ShaderGraphNodeInstance,
		key: String, path_edit: LineEdit) -> void:
	_update_node_property(node_inst, key, path)
	path_edit.text = path


func _update_node_property(
		node_inst: ShaderGraphNodeInstance,
		key: String,
		value: Variant) -> void:
	node_inst.set_property(key, value)
	property_edited.emit(node_inst, key, value)
