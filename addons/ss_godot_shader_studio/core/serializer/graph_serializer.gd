## Saves and loads ShaderGraphDocument as JSON (.gshadergraph).
class_name GraphSerializer

const CURRENT_FORMAT_VERSION := 1


func save(doc: ShaderGraphDocument, path: String) -> Error:
	var d := _document_to_dict(doc)
	var json_text := JSON.stringify(d, "\t", false)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("GraphSerializer: cannot open file for writing: %s" % path)
		return FAILED
	file.store_string(json_text)
	file.close()
	return OK


func load(path: String) -> ShaderGraphDocument:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("GraphSerializer: cannot open file for reading: %s" % path)
		return null
	var json_text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_text)
	if parsed == null or not (parsed is Dictionary):
		push_error("GraphSerializer: invalid JSON in: %s" % path)
		return null

	var d: Dictionary = parsed
	var file_version: int = d.get("format_version", 0)
	if file_version < CURRENT_FORMAT_VERSION:
		d = _migrate(d, file_version, CURRENT_FORMAT_VERSION)

	return _dict_to_document(d)


# ---- Document → Dictionary ----

func _document_to_dict(doc: ShaderGraphDocument) -> Dictionary:
	var d := {
		"format_version": CURRENT_FORMAT_VERSION,
		"uuid":           doc.get_uuid(),
		"name":           doc.get_name(),
		"shader_domain":  doc.get_shader_domain(),
		"stage_config":   doc.get_stage_config(),
	}

	var nodes_arr := []
	for n in doc.get_all_nodes():
		var node := n as ShaderGraphNodeInstance
		nodes_arr.append({
			"id":              node.id,
			"definition_id":   node.definition_id,
			"title":           node.title,
			"position":        {"x": node.position.x, "y": node.position.y},
			"properties":      node.get_properties(),
			"stage_scope":     node.stage_scope,
			"preview_enabled": node.preview_enabled,
		})
	d["nodes"] = nodes_arr

	var edges_arr := []
	for e in doc.get_all_edges():
		var edge := e as ShaderGraphEdge
		edges_arr.append({
			"id":           edge.id,
			"from_node_id": edge.from_node_id,
			"from_port_id": edge.from_port_id,
			"to_node_id":   edge.to_node_id,
			"to_port_id":   edge.to_port_id,
		})
	d["edges"] = edges_arr

	var frames_arr := []
	for f in doc.get_all_frames():
		frames_arr.append({
			"id":    f["id"],
			"title": f["title"],
			"position":       {"x": f["position"].x, "y": f["position"].y},
			"size":           {"x": f["size"].x,     "y": f["size"].y},
			"attached_nodes": f.get("attached_nodes", []),
		})
	d["frames"] = frames_arr

	d["parameters"]    = doc.get_parameters()
	d["subgraph_refs"] = doc.get_subgraph_refs()
	d["editor_state"]  = doc.get_editor_state()
	return d


# ---- Dictionary → Document ----

func _dict_to_document(d: Dictionary) -> ShaderGraphDocument:
	var doc := ShaderGraphDocument.new()
	if d.has("uuid"):          doc.set_uuid(d["uuid"])
	if d.has("name"):          doc.set_name(d["name"])
	if d.has("shader_domain"): doc.set_shader_domain(d["shader_domain"])
	if d.has("stage_config"):  doc.set_stage_config(d["stage_config"])
	if d.has("parameters"):    doc.set_parameters(d["parameters"])
	if d.has("subgraph_refs"): doc.set_subgraph_refs(d["subgraph_refs"])
	if d.has("editor_state"):  doc.set_editor_state(d["editor_state"])

	if d.has("nodes"):
		var node_list := []
		for nd in d["nodes"]:
			var node := ShaderGraphNodeInstance.new()
			if nd.has("id"):              node.id = nd["id"]
			if nd.has("definition_id"):   node.definition_id = nd["definition_id"]
			if nd.has("title"):           node.title = nd["title"]
			if nd.has("properties"):      node.set_properties(nd["properties"])
			if nd.has("stage_scope"):     node.stage_scope = nd["stage_scope"]
			if nd.has("preview_enabled"): node.preview_enabled = nd["preview_enabled"]
			if nd.has("position"):
				var pos: Dictionary = nd["position"]
				node.position = Vector2(float(pos.get("x", 0.0)), float(pos.get("y", 0.0)))
			node_list.append(node)
		doc.set_nodes(node_list)  # also syncs counters

	if d.has("edges"):
		var edge_list := []
		for ed in d["edges"]:
			var edge := ShaderGraphEdge.new()
			if ed.has("id"):           edge.id = ed["id"]
			if ed.has("from_node_id"): edge.from_node_id = ed["from_node_id"]
			if ed.has("from_port_id"): edge.from_port_id = ed["from_port_id"]
			if ed.has("to_node_id"):   edge.to_node_id = ed["to_node_id"]
			if ed.has("to_port_id"):   edge.to_port_id = ed["to_port_id"]
			edge_list.append(edge)
		doc.set_edges(edge_list)

	if d.has("frames"):
		var frame_list := []
		for fd in d["frames"]:
			var pos_d: Dictionary = fd.get("position", {})
			var sz_d:  Dictionary = fd.get("size", {})
			frame_list.append({
				"id":             fd.get("id", ""),
				"title":          fd.get("title", ""),
				"position":       Vector2(float(pos_d.get("x", 0.0)), float(pos_d.get("y", 0.0))),
				"size":           Vector2(float(sz_d.get("x", 200.0)), float(sz_d.get("y", 150.0))),
				"attached_nodes": fd.get("attached_nodes", []),
			})
		doc.set_frames(frame_list)

	return doc


# ---- Migration ----

func _migrate(d: Dictionary, _from: int, _to: int) -> Dictionary:
	# No migrations needed yet.
	return d
