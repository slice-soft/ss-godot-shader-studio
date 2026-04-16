@tool
extends PanelContainer

signal parameter_edited(node_instance: ShaderGraphNodeInstance, key: String, value: Variant)

@onready var _list: VBoxContainer = $VBoxContainer/ScrollContainer/ParamsList

var _document: ShaderGraphDocument = null


func refresh(doc: ShaderGraphDocument) -> void:
	_document = doc
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()

	if doc == null:
		return

	var found := false
	for n in doc.get_all_nodes():
		var inst := n as ShaderGraphNodeInstance
		if inst == null or not inst.definition_id.begins_with("parameter/"):
			continue
		found = true
		_list.add_child(_make_entry(inst))

	if not found:
		var hint := Label.new()
		hint.text = "No parameters.\nDouble-click the canvas\nand search 'parameter'."
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list.add_child(hint)

	call_deferred(&"_rewire_focus")


func _make_entry(inst: ShaderGraphNodeInstance) -> Control:
	var container := VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.focus_mode = Control.FOCUS_NONE
	container.mouse_filter = Control.MOUSE_FILTER_PASS

	# Header row: colored type label + name edit
	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.focus_mode = Control.FOCUS_NONE
	header.mouse_filter = Control.MOUSE_FILTER_PASS

	var type_label := Label.new()
	type_label.text = _type_short(inst.definition_id)
	type_label.custom_minimum_size = Vector2(52, 0)
	type_label.add_theme_color_override("font_color", _type_color(inst.definition_id))
	type_label.focus_mode = Control.FOCUS_NONE
	header.add_child(type_label)

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
	header.add_child(name_edit)
	container.add_child(header)

	# Type-specific value controls
	match inst.definition_id:
		"parameter/float":
			_add_float_controls(container, inst, false)
		"parameter/int":
			_add_float_controls(container, inst, true)
		"parameter/toggle":
			_add_toggle_controls(container, inst)
		"parameter/vec2":
			_add_vec_controls(container, ["X", "Y"], inst, 2, "vec2")
		"parameter/vec3":
			_add_vec_controls(container, ["X", "Y", "Z"], inst, 3, "vec3")
		"parameter/vec4":
			_add_vec_controls(container, ["X", "Y", "Z", "W"], inst, 4, "vec4")
		"parameter/color":
			_add_color_controls(container, inst)
		"parameter/texture2d":
			_add_texture_controls(container, inst)
		# parameter/sampler_cube: name only, no default value

	var sep := HSeparator.new()
	sep.focus_mode = Control.FOCUS_NONE
	container.add_child(sep)

	return container


# ---------------------------------------------------------------------------
# Float / Int
# ---------------------------------------------------------------------------

func _add_float_controls(parent: VBoxContainer, inst: ShaderGraphNodeInstance, is_int: bool) -> void:
	var use_slider_prop = inst.get_property("use_slider")
	var use_slider := use_slider_prop == null or str(use_slider_prop) != "false"

	var toggle_row := _make_label_row("Slider")
	var toggle_btn := CheckButton.new()
	toggle_btn.button_pressed = use_slider
	toggle_row.add_child(toggle_btn)
	parent.add_child(toggle_row)

	var value_area := VBoxContainer.new()
	value_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_area.focus_mode = Control.FOCUS_NONE
	value_area.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(value_area)

	var rebuild := func() -> void:
		for c in value_area.get_children():
			value_area.remove_child(c)
			c.free()
		if toggle_btn.button_pressed:
			_fill_slider_controls(value_area, inst, is_int)
		else:
			_fill_spinbox_controls(value_area, inst, is_int)
		call_deferred(&"_rewire_focus")

	toggle_btn.toggled.connect(func(on: bool) -> void:
		_update_parameter(inst, "use_slider", "true" if on else "false")
		rebuild.call()
	)
	rebuild.call()


