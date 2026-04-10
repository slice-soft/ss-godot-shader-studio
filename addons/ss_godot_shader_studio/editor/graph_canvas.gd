@tool
extends GraphEdit

const SubgraphContract = preload("res://addons/ss_godot_shader_studio/core/graph/subgraph_contract.gd")

signal node_selected_in_canvas(node_instance: ShaderGraphNodeInstance)
signal frame_selected_in_canvas(frame_data: Dictionary, frame_widget: GraphFrame)
signal graph_changed

# Port data is read live from NodeRegistry — no hardcoded table needed.

# Default values for unconnected input ports, stored as GLSL literal strings.
# Only entries that differ from zero or have meaningful non-zero values are listed.
const PORT_DEFAULTS: Dictionary = {
	"math/add":      {"a": "0.0",  "b": "0.0"},
	"math/subtract": {"a": "0.0",  "b": "0.0"},
	"math/multiply": {"a": "1.0",  "b": "1.0"},
	"math/divide":   {"a": "1.0",  "b": "1.0"},
	"math/power":    {"base": "1.0", "exp": "2.0"},
	"math/sqrt":     {"x": "1.0"},
	"math/abs":      {"x": "0.0"},
	"math/negate":   {"x": "0.0"},
	"math/floor":    {"x": "0.0"},
	"math/ceil":     {"x": "0.0"},
	"math/round":    {"x": "0.0"},
	"math/fract":    {"x": "0.0"},
	"math/mod":      {"x": "0.0",  "y": "1.0"},
	"math/min":      {"a": "0.0",  "b": "0.0"},
	"math/max":      {"a": "0.0",  "b": "0.0"},
	"math/sign":     {"x": "0.0"},
	"float/lerp":       {"a": "0.0", "b": "1.0", "t": "0.5"},
	"float/clamp":      {"x": "0.0", "min_val": "0.0", "max_val": "1.0"},
	"float/smoothstep": {"edge0": "0.0", "edge1": "1.0", "x": "0.5"},
	"float/step":       {"edge": "0.5", "x": "0.0"},
	"float/saturate":   {"x": "0.0"},
	"float/remap":      {"x": "0.0", "in_min": "0.0", "in_max": "1.0", "out_min": "0.0", "out_max": "1.0"},
	"swizzle/append_vec2": {"x": "0.0", "y": "0.0"},
	"swizzle/append_vec3": {"x": "0.0", "y": "0.0", "z": "0.0"},
	"swizzle/append_vec4": {"x": "0.0", "y": "0.0", "z": "0.0", "w": "1.0"},
}

var _document: ShaderGraphDocument = null
var _undo_redo: EditorUndoRedoManager = null

# Clipboard for copy/paste. Each entry: {def_id, title, props, rel_pos}.
# _clipboard_edges: [{from_idx, from_port, to_idx, to_port}] (indices into _clipboard).
var _clipboard: Array = []
var _clipboard_edges: Array = []

@onready var _search_popup = $NodeSearchPopup

const _WIDGET_SCENE = preload("res://addons/ss_godot_shader_studio/editor/graph_node_widget.tscn")


func _ready() -> void:
	connection_request.connect(_on_connection_request)
	disconnection_request.connect(_on_disconnection_request)
	node_selected.connect(_on_node_selected)
	delete_nodes_request.connect(_on_delete_nodes_request)
	graph_elements_linked_to_frame_request.connect(_on_elements_linked_to_frame)
	_search_popup.node_chosen.connect(_on_node_chosen)
	right_disconnects = true


func setup_undo_redo(ur: EditorUndoRedoManager) -> void:
	_undo_redo = ur


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.double_click and mb.pressed:
			var on_node := false
			for child in get_children():
				if (child is GraphNode or child is GraphFrame) \
						and child.get_global_rect().has_point(mb.global_position):
					on_node = true
					break
			if not on_node:
				var graph_pos := mb.position / zoom + scroll_offset
				_search_popup.open_at(DisplayServer.mouse_get_position(), graph_pos)
				accept_event()
	elif event is InputEventKey and event.pressed and not event.echo \
			and (event.ctrl_pressed or event.meta_pressed):
		match event.keycode:
			KEY_C:
				_copy_selected()
				accept_event()
			KEY_V:
				_paste_clipboard()
				accept_event()
			KEY_D:
				_duplicate_selected()
				accept_event()
			KEY_G:
				_create_frame_from_selection()
				accept_event()

