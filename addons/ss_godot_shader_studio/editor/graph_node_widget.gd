@tool
extends GraphNode

signal node_property_changed(key: String, value: Variant)

const COLOR_INPUT  := Color(0.27, 0.76, 0.35)
const COLOR_OUTPUT := Color(0.85, 0.55, 0.15)

var _node_inst: ShaderGraphNodeInstance = null


func setup(node_inst: ShaderGraphNodeInstance, port_info: Dictionary) -> void:
	_node_inst = node_inst
	title = node_inst.get_title()

	# Remove all existing children (the template VBoxContainer)
	clear_all_slots()
	for child in get_children():
		remove_child(child)
		child.free()

	# Reroute nodes get a compact, title-less widget — just two port dots.
	if node_inst.get_definition_id() == "utility/reroute":
		title = ""
		custom_minimum_size = Vector2(64, 0)
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(24, 20)
		add_child(row)
		set_slot(0, true, 0, COLOR_INPUT, true, 0, COLOR_OUTPUT)
		return

	# Parameter nodes get inline name + value editing controls.
	if node_inst.get_definition_id().begins_with("parameter/"):
		_setup_parameter_node(node_inst)
		return

	var inputs: Array  = port_info.get("inputs", [])
	var outputs: Array = port_info.get("outputs", [])
	var n_rows: int    = maxi(inputs.size(), outputs.size())

	# Need at least one row to display the node
	if n_rows == 0:
		n_rows = 1

	for i in n_rows:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_FILL

		var left := Label.new()
		left.text = str(inputs[i]) if i < inputs.size() else ""
		left.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(left)

		var right := Label.new()
		right.text = str(outputs[i]) if i < outputs.size() else ""
		right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(right)

		add_child(row)

		set_slot(i,
			i < inputs.size(),  # left enabled
			0,                  # left type
			COLOR_INPUT,
			i < outputs.size(), # right enabled
			0,                  # right type
			COLOR_OUTPUT,
		)



# ---------------------------------------------------------------------------
# Parameter node inline editor
# ---------------------------------------------------------------------------

func _setup_parameter_node(node_inst: ShaderGraphNodeInstance) -> void:
	var def_id := node_inst.get_definition_id()
	custom_minimum_size = Vector2(260, 0)

	# Row 0: editable param name + output port on the right.
	var name_row := HBoxContainer.new()
	name_row.size_flags_horizontal = Control.SIZE_FILL

	var name_lbl := Label.new()
	name_lbl.text = "Name"
	name_lbl.custom_minimum_size = Vector2(44, 0)
	name_row.add_child(name_lbl)

	var name_edit := LineEdit.new()
	var cur_name = node_inst.get_property("param_name")
	name_edit.text = str(cur_name) if cur_name != null else ""
	name_edit.placeholder_text = "param_name"
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.text_submitted.connect(func(t: String) -> void:
		_emit_property("param_name", t)
	)
	name_edit.focus_exited.connect(func() -> void:
		_emit_property("param_name", name_edit.text)
	)
	name_row.add_child(name_edit)
	add_child(name_row)
	# Slot 0: no input port, output port on right.
	set_slot(0, false, 0, COLOR_INPUT, true, 0, COLOR_OUTPUT)

	# Value rows — type-specific.
	match def_id:
		"parameter/float":
			_add_float_value_rows("default_value", node_inst, 1, false)
		"parameter/int":
			_add_float_value_rows("default_value", node_inst, 1, true)
		"parameter/toggle":
			_add_toggle_row("Value", "default_value", node_inst, 1)
		"parameter/vec2":
			_add_vec_rows(["X", "Y"], "default_value", node_inst, 1, 2, "vec2")
		"parameter/vec3":
			_add_vec_rows(["X", "Y", "Z"], "default_value", node_inst, 1, 3, "vec3")
		"parameter/vec4":
			_add_vec_rows(["X", "Y", "Z", "W"], "default_value", node_inst, 1, 4, "vec4")
		"parameter/color":
			_add_color_row("default_value", node_inst, 1)
		"parameter/texture2d":
			_add_texture_rows(node_inst, 1)
		# parameter/sampler_cube: no value rows


