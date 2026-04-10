## Validates a ShaderGraphDocument against the registry.
## Returns a Dictionary: {"success": bool, "issues": Array[Dictionary]}
## Each issue: {"severity": int, "node_id": String, "port_id": String, "message": String, "code": String}
class_name ValidationEngine


func validate(doc: ShaderGraphDocument, registry: NodeRegistry) -> Dictionary:
	var issues: Array = []
	_pass_structural(doc, registry, issues)
	if _has_errors(issues):
		return {"success": false, "issues": issues}
	_pass_typing(doc, registry, issues)
	if _has_errors(issues):
		return {"success": false, "issues": issues}
	_pass_stage(doc, registry, issues)
	_pass_cycles(doc, issues)
	_pass_outputs(doc, registry, issues)
	return {"success": not _has_errors(issues), "issues": issues}


func _has_errors(issues: Array) -> bool:
	for i in issues:
		if i["severity"] == 2:  # ERROR
			return true
	return false


func _issue(severity: int, node_id: String, port_id: String,
		message: String, code: String) -> Dictionary:
	return {"severity": severity, "node_id": node_id, "port_id": port_id,
			"message": message, "code": code}


# ---- Pass 1: Structural ----

func _pass_structural(doc: ShaderGraphDocument, registry: NodeRegistry, issues: Array) -> void:
	var nodes := doc.get_all_nodes()
	var edges := doc.get_all_edges()
	var node_ids := {}

	for n in nodes:
		var node := n as ShaderGraphNodeInstance
		if node == null:
			issues.append(_issue(2, "", "", "Null node in document", "E001"))
			continue
		if node_ids.has(node.id):
			issues.append(_issue(2, node.id, "", "Duplicate node id: %s" % node.id, "E002"))
		node_ids[node.id] = true
		if registry.get_definition(node.definition_id) == null:
			issues.append(_issue(2, node.id, "", "Unknown definition_id: '%s'" % node.definition_id, "E003"))

	var edge_ids := {}
	for e in edges:
		var edge := e as ShaderGraphEdge
		if edge == null:
			issues.append(_issue(2, "", "", "Null edge in document", "E004"))
			continue
		if edge_ids.has(edge.id):
			issues.append(_issue(2, "", "", "Duplicate edge id: %s" % edge.id, "E005"))
		edge_ids[edge.id] = true
		if not node_ids.has(edge.from_node_id):
			issues.append(_issue(2, "", "", "Edge from_node_id references unknown node: %s" % edge.from_node_id, "E006"))
		if not node_ids.has(edge.to_node_id):
			issues.append(_issue(2, "", "", "Edge to_node_id references unknown node: %s" % edge.to_node_id, "E007"))

		if _has_errors(issues):
			continue
		var from_def := registry.get_definition(doc.get_node(edge.from_node_id).definition_id)
		var to_def   := registry.get_definition(doc.get_node(edge.to_node_id).definition_id)
		if from_def and edge.from_port_id not in from_def.get_output_ids():
			issues.append(_issue(2, edge.from_node_id, edge.from_port_id,
				"Edge references unknown output port '%s'" % edge.from_port_id, "E008"))
		if to_def and edge.to_port_id not in to_def.get_input_ids():
			issues.append(_issue(2, edge.to_node_id, edge.to_port_id,
				"Edge references unknown input port '%s'" % edge.to_port_id, "E009"))


# ---- Pass 2: Typing ----

