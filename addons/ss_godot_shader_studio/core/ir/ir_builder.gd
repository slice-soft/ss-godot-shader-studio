## Transforms a validated ShaderGraphDocument into an IRGraph dictionary.
## IRGraph: {
##   "shader_domain": String,
##   "uniforms": Array,         # [{name, type, glsl_hint, default_value}]
##   "varyings": Array,         # [{name, type}]
##   "helper_functions": Array, # [String]
##   "vertex_nodes": Array,     # [IRNode]
##   "fragment_nodes": Array,   # [IRNode]
## }
## IRNode: {
##   "node_id": String,
##   "definition_id": String,
##   "compiler_template": String,
##   "properties": Dictionary,
##   "stage": String,
##   "resolved_inputs": Dictionary,  # port_id -> IRValue
##   "output_vars": Dictionary,       # port_id -> IRValue
## }
## IRValue: {"var_name": String, "type": int}
class_name IRBuilder

const SubgraphContract = preload("res://addons/ss_godot_shader_studio/core/graph/subgraph_contract.gd")

## Shared counter used across build() and subgraph expansions so var names
## never collide even when multiple subgraphs are embedded.
static var _global_counter: int = 0


static func _effective_inputs(
		doc: ShaderGraphDocument,
		node: ShaderGraphNodeInstance,
		registry: NodeRegistry) -> Array:
	return SubgraphContract.get_input_ports(doc, node, registry)


static func _effective_outputs(
		doc: ShaderGraphDocument,
		node: ShaderGraphNodeInstance,
		registry: NodeRegistry) -> Array:
	return SubgraphContract.get_output_ports(doc, node, registry)


static func _coerce_value_to_type(resolved_input: Dictionary, target_type: int) -> Dictionary:
	var resolved := resolved_input.duplicate()
	var cast := TypeSystem.get_cast_type(resolved["type"], target_type)
	if cast == SGSTypes.CastType.IMPLICIT_SPLAT:
		var glsl_type := TypeSystem.type_to_glsl(target_type)
		resolved["var_name"] = "%s(%s)" % [glsl_type, resolved["var_name"]]
		resolved["type"] = target_type
	elif cast == SGSTypes.CastType.IMPLICIT_TRUNCATE:
		var tc := TypeSystem.get_component_count(target_type)
		var swiz := [".x", ".xy", ".xyz", ".xyzw"]
		resolved["var_name"] = resolved["var_name"] + swiz[tc - 1]
		resolved["type"] = target_type
	elif cast == SGSTypes.CastType.IMPLICIT_VEC3_TO_COLOR:
		resolved["var_name"] = "vec4(%s, 1.0)" % resolved["var_name"]
		resolved["type"] = target_type
	return resolved


static func _zero_value_for_type(port_type: int) -> Dictionary:
	var glsl_type := TypeSystem.type_to_glsl(port_type)
	var zero := "0.0"
	match glsl_type:
		"vec2":
			zero = "vec2(0.0)"
		"vec3":
			zero = "vec3(0.0)"
		"vec4":
			zero = "vec4(0.0)"
		"sampler2D":
			zero = "sampler2D()"
	return {"var_name": zero, "type": port_type}


static func _resolved_stage(node: ShaderGraphNodeInstance, def: ShaderNodeDefinition) -> String:
	if node.stage_scope == "vertex":
		return "vertex"
	if node.stage_scope == "fragment":
		return "fragment"
	if def.stage_support == SGSTypes.STAGE_VERTEX:
		return "vertex"
	return "fragment"


static func _supports_stage_varyings(domain: String) -> bool:
	return domain == "spatial" or domain == "canvas_item" or domain == "fullscreen"