# Wrapper: shows a slider or a plain spinbox depending on use_slider property.
func _add_float_value_rows(key: String, node_inst: ShaderGraphNodeInstance,
		slot_idx: int, is_int: bool) -> int:
	var use_slider_prop = node_inst.get_property("use_slider")
	var use_slider := use_slider_prop == null or str(use_slider_prop) != "false"

	# Toggle row (always present)
	var toggle_row := HBoxContainer.new()
	toggle_row.size_flags_horizontal = Control.SIZE_FILL
	var toggle_lbl := Label.new()
	toggle_lbl.text = "Slider"
	toggle_lbl.custom_minimum_size = Vector2(44, 0)
	toggle_row.add_child(toggle_lbl)
	var toggle_btn := CheckButton.new()
	toggle_btn.button_pressed = use_slider
	toggle_btn.toggled.connect(func(on: bool) -> void:
		_emit_property("use_slider", "true" if on else "false")
	)
	toggle_row.add_child(toggle_btn)
	add_child(toggle_row)
	set_slot(slot_idx, false, 0, COLOR_INPUT, false, 0, COLOR_OUTPUT)

	if use_slider:
		return _add_float_slider_rows(key, node_inst, slot_idx + 1, is_int)

	# Plain value row
	var spb_row := HBoxContainer.new()
	spb_row.size_flags_horizontal = Control.SIZE_FILL
	var val_lbl := Label.new()
	val_lbl.text = "Value"
	val_lbl.custom_minimum_size = Vector2(44, 0)
	spb_row.add_child(val_lbl)
	var spb := SpinBox.new()
	spb.min_value = -9999.0
	spb.max_value = 9999.0
	spb.step = 1.0 if is_int else 0.001
	spb.allow_greater = true
	spb.allow_lesser = true
	var cur_val = node_inst.get_property(key)
	spb.value = float(str(cur_val)) if cur_val != null else 0.0
	spb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spb.value_changed.connect(func(v: float) -> void:
		_emit_property(key, str(int(v)) if is_int else str(v))
	)
	spb_row.add_child(spb)
	add_child(spb_row)
	set_slot(slot_idx + 1, false, 0, COLOR_INPUT, false, 0, COLOR_OUTPUT)
	return slot_idx + 2


func _add_texture_rows(node_inst: ShaderGraphNodeInstance, slot_idx: int) -> int:
	# Texture picker row
	var pick_row := HBoxContainer.new()
	pick_row.size_flags_horizontal = Control.SIZE_FILL
	var pick_lbl := Label.new()
	pick_lbl.text = "Tex"
	pick_lbl.custom_minimum_size = Vector2(44, 0)
	pick_row.add_child(pick_lbl)
	var picker := EditorResourcePicker.new()
	picker.base_type = "Texture2D"
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cur_path = node_inst.get_property("texture_path")
	if cur_path != null and str(cur_path) != "":
		var tex = load(str(cur_path))
		if tex is Texture2D:
			picker.edited_resource = tex
	picker.resource_changed.connect(func(res: Resource) -> void:
		_emit_property("texture_path", res.resource_path if res != null else "")
	)
	pick_row.add_child(picker)
	add_child(pick_row)
	set_slot(slot_idx, false, 0, COLOR_INPUT, false, 0, COLOR_OUTPUT)

	# Hint dropdown row
	var hint_row := HBoxContainer.new()
	hint_row.size_flags_horizontal = Control.SIZE_FILL
	var hint_lbl := Label.new()
	hint_lbl.text = "Hint"
	hint_lbl.custom_minimum_size = Vector2(44, 0)
	hint_row.add_child(hint_lbl)
	var hint_opt := OptionButton.new()
	hint_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	const _HINT_VALUES := ["", "hint_default_white", "hint_default_black",
		"hint_normal", "hint_roughness_gray"]
	const _HINT_LABELS := ["none", "default white", "default black",
		"normal map", "roughness gray"]
	for i in _HINT_VALUES.size():
		hint_opt.add_item(_HINT_LABELS[i], i)
	var cur_hint = node_inst.get_property("texture_hint")
	var cur_hint_str := str(cur_hint) if cur_hint != null else ""
	var hint_idx := _HINT_VALUES.find(cur_hint_str)
	hint_opt.selected = hint_idx if hint_idx >= 0 else 0
	hint_opt.item_selected.connect(func(idx: int) -> void:
		_emit_property("texture_hint", _HINT_VALUES[idx])
	)
	hint_row.add_child(hint_opt)
	add_child(hint_row)
	set_slot(slot_idx + 1, false, 0, COLOR_INPUT, false, 0, COLOR_OUTPUT)
	return slot_idx + 2