func load_document(doc: ShaderGraphDocument) -> void:
	_document = doc
	_clear_canvas()

	for frame_data in doc.get_all_frames():
		_create_frame_widget(frame_data)

	for node_inst in doc.get_all_nodes():
		apply_port_defaults(node_inst as ShaderGraphNodeInstance)
		_create_node_widget(node_inst as ShaderGraphNodeInstance)

	_remove_invalid_edges()
	for edge in doc.get_all_edges():
		_connect_edge_visual(edge as ShaderGraphEdge)

	# Restore frame attachments after all widgets exist.
	for frame_data in doc.get_all_frames():
		for nid in frame_data.get("attached_nodes", []):
			if get_node_or_null(NodePath(nid)) != null:
				attach_graph_element_to_frame(nid, frame_data["id"])


func sync_positions_to_document() -> void:
	if _document == null:
		return
	for child in get_children():
		if child is GraphFrame:
			var frame_data: Dictionary = _document.get_frame(child.name)
			if not frame_data.is_empty():
				frame_data["position"] = child.position_offset
				frame_data["size"]     = child.size
				frame_data["title"]    = child.title
				# Persist which nodes are currently attached.
				var attached := get_attached_nodes_of_frame(child.name)
				frame_data["attached_nodes"] = attached.map(func(n): return String(n))
		elif child is GraphNode:
			var node_inst: ShaderGraphNodeInstance = _document.get_node(child.name)
			if node_inst != null:
				node_inst.set_position(child.position_offset)


func _clear_canvas() -> void:
	for child in get_children():
		if child is GraphFrame or child is GraphNode:
			remove_child(child)
			child.queue_free()
	clear_connections()


func _create_node_widget(node_inst: ShaderGraphNodeInstance) -> void:
	var widget: GraphNode = _WIDGET_SCENE.instantiate()
	widget.name = node_inst.get_id()
	widget.position_offset = node_inst.get_position()
	add_child(widget)
	widget.setup(node_inst, _get_port_info_for_node(node_inst))


func refresh_node_widget(node_inst: ShaderGraphNodeInstance) -> void:
	if node_inst == null:
		return
	var widget := get_node_or_null(NodePath(node_inst.get_id()))
	if widget == null:
		_create_node_widget(node_inst)
		return
	widget.setup(node_inst, _get_port_info_for_node(node_inst))
	widget.position_offset = node_inst.get_position()


func refresh_dynamic_ports() -> Dictionary:
	if _document == null:
		return {"removed_edges": 0}

	for entry in _document.get_all_nodes():
		var node_inst := entry as ShaderGraphNodeInstance
		if node_inst == null or not _is_dynamic_port_node(node_inst):
			continue
		refresh_node_widget(node_inst)

	var removed_edges := _remove_invalid_edges()
	_rebuild_connections()
	return {"removed_edges": removed_edges}


func _get_port_info_for_node(node_inst: ShaderGraphNodeInstance) -> Dictionary:
	var inputs: Array = []
	var outputs: Array = []
	for port in _effective_input_ports(node_inst):
		inputs.append(port["name"])
	for port in _effective_output_ports(node_inst):
		outputs.append(port["name"])
	return {"inputs": inputs, "outputs": outputs}


func _connect_edge_visual(edge: ShaderGraphEdge) -> void:
	var from_id := edge.get_from_node_id()
	var to_id := edge.get_to_node_id()
	var from_port_idx := _output_index(from_id, edge.get_from_port_id())
	var to_port_idx := _input_index(to_id, edge.get_to_port_id())
	if from_port_idx >= 0 and to_port_idx >= 0:
		connect_node(from_id, from_port_idx, to_id, to_port_idx)


func _rebuild_connections() -> void:
	clear_connections()
	if _document == null:
		return
	for edge in _document.get_all_edges():
		_connect_edge_visual(edge as ShaderGraphEdge)