static func build(doc: ShaderGraphDocument, registry: NodeRegistry) -> Dictionary:
	_global_counter = 0
	var ir := {
		"shader_domain": doc.get_shader_domain(),
		"uniforms": [],
		"varyings": [],
		"helper_functions": [],
		"vertex_nodes": [],
		"fragment_nodes": [],
	}

	# 1. Topological sort (Kahn's algorithm)
	var sorted := _topological_sort(doc)
	var node_stage_map: Dictionary = {}
	for node_id in sorted:
		var node := doc.get_node(node_id)
		if node == null:
			continue
		var def := registry.get_definition(node.definition_id)
		if def == null:
			continue
		node_stage_map[node_id] = _resolved_stage(node, def)

	# 2. Assign output variable names: "node_id::port_id" → IRValue
	# Transparent nodes (reroute, subgraph) are skipped — they get their
	# var_names resolved lazily (3b and 5 respectively).
	# Parameter nodes use their param_name as the var_name (IS the uniform).
	var var_map := {}  # "node_id::port_id" → {var_name, type}
	for node_id in sorted:
		var node := doc.get_node(node_id)
		if node == null:
			continue
		var def := registry.get_definition(node.definition_id)
		if def == null:
			continue
		var skip := (node.definition_id == "utility/reroute"
				or node.definition_id == "utility/subgraph"
				or node.definition_id == "subgraph/input"
				or node.definition_id == "subgraph/output")
		if skip:
			continue
		for port in _effective_outputs(doc, node, registry):
			var key := "%s::%s" % [node_id, port["id"]]
			if node.definition_id.begins_with("parameter/"):
				# Output var_name IS the uniform name — downstream nodes reference it directly.
				var param_name: String = str(node.get_property("param_name")) \
						if node.get_property("param_name") != null else ("param_%d" % _global_counter)
				var_map[key] = {"var_name": param_name, "type": port["type"]}
			else:
				var_map[key] = {"var_name": "_t%d" % _global_counter, "type": port["type"]}
				_global_counter += 1

	# 3. Build edge lookup: "to_node_id::to_port_id" → IRValue
	var input_lookup := {}
	var varying_by_source: Dictionary = {}
	var varying_assignments: Dictionary = {}
	for e in doc.get_all_edges():
		var edge := e as ShaderGraphEdge
		var from_key := "%s::%s" % [edge.from_node_id, edge.from_port_id]
		var to_key   := "%s::%s" % [edge.to_node_id, edge.to_port_id]
		if not var_map.has(from_key):
			continue
		var from_stage := String(node_stage_map.get(edge.from_node_id, "fragment"))
		var to_stage := String(node_stage_map.get(edge.to_node_id, "fragment"))
		if from_stage == "vertex" \
				and to_stage == "fragment" \
				and _supports_stage_varyings(doc.get_shader_domain()):
			if not varying_by_source.has(from_key):
				var varying_name := "_v%d" % ir["varyings"].size()
				var varying_value := {
					"var_name": varying_name,
					"type": var_map[from_key]["type"],
				}
				varying_by_source[from_key] = varying_value
				ir["varyings"].append({
					"name": varying_name,
					"type": varying_value["type"],
				})
				if not varying_assignments.has(edge.from_node_id):
					varying_assignments[edge.from_node_id] = []
				varying_assignments[edge.from_node_id].append({
					"port_id": edge.from_port_id,
					"varying_name": varying_name,
				})
			input_lookup[to_key] = (varying_by_source[from_key] as Dictionary).duplicate()
			continue
		input_lookup[to_key] = var_map[from_key].duplicate()

	# 3b. Propagate reroute nodes (in topological order so chains work).
	for node_id in sorted:
		var node := doc.get_node(node_id)
		if node == null or node.definition_id != "utility/reroute":
			continue
		var in_key  := "%s::in"  % node_id
		var out_key := "%s::out" % node_id
		if input_lookup.has(in_key):
			var pass_val: Dictionary = input_lookup[in_key].duplicate()
			var_map[out_key] = pass_val
			for e in doc.get_all_edges():
				var edge := e as ShaderGraphEdge
				if edge.from_node_id == node_id and edge.from_port_id == "out":
					var downstream := "%s::%s" % [edge.to_node_id, edge.to_port_id]
					input_lookup[downstream] = pass_val.duplicate()

	# 4. Collect uniforms from parameter/* nodes in the graph.
	var seen_uniforms: Dictionary = {}
	for node_id in sorted:
		var node := doc.get_node(node_id)
		if node == null or not node.definition_id.begins_with("parameter/"):
			continue
		var param_name: String = str(node.get_property("param_name")) \
				if node.get_property("param_name") != null else ""
		if param_name.is_empty() or seen_uniforms.has(param_name):
			continue
		seen_uniforms[param_name] = true
		var def := registry.get_definition(node.definition_id)
		if def == null or def.outputs.is_empty():
			continue
		var port_type: int = def.outputs[0]["type"]
		var glsl_hint := ""
		if node.definition_id == "parameter/color":
			glsl_hint = ": source_color"
		elif node.definition_id == "parameter/texture2d":
			var tex_hint = node.get_property("texture_hint")
			var tex_hint_str := str(tex_hint) if tex_hint != null else ""
			if not tex_hint_str.is_empty():
				glsl_hint = ": %s" % tex_hint_str
		var dv: Variant = node.get_property("default_value")
		ir["uniforms"].append({
			"name":          param_name,
			"type":          port_type,
			"glsl_hint":     glsl_hint,
			"default_value": str(dv) if dv != null and str(dv) != "" else "",
		})

	# 4b. Collect auto_uniforms from node definitions (e.g. hint_screen_texture).
	for node_id in sorted:
		var node := doc.get_node(node_id)
		if node == null:
			continue
		var def := registry.get_definition(node.definition_id)
		if def == null or def.auto_uniform.is_empty():
			continue
		var uname: String = def.auto_uniform["name"]
		if seen_uniforms.has(uname):
			continue
		seen_uniforms[uname] = true
		ir["uniforms"].append(def.auto_uniform.duplicate())

	# 4c. Collect helper_functions from node definitions (deduped by full string).
	var seen_helpers: Dictionary = {}
	for node_id in sorted:
		var node := doc.get_node(node_id)
		if node == null:
			continue
		var def := registry.get_definition(node.definition_id)
		if def == null:
			continue
		for hf: String in def.helper_functions:
			if not seen_helpers.has(hf):
				seen_helpers[hf] = true
				ir["helper_functions"].append(hf)

	# 5. Build IR nodes.
	# Transparent: reroute, parameter/*, subgraph/input, subgraph/output → skip.
	# Special: utility/subgraph → expand inline.
	# Special: utility/custom_function → dynamic template from 'body' property.
	for node_id in sorted:
		var node := doc.get_node(node_id)
		if node == null:
			continue
		var def := registry.get_definition(node.definition_id)
		if def == null:
			continue

		var transparent := (node.definition_id == "utility/reroute"
				or node.definition_id.begins_with("parameter/")
				or node.definition_id == "subgraph/input"
				or node.definition_id == "subgraph/output")
		if transparent:
			continue

		# --- Subgraph inline expansion ---
		if node.definition_id == "utility/subgraph":
			_expand_subgraph_node(node, node_id, ir, registry, var_map, input_lookup, doc)
			continue

		var ir_node := {
			"node_id": node_id,
			"definition_id": node.definition_id,
			"compiler_template": def.compiler_template,
			"properties": node.get_properties(),
			"stage": node.stage_scope,
			"resolved_inputs": {},
			"output_vars": {},
			"post_lines": [],
		}

		# --- Custom Function: build template from 'body' property ---
		if node.definition_id == "utility/custom_function":
			var body_val = node.get_property("body")
			var body: String = str(body_val) if body_val != null and str(body_val) != "" else "0.0"
			ir_node["compiler_template"] = "float {result} = " + body + ";"

		# Resolve inputs
		for port in _effective_inputs(doc, node, registry):
			var pid: String = port["id"]
			var to_key := "%s::%s" % [node_id, pid]
			if input_lookup.has(to_key):
				ir_node["resolved_inputs"][pid] = _coerce_value_to_type(input_lookup[to_key], port["type"])
			else:
				ir_node["resolved_inputs"][pid] = _resolve_default(node, port)

		# Assign output vars
		for port in _effective_outputs(doc, node, registry):
			var pid: String = port["id"]
			var key := "%s::%s" % [node_id, pid]
			if var_map.has(key):
				ir_node["output_vars"][pid] = var_map[key]

		if varying_assignments.has(node_id):
			for entry in varying_assignments[node_id]:
				var port_id: String = entry["port_id"]
				if not ir_node["output_vars"].has(port_id):
					continue
				var source_var: String = ir_node["output_vars"][port_id]["var_name"]
				ir_node["post_lines"].append("%s = %s;" % [entry["varying_name"], source_var])

		# Stage routing
		var is_vertex: bool = String(node_stage_map.get(node_id, "fragment")) == "vertex"
		if is_vertex:
			ir["vertex_nodes"].append(ir_node)
		else:
			ir["fragment_nodes"].append(ir_node)

	return ir


