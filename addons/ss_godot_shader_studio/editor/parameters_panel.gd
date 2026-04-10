@tool
extends PanelContainer

signal parameter_edited(node_instance: ShaderGraphNodeInstance, key: String, value: Variant)

@onready var _list: VBoxContainer = $VBoxContainer/ScrollContainer/ParamsList

var _document: ShaderGraphDocument = null


func refresh(doc: ShaderGraphDocument) -> void:
	_document = doc
	for child in _list.get_children():
		_list.remove_child(child)
		child.free()

	if doc == null:
		return

	var found := false
	for n in doc.get_all_nodes():
		var inst := n as ShaderGraphNodeInstance
		if inst == null or not inst.definition_id.begins_with("parameter/"):
			continue
		found = true
		_list.add_child(_make_row(inst))

	if not found:
		var hint := Label.new()
		hint.text = "No parameters.\nDouble-click the canvas\nand search 'parameter'."
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list.add_child(hint)


func _make_row(inst: ShaderGraphNodeInstance) -> Control:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var type_label := Label.new()
	type_label.text = _type_short(inst.definition_id)
	type_label.custom_minimum_size = Vector2(44, 0)
	type_label.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0))
	row.add_child(type_label)

	var name_edit := LineEdit.new()
	var cur_name: Variant = inst.get_property("param_name")
	name_edit.text = str(cur_name) if cur_name != null else ""
	name_edit.placeholder_text = "param_name"
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.text_submitted.connect(func(text: String) -> void:
		_update_parameter(inst, "param_name", text)
	)
	name_edit.focus_exited.connect(func() -> void:
		_update_parameter(inst, "param_name", name_edit.text)
	)
	row.add_child(name_edit)

	# Default value field (not shown for texture2d — no simple literal default)
	if inst.definition_id != "parameter/texture2d":
		var val_edit := LineEdit.new()
		var cur_val: Variant = inst.get_property("default_value")
		val_edit.text = str(cur_val) if cur_val != null else ""
		val_edit.placeholder_text = "default"
		val_edit.custom_minimum_size = Vector2(72, 0)
		val_edit.text_submitted.connect(func(text: String) -> void:
			_update_parameter(inst, "default_value", text)
		)
		val_edit.focus_exited.connect(func() -> void:
			_update_parameter(inst, "default_value", val_edit.text)
		)
		row.add_child(val_edit)

	return row


func _type_short(def_id: String) -> String:
	match def_id:
		"parameter/float":     return "float"
		"parameter/vec4":      return "vec4"
		"parameter/color":     return "color"
		"parameter/texture2d": return "tex2D"
		_:                     return "?"


func _update_parameter(inst: ShaderGraphNodeInstance, key: String, value: Variant) -> void:
	inst.set_property(key, value)
	parameter_edited.emit(inst, key, value)