func _def_id_of(node_id: String) -> String:
	if _document == null:
		return ""
	var n: ShaderGraphNodeInstance = _document.get_node(node_id)
	return n.get_definition_id() if n != null else ""


func _output_index(node_id: String, port_id: String) -> int:
	var node_inst: ShaderGraphNodeInstance = _document.get_node(node_id) if _document != null else null
	if node_inst == null:
		return -1
	var outputs := _effective_output_ports(node_inst)
	for i in outputs.size():
		if outputs[i]["id"] == port_id:
			return i
	return -1


func _input_index(node_id: String, port_id: String) -> int:
	var node_inst: ShaderGraphNodeInstance = _document.get_node(node_id) if _document != null else null
	if node_inst == null:
		return -1
	var inputs := _effective_input_ports(node_inst)
	for i in inputs.size():
		if inputs[i]["id"] == port_id:
			return i
	return -1


func _effective_input_ports(node_inst: ShaderGraphNodeInstance) -> Array:
	var registry = Engine.get_singleton("NodeRegistry") as NodeRegistry
	return SubgraphContract.get_input_ports(_document, node_inst, registry)


func _effective_output_ports(node_inst: ShaderGraphNodeInstance) -> Array:
	var registry = Engine.get_singleton("NodeRegistry") as NodeRegistry
	return SubgraphContract.get_output_ports(_document, node_inst, registry)


func _has_input_port(node_id: String, port_id: String) -> bool:
	var node_inst: ShaderGraphNodeInstance = _document.get_node(node_id) if _document != null else null
	if node_inst == null:
		return false
	for port in _effective_input_ports(node_inst):
		if port["id"] == port_id:
			return true
	return false


func _has_output_port(node_id: String, port_id: String) -> bool:
	var node_inst: ShaderGraphNodeInstance = _document.get_node(node_id) if _document != null else null
	if node_inst == null:
		return false
	for port in _effective_output_ports(node_inst):
		if port["id"] == port_id:
			return true
	return false


func _remove_invalid_edges() -> int:
	if _document == null:
		return 0

	var removed := 0
	var edges := _document.get_all_edges()
	for i in range(edges.size() - 1, -1, -1):
		var edge := edges[i] as ShaderGraphEdge
		if edge == null:
			continue
		if _has_output_port(edge.get_from_node_id(), edge.get_from_port_id()) \
				and _has_input_port(edge.get_to_node_id(), edge.get_to_port_id()):
			continue
		_document.remove_edge(edge.get_id())
		removed += 1
	return removed


func _is_dynamic_port_node(node_inst: ShaderGraphNodeInstance) -> bool:
	if node_inst == null:
		return false
	return node_inst.get_definition_id() == "utility/subgraph" \
			or node_inst.get_definition_id() == "subgraph/input" \
			or node_inst.get_definition_id() == "subgraph/output"


# ---------------------------------------------------------------------------
# Undo/redo primitives — called by UndoRedo history on do/undo.
# ---------------------------------------------------------------------------

## Add a node to the document and canvas, restoring a specific ID.
## Used both by initial creation (id == the one just generated) and by redo.
func _cmd_add_node(node_id: String, def_id: String, pos: Vector2,
		title: String, props: Dictionary) -> void:
	_document.add_node(def_id, pos)
	# The newly added node is always the last element — do NOT use get_node(temp_id)
	# because the auto-generated temp_id may collide with an existing node's id,
	# causing get_node() to return the wrong (pre-existing) node.
	var all_nodes := _document.get_all_nodes()
	var node_inst: ShaderGraphNodeInstance = all_nodes[all_nodes.size() - 1]
	# Restore the original id so edges and widget name stay consistent.
	node_inst.set_id(node_id)
	node_inst.set_title(title)
	for key in props:
		node_inst.set_property(key, props[key])
	apply_port_defaults(node_inst)
	_create_node_widget(node_inst)
	graph_changed.emit()


## Remove a node (and all its edges) from the document and canvas.
func _cmd_remove_node(node_id: String) -> void:
	_document.remove_node(node_id)
	var widget := get_node_or_null(NodePath(node_id))
	if is_instance_valid(widget):
		remove_child(widget)
		widget.queue_free()
	_rebuild_connections()
	graph_changed.emit()