# ---------------------------------------------------------------------------
# Subgraph inline expansion
# ---------------------------------------------------------------------------

## Loads and expands a utility/subgraph node into the parent IR.
## After this call, var_map and input_lookup are updated so downstream nodes
## in the parent graph can resolve the subgraph's output values.
static func _expand_subgraph_node(
		node: ShaderGraphNodeInstance,
		node_id: String,
		ir: Dictionary,
		registry: NodeRegistry,
		var_map: Dictionary,
		input_lookup: Dictionary,
		doc: ShaderGraphDocument) -> void:

	var sg_path: String = str(node.get_property("subgraph_path")) \
			if node.get_property("subgraph_path") != null else ""
	if sg_path.is_empty():
		return

	var contract := SubgraphContract.load_contract_from_path(sg_path)
	if not contract.get("valid", false):
		push_warning("IRBuilder: could not load subgraph '%s' — node '%s' will be skipped." \
				% [sg_path, node_id])
		return

	var sg_doc := _load_subgraph(contract.get("resolved_path", sg_path))
	if sg_doc == null:
		push_warning("IRBuilder: could not load subgraph '%s' — node '%s' will be skipped." \
				% [sg_path, node_id])
		return

	# Resolve this subgraph node's inputs from the parent input_lookup.
	var parent_inputs: Dictionary = {}  # contract port_id → IRValue
	for port in contract.get("inputs", []):
		var port_id: String = port["id"]
		var to_key := "%s::%s" % [node_id, port_id]
		if input_lookup.has(to_key):
			parent_inputs[port_id] = input_lookup[to_key].duplicate()

	# Expand the subgraph and get its output IRValues.
	var prefix := "%s_sg_" % node_id
	var sg_outputs: Dictionary = _expand_subgraph_doc(
			sg_doc, prefix, parent_inputs, ir, registry)

	# Populate var_map for this subgraph node's outputs.
	for out_id in sg_outputs:
		var_map["%s::%s" % [node_id, out_id]] = sg_outputs[out_id]

	# Update input_lookup for all downstream nodes connected to this subgraph's outputs.
	for e in doc.get_all_edges():
		var edge := e as ShaderGraphEdge
		if edge.from_node_id != node_id:
			continue
		var out_key := "%s::%s" % [node_id, edge.from_port_id]
		if var_map.has(out_key):
			input_lookup["%s::%s" % [edge.to_node_id, edge.to_port_id]] = var_map[out_key].duplicate()


