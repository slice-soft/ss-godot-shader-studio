## Resolves dynamic port contracts for subgraphs and subgraph-backed nodes.
class_name SubgraphContract

const SUPPORTED_TYPE_NAMES := ["float", "vec2", "vec3", "vec4", "color", "sampler2D"]

static var _cache: Dictionary = {}


static func get_input_ports(
		doc: ShaderGraphDocument,
		node: ShaderGraphNodeInstance,
		registry: NodeRegistry) -> Array:
	if node == null:
		return []

	match node.get_definition_id():
		"subgraph/output":
			return [_make_value_port("value", _display_name(node, false), get_output_port_type(node))]
		"utility/subgraph":
			return load_contract_from_path(_subgraph_path_of(node)).get("inputs", []).duplicate(true)
		_:
			var def := registry.get_definition(node.get_definition_id()) if registry != null else null
			return def.inputs.duplicate(true) if def != null else []


static func get_output_ports(
		doc: ShaderGraphDocument,
		node: ShaderGraphNodeInstance,
		registry: NodeRegistry) -> Array:
	if node == null:
		return []

	match node.get_definition_id():
		"subgraph/input":
			return [_make_value_port("value", _display_name(node, true), get_input_port_type(node))]
		"utility/subgraph":
			return load_contract_from_path(_subgraph_path_of(node)).get("outputs", []).duplicate(true)
		_:
			var def := registry.get_definition(node.get_definition_id()) if registry != null else null
			return def.outputs.duplicate(true) if def != null else []


static func load_contract_from_path(path: String) -> Dictionary:
	var contract := {
		"requested_path": path,
		"resolved_path": "",
		"valid": false,
		"inputs": [],
		"outputs": [],
		"error": "",
	}
	if path.is_empty():
		contract["error"] = "missing_path"
		return contract

	var resolved_path := resolve_subgraph_path(path)
	contract["resolved_path"] = resolved_path
	if resolved_path.is_empty():
		contract["error"] = "missing_file"
		return contract

	var modified_time := FileAccess.get_modified_time(resolved_path)
	if _cache.has(resolved_path):
		var cached: Dictionary = _cache[resolved_path]
		if cached.get("modified_time", -1) == modified_time:
			return cached.get("contract", contract).duplicate(true)

	var serializer := GraphSerializer.new()
	var doc := serializer.load(resolved_path)
	if doc == null:
		contract["error"] = "load_failed"
		return contract
	if doc.get_shader_domain() != "subgraph":
		contract["error"] = "wrong_domain"
		return contract

	contract = build_contract_from_document(doc)
	contract["requested_path"] = path
	contract["resolved_path"] = resolved_path
	contract["valid"] = true
	contract["error"] = ""

	_cache[resolved_path] = {
		"modified_time": modified_time,
		"contract": contract.duplicate(true),
	}
	return contract.duplicate(true)


static func build_contract_from_document(doc: ShaderGraphDocument) -> Dictionary:
	var contract := {
		"requested_path": "",
		"resolved_path": "",
		"valid": doc != null and doc.get_shader_domain() == "subgraph",
		"inputs": [],
		"outputs": [],
		"error": "",
	}
	if doc == null:
		contract["valid"] = false
		contract["error"] = "missing_document"
		return contract
	if doc.get_shader_domain() != "subgraph":
		contract["valid"] = false
		contract["error"] = "wrong_domain"
		return contract

	var inputs: Array = []
	var outputs: Array = []
	for entry in doc.get_all_nodes():
		var node := entry as ShaderGraphNodeInstance
		if node == null:
			continue
		if node.get_definition_id() == "subgraph/input":
			inputs.append(_contract_entry(node, true))
		elif node.get_definition_id() == "subgraph/output":
			outputs.append(_contract_entry(node, false))

	inputs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _contract_sort_key(a) < _contract_sort_key(b)
	)
	outputs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _contract_sort_key(a) < _contract_sort_key(b)
	)

	contract["inputs"] = inputs
	contract["outputs"] = outputs
	return contract