## Add an edge to the document and draw it on the canvas.
func _cmd_add_edge(from_node: String, from_port: String,
		to_node: String, to_port: String) -> void:
	var edge_id := _document.add_edge(from_node, from_port, to_node, to_port)
	if not edge_id.is_empty():
		var from_idx := _output_index(from_node, from_port)
		var to_idx := _input_index(to_node, to_port)
		if from_idx >= 0 and to_idx >= 0:
			connect_node(from_node, from_idx, to_node, to_idx)
	graph_changed.emit()


## Remove an edge from the document and the canvas.
func _cmd_remove_edge(from_node: String, from_port: String,
		to_node: String, to_port: String) -> void:
	for edge in _document.get_all_edges():
		var e := edge as ShaderGraphEdge
		if (e.get_from_node_id() == from_node and e.get_from_port_id() == from_port
				and e.get_to_node_id() == to_node and e.get_to_port_id() == to_port):
			_document.remove_edge(e.get_id())
			break
	var from_idx := _output_index(from_node, from_port)
	var to_idx := _input_index(to_node, to_port)
	if from_idx >= 0 and to_idx >= 0:
		disconnect_node(from_node, from_idx, to_node, to_idx)
	graph_changed.emit()


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_connection_request(from_node: StringName, from_port: int,
		to_node: StringName, to_port: int) -> void:
	if _document == null:
		return
	var from_inst := _document.get_node(String(from_node))
	var to_inst := _document.get_node(String(to_node))
	if from_inst == null or to_inst == null:
		return
	var outputs := _effective_output_ports(from_inst)
	var inputs := _effective_input_ports(to_inst)
	if from_port >= outputs.size() or to_port >= inputs.size():
		return
	var from_port_id: String = outputs[from_port]["id"]
	var to_port_id: String   = inputs[to_port]["id"]
	var edge_id := _document.add_edge(from_node, from_port_id, to_node, to_port_id)
	if edge_id.is_empty():
		return
	connect_node(from_node, from_port, to_node, to_port)
	graph_changed.emit()
	if _undo_redo != null:
		var fn := String(from_node)
		var tn := String(to_node)
		_undo_redo.create_action("Connect Nodes")
		_undo_redo.add_do_method(self, "_cmd_add_edge", fn, from_port_id, tn, to_port_id)
		_undo_redo.add_undo_method(self, "_cmd_remove_edge", fn, from_port_id, tn, to_port_id)
		_undo_redo.commit_action(false)


func _on_disconnection_request(from_node: StringName, from_port: int,
		to_node: StringName, to_port: int) -> void:
	if _document == null:
		return
	var from_inst := _document.get_node(String(from_node))
	var to_inst := _document.get_node(String(to_node))
	if from_inst == null or to_inst == null:
		return
	var outputs := _effective_output_ports(from_inst)
	var inputs := _effective_input_ports(to_inst)
	if from_port >= outputs.size() or to_port >= inputs.size():
		return
	var from_port_id: String = outputs[from_port]["id"]
	var to_port_id: String   = inputs[to_port]["id"]
	for edge in _document.get_all_edges():
		var e := edge as ShaderGraphEdge
		if (e.get_from_node_id() == from_node and e.get_from_port_id() == from_port_id
				and e.get_to_node_id() == to_node and e.get_to_port_id() == to_port_id):
			_document.remove_edge(e.get_id())
			break
	disconnect_node(from_node, from_port, to_node, to_port)
	graph_changed.emit()
	if _undo_redo != null:
		var fn := String(from_node)
		var tn := String(to_node)
		_undo_redo.create_action("Disconnect Nodes")
		_undo_redo.add_do_method(self, "_cmd_remove_edge", fn, from_port_id, tn, to_port_id)
		_undo_redo.add_undo_method(self, "_cmd_add_edge", fn, from_port_id, tn, to_port_id)
		_undo_redo.commit_action(false)


func _on_node_selected(node: Node) -> void:
	if _document == null:
		return
	if node is GraphFrame:
		var frame_data := _document.get_frame(node.name)
		if not frame_data.is_empty():
			frame_selected_in_canvas.emit(frame_data, node)
		return
	var node_inst: ShaderGraphNodeInstance = _document.get_node(node.name)
	if node_inst != null:
		node_selected_in_canvas.emit(node_inst)