## Expands a ShaderGraphDocument (subgraph) into the parent IR.
## Returns a Dictionary mapping output port ids (out1, out2) to their IRValues.
static func _expand_subgraph_doc(
		sg_doc: ShaderGraphDocument,
		prefix: String,
		parent_inputs: Dictionary,
		ir: Dictionary,
		registry: NodeRegistry) -> Dictionary:

	var sorted := _topological_sort(sg_doc)
	var sg_var_map := {}

	# Assign prefixed var names for all non-transparent nodes.
	for node_id in sorted:
		var node := sg_doc.get_node(node_id)
		if node == null:
			continue
		var def := registry.get_definition(node.definition_id)
		if def == null:
			continue
		if node.definition_id == "subgraph/input" \
				or node.definition_id == "subgraph/output":
			continue
		for port in _effective_outputs(sg_doc, node, registry):
			var key := "%s::%s" % [node_id, port["id"]]
			sg_var_map[key] = {"var_name": "%s_t%d" % [prefix, _global_counter], "type": port["type"]}
			_global_counter += 1

	# Wire subgraph/input nodes: map their output to the parent's input var.
	for node_id in sorted:
		var node := sg_doc.get_node(node_id)
		if node == null or node.definition_id != "subgraph/input":
			continue
		var contract_id := SubgraphContract.contract_id_for_node(node, true)
		var input_type := SubgraphContract.get_input_port_type(node)
		if parent_inputs.has(contract_id):
			sg_var_map["%s::value" % node_id] = _coerce_value_to_type(parent_inputs[contract_id], input_type)
		else:
			sg_var_map["%s::value" % node_id] = _zero_value_for_type(input_type)

	# Build edge lookup for the subgraph.
	var sg_input_lookup := {}
	for e in sg_doc.get_all_edges():
		var edge := e as ShaderGraphEdge
		var from_key := "%s::%s" % [edge.from_node_id, edge.from_port_id]
		var to_key   := "%s::%s" % [edge.to_node_id, edge.to_port_id]
		if sg_var_map.has(from_key):
			sg_input_lookup[to_key] = sg_var_map[from_key].duplicate()

	# Build IR nodes for regular subgraph nodes; capture outputs.
	var outputs: Dictionary = {}
	for node_id in sorted:
		var node := sg_doc.get_node(node_id)
		if node == null:
			continue
		var def := registry.get_definition(node.definition_id)
		if def == null:
			continue

		if node.definition_id == "subgraph/input":
			continue  # wired above

		if node.definition_id == "subgraph/output":
			var out_name := SubgraphContract.contract_id_for_node(node, false)
			var in_key := "%s::value" % node_id
			if sg_input_lookup.has(in_key):
				outputs[out_name] = sg_input_lookup[in_key].duplicate()
			else:
				outputs[out_name] = _zero_value_for_type(SubgraphContract.get_output_port_type(node))
			continue

		if node.definition_id == "utility/reroute" \
				or node.definition_id.begins_with("parameter/"):
			continue  # transparent within subgraph too

		var ir_node := {
			"node_id": prefix + node_id,
			"definition_id": node.definition_id,
			"compiler_template": def.compiler_template,
			"properties": node.get_properties(),
			"stage": node.stage_scope,
			"resolved_inputs": {},
			"output_vars": {},
		}

		if node.definition_id == "utility/custom_function":
			var body_val = node.get_property("body")
			var body: String = str(body_val) if body_val != null and str(body_val) != "" else "0.0"
			ir_node["compiler_template"] = "float {result} = " + body + ";"

		for port in _effective_inputs(sg_doc, node, registry):
			var pid: String = port["id"]
			var to_key := "%s::%s" % [node_id, pid]
			if sg_input_lookup.has(to_key):
				ir_node["resolved_inputs"][pid] = _coerce_value_to_type(sg_input_lookup[to_key], port["type"])
			else:
				ir_node["resolved_inputs"][pid] = _resolve_default(node, port)

		for port in _effective_outputs(sg_doc, node, registry):
			var pid: String = port["id"]
			var key := "%s::%s" % [node_id, pid]
			if sg_var_map.has(key):
				ir_node["output_vars"][pid] = sg_var_map[key]

		var is_vertex: bool = (node.stage_scope == "vertex") or \
							  (def.stage_support == SGSTypes.STAGE_VERTEX)
		if is_vertex:
			ir["vertex_nodes"].append(ir_node)
		else:
			ir["fragment_nodes"].append(ir_node)

	return outputs