static func resolve_subgraph_path(path: String) -> String:
	if path.is_empty():
		return ""
	if FileAccess.file_exists(path):
		return path

	var basename := path.get_basename()
	var preferred := "%s.gssubgraph" % basename
	if FileAccess.file_exists(preferred):
		return preferred

	var legacy := "%s.gshadergraph" % basename
	if FileAccess.file_exists(legacy):
		return legacy

	return ""


static func contract_id_for_node(node: ShaderGraphNodeInstance, is_input: bool) -> String:
	if node == null:
		return ""
	var raw_id := str(node.get_property("port_id")) if node.get_property("port_id") != null else ""
	if not raw_id.is_empty():
		return raw_id
	return "%s_%s" % ["in" if is_input else "out", node.get_id()]


static func get_input_port_type(node: ShaderGraphNodeInstance) -> int:
	return type_name_to_enum(input_port_type_name(node))


static func get_output_port_type(node: ShaderGraphNodeInstance) -> int:
	return type_name_to_enum(output_port_type_name(node))


static func input_port_type_name(node: ShaderGraphNodeInstance) -> String:
	var raw := str(node.get_property("input_type")) if node != null and node.get_property("input_type") != null else ""
	return normalize_type_name(raw)


static func output_port_type_name(node: ShaderGraphNodeInstance) -> String:
	var raw := str(node.get_property("output_type")) if node != null and node.get_property("output_type") != null else ""
	return normalize_type_name(raw)


static func normalize_type_name(raw_type: String) -> String:
	var normalized := raw_type.strip_edges().to_lower()
	match normalized:
		"", "float":
			return "float"
		"vec2":
			return "vec2"
		"vec3":
			return "vec3"
		"vec4":
			return "vec4"
		"color":
			return "color"
		"sampler2d", "texture2d":
			return "sampler2D"
		_:
			return "float"


static func type_name_to_enum(type_name: String) -> int:
	match normalize_type_name(type_name):
		"vec2":
			return SGSTypes.ShaderType.VEC2
		"vec3":
			return SGSTypes.ShaderType.VEC3
		"vec4":
			return SGSTypes.ShaderType.VEC4
		"color":
			return SGSTypes.ShaderType.COLOR
		"sampler2D":
			return SGSTypes.ShaderType.SAMPLER2D
		_:
			return SGSTypes.ShaderType.FLOAT


static func raw_type_name_is_supported(raw_type: String) -> bool:
	var normalized := raw_type.strip_edges().to_lower()
	return normalized.is_empty() \
			or normalized == "float" \
			or normalized == "vec2" \
			or normalized == "vec3" \
			or normalized == "vec4" \
			or normalized == "color" \
			or normalized == "sampler2d" \
			or normalized == "texture2d"


static func _contract_entry(node: ShaderGraphNodeInstance, is_input: bool) -> Dictionary:
	var type_name := input_port_type_name(node) if is_input else output_port_type_name(node)
	var position := node.get_position()
	return {
		"id": contract_id_for_node(node, is_input),
		"name": _display_name(node, is_input),
		"type": type_name_to_enum(type_name),
		"type_name": type_name,
		"node_id": node.get_id(),
		"position": position,
	}


static func _contract_sort_key(entry: Dictionary) -> String:
	var position: Vector2 = entry.get("position", Vector2.ZERO)
	return "%08d_%08d_%s" % [
		int(round(position.y * 100.0)),
		int(round(position.x * 100.0)),
		str(entry.get("node_id", "")),
	]


static func _make_value_port(port_id: String, display_name: String, port_type: int) -> Dictionary:
	return {
		"id": port_id,
		"name": display_name,
		"type": port_type,
		"default": null,
		"optional": false,
	}


static func _display_name(node: ShaderGraphNodeInstance, is_input: bool) -> String:
	if node == null:
		return "Value"

	var property_name := "input_name" if is_input else "output_name"
	var fallback := "Input" if is_input else "Output"
	var raw_name := str(node.get_property(property_name)) if node.get_property(property_name) != null else ""
	var display := raw_name.strip_edges()
	return display if not display.is_empty() else fallback


static func _subgraph_path_of(node: ShaderGraphNodeInstance) -> String:
	return str(node.get_property("subgraph_path")) if node != null and node.get_property("subgraph_path") != null else ""