func _pass_typing(doc: ShaderGraphDocument, registry: NodeRegistry, issues: Array) -> void:
	for e in doc.get_all_edges():
		var edge := e as ShaderGraphEdge
		var from_node := doc.get_node(edge.from_node_id)
		var to_node   := doc.get_node(edge.to_node_id)
		if from_node == null or to_node == null:
			continue
		# Reroute nodes are type-transparent pass-throughs; skip type checks at their ports.
		if from_node.definition_id == "utility/reroute" \
				or to_node.definition_id == "utility/reroute":
			continue
		var from_def := registry.get_definition(from_node.definition_id)
		var to_def   := registry.get_definition(to_node.definition_id)
		if from_def == null or to_def == null:
			continue
		var from_type := from_def.get_output_type(edge.from_port_id)
		var to_type   := to_def.get_input_type(edge.to_port_id)
		var cast := TypeSystem.get_cast_type(from_type, to_type)
		if cast == SGSTypes.CastType.INCOMPATIBLE:
			issues.append(_issue(2, edge.to_node_id, edge.to_port_id,
				"Incompatible types: %s -> %s" % [
					TypeSystem.type_to_display_name(from_type),
					TypeSystem.type_to_display_name(to_type)], "E010"))
		elif cast == SGSTypes.CastType.IMPLICIT_TRUNCATE:
			issues.append(_issue(1, edge.to_node_id, edge.to_port_id,
				"Lossy cast: %s -> %s (truncation)" % [
					TypeSystem.type_to_display_name(from_type),
					TypeSystem.type_to_display_name(to_type)], "W001"))


# ---- Pass 3: Stage ----

func _pass_stage(doc: ShaderGraphDocument, registry: NodeRegistry, issues: Array) -> void:
	for n in doc.get_all_nodes():
		var node := n as ShaderGraphNodeInstance
		var def := registry.get_definition(node.definition_id)
		if def == null:
			continue
		if node.stage_scope == "vertex" and not def.supports_stage(SGSTypes.STAGE_VERTEX):
			issues.append(_issue(2, node.id, "",
				"Node '%s' does not support vertex stage" % node.definition_id, "E011"))
		elif node.stage_scope == "fragment" and not def.supports_stage(SGSTypes.STAGE_FRAGMENT):
			issues.append(_issue(2, node.id, "",
				"Node '%s' does not support fragment stage" % node.definition_id, "E012"))


# ---- Pass 4: Cycle detection (DFS) ----

func _pass_cycles(doc: ShaderGraphDocument, issues: Array) -> void:
	var adj: Dictionary = {}
	for n in doc.get_all_nodes():
		adj[(n as ShaderGraphNodeInstance).id] = []
	for e in doc.get_all_edges():
		var edge := e as ShaderGraphEdge
		if adj.has(edge.from_node_id):
			adj[edge.from_node_id].append(edge.to_node_id)

	# 0=white, 1=gray, 2=black
	var color: Dictionary = {}
	for nid in adj:
		color[nid] = 0

	for start in adj:
		if color[start] == 0:
			if _dfs_has_cycle(start, adj, color):
				issues.append(_issue(2, "", "",
					"Graph contains a cycle — shader graphs must be acyclic", "E020"))
				return


func _dfs_has_cycle(node: String, adj: Dictionary, color: Dictionary) -> bool:
	color[node] = 1
	for neighbor in adj.get(node, []):
		if color.get(neighbor, 0) == 1:
			return true
		if color.get(neighbor, 0) == 0 and _dfs_has_cycle(neighbor, adj, color):
			return true
	color[node] = 2
	return false


# ---- Pass 5: Output nodes ----

func _pass_outputs(doc: ShaderGraphDocument, registry: NodeRegistry, issues: Array) -> void:
	var domain := doc.get_shader_domain()
	# Subgraph files use domain "subgraph" — they don't need an output node.
	if domain == "subgraph":
		return
	var required_map := {
		"spatial":     "output/spatial",
		"canvas_item": "output/canvas_item",
		"particles":   "output/particles",
		"sky":         "output/sky",
		"fog":         "output/fog",
		"fullscreen":  "output/fullscreen",
	}
	var required: String = required_map.get(domain, "")
	if required.is_empty():
		return
	for n in doc.get_all_nodes():
		if (n as ShaderGraphNodeInstance).definition_id == required:
			return
	issues.append(_issue(2, "", "",
		"Document has no output node for domain '%s'. Add a '%s' node." % [domain, required], "E030"))
