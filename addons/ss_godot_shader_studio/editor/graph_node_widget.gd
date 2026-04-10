@tool
extends GraphNode

const COLOR_INPUT  := Color(0.27, 0.76, 0.35)
const COLOR_OUTPUT := Color(0.85, 0.55, 0.15)


func setup(node_inst: ShaderGraphNodeInstance, port_info: Dictionary) -> void:
	title = node_inst.get_title()

	# Remove all existing children (the template VBoxContainer)
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
		left.text = inputs[i].capitalize() if i < inputs.size() else ""
		left.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(left)

		var right := Label.new()
		right.text = outputs[i].capitalize() if i < outputs.size() else ""
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