func _on_delete_nodes_request(nodes: Array) -> void:
	if _document == null:
		return

	# Handle frame deletions separately — frames are not in the node registry.
	var frames_deleted: Array = []
	for element_name in nodes:
		var eid := String(element_name)
		if not _document.get_frame(eid).is_empty():
			frames_deleted.append(eid)
	for fid in frames_deleted:
		var frame_data: Dictionary = _document.get_frame(fid).duplicate(true)
		_cmd_remove_frame(fid)
		if _undo_redo != null:
			_undo_redo.create_action("Delete Frame")
			_undo_redo.add_do_method(self, "_cmd_remove_frame", fid)
			_undo_redo.add_undo_method(self, "_cmd_add_frame",
					fid,
					frame_data.get("title", ""),
					frame_data.get("position", Vector2.ZERO),
					frame_data.get("size", Vector2(200, 150)),
					frame_data.get("attached_nodes", []).duplicate())
			_undo_redo.commit_action(false)

	# Collect data for all affected nodes and their edges (deduplicated).
	var nodes_data: Array = []
	var seen_edges: Dictionary = {}
	for node_name in nodes:
		var nid := String(node_name)
		# Skip frames — already handled above.
		if not _document.get_frame(nid).is_empty():
			continue
		var node_inst: ShaderGraphNodeInstance = _document.get_node(nid)
		if node_inst == null:
			continue
		var node_edges: Array = []
		for edge in _document.get_all_edges():
			var e := edge as ShaderGraphEdge
			if e.get_from_node_id() == nid or e.get_to_node_id() == nid:
				if not seen_edges.has(e.get_id()):
					seen_edges[e.get_id()] = true
					node_edges.append({
						"from_node": e.get_from_node_id(),
						"from_port": e.get_from_port_id(),
						"to_node":   e.get_to_node_id(),
						"to_port":   e.get_to_port_id()
					})
		nodes_data.append({
			"id":     nid,
			"def_id": node_inst.get_definition_id(),
			"pos":    node_inst.get_position(),
			"title":  node_inst.get_title(),
			"props":  node_inst.get_properties().duplicate(),
			"edges":  node_edges
		})

	# Perform the deletion.
	for nd in nodes_data:
		_document.remove_node(nd["id"])
		var widget := get_node_or_null(NodePath(nd["id"]))
		if is_instance_valid(widget):
			remove_child(widget)
			widget.queue_free()
	_rebuild_connections()
	graph_changed.emit()

	if _undo_redo == null:
		return

	_undo_redo.create_action("Delete Node(s)")
	# do (redo) = remove the nodes again
	for nd in nodes_data:
		_undo_redo.add_do_method(self, "_cmd_remove_node", nd["id"])
	# undo = restore nodes first, then edges
	for nd in nodes_data:
		_undo_redo.add_undo_method(self, "_cmd_add_node",
				nd["id"], nd["def_id"], nd["pos"], nd["title"], nd["props"])
	for nd in nodes_data:
		for ed in nd["edges"]:
			_undo_redo.add_undo_method(self, "_cmd_add_edge",
					ed["from_node"], ed["from_port"], ed["to_node"], ed["to_port"])
	_undo_redo.commit_action(false)


# ---------------------------------------------------------------------------
# Validation overlay
# ---------------------------------------------------------------------------

## Paints each node widget according to validation results.
## Nodes not mentioned in issues are cleared to their default state.
func apply_validation_result(issues: Array) -> void:
	var error_nodes: Dictionary = {}
	var warning_nodes: Dictionary = {}
	for issue in issues:
		var nid: String = issue.get("node_id", "")
		if nid.is_empty():
			continue
		if issue.get("severity", 0) == 2:  # ERROR
			error_nodes[nid] = true
		elif issue.get("severity", 0) == 1:  # WARNING
			if not error_nodes.has(nid):
				warning_nodes[nid] = true
	for child in get_children():
		if child is GraphNode:
			var nid := child.name as String
			child.set_validation_state(error_nodes.has(nid), warning_nodes.has(nid))


