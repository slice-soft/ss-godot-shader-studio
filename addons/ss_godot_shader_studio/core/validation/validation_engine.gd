## Validates a ShaderGraphDocument against the registry.
## Returns a Dictionary: {"success": bool, "issues": Array[Dictionary]}
## Each issue: {"severity": int, "node_id": String, "port_id": String, "message": String, "code": String}
class_name ValidationEngine

const SubgraphContract = preload("res://addons/ss_godot_shader_studio/core/graph/subgraph_contract.gd")


func validate(doc: ShaderGraphDocument, registry: NodeRegistry) -> Dictionary:
	var issues: Array = []
	_pass_structural(doc, registry, issues)
	if _has_errors(issues):
		return {"success": false, "issues": issues}
	_pass_subgraphs(doc, issues)
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


func _effective_inputs(
		doc: ShaderGraphDocument,
		node: ShaderGraphNodeInstance,
		registry: NodeRegistry) -> Array:
	return SubgraphContract.get_input_ports(doc, node, registry)


func _effective_outputs(
		doc: ShaderGraphDocument,
		node: ShaderGraphNodeInstance,
		registry: NodeRegistry) -> Array:
	return SubgraphContract.get_output_ports(doc, node, registry)


func _port_ids(ports: Array) -> Array:
	var ids := []
	for port in ports:
		ids.append(port["id"])
	return ids


func _port_type(ports: Array, port_id: String) -> int:
	for port in ports:
		if port["id"] == port_id:
			return port["type"]
	return SGSTypes.ShaderType.VOID


func _domain_flag(domain: String) -> int:
	match domain:
		"spatial":
			return SGSTypes.DOMAIN_SPATIAL
		"canvas_item":
			return SGSTypes.DOMAIN_CANVAS_ITEM
		"particles":
			return SGSTypes.DOMAIN_PARTICLES
		"sky":
			return SGSTypes.DOMAIN_SKY
		"fog":
			return SGSTypes.DOMAIN_FOG
		"fullscreen":
			return SGSTypes.DOMAIN_FULLSCREEN
		"subgraph":
			return SGSTypes.DOMAIN_ALL
		_:
			return 0


func _resolved_stage(node: ShaderGraphNodeInstance, def: ShaderNodeDefinition) -> String:
	if node.stage_scope == "vertex":
		return "vertex"
	if node.stage_scope == "fragment":
		return "fragment"
	if def.stage_support == SGSTypes.STAGE_VERTEX:
		return "vertex"
	return "fragment"


func _supports_stage_varyings(domain: String) -> bool:
	return domain == "spatial" or domain == "canvas_item" or domain == "fullscreen"


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
		var from_node := doc.get_node(edge.from_node_id)
		var to_node := doc.get_node(edge.to_node_id)
		var from_ports := _effective_outputs(doc, from_node, registry)
		var to_ports := _effective_inputs(doc, to_node, registry)
		if edge.from_port_id not in _port_ids(from_ports):
			issues.append(_issue(2, edge.from_node_id, edge.from_port_id,
				"Edge references unknown output port '%s'" % edge.from_port_id, "E008"))
		if edge.to_port_id not in _port_ids(to_ports):
			issues.append(_issue(2, edge.to_node_id, edge.to_port_id,
				"Edge references unknown input port '%s'" % edge.to_port_id, "E009"))