func _add_float_slider_rows(key: String, node_inst: ShaderGraphNodeInstance,
		slot_idx: int, is_int: bool = false) -> int:
	var _pf := func(prop: String, def: float) -> float:
		var v = node_inst.get_property(prop)
		return float(str(v)) if v != null else def
	var cur_val  := _pf.call(key,          0.0)
	var cur_min  := _pf.call("param_min",  0.0)
	var cur_max  := _pf.call("param_max",  1.0)
	var cur_step := _pf.call("param_step", 1.0 if is_int else 0.01)

	# --- Slider row ---
	var slider_row := HBoxContainer.new()
	slider_row.size_flags_horizontal = Control.SIZE_FILL

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
	slider_row.add_child(val_lbl)

	add_child(slider_row)
	set_slot(slot_idx, false, 0, COLOR_INPUT, false, 0, COLOR_OUTPUT)

	# --- Config row: Min / Max / Step ---
	var cfg_row := HBoxContainer.new()
	cfg_row.size_flags_horizontal = Control.SIZE_FILL

	var min_lbl := Label.new()
	min_lbl.text = "Min"
	min_lbl.custom_minimum_size = Vector2(22, 0)
	cfg_row.add_child(min_lbl)
	var min_edit := LineEdit.new()
	min_edit.text = str(cur_min)
	min_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cfg_row.add_child(min_edit)

	var max_lbl := Label.new()
	max_lbl.text = "Max"
	max_lbl.custom_minimum_size = Vector2(26, 0)
	cfg_row.add_child(max_lbl)
	var max_edit := LineEdit.new()
	max_edit.text = str(cur_max)
	max_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cfg_row.add_child(max_edit)

	var stp_lbl := Label.new()
	stp_lbl.text = "Stp"
	stp_lbl.custom_minimum_size = Vector2(22, 0)
	cfg_row.add_child(stp_lbl)
	var stp_edit := LineEdit.new()
	stp_edit.text = str(cur_step)
	stp_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cfg_row.add_child(stp_edit)

	add_child(cfg_row)
	set_slot(slot_idx + 1, false, 0, COLOR_INPUT, false, 0, COLOR_OUTPUT)

	# --- Signals ---
	slider.value_changed.connect(func(v: float) -> void:
		val_lbl.text = str(int(v)) if is_int else ("%.3f" % v)
		_emit_property(key, str(int(v)) if is_int else str(v))
	)

	var apply_cfg := func() -> void:
		if not min_edit.text.is_valid_float() or not max_edit.text.is_valid_float() \
				or not stp_edit.text.is_valid_float():
			return
		slider.min_value = float(min_edit.text)
		slider.max_value = float(max_edit.text)
		slider.step      = float(stp_edit.text)
		_emit_property("param_min",  min_edit.text)
		_emit_property("param_max",  max_edit.text)
		_emit_property("param_step", stp_edit.text)

	min_edit.text_submitted.connect(func(_t: String) -> void: apply_cfg.call())
	min_edit.focus_exited.connect(func() -> void: apply_cfg.call())
	max_edit.text_submitted.connect(func(_t: String) -> void: apply_cfg.call())
	max_edit.focus_exited.connect(func() -> void: apply_cfg.call())
	stp_edit.text_submitted.connect(func(_t: String) -> void: apply_cfg.call())
	stp_edit.focus_exited.connect(func() -> void: apply_cfg.call())

	return slot_idx + 2


func _add_toggle_row(label_text: String, key: String,
		node_inst: ShaderGraphNodeInstance, slot_idx: int) -> int:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_FILL
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(44, 0)
	row.add_child(lbl)
	var check := CheckBox.new()
	var cur = node_inst.get_property(key)
	check.button_pressed = float(str(cur)) > 0.5 if cur != null else false
	check.toggled.connect(func(pressed: bool) -> void:
		_emit_property(key, "1.0" if pressed else "0.0")
	)
	row.add_child(check)
	add_child(row)
	set_slot(slot_idx, false, 0, COLOR_INPUT, false, 0, COLOR_OUTPUT)
	return slot_idx + 1