func clear_validation() -> void:
	for child in get_children():
		if child is GraphNode:
			child.set_validation_state(false, false)


# ---------------------------------------------------------------------------
# Frame (comment) nodes — Ctrl+G creates a frame around selected nodes
# ---------------------------------------------------------------------------

const _FRAME_PADDING := 24.0


func _create_frame_widget(frame_data: Dictionary) -> GraphFrame:
	var frame := GraphFrame.new()
	frame.name = frame_data["id"]
	frame.title = frame_data["title"]
	frame.position_offset = frame_data["position"]
	frame.size = frame_data["size"]
	# autoshrink=true: frame grows AND shrinks to contain attached nodes.
	# The user can still drag corners to make it larger than the minimum.
	frame.autoshrink_enabled = true
	frame.autoshrink_margin = int(_FRAME_PADDING)
	add_child(frame)
	# Frames must sit behind nodes in draw order.
	move_child(frame, 0)
	return frame


func _create_frame_from_selection() -> void:
	if _document == null:
		return
	var selected_ids := _get_selected_node_ids()
	if selected_ids.is_empty():
		return

	# Bounding box of all selected node widgets.
	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)
	for nid in selected_ids:
		var w := get_node_or_null(NodePath(nid))
		if not is_instance_valid(w):
			continue
		var gn := w as GraphNode
		min_pos = min_pos.min(gn.position_offset)
		max_pos = max_pos.max(gn.position_offset + gn.size)

	if min_pos.x == INF:
		return

	var pad := Vector2(_FRAME_PADDING, _FRAME_PADDING)
	var frame_pos  := min_pos - pad
	var frame_size := (max_pos - min_pos) + pad * 2.0

	var frame_id := _document.add_frame("Comment", frame_pos, frame_size)
	var frame_data := _document.get_frame(frame_id)
	frame_data["attached_nodes"] = selected_ids.duplicate()
	_create_frame_widget(frame_data)

	# Attach selected nodes so they move with the frame.
	for nid in selected_ids:
		attach_graph_element_to_frame(nid, frame_id)

	if _undo_redo != null:
		_undo_redo.create_action("Add Frame")
		_undo_redo.add_do_method(self, "_cmd_add_frame",
				frame_id, "Comment", frame_pos, frame_size, selected_ids.duplicate())
		_undo_redo.add_undo_method(self, "_cmd_remove_frame", frame_id)
		_undo_redo.commit_action(false)


func _cmd_add_frame(frame_id: String, title: String,
		pos: Vector2, sz: Vector2, attached: Array) -> void:
	_document.add_frame(title, pos, sz)
	var all_frames := _document.get_all_frames()
	var frame_data: Dictionary = all_frames[all_frames.size() - 1]
	frame_data["id"] = frame_id
	frame_data["attached_nodes"] = attached.duplicate()
	_create_frame_widget(frame_data)
	for nid in attached:
		if get_node_or_null(NodePath(nid)) != null:
			attach_graph_element_to_frame(nid, frame_id)
	graph_changed.emit()


func _cmd_remove_frame(frame_id: String) -> void:
	# Detach nodes before removing the frame widget.
	var frame_data := _document.get_frame(frame_id)
	for nid in frame_data.get("attached_nodes", []):
		if get_node_or_null(NodePath(nid)) != null:
			detach_graph_element_from_frame(nid)
	_document.remove_frame(frame_id)
	var widget := get_node_or_null(NodePath(frame_id))
	if is_instance_valid(widget):
		remove_child(widget)
		widget.queue_free()
	graph_changed.emit()


## Called by Godot when the user drags nodes onto a frame interactively.
func _on_elements_linked_to_frame(elements: Array, frame: StringName) -> void:
	var fid := String(frame)
	for element in elements:
		attach_graph_element_to_frame(String(element), fid)
	# Update attached_nodes in the document so it serializes correctly.
	var frame_data := _document.get_frame(fid)
	if not frame_data.is_empty():
		var attached := get_attached_nodes_of_frame(fid)
		frame_data["attached_nodes"] = attached.map(func(n): return String(n))


# ---------------------------------------------------------------------------
# Copy / Paste / Duplicate
# ---------------------------------------------------------------------------