func _fill_spinbox_controls(parent: VBoxContainer, inst: ShaderGraphNodeInstance, is_int: bool) -> void:
	var row := _make_label_row("Value")
	var spb := SpinBox.new()
	spb.min_value = -9999.0
	spb.max_value =  9999.0
	spb.step = 1.0 if is_int else 0.001
	spb.allow_greater = true
	spb.allow_lesser  = true
	var cur = inst.get_property("default_value")
	spb.value = float(str(cur)) if cur != null else 0.0
	spb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spb.value_changed.connect(func(v: float) -> void:
		_update_parameter(inst, "default_value", str(int(v)) if is_int else str(v))
	)
	row.add_child(spb)
	parent.add_child(row)


func _fill_slider_controls(parent: VBoxContainer, inst: ShaderGraphNodeInstance, is_int: bool) -> void:
	var _pf := func(prop: String, def: float) -> float:
		var v = inst.get_property(prop)
		return float(str(v)) if v != null else def
	var cur_val  := _pf.call("default_value", 0.0)
	var cur_min  := _pf.call("param_min",     0.0)
	var cur_max  := _pf.call("param_max",     1.0)
	var cur_step := _pf.call("param_step",    1.0 if is_int else 0.01)

	# Slider + value label row
	var slider_row := HBoxContainer.new()
	slider_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_row.focus_mode = Control.FOCUS_NONE
	slider_row.mouse_filter = Control.MOUSE_FILTER_PASS

	var slider := HSlider.new()
	slider.min_value = cur_min
	slider.max_value = cur_max
	slider.step      = cur_step
	slider.value     = clampf(cur_val, cur_min, cur_max)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_row.add_child(slider)

	var val_lbl := Label.new()
	val_lbl.text = str(int(cur_val)) if is_int else ("%.3f" % cur_val)
	val_lbl.custom_minimum_size = Vector2(50, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.focus_mode = Control.FOCUS_NONE
	slider_row.add_child(val_lbl)
	parent.add_child(slider_row)

	# Min / Max / Step config row
	var cfg_row := HBoxContainer.new()
	cfg_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cfg_row.focus_mode = Control.FOCUS_NONE
	cfg_row.mouse_filter = Control.MOUSE_FILTER_PASS

	var min_lbl := Label.new()
	min_lbl.text = "Min"
	min_lbl.custom_minimum_size = Vector2(22, 0)
	min_lbl.focus_mode = Control.FOCUS_NONE
	cfg_row.add_child(min_lbl)
	var min_edit := LineEdit.new()
	min_edit.text = str(cur_min)
	min_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cfg_row.add_child(min_edit)

	var max_lbl := Label.new()
	max_lbl.text = "Max"
	max_lbl.custom_minimum_size = Vector2(26, 0)
	max_lbl.focus_mode = Control.FOCUS_NONE
	cfg_row.add_child(max_lbl)
	var max_edit := LineEdit.new()
	max_edit.text = str(cur_max)
	max_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cfg_row.add_child(max_edit)

	var stp_lbl := Label.new()
	stp_lbl.text = "Stp"
	stp_lbl.custom_minimum_size = Vector2(22, 0)
	stp_lbl.focus_mode = Control.FOCUS_NONE
	cfg_row.add_child(stp_lbl)
	var stp_edit := LineEdit.new()
	stp_edit.text = str(cur_step)
	stp_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cfg_row.add_child(stp_edit)

	parent.add_child(cfg_row)

	slider.value_changed.connect(func(v: float) -> void:
		val_lbl.text = str(int(v)) if is_int else ("%.3f" % v)
		_update_parameter(inst, "default_value", str(int(v)) if is_int else str(v))
	)

	var apply_cfg := func() -> void:
		if not min_edit.text.is_valid_float() or not max_edit.text.is_valid_float() \
				or not stp_edit.text.is_valid_float():
			return
		slider.min_value = float(min_edit.text)
		slider.max_value = float(max_edit.text)
		slider.step      = float(stp_edit.text)
		_update_parameter(inst, "param_min",  min_edit.text)
		_update_parameter(inst, "param_max",  max_edit.text)
		_update_parameter(inst, "param_step", stp_edit.text)

	min_edit.text_submitted.connect(func(_t: String) -> void: apply_cfg.call())
	min_edit.focus_exited.connect(func() -> void: apply_cfg.call())
	max_edit.text_submitted.connect(func(_t: String) -> void: apply_cfg.call())
	max_edit.focus_exited.connect(func() -> void: apply_cfg.call())
	stp_edit.text_submitted.connect(func(_t: String) -> void: apply_cfg.call())
	stp_edit.focus_exited.connect(func() -> void: apply_cfg.call())


# ---------------------------------------------------------------------------
# Toggle / Bool
# ---------------------------------------------------------------------------

func _add_toggle_controls(parent: VBoxContainer, inst: ShaderGraphNodeInstance) -> void:
	var row := _make_label_row("Value")
	var check := CheckBox.new()
	var cur = inst.get_property("default_value")
	check.button_pressed = float(str(cur)) > 0.5 if cur != null else false
	check.toggled.connect(func(pressed: bool) -> void:
		_update_parameter(inst, "default_value", "1.0" if pressed else "0.0")
	)
	row.add_child(check)
	parent.add_child(row)


# ---------------------------------------------------------------------------
# Vec2 / Vec3 / Vec4
# ---------------------------------------------------------------------------

func _add_vec_controls(parent: VBoxContainer, labels: Array,
		inst: ShaderGraphNodeInstance, n: int, prefix: String) -> void:
	var cur = inst.get_property("default_value")
	var components := _parse_vec_components(str(cur) if cur != null else "", n)
	var spinboxes: Array = []

	for i in n:
		var row := _make_label_row(labels[i])
		var spb := SpinBox.new()
		spb.min_value = -9999.0
		spb.max_value =  9999.0
		spb.step = 0.001
		spb.value = float(components[i])
		spb.allow_greater = true
		spb.allow_lesser  = true
		spb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spinboxes.append(spb)
		row.add_child(spb)
		parent.add_child(row)

	for spb: SpinBox in spinboxes:
		spb.value_changed.connect(func(_v: float) -> void:
			var vals := spinboxes.map(func(s: SpinBox) -> String: return "%.6f" % s.value)
			_update_parameter(inst, "default_value", _build_vec_value(vals, prefix))
		)


# ---------------------------------------------------------------------------
# Color
# ---------------------------------------------------------------------------

func _add_color_controls(parent: VBoxContainer, inst: ShaderGraphNodeInstance) -> void:
	var row := _make_label_row("Color")
	var picker := ColorPickerButton.new()
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.edit_alpha = true
	var cur = inst.get_property("default_value")
	var comps := _parse_vec_components(str(cur) if cur != null else "", 4)
	picker.color = Color(
		float(comps[0]), float(comps[1]), float(comps[2]), float(comps[3])
	)
	picker.color_changed.connect(func(c: Color) -> void:
		_update_parameter(inst, "default_value",
			"vec4(%.4f, %.4f, %.4f, %.4f)" % [c.r, c.g, c.b, c.a])
	)
	row.add_child(picker)
	parent.add_child(row)


# ---------------------------------------------------------------------------
# Texture2D
# ---------------------------------------------------------------------------

func _add_texture_controls(parent: VBoxContainer, inst: ShaderGraphNodeInstance) -> void:
	var pick_row := _make_label_row("Tex")
	var picker := EditorResourcePicker.new()
	picker.base_type = "Texture2D"
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cur_path = inst.get_property("texture_path")
	if cur_path != null and str(cur_path) != "":
		var tex = load(str(cur_path))
		if tex is Texture2D:
			picker.edited_resource = tex
	picker.resource_changed.connect(func(res: Resource) -> void:
		_update_parameter(inst, "texture_path", res.resource_path if res != null else "")
	)
	pick_row.add_child(picker)
	parent.add_child(pick_row)

	var hint_row := _make_label_row("Hint")
	var hint_opt := OptionButton.new()
	hint_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	const _HINT_VALUES := ["", "hint_default_white", "hint_default_black",
		"hint_normal", "hint_roughness_gray"]
	const _HINT_LABELS := ["none", "default white", "default black",
		"normal map", "roughness gray"]
	for i in _HINT_VALUES.size():
		hint_opt.add_item(_HINT_LABELS[i], i)
	var cur_hint = inst.get_property("texture_hint")
	var hint_idx := _HINT_VALUES.find(str(cur_hint) if cur_hint != null else "")
	hint_opt.selected = hint_idx if hint_idx >= 0 else 0
	hint_opt.item_selected.connect(func(idx: int) -> void:
		_update_parameter(inst, "texture_hint", _HINT_VALUES[idx])
	)
	hint_row.add_child(hint_opt)
	parent.add_child(hint_row)


# ---------------------------------------------------------------------------
# Focus chain — called deferred so the tree is fully settled
# ---------------------------------------------------------------------------

func _rewire_focus() -> void:
	var focusables: Array[Control] = []
	_collect_focusables(_list, focusables)
	var n := focusables.size()
	if n == 0:
		return
	for i in n:
		var ctrl  := focusables[i]
		var prev  := focusables[(i - 1 + n) % n]
		var nxt   := focusables[(i + 1) % n]
		ctrl.focus_next     = ctrl.get_path_to(nxt)
		ctrl.focus_previous = ctrl.get_path_to(prev)


func _collect_focusables(node: Node, result: Array[Control]) -> void:
	if node is Control:
		var ctrl := node as Control
		# Focusable leaf — add and don't recurse (avoids entering SpinBox internals etc.)
		if ctrl.focus_mode != Control.FOCUS_NONE and ctrl.is_visible_in_tree():
			result.append(ctrl)
			return
	for child in node.get_children():
		_collect_focusables(child, result)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_label_row(label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.focus_mode = Control.FOCUS_NONE
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(52, 0)
	lbl.focus_mode = Control.FOCUS_NONE
	row.add_child(lbl)
	return row


func _type_short(def_id: String) -> String:
	match def_id:
		"parameter/float":        return "float"
		"parameter/int":          return "int"
		"parameter/vec2":         return "vec2"
		"parameter/vec3":         return "vec3"
		"parameter/vec4":         return "vec4"
		"parameter/color":        return "color"
		"parameter/toggle":       return "bool"
		"parameter/texture2d":    return "tex2D"
		"parameter/sampler_cube": return "cube"
		_:                        return "?"


func _type_color(def_id: String) -> Color:
	match def_id:
		"parameter/float", "parameter/int":
			return Color(0.65, 0.85, 1.0)
		"parameter/vec2", "parameter/vec3", "parameter/vec4":
			return Color(0.8, 0.7, 1.0)
		"parameter/color":
			return Color(1.0, 0.85, 0.5)
		"parameter/toggle":
			return Color(0.7, 1.0, 0.7)
		"parameter/texture2d", "parameter/sampler_cube":
			return Color(1.0, 0.7, 0.7)
		_:
			return Color(0.8, 0.8, 0.8)


func _update_parameter(inst: ShaderGraphNodeInstance, key: String, value: Variant) -> void:
	inst.set_property(key, value)
	parameter_edited.emit(inst, key, value)


static func _parse_vec_components(s: String, n: int) -> Array:
	var re := RegEx.new()
	re.compile("vec\\d+\\((.+)\\)")
	var m := re.search(s)
	if m:
		var parts := m.get_string(1).split(",")
		var result: Array = []
		for i in n:
			result.append(parts[i].strip_edges() if i < parts.size() else "0.0")
		return result
	var result: Array = []
	for i in n:
		result.append(s.strip_edges() if i == 0 and not s.is_empty() else "0.0")
	return result


static func _build_vec_value(components: Array, prefix: String) -> String:
	return "%s(%s)" % [prefix, ", ".join(components)]