func _add_vec_rows(labels: Array, key: String,
		node_inst: ShaderGraphNodeInstance, start_slot: int,
		n: int, prefix: String) -> int:
	var cur = node_inst.get_property(key)
	var components := _parse_vec_components(str(cur) if cur != null else "", n)
	var spinboxes: Array = []

	for i in n:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_FILL
		var lbl := Label.new()
		lbl.text = labels[i]
		lbl.custom_minimum_size = Vector2(16, 0)
		row.add_child(lbl)
		var spb := SpinBox.new()
		spb.min_value      = -9999.0
		spb.max_value      =  9999.0
		spb.step           = 0.001
		spb.value          = float(components[i])
		spb.allow_greater  = true
		spb.allow_lesser   = true
		spb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spinboxes.append(spb)
		row.add_child(spb)
		add_child(row)
		set_slot(start_slot + i, false, 0, COLOR_INPUT, false, 0, COLOR_OUTPUT)

	# Connect after all spinboxes exist so the lambda captures the complete array.
	for spb: SpinBox in spinboxes:
		spb.value_changed.connect(func(_v: float) -> void:
			var vals := spinboxes.map(func(s: SpinBox) -> String: return "%.6f" % s.value)
			_emit_property(key, _build_vec_value(vals, prefix))
		)

	return start_slot + n


func _add_color_row(key: String, node_inst: ShaderGraphNodeInstance, slot_idx: int) -> int:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_FILL
	var lbl := Label.new()
	lbl.text = "Color"
	lbl.custom_minimum_size = Vector2(44, 0)
	row.add_child(lbl)
	var picker := ColorPickerButton.new()
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.edit_alpha = true
	# Parse stored vec4 string into a Color.
	var cur = node_inst.get_property(key)
	var comps := _parse_vec_components(str(cur) if cur != null else "", 4)
	picker.color = Color(
		float(comps[0]), float(comps[1]),
		float(comps[2]), float(comps[3])
	)
	picker.color_changed.connect(func(c: Color) -> void:
		_emit_property(key, "vec4(%.4f, %.4f, %.4f, %.4f)" % [c.r, c.g, c.b, c.a])
	)
	row.add_child(picker)
	add_child(row)
	set_slot(slot_idx, false, 0, COLOR_INPUT, false, 0, COLOR_OUTPUT)
	return slot_idx + 1


func _emit_property(key: String, value: Variant) -> void:
	if _node_inst == null:
		return
	_node_inst.set_property(key, value)
	node_property_changed.emit(key, value)


static func _parse_vec_components(s: String, n: int) -> Array:
	# Parse "vecN(a, b, c, ...)" format.
	var re := RegEx.new()
	re.compile("vec\\d+\\((.+)\\)")
	var m := re.search(s)
	if m:
		var parts := m.get_string(1).split(",")
		var result: Array = []
		for i in n:
			result.append(parts[i].strip_edges() if i < parts.size() else "0.0")
		return result
	# Single value or empty — put it in first component, rest are 0.
	var result: Array = []
	for i in n:
		result.append(s.strip_edges() if i == 0 and not s.is_empty() else "0.0")
	return result


static func _build_vec_value(components: Array, prefix: String) -> String:
	return "%s(%s)" % [prefix, ", ".join(components)]


# ---------------------------------------------------------------------------
# Validation overlay
# ---------------------------------------------------------------------------

## Updates the title bar color to reflect validation state.
## Call with both false to restore the default theme.
func set_validation_state(has_error: bool, has_warning: bool) -> void:
	if has_error:
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.55, 0.15, 0.15)
		s.corner_radius_top_left = 4
		s.corner_radius_top_right = 4
		add_theme_stylebox_override("titlebar", s)
	elif has_warning:
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.50, 0.38, 0.08)
		s.corner_radius_top_left = 4
		s.corner_radius_top_right = 4
		add_theme_stylebox_override("titlebar", s)
	else:
		remove_theme_stylebox_override("titlebar")