func _get_selected_node_ids() -> Array:
	var result := []
	for child in get_children():
		if child is GraphNode and child.selected:
			result.append(child.name as String)
	return result


func _copy_selected() -> void:
	if _document == null:
		return
	var selected_ids := _get_selected_node_ids()
	if selected_ids.is_empty():
		return
	_clipboard.clear()
	_clipboard_edges.clear()
	var selected_set := {}
	for nid in selected_ids:
		selected_set[nid] = true
	# Compute centroid for relative positioning.
	var centroid := Vector2.ZERO
	for nid in selected_ids:
		var w := get_node_or_null(NodePath(nid))
		centroid += (w as GraphNode).position_offset if is_instance_valid(w) \
				else _document.get_node(nid).get_position()
	centroid /= selected_ids.size()
	# Snapshot each selected node.
	var node_index := {}
	for nid in selected_ids:
		var inst: ShaderGraphNodeInstance = _document.get_node(nid)
		if inst == null:
			continue
		var w := get_node_or_null(NodePath(nid))
		var pos := (w as GraphNode).position_offset if is_instance_valid(w) else inst.get_position()
		node_index[nid] = _clipboard.size()
		_clipboard.append({
			"def_id":   inst.get_definition_id(),
			"title":    inst.get_title(),
			"props":    inst.get_properties().duplicate(),
			"rel_pos":  pos - centroid,
		})
	# Snapshot edges between selected nodes.
	for edge in _document.get_all_edges():
		var e := edge as ShaderGraphEdge
		if selected_set.has(e.get_from_node_id()) and selected_set.has(e.get_to_node_id()):
			_clipboard_edges.append({
				"from_idx":  node_index[e.get_from_node_id()],
				"from_port": e.get_from_port_id(),
				"to_idx":    node_index[e.get_to_node_id()],
				"to_port":   e.get_to_port_id(),
			})


func _paste_clipboard() -> void:
	if _document == null or _clipboard.is_empty():
		return
	var paste_center := scroll_offset + size * 0.5 / zoom
	var nodes := []
	for nd in _clipboard:
		nodes.append({
			"def_id": nd["def_id"],
			"title":  nd["title"],
			"props":  nd["props"].duplicate(),
			"pos":    paste_center + nd["rel_pos"],
		})
	_spawn_nodes(nodes, _clipboard_edges)


func _duplicate_selected() -> void:
	if _document == null:
		return
	var selected_ids := _get_selected_node_ids()
	if selected_ids.is_empty():
		return
	var selected_set := {}
	for nid in selected_ids:
		selected_set[nid] = true
	var snap_nodes := []
	var snap_edges := []
	var node_index := {}
	for nid in selected_ids:
		var inst: ShaderGraphNodeInstance = _document.get_node(nid)
		if inst == null:
			continue
		var w := get_node_or_null(NodePath(nid))
		var pos := (w as GraphNode).position_offset if is_instance_valid(w) else inst.get_position()
		node_index[nid] = snap_nodes.size()
		snap_nodes.append({
			"def_id": inst.get_definition_id(),
			"title":  inst.get_title(),
			"props":  inst.get_properties().duplicate(),
			"pos":    pos + Vector2(30, 30),
		})
	for edge in _document.get_all_edges():
		var e := edge as ShaderGraphEdge
		if selected_set.has(e.get_from_node_id()) and selected_set.has(e.get_to_node_id()):
			snap_edges.append({
				"from_idx":  node_index[e.get_from_node_id()],
				"from_port": e.get_from_port_id(),
				"to_idx":    node_index[e.get_to_node_id()],
				"to_port":   e.get_to_port_id(),
			})
	_spawn_nodes(snap_nodes, snap_edges)


