## Root resource representing a shader graph: nodes, edges, metadata.
class_name ShaderGraphDocument
extends Resource

var uuid: String = ""
var name: String = "Untitled"
var format_version: int = 1
var shader_domain: String = "spatial"
var stage_config: Dictionary = {"has_vertex": true, "has_fragment": true, "has_light": false}
var parameters: Array = []
var subgraph_refs: Array = []
var editor_state: Dictionary = {}

var _nodes: Array = []   # Array[ShaderGraphNodeInstance]
var _edges: Array = []   # Array[ShaderGraphEdge]
var _frames: Array = []  # Array[Dictionary] — {id, title, position, size}
var _node_counter: int = 0
var _edge_counter: int = 0
var _frame_counter: int = 0


# ---- Identity accessors (mirror C++ API) ----

func get_uuid() -> String:          return uuid
func get_name() -> String:          return name
func get_format_version() -> int:   return format_version
func get_shader_domain() -> String: return shader_domain
func get_stage_config() -> Dictionary: return stage_config
func get_parameters() -> Array:     return parameters
func get_subgraph_refs() -> Array:  return subgraph_refs
func get_editor_state() -> Dictionary: return editor_state
func get_generated_shader_dir() -> String: return str(editor_state.get("generated_shader_dir", ""))

func set_uuid(v: String) -> void:          uuid = v
func set_name(v: String) -> void:          name = v
func set_format_version(v: int) -> void:   format_version = v
func set_shader_domain(v: String) -> void: shader_domain = v
func set_stage_config(v: Dictionary) -> void: stage_config = v
func set_parameters(v: Array) -> void:     parameters = v
func set_subgraph_refs(v: Array) -> void:  subgraph_refs = v
func set_editor_state(v: Dictionary) -> void: editor_state = v
func set_generated_shader_dir(v: String) -> void: editor_state["generated_shader_dir"] = v


# ---- Node management ----

func add_node(definition_id: String, position: Vector2) -> String:
	_node_counter += 1
	var node := ShaderGraphNodeInstance.new()
	node.id = "node_%d" % _node_counter
	node.definition_id = definition_id
	node.title = definition_id
	node.position = position
	_nodes.append(node)
	return node.id


func remove_node(node_id: String) -> void:
	for i in range(_nodes.size() - 1, -1, -1):
		if (_nodes[i] as ShaderGraphNodeInstance).id == node_id:
			_nodes.remove_at(i)
			break
	# Remove all edges connected to this node
	for i in range(_edges.size() - 1, -1, -1):
		var e := _edges[i] as ShaderGraphEdge
		if e.from_node_id == node_id or e.to_node_id == node_id:
			_edges.remove_at(i)


func get_node(node_id: String) -> ShaderGraphNodeInstance:
	for n in _nodes:
		if (n as ShaderGraphNodeInstance).id == node_id:
			return n as ShaderGraphNodeInstance
	return null


func get_all_nodes() -> Array:
	return _nodes


# ---- Edge management ----

func add_edge(from_node: String, from_port: String,
		to_node: String, to_port: String) -> String:
	# Prevent duplicate connections to the same input port
	for e in _edges:
		var edge := e as ShaderGraphEdge
		if edge.to_node_id == to_node and edge.to_port_id == to_port:
			return ""
	_edge_counter += 1
	var edge := ShaderGraphEdge.new()
	edge.id = "edge_%d" % _edge_counter
	edge.from_node_id = from_node
	edge.from_port_id = from_port
	edge.to_node_id   = to_node
	edge.to_port_id   = to_port
	_edges.append(edge)
	return edge.id


func remove_edge(edge_id: String) -> void:
	for i in range(_edges.size()):
		if (_edges[i] as ShaderGraphEdge).id == edge_id:
			_edges.remove_at(i)
			return


func get_edges_from(node_id: String) -> Array:
	var result := []
	for e in _edges:
		if (e as ShaderGraphEdge).from_node_id == node_id:
			result.append(e)
	return result


func get_edges_to(node_id: String) -> Array:
	var result := []
	for e in _edges:
		if (e as ShaderGraphEdge).to_node_id == node_id:
			result.append(e)
	return result


func get_all_edges() -> Array:
	return _edges


# ---- Frame management ----

func add_frame(title: String, pos: Vector2, sz: Vector2) -> String:
	_frame_counter += 1
	var frame := {
		"id":       "frame_%d" % _frame_counter,
		"title":    title,
		"position": pos,
		"size":     sz,
	}
	_frames.append(frame)
	return frame["id"]


func remove_frame(frame_id: String) -> void:
	for i in range(_frames.size() - 1, -1, -1):
		if _frames[i]["id"] == frame_id:
			_frames.remove_at(i)
			return


func get_frame(frame_id: String) -> Dictionary:
	for f in _frames:
		if f["id"] == frame_id:
			return f
	return {}


func get_all_frames() -> Array:
	return _frames


# ---- Raw array access (used by serializer) ----

func get_nodes() -> Array: return _nodes
func get_edges() -> Array: return _edges
func get_frames() -> Array: return _frames

func set_nodes(nodes: Array) -> void:
	_nodes = nodes
	# Sync counter to avoid collisions with restored node IDs.
	_node_counter = 0
	for n in _nodes:
		var nid: String = (n as ShaderGraphNodeInstance).id
		if nid.begins_with("node_"):
			var num := nid.trim_prefix("node_").to_int()
			if num > _node_counter:
				_node_counter = num

func set_edges(edges: Array) -> void:
	_edges = edges
	_edge_counter = 0
	for e in _edges:
		var eid: String = (e as ShaderGraphEdge).id
		if eid.begins_with("edge_"):
			var num := eid.trim_prefix("edge_").to_int()
			if num > _edge_counter:
				_edge_counter = num


func set_frames(frames: Array) -> void:
	_frames = frames
	_frame_counter = 0
	for f in _frames:
		var fid: String = f.get("id", "")
		if fid.begins_with("frame_"):
			var num := fid.trim_prefix("frame_").to_int()
			if num > _frame_counter:
				_frame_counter = num