static func _load_subgraph(path: String) -> ShaderGraphDocument:
	var resolved_path := SubgraphContract.resolve_subgraph_path(path)
	if resolved_path.is_empty():
		return null
	var serializer := GraphSerializer.new()
	var doc := serializer.load(resolved_path)
	if doc == null or doc.get_shader_domain() != "subgraph":
		return null
	return doc


# ---------------------------------------------------------------------------
# Topological sort (Kahn's)
# ---------------------------------------------------------------------------

static func _topological_sort(doc: ShaderGraphDocument) -> Array:
	var in_degree: Dictionary = {}
	var adj: Dictionary = {}

	for n in doc.get_all_nodes():
		var nid: String = (n as ShaderGraphNodeInstance).id
		in_degree[nid] = 0
		adj[nid] = []

	for e in doc.get_all_edges():
		var edge := e as ShaderGraphEdge
		adj[edge.from_node_id].append(edge.to_node_id)
		in_degree[edge.to_node_id] = in_degree.get(edge.to_node_id, 0) + 1

	var queue: Array = []
	for nid in in_degree:
		if in_degree[nid] == 0:
			queue.append(nid)
	queue.sort()

	var sorted: Array = []
	while not queue.is_empty():
		var curr: String = queue.pop_front()
		sorted.append(curr)
		var neighbors: Array = adj.get(curr, []).duplicate()
		neighbors.sort()
		for neighbor in neighbors:
			in_degree[neighbor] -= 1
			if in_degree[neighbor] == 0:
				var inserted := false
				for i in range(queue.size()):
					if neighbor < queue[i]:
						queue.insert(i, neighbor)
						inserted = true
						break
				if not inserted:
					queue.append(neighbor)
	return sorted


# ---------------------------------------------------------------------------
# Default value resolution
# ---------------------------------------------------------------------------

static func _resolve_default(node: ShaderGraphNodeInstance, port: Dictionary) -> Dictionary:
	var port_type: int = port["type"]
	var glsl_type := TypeSystem.type_to_glsl(port_type)

	var override = node.get_property(port["id"])
	if override != null and str(override) != "":
		return {"var_name": str(override), "type": port_type}

	var dv = port.get("default", null)
	if dv != null:
		if dv is float or dv is int:
			var fv := float(dv)
			return {"var_name": "%.1f" % fv if fv == int(fv) else str(fv), "type": port_type}

	var zero := "0.0"
	match glsl_type:
		"vec2":  zero = "vec2(0.0)"
		"vec3":  zero = "vec3(0.0)"
		"vec4":  zero = "vec4(0.0)"
	return {"var_name": zero, "type": port_type}


static func _param_type_from_string(s: String) -> int:
	match s:
		"float":             return SGSTypes.ShaderType.FLOAT
		"vec2":              return SGSTypes.ShaderType.VEC2
		"vec3":              return SGSTypes.ShaderType.VEC3
		"vec4", "color":     return SGSTypes.ShaderType.VEC4
		"sampler2D":         return SGSTypes.ShaderType.SAMPLER2D
		_:                   return SGSTypes.ShaderType.FLOAT