## Instantiates a batch of node snapshots onto the canvas and document.
## `nodes`: Array[{def_id, title, props, pos}]
## `edges`: Array[{from_idx, from_port, to_idx, to_port}] (indices into `nodes`)
func _spawn_nodes(nodes: Array, edges: Array) -> void:
	var new_ids := []
	for nd in nodes:
		var node_id := _document.add_node(nd["def_id"], nd["pos"])
		var inst: ShaderGraphNodeInstance = _document.get_node(node_id)
		if inst == null:
			new_ids.append("")
			continue
		inst.set_title(nd["title"])
		for key in nd["props"]:
			inst.set_property(key, nd["props"][key])
		apply_port_defaults(inst)
		_create_node_widget(inst)
		new_ids.append(node_id)
	for ed in edges:
		var fi: int = ed["from_idx"]
		var ti: int = ed["to_idx"]
		if fi >= new_ids.size() or ti >= new_ids.size():
			continue
		if new_ids[fi].is_empty() or new_ids[ti].is_empty():
			continue
		var edge_id := _document.add_edge(new_ids[fi], ed["from_port"], new_ids[ti], ed["to_port"])
		if not edge_id.is_empty():
			var from_idx := _output_index(new_ids[fi], ed["from_port"])
			var to_idx := _input_index(new_ids[ti], ed["to_port"])
			if from_idx >= 0 and to_idx >= 0:
				connect_node(new_ids[fi], from_idx, new_ids[ti], to_idx)
	graph_changed.emit()


func apply_port_defaults(node_inst: ShaderGraphNodeInstance) -> void:
	var def_id := node_inst.get_definition_id()
	if PORT_DEFAULTS.has(def_id):
		var defaults: Dictionary = PORT_DEFAULTS[def_id]
		for key in defaults:
			node_inst.set_property(key, defaults[key])
	# Custom function: seed with a no-op expression so the node compiles immediately.
	if def_id == "utility/custom_function":
		if node_inst.get_property("body") == null:
			node_inst.set_property("body", "0.0")
	# Subgraph: seed path so the inspector shows the picker right away.
	if def_id == "utility/subgraph":
		if node_inst.get_property("subgraph_path") == null:
			node_inst.set_property("subgraph_path", "")
	# Subgraph input/output: seed with default names.
	if def_id == "subgraph/input":
		if node_inst.get_property("input_name") == null:
			node_inst.set_property("input_name", "a")
		node_inst.set_property("input_type", SubgraphContract.input_port_type_name(node_inst))
		node_inst.set_property("port_id", "in_%s" % node_inst.get_id())
	if def_id == "subgraph/output":
		if node_inst.get_property("output_name") == null:
			node_inst.set_property("output_name", "out1")
		node_inst.set_property("output_type", SubgraphContract.output_port_type_name(node_inst))
		node_inst.set_property("port_id", "out_%s" % node_inst.get_id())
	# Parameter nodes: seed with a unique name and a type-appropriate default value.
	if def_id.begins_with("parameter/"):
		if node_inst.get_property("param_name") == null or \
				str(node_inst.get_property("param_name")).is_empty():
			node_inst.set_property("param_name", "my_param")
		if node_inst.get_property("default_value") == null:
			var _dv_default: String
			match def_id:
				"parameter/float":    _dv_default = "0.0"
				"parameter/vec4":     _dv_default = "vec4(0.0, 0.0, 0.0, 1.0)"
				"parameter/color":    _dv_default = "vec4(1.0, 1.0, 1.0, 1.0)"
				_:                    _dv_default = ""
			if not _dv_default.is_empty():
				node_inst.set_property("default_value", _dv_default)


func _on_node_chosen(def_id: String, graph_pos: Vector2) -> void:
	if _document == null:
		return
	var node_id := _document.add_node(def_id, graph_pos)
	var node_inst: ShaderGraphNodeInstance = _document.get_node(node_id)
	if node_inst == null:
		return
	var registry = Engine.get_singleton("NodeRegistry")
	if registry != null:
		var def = registry.get_definition(def_id)
		if def != null:
			node_inst.set_title(def.get_display_name())
	apply_port_defaults(node_inst)
	_create_node_widget(node_inst)
	graph_changed.emit()

	if _undo_redo != null:
		_undo_redo.create_action("Add Node")
		_undo_redo.add_do_method(self, "_cmd_add_node",
				node_id, def_id, graph_pos,
				node_inst.get_title(), node_inst.get_properties().duplicate())
		_undo_redo.add_undo_method(self, "_cmd_remove_node", node_id)
		_undo_redo.commit_action(false)