func _pass_subgraphs(doc: ShaderGraphDocument, issues: Array) -> void:
	var seen_inputs: Dictionary = {}
	var seen_outputs: Dictionary = {}

	for entry in doc.get_all_nodes():
		var node := entry as ShaderGraphNodeInstance
		if node == null:
			continue

		if node.definition_id == "utility/subgraph":
			var sg_path := str(node.get_property("subgraph_path")) \
					if node.get_property("subgraph_path") != null else ""
			if sg_path.is_empty():
				issues.append(_issue(2, node.id, "subgraph_path",
					"Subgraph node requires a .gssubgraph source path.", "E040"))
				continue
			var contract := SubgraphContract.load_contract_from_path(sg_path)
			if contract.get("valid", false):
				continue
			match contract.get("error", ""):
				"missing_file":
					issues.append(_issue(2, node.id, "subgraph_path",
						"Subgraph file was not found: %s" % sg_path, "E041"))
				"wrong_domain":
					issues.append(_issue(2, node.id, "subgraph_path",
						"Referenced file is not a subgraph: %s" % contract.get("resolved_path", sg_path), "E042"))
				_:
					issues.append(_issue(2, node.id, "subgraph_path",
						"Subgraph file could not be loaded: %s" % sg_path, "E043"))

		if doc.get_shader_domain() != "subgraph":
			continue

		if node.definition_id == "subgraph/input":
			var input_name := str(node.get_property("input_name")) if node.get_property("input_name") != null else ""
			input_name = input_name.strip_edges()
			if input_name.is_empty():
				issues.append(_issue(2, node.id, "input_name",
					"Subgraph input nodes need a visible input_name.", "E044"))
			elif seen_inputs.has(input_name):
				issues.append(_issue(2, node.id, "input_name",
					"Duplicate subgraph input name '%s'." % input_name, "E045"))
			else:
				seen_inputs[input_name] = true

			var raw_input_type := str(node.get_property("input_type")) if node.get_property("input_type") != null else ""
			if not SubgraphContract.raw_type_name_is_supported(raw_input_type):
				issues.append(_issue(2, node.id, "input_type",
					"Unsupported subgraph input type '%s'." % raw_input_type, "E046"))

		elif node.definition_id == "subgraph/output":
			var output_name := str(node.get_property("output_name")) if node.get_property("output_name") != null else ""
			output_name = output_name.strip_edges()
			if output_name.is_empty():
				issues.append(_issue(2, node.id, "output_name",
					"Subgraph output nodes need a visible output_name.", "E047"))
			elif seen_outputs.has(output_name):
				issues.append(_issue(2, node.id, "output_name",
					"Duplicate subgraph output name '%s'." % output_name, "E048"))
			else:
				seen_outputs[output_name] = true

			var raw_output_type := str(node.get_property("output_type")) if node.get_property("output_type") != null else ""
			if not SubgraphContract.raw_type_name_is_supported(raw_output_type):
				issues.append(_issue(2, node.id, "output_type",
					"Unsupported subgraph output type '%s'." % raw_output_type, "E049"))


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
		var from_ports := _effective_outputs(doc, from_node, registry)
		var to_ports := _effective_inputs(doc, to_node, registry)
		var from_type := _port_type(from_ports, edge.from_port_id)
		var to_type   := _port_type(to_ports, edge.to_port_id)
		if from_type == SGSTypes.ShaderType.VOID or to_type == SGSTypes.ShaderType.VOID:
			continue
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
	var domain := doc.get_shader_domain()
	var domain_flag := _domain_flag(domain)
	var stage_by_node: Dictionary = {}

	for n in doc.get_all_nodes():
		var node := n as ShaderGraphNodeInstance
		var def := registry.get_definition(node.definition_id)
		if def == null:
			continue
		if domain != "subgraph" and domain_flag != 0 and not def.supports_domain(domain_flag):
			issues.append(_issue(2, node.id, "",
				"Node '%s' is not available in '%s' shaders" % [node.definition_id, domain], "E013"))
		if node.stage_scope == "vertex" and not def.supports_stage(SGSTypes.STAGE_VERTEX):
			issues.append(_issue(2, node.id, "",
				"Node '%s' does not support vertex stage" % node.definition_id, "E011"))
		elif node.stage_scope == "fragment" and not def.supports_stage(SGSTypes.STAGE_FRAGMENT):
			issues.append(_issue(2, node.id, "",
				"Node '%s' does not support fragment stage" % node.definition_id, "E012"))
		stage_by_node[node.id] = _resolved_stage(node, def)

	for entry in doc.get_all_edges():
		var edge := entry as ShaderGraphEdge
		if edge == null:
			continue
		var from_node := doc.get_node(edge.from_node_id)
		var to_node := doc.get_node(edge.to_node_id)
		if from_node == null or to_node == null:
			continue
		var from_def := registry.get_definition(from_node.definition_id)
		var to_def := registry.get_definition(to_node.definition_id)
		if from_def == null or to_def == null:
			continue
		var from_stage := stage_by_node.get(from_node.id, _resolved_stage(from_node, from_def))
		var to_stage := stage_by_node.get(to_node.id, _resolved_stage(to_node, to_def))
		if from_stage == to_stage:
			continue
		if from_stage == "fragment" and to_stage == "vertex":
			issues.append(_issue(2, to_node.id, edge.to_port_id,
				"Fragment-stage data cannot feed vertex-stage input '%s'." % edge.to_port_id, "E014"))
		elif from_stage == "vertex" and to_stage == "fragment" and not _supports_stage_varyings(domain):
			issues.append(_issue(2, to_node.id, edge.to_port_id,
				"Domain '%s' does not support automatic vertex-to-fragment varying transfer." % domain, "E015"))


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
